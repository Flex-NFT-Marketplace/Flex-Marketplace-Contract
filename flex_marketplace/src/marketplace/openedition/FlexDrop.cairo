#[starknet::contract]
mod FlexDrop {
    use flex::marketplace::utils::openedition::PublicDrop;
    use flex::marketplace::openedition::interfaces::IFlexDrop::IFlexDrop;
    use flex::marketplace::openedition::interfaces::INonFungibleFlexDropToken::{
        INonFungibleFlexDropTokenDispatcher, INonFungibleFlexDropTokenDispatcherTrait,
        I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID
    };
    use flex::marketplace::{
        currency_manager::{ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait}
    };
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use alexandria_storage::list::{List, ListTrait};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use array::{Array, ArrayTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy, event: ReentrancyGuardEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;

    impl ReentrancyGuardImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        // mapping nft address => Public drop
        public_drops: LegacyMap::<ContractAddress, PublicDrop>,
        // mapping nft address => creator payout address
        creator_payout_address: LegacyMap::<ContractAddress, ContractAddress>,
        // mapping (nft address, fee recipient) => is allowed
        allowed_fee_recipients: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        // mapping nft address => enumerated allowed fee recipients
        enumerated_allowed_fee_recipients: LegacyMap::<ContractAddress, List<ContractAddress>>,
        // mapping (nft address, payer) => is allowed
        allowed_payer: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        // protocol fee
        fee_bps: u128,
        // mapping nft address => enumerated allowed payer
        enumerated_allowed_payer: LegacyMap::<ContractAddress, List<ContractAddress>>,
        currency_manager: ICurrencyManagerDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancy: ReentrancyGuardComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FlexDropMinted: FlexDropMinted,
        ChangeFeeBPS: ChangeFeeBPS,
        PublicDropUpdated: PublicDropUpdated,
        CreatorPayoutUpdated: CreatorPayoutUpdated,
        FeeRecipientUpdated: FeeRecipientUpdated,
        PayerUpdated: PayerUpdated,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct FlexDropMinted {
        #[key]
        nft_address: ContractAddress,
        minter: ContractAddress,
        fee_recipient: ContractAddress,
        payer: ContractAddress,
        quantity_minted: u64,
        total_mint_price: u256,
        fee_bps: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct ChangeFeeBPS {
        old_fee_bps: u128,
        new_fee_bps: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct PublicDropUpdated {
        #[key]
        nft_address: ContractAddress,
        public_drop: PublicDrop,
    }

    #[derive(Drop, starknet::Event)]
    struct CreatorPayoutUpdated {
        #[key]
        nft_address: ContractAddress,
        new_payout_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct FeeRecipientUpdated {
        #[key]
        nft_address: ContractAddress,
        fee_recipient: ContractAddress,
        allowed: bool
    }

    #[derive(Drop, starknet::Event)]
    struct PayerUpdated {
        #[key]
        nft_address: ContractAddress,
        payer: ContractAddress,
        allowed: bool
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        currency_manager: ContractAddress,
        fee_bps: u128,
    ) {
        self.ownable.initializer(owner);

        assert(fee_bps <= 10_000, 'Invalid Fee Basic Points');
        self.fee_bps.write(fee_bps);
        self
            .currency_manager
            .write(ICurrencyManagerDispatcher { contract_address: currency_manager });
    }

    #[abi(embed_v0)]
    impl FlexDropImpl of IFlexDrop<ContractState> {
        fn mint_public(
            ref self: ContractState,
            nft_address: ContractAddress,
            fee_recipient: ContractAddress,
            minter_if_not_payer: ContractAddress,
            quantity: u64,
            currency: ContractAddress,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
            let public_drop = self.public_drops.read(nft_address);
            self.assert_active_public_drop(@public_drop);

            self.assert_whitelisted_currency(@currency);

            let mut minter = get_caller_address();
            if !minter_if_not_payer.is_zero() {
                minter = minter_if_not_payer.clone();
            }

            if minter != get_caller_address() {
                self.assert_allowed_payer(nft_address, get_caller_address());
            }

            self
                .assert_valid_mint_quantity(
                    @nft_address, @minter, quantity, public_drop.max_mint_per_wallet
                );

            self
                .assert_allowed_fee_recipient(
                    @nft_address, @fee_recipient, public_drop.restrict_fee_recipients
                );

            let total_mint_price = quantity.into() * public_drop.mint_price;
            self
                .mint_and_pay(
                    nft_address,
                    get_caller_address(),
                    minter,
                    quantity,
                    currency,
                    total_mint_price,
                    self.fee_bps.read(),
                    fee_recipient
                );
            self.reentrancy.end();
        }

        fn update_public_drop(ref self: ContractState, public_drop: PublicDrop) {
            self.pausable.assert_not_paused();
            self.assert_only_non_fungible_flex_drop_token();

            self.public_drops.write(get_caller_address(), public_drop);
            self.emit(PublicDropUpdated { nft_address: get_caller_address(), public_drop });
        }

        fn update_creator_payout_address(
            ref self: ContractState, new_payout_address: ContractAddress
        ) {
            self.pausable.assert_not_paused();
            self.assert_only_non_fungible_flex_drop_token();

            assert(!new_payout_address.is_zero(), 'Only non zero payout address');
            self.creator_payout_address.write(get_caller_address(), new_payout_address);

            self
                .emit(
                    CreatorPayoutUpdated { nft_address: get_caller_address(), new_payout_address }
                );
        }

        fn update_allowed_fee_recipient(
            ref self: ContractState, fee_recipient: ContractAddress, allowed: bool
        ) {
            self.pausable.assert_not_paused();
            self.assert_only_non_fungible_flex_drop_token();
            assert(!fee_recipient.is_zero(), 'Only non zero fee recipient');

            let nft_address = get_caller_address();
            if allowed {
                assert(
                    !self.allowed_fee_recipients.read((nft_address, fee_recipient)),
                    'Duplicate Fee Recipient'
                );
                self.allowed_fee_recipients.write((nft_address, fee_recipient), true);
                let mut enumerated_allowed_fee_recipients = self
                    .enumerated_allowed_fee_recipients
                    .read(nft_address);
                enumerated_allowed_fee_recipients.append(fee_recipient);
                self
                    .enumerated_allowed_fee_recipients
                    .write(nft_address, enumerated_allowed_fee_recipients);
            } else {
                assert(
                    self.allowed_fee_recipients.read((nft_address, fee_recipient)),
                    'Fee Recipient not present'
                );
                self.allowed_fee_recipients.write((nft_address, fee_recipient), false);
                self.remove_enumerated_allowed_fee_recipient(nft_address, fee_recipient);
            }

            self.emit(FeeRecipientUpdated { nft_address, fee_recipient, allowed });
        }

        fn update_payer(ref self: ContractState, payer: ContractAddress, allowed: bool) {
            self.pausable.assert_not_paused();
            self.assert_only_non_fungible_flex_drop_token();
            assert(!payer.is_zero(), 'Only non zero payer');

            let nft_address = get_caller_address();
            if allowed {
                assert(!self.allowed_payer.read((nft_address, payer)), 'Duplicate payer');
                self.allowed_payer.write((nft_address, payer), true);

                let mut enumerated_allowed_payer = self.enumerated_allowed_payer.read(nft_address);
                enumerated_allowed_payer.append(payer);
                self.enumerated_allowed_payer.write(nft_address, enumerated_allowed_payer);
            } else {
                assert(self.allowed_payer.read((nft_address, payer)), 'Payer not present');
                self.allowed_payer.write((nft_address, payer), false);
                self.remove_enumerated_allowed_payer(nft_address, payer);
            }

            self.emit(PayerUpdated { nft_address, payer, allowed });
        }
    }

    #[abi(per_item)]
    #[generate_trait]
    impl AdditionalAccessors of AdditionalAccessorsTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable._pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable._unpause();
        }

        #[external(v0)]
        fn change_currency_manager(ref self: ContractState, new_currency_manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self
                .currency_manager
                .write(ICurrencyManagerDispatcher { contract_address: new_currency_manager })
        }

        #[external(v0)]
        fn change_fee_bps(ref self: ContractState, new_fee_bps: u128) {
            self.ownable.assert_only_owner();

            assert(new_fee_bps <= 10_000, 'Invalid Fee Basic Points');
            let old_fee_bps = self.fee_bps.read();
            self.fee_bps.write(new_fee_bps);

            self.emit(ChangeFeeBPS { old_fee_bps, new_fee_bps })
        }

        #[external(v0)]
        fn get_fee_bps(self: @ContractState) -> u128 {
            self.fee_bps.read()
        }

        #[external(v0)]
        fn get_public_drop(self: @ContractState, nft_address: ContractAddress) -> PublicDrop {
            self.public_drops.read(nft_address)
        }

        #[external(v0)]
        fn get_currency_manager(self: @ContractState) -> ContractAddress {
            self.currency_manager.read().contract_address
        }

        #[external(v0)]
        fn get_creator_payout_address(
            self: @ContractState, nft_address: ContractAddress
        ) -> ContractAddress {
            self.creator_payout_address.read(nft_address)
        }

        #[external(v0)]
        fn get_enumerated_allowed_fee_recipients(
            self: @ContractState, nft_address: ContractAddress
        ) -> Span::<ContractAddress> {
            self.enumerated_allowed_fee_recipients.read(nft_address).array().span()
        }

        #[external(v0)]
        fn get_enumerated_allowed_payer(
            self: @ContractState, nft_address: ContractAddress
        ) -> Span::<ContractAddress> {
            self.enumerated_allowed_payer.read(nft_address).array().span()
        }

        fn assert_only_non_fungible_flex_drop_token(self: @ContractState) {
            let nft_address = get_caller_address();
            let is_supported_interface = ISRC5Dispatcher { contract_address: nft_address }
                .supports_interface(I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID);
        }

        fn assert_active_public_drop(self: @ContractState, public_drop: @PublicDrop) {
            let block_time = get_block_timestamp();
            assert(
                *public_drop.start_time <= block_time && *public_drop.end_time > block_time,
                'Public drop not active'
            );
        }

        fn assert_whitelisted_currency(self: @ContractState, currency: @ContractAddress) {
            assert(
                self.currency_manager.read().is_currency_whitelisted(*currency),
                'currency is not whitelisted'
            );
        }


        fn assert_allowed_payer(
            self: @ContractState, nft_address: ContractAddress, payer: ContractAddress
        ) {
            assert(self.allowed_payer.read((nft_address, payer)), 'Only allowed payer');
        }

        fn assert_valid_mint_quantity(
            self: @ContractState,
            nft_address: @ContractAddress,
            minter: @ContractAddress,
            quantity: u64,
            max_total_mint_per_wallet: u64,
        ) {
            assert(quantity > 0, 'Only non zero quantity');

            let (total_minted, current_total_supply, max_supply) =
                INonFungibleFlexDropTokenDispatcher {
                contract_address: *nft_address
            }
                .get_mint_state(*minter);

            assert(
                total_minted + quantity <= max_total_mint_per_wallet, 'Exceeds maximum total minted'
            );
            assert(quantity + current_total_supply <= max_supply, 'Exceeds maximum total supply');
        }

        fn assert_allowed_fee_recipient(
            self: @ContractState,
            nft_address: @ContractAddress,
            fee_recipient: @ContractAddress,
            restrict_fee_recipient: bool
        ) {
            assert(!(*fee_recipient).is_zero(), 'Only non zero fee recipient');

            if restrict_fee_recipient {
                assert(
                    self.allowed_fee_recipients.read((*nft_address, *fee_recipient)),
                    'Only allowed fee recipient'
                );
            }
        }

        fn mint_and_pay(
            ref self: ContractState,
            nft_address: ContractAddress,
            payer: ContractAddress,
            minter: ContractAddress,
            quantity: u64,
            currency_address: ContractAddress,
            total_mint_price: u256,
            fee_bps: u128,
            fee_recipient: ContractAddress
        ) {
            if total_mint_price != 0 {
                self
                    .split_payout(
                        payer,
                        nft_address,
                        fee_recipient,
                        fee_bps,
                        currency_address,
                        total_mint_price
                    );
            }

            INonFungibleFlexDropTokenDispatcher { contract_address: nft_address }
                .mint_flex_drop(minter, quantity);

            self
                .emit(
                    FlexDropMinted {
                        nft_address,
                        minter,
                        fee_recipient,
                        payer,
                        quantity_minted: quantity,
                        total_mint_price,
                        fee_bps,
                    }
                )
        }

        fn split_payout(
            ref self: ContractState,
            from: ContractAddress,
            nft_address: ContractAddress,
            fee_recipient: ContractAddress,
            fee_bps: u128,
            currency_address: ContractAddress,
            total_mint_price: u256
        ) {
            assert(fee_bps <= 10_000, 'Invalid Fee Basic Points');

            let creator_payout_address = self.creator_payout_address.read(nft_address);
            assert(!creator_payout_address.is_zero(), 'Only non zero creator payout');

            let currency_contract = IERC20Dispatcher { contract_address: currency_address };
            if fee_bps == 0 {
                currency_contract.transfer_from(from, creator_payout_address, total_mint_price);
                return;
            }

            let fee_amount = (total_mint_price * fee_bps.into()) / 10_000;
            let payout_amount = total_mint_price - fee_amount;

            if fee_amount > 0 {
                currency_contract.transfer_from(from, fee_recipient, fee_amount);
            }

            currency_contract.transfer_from(from, creator_payout_address, payout_amount);
        }

        fn remove_enumerated_allowed_fee_recipient(
            ref self: ContractState, nft_address: ContractAddress, to_remove: ContractAddress
        ) {
            let mut enumerated_allowed_fee_recipients = self
                .enumerated_allowed_fee_recipients
                .read(nft_address);

            let mut index = 0;
            let enumerated_allowed_fee_recipients_length = enumerated_allowed_fee_recipients.len();
            let mut new_enumerated_allowed_fee_recipients = ArrayTrait::<ContractAddress>::new();

            let cp_enumerated = enumerated_allowed_fee_recipients.array();
            loop {
                if index == enumerated_allowed_fee_recipients_length {
                    break;
                }

                if *cp_enumerated.get(index).unwrap().unbox() != to_remove {
                    new_enumerated_allowed_fee_recipients
                        .append(*cp_enumerated.get(index).unwrap().unbox());
                }
                index += 1;
            };
            enumerated_allowed_fee_recipients.from_array(@new_enumerated_allowed_fee_recipients);
            self
                .enumerated_allowed_fee_recipients
                .write(nft_address, enumerated_allowed_fee_recipients);
        }

        fn remove_enumerated_allowed_payer(
            ref self: ContractState, nft_address: ContractAddress, to_remove: ContractAddress
        ) {
            let mut enumerated_allowed_payer = self.enumerated_allowed_payer.read(nft_address);

            let mut index = 0;
            let enumerated_allowed_payer_length = enumerated_allowed_payer.len();
            let mut new_enumerated_allowed_payer = ArrayTrait::<ContractAddress>::new();

            let cp_enumerated = enumerated_allowed_payer.array();
            loop {
                if index == enumerated_allowed_payer_length {
                    break;
                }

                if *cp_enumerated.get(index).unwrap().unbox() != to_remove {
                    new_enumerated_allowed_payer.append(*cp_enumerated.get(index).unwrap().unbox());
                }
                index += 1;
            };
            enumerated_allowed_payer.from_array(@new_enumerated_allowed_payer);
            self.enumerated_allowed_payer.write(nft_address, enumerated_allowed_payer);
        }
    }
}
