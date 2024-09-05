#[starknet::contract]
mod FlexDrop {
    use core::box::BoxTrait;
    use openedition::utils::openedition::{PhaseDrop, WhiteListParam};
    use openedition::IFlexDrop;
    use openedition::interfaces::INonFungibleFlexDropToken::{
        INonFungibleFlexDropTokenDispatcher, INonFungibleFlexDropTokenDispatcherTrait,
        I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID
    };
    use openedition::{
        interfaces::ICurrencyManager::{ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait},
        interfaces::ISignatureChecker2::{ISignatureChecker2Dispatcher, ISignatureChecker2DispatcherTrait},
    };
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use alexandria_storage::list::{List, ListTrait};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_tx_info, Zeroable};
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
        // mapping (nft address, phase id) => Public drop
        phase_drops: LegacyMap::<(ContractAddress, u64), PhaseDrop>,
        // mapping nft address => creator payout address
        creator_payout_address: LegacyMap::<ContractAddress, ContractAddress>,
        // mapping fee recipient of protocol => is allowed
        protocol_fee_recipients: LegacyMap::<ContractAddress, bool>,
        // mapping (nft address, payer) => is allowed
        allowed_payer: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        // protocol fee mint
        fee_mint: u256,
        // protocol fee mint when creator set mint price is 0
        fee_mint_when_zero_price: u256,
        // protocal fee currency
        fee_currency: ContractAddress,
        // start new phase fee
        new_phase_fee: u256,
        // validator validating the proof of whitelist
        validator: ContractAddress,
        // domain hash
        domain_hash: felt252,
        // contract to verify proof
        signature_checker: ContractAddress,
        // mapping proof => is used
        is_used_proof: LegacyMap::<felt252, bool>,
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
        PhaseDropUpdated: PhaseDropUpdated,
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
        phase_id: u64,
        minter: ContractAddress,
        fee_recipient: ContractAddress,
        payer: ContractAddress,
        quantity_minted: u64,
        total_mint_price: u256,
        fee_mint: u256,
        is_warpcast: bool
    }

    #[derive(Drop, starknet::Event)]
    struct PhaseDropUpdated {
        #[key]
        nft_address: ContractAddress,
        phase_drop_id: u64,
        phase_drop: PhaseDrop,
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
        fee_currency: ContractAddress,
        fee_mint: u256,
        fee_mint_when_zero_price: u256,
        new_phase_fee: u256,
        domain_hash: felt252,
        validator: ContractAddress,
        signature_checker: ContractAddress,
        fee_recipients: Span::<ContractAddress>
    ) {
        self.ownable.initializer(owner);
        self.fee_currency.write(fee_currency);
        self.fee_mint.write(fee_mint);
        self.fee_mint_when_zero_price.write(fee_mint_when_zero_price);
        self.new_phase_fee.write(new_phase_fee);
        self.validator.write(validator);
        self.domain_hash.write(domain_hash);
        self.signature_checker.write(signature_checker);
        self
            .currency_manager
            .write(ICurrencyManagerDispatcher { contract_address: currency_manager });

        let recipient_length = fee_recipients.len();
        let mut index: u32 = 0;
        loop {
            if index == recipient_length {
                break;
            }

            self.protocol_fee_recipients.write(*fee_recipients.at(index), true);
            index += 1;
        }
    }

    #[abi(embed_v0)]
    impl FlexDropImpl of IFlexDrop<ContractState> {
        fn mint_public(
            ref self: ContractState,
            nft_address: ContractAddress,
            phase_id: u64,
            fee_recipient: ContractAddress,
            minter_if_not_payer: ContractAddress,
            quantity: u64,
            is_warpcast: bool,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
            let phase_drop = self.phase_drops.read((nft_address, phase_id));
            self.assert_active_phase_drop(@phase_drop);

            let mut minter = get_caller_address();
            if !minter_if_not_payer.is_zero() {
                minter = minter_if_not_payer.clone();
            }

            if minter != get_caller_address() {
                self.assert_allowed_payer(nft_address, get_caller_address());
            } else {
                assert(!is_warpcast, 'FlexDrop: Method Not Allowed');
            }

            self
                .assert_valid_mint_quantity(
                    @nft_address, @minter, phase_id, quantity, phase_drop.max_mint_per_wallet
                );

            self.assert_allowed_fee_recipient(@fee_recipient);

            let total_mint_price = quantity.into() * phase_drop.mint_price;
            self
                .mint_and_pay(
                    nft_address,
                    get_caller_address(),
                    minter,
                    is_warpcast,
                    phase_id,
                    quantity,
                    phase_drop.currency,
                    total_mint_price,
                    fee_recipient,
                    false
                );
            self.reentrancy.end();
        }

        fn whitelist_mint(
            ref self: ContractState,
            whitelist_data: WhiteListParam,
            fee_recipient: ContractAddress,
            proof: Array<felt252>
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
            let phase_drop = self
                .phase_drops
                .read((whitelist_data.nft_address, whitelist_data.phase_id));
            self.assert_active_phase_drop(@phase_drop);

            let sig_checker_dis = ISignatureChecker2Dispatcher {
                contract_address: self.get_signature_checker()
            };

            self.assert_allowed_fee_recipient(@fee_recipient);

            sig_checker_dis
                .verify_whitelist_mint_proof(
                    self.get_domain_hash(), self.get_validator(), whitelist_data, proof
                );
            let mint_hash = sig_checker_dis
                .compute_whitelist_mint_message_hash(
                    self.get_domain_hash(), self.get_validator(), whitelist_data
                );
            assert(!self.is_used_proof.read(mint_hash), 'FlexDrop: Proof is used');

            self.is_used_proof.write(mint_hash, true);

            self
                .mint_and_pay(
                    whitelist_data.nft_address,
                    whitelist_data.minter,
                    whitelist_data.minter,
                    false,
                    whitelist_data.phase_id,
                    1,
                    phase_drop.currency,
                    0,
                    fee_recipient,
                    true
                );
            self.reentrancy.end();
        }

        fn start_new_phase_drop(
            ref self: ContractState,
            phase_drop_id: u64,
            phase_drop: PhaseDrop,
            fee_recipient: ContractAddress,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
            self.assert_only_non_fungible_flex_drop_token();
            let nft_address = get_caller_address();

            let phase_detail = self.phase_drops.read((nft_address, phase_drop_id));
            assert!(phase_detail.phase_type == 0, "FlexDrop: Phase have been started");
            self.validate_new_phase_drop(@phase_drop);

            let new_phase_fee = self.new_phase_fee.read();
            if new_phase_fee > 0 {
                assert!(
                    self.protocol_fee_recipients.read(fee_recipient),
                    "FlexDrop: Only allowed fee recipient"
                );
                let payer = get_tx_info().unbox().account_contract_address;
                let erc20_dispatcher = IERC20Dispatcher {
                    contract_address: self.fee_currency.read()
                };
                erc20_dispatcher.transfer_from(payer, fee_recipient, new_phase_fee);
            }
            self.phase_drops.write((nft_address, phase_drop_id), phase_drop);

            self.emit(PhaseDropUpdated { nft_address, phase_drop_id, phase_drop });
            self.reentrancy.end();
        }

        fn update_phase_drop(ref self: ContractState, phase_drop_id: u64, phase_drop: PhaseDrop) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
            self.assert_only_non_fungible_flex_drop_token();
            let nft_address = get_caller_address();
            let phase_drop_detail = self.phase_drops.read((nft_address, phase_drop_id));
            assert(
                get_block_timestamp() + 3600 < phase_drop_detail.start_time,
                'FlexDrop: timeout for updating '
            );

            self.validate_new_phase_drop(@phase_drop);

            self.phase_drops.write((nft_address, phase_drop_id), phase_drop);
            self.emit(PhaseDropUpdated { nft_address, phase_drop_id, phase_drop });
            self.reentrancy.end();
        }

        fn update_creator_payout_address(
            ref self: ContractState, new_payout_address: ContractAddress
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();

            self.assert_only_non_fungible_flex_drop_token();

            assert(!new_payout_address.is_zero(), 'Only non zero payout address');
            self.creator_payout_address.write(get_caller_address(), new_payout_address);

            self
                .emit(
                    CreatorPayoutUpdated { nft_address: get_caller_address(), new_payout_address }
                );
            self.reentrancy.end();
        }

        fn update_payer(ref self: ContractState, payer: ContractAddress, allowed: bool) {
            self.pausable.assert_not_paused();
            self.reentrancy.start();
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
            self.reentrancy.end();
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
        fn change_protocol_fee_mint(
            ref self: ContractState, new_fee_currency: ContractAddress, new_fee_mint: u256
        ) {
            self.ownable.assert_only_owner();

            let old_fee_mint = self.fee_mint.read();
            if old_fee_mint != new_fee_mint {
                self.fee_mint.write(new_fee_mint);
            }

            let old_fee_currency = self.fee_currency.read();
            if old_fee_currency != new_fee_currency {
                self.fee_currency.write(new_fee_currency);
            }
        }

        #[external(v0)]
        fn change_protocol_fee_mint_when_zero_price(
            ref self: ContractState,
            new_fee_currency: ContractAddress,
            new_fee_mint_when_zero_price: u256
        ) {
            self.ownable.assert_only_owner();

            let old_fee_mint = self.fee_mint_when_zero_price.read();
            if old_fee_mint != new_fee_mint_when_zero_price {
                self.fee_mint_when_zero_price.write(new_fee_mint_when_zero_price);
            }

            let old_fee_currency = self.fee_currency.read();
            if old_fee_currency != new_fee_currency {
                self.fee_currency.write(new_fee_currency);
            }
        }

        #[external(v0)]
        fn update_protocol_fee_recipients(
            ref self: ContractState, fee_recipient: ContractAddress, allowed: bool
        ) {
            self.ownable.assert_only_owner();
            assert(fee_recipient.is_non_zero(), 'Only nonzero fee recipient');
            if allowed {
                assert(
                    !self.protocol_fee_recipients.read(fee_recipient), 'Duplicate fee recipient'
                );
                self.protocol_fee_recipients.write(fee_recipient, true);
            } else {
                assert(self.protocol_fee_recipients.read(fee_recipient), 'Duplicate fee recipient');
                self.protocol_fee_recipients.write(fee_recipient, false);
            }
        }

        #[external(v0)]
        fn get_fee_currency(self: @ContractState) -> ContractAddress {
            self.fee_currency.read()
        }

        #[external(v0)]
        fn get_fee_mint(self: @ContractState) -> u256 {
            self.fee_mint.read()
        }

        #[external(v0)]
        fn get_fee_mint_when_zero_price(self: @ContractState) -> u256 {
            self.fee_mint_when_zero_price.read()
        }

        #[external(v0)]
        fn get_new_phase_fee(self: @ContractState) -> u256 {
            self.new_phase_fee.read()
        }

        #[external(v0)]
        fn update_new_phase_fee(ref self: ContractState, new_fee: u256) {
            self.ownable.assert_only_owner();
            self.new_phase_fee.write(new_fee)
        }

        #[external(v0)]
        fn update_validator(ref self: ContractState, new_validator: ContractAddress) {
            self.ownable.assert_only_owner();
            self.validator.write(new_validator);
        }

        #[external(v0)]
        fn get_validator(self: @ContractState) -> ContractAddress {
            self.validator.read()
        }

        #[external(v0)]
        fn update_domain_hash(ref self: ContractState, new_domain_hash: felt252) {
            self.ownable.assert_only_owner();
            self.domain_hash.write(new_domain_hash);
        }

        #[external(v0)]
        fn get_domain_hash(self: @ContractState) -> felt252 {
            self.domain_hash.read()
        }

        #[external(v0)]
        fn update_signature_checker(
            ref self: ContractState, new_signature_checker: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            self.signature_checker.write(new_signature_checker);
        }

        #[external(v0)]
        fn get_signature_checker(self: @ContractState) -> ContractAddress {
            self.signature_checker.read()
        }

        #[external(v0)]
        fn get_phase_drop(
            self: @ContractState, nft_address: ContractAddress, phase_id: u64
        ) -> PhaseDrop {
            self.phase_drops.read((nft_address, phase_id))
        }

        #[external(v0)]
        fn get_currency_manager(self: @ContractState) -> ContractAddress {
            self.currency_manager.read().contract_address
        }

        #[external(v0)]
        fn get_protocol_fee_recipients(
            self: @ContractState, fee_recipient: ContractAddress
        ) -> bool {
            self.protocol_fee_recipients.read(fee_recipient)
        }

        #[external(v0)]
        fn get_creator_payout_address(
            self: @ContractState, nft_address: ContractAddress
        ) -> ContractAddress {
            self.creator_payout_address.read(nft_address)
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
            assert(is_supported_interface, 'FlexDrop: Unsupport Interface');
        }

        fn validate_new_phase_drop(self: @ContractState, phase_drop: @PhaseDrop) {
            assert!(*phase_drop.phase_type == 1, "FlexDrop: Currently supported public phase");
            assert!(
                *phase_drop.start_time >= get_block_timestamp()
                    + 1800 && *phase_drop.start_time
                    + 3600 <= *phase_drop.end_time,
                "FlexDrop: Wrong start and end time"
            );
            assert!(*phase_drop.max_mint_per_wallet > 0, "FlexDrop: invalid max mint per wallet");
            self.assert_whitelisted_currency(phase_drop.currency);
        }

        fn assert_active_phase_drop(self: @ContractState, phase_drop: @PhaseDrop) {
            let block_time = get_block_timestamp();
            assert!(
                *phase_drop.start_time <= block_time && *phase_drop.end_time > block_time,
                "FlexDrop: Public drop not active"
            );
        }

        fn assert_whitelisted_currency(self: @ContractState, currency: @ContractAddress) {
            assert!(
                self.currency_manager.read().is_currency_whitelisted(*currency),
                "FlexDrop: Currency is not whitelisted"
            );
        }


        fn assert_allowed_payer(
            self: @ContractState, nft_address: ContractAddress, payer: ContractAddress
        ) {
            assert(self.allowed_payer.read((nft_address, payer)), 'FlexDrop: Only allowed payer');
        }

        fn assert_valid_mint_quantity(
            self: @ContractState,
            nft_address: @ContractAddress,
            minter: @ContractAddress,
            phase_id: u64,
            quantity: u64,
            max_total_mint_per_wallet: u64,
        ) {
            assert(quantity > 0, 'Only non zero quantity');

            let (total_minted, current_supply, total_supply) = INonFungibleFlexDropTokenDispatcher {
                contract_address: *nft_address
            }
                .get_mint_state(*minter, phase_id);

            assert(
                total_minted + quantity <= max_total_mint_per_wallet, 'Exceeds maximum total minted'
            );

            assert(current_supply + quantity <= total_supply, 'Exceeds maximum total supply');
        }

        fn assert_allowed_fee_recipient(self: @ContractState, fee_recipient: @ContractAddress,) {
            assert!(
                self.protocol_fee_recipients.read(*fee_recipient),
                "FlexDrop: Only allowed fee recipient"
            );
        }

        fn mint_and_pay(
            ref self: ContractState,
            nft_address: ContractAddress,
            payer: ContractAddress,
            minter: ContractAddress,
            is_warpcast: bool,
            phase_id: u64,
            quantity: u64,
            currency_address: ContractAddress,
            total_mint_price: u256,
            fee_recipient: ContractAddress,
            is_whitelist_mint: bool
        ) {
            self
                .split_payout(
                    payer,
                    is_warpcast,
                    nft_address,
                    fee_recipient,
                    currency_address,
                    total_mint_price,
                    is_whitelist_mint
                );

            INonFungibleFlexDropTokenDispatcher { contract_address: nft_address }
                .mint_flex_drop(minter, phase_id, quantity);

            let mut fee_mint = self.fee_mint.read();
            if total_mint_price == 0 && !is_whitelist_mint && !is_warpcast {
                fee_mint = self.fee_mint_when_zero_price.read();
            }
            self
                .emit(
                    FlexDropMinted {
                        nft_address,
                        phase_id,
                        minter,
                        fee_recipient,
                        payer,
                        quantity_minted: quantity,
                        total_mint_price,
                        fee_mint,
                        is_warpcast
                    }
                )
        }

        fn split_payout(
            ref self: ContractState,
            from: ContractAddress,
            is_warpcast: bool,
            nft_address: ContractAddress,
            fee_recipient: ContractAddress,
            currency_address: ContractAddress,
            total_mint_price: u256,
            is_whitelist_mint: bool,
        ) {
            let fee_mint = self.fee_mint.read();
            let fee_mint_when_zero_price = self.fee_mint_when_zero_price.read();
            let fee_currency_contract = IERC20Dispatcher {
                contract_address: self.fee_currency.read()
            };
            if total_mint_price == 0
                && fee_mint_when_zero_price > 0
                && !is_whitelist_mint
                && !is_warpcast {
                fee_currency_contract.transfer_from(from, fee_recipient, fee_mint_when_zero_price);
            } else if fee_mint > 0 {
                fee_currency_contract.transfer_from(from, fee_recipient, fee_mint);
            }

            if total_mint_price > 0 && !is_warpcast {
                let currency_contract = IERC20Dispatcher { contract_address: currency_address };
                let creator_payout_address = self.creator_payout_address.read(nft_address);
                assert!(
                    !creator_payout_address.is_zero(), "FlexDrop: Only non zero creator payout"
                );
                currency_contract.transfer_from(from, creator_payout_address, total_mint_price);
            }
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
