#[starknet::contract]
mod ERC721 {
    use alexandria_storage::list::ListTrait;
    use openzeppelin::token::erc721::erc721::ERC721Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use flex::marketplace::openedition::interfaces::IFlexDropContractMetadata::IFlexDropContractMetadata;
    use flex::marketplace::openedition::erc721_metadata::ERC721_metadata::ERC721MetadataComponent;
    use flex::marketplace::openedition::interfaces::IFlexDrop::{
        IFlexDropDispatcher, IFlexDropDispatcherTrait
    };
    use flex::marketplace::openedition::interfaces::INonFungibleFlexDropToken::{
        INonFungibleFlexDropToken, I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID
    };
    use flex::marketplace::utils::openedition::{PublicDrop, MultiConfigureStruct};
    use alexandria_storage::list::List;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use integer::BoundedU64;

    component!(path: ERC721MetadataComponent, storage: erc721_metadata, event: ERC721MetadataEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent
    );

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Metadata = ERC721Component::ERC721MetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721FlexMetadataImpl =
        ERC721MetadataComponent::FlexDropContractMetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl ERC721MetadataInternalImpl = ERC721MetadataComponent::InternalImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    impl SRC5Internal = SRC5Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        current_token_id: u256,
        // mapping allowed FlexDrop contract
        allowed_flex_drop: LegacyMap::<ContractAddress, bool>,
        total_minted: u64,
        // mapping total minted per minter
        total_minted_per_wallet: LegacyMap::<ContractAddress, u64>,
        // Track the enumerated allowed FlexDrop address
        enumerated_allowed_flex_drop: List<ContractAddress>,
        #[substorage(v0)]
        erc721_metadata: ERC721MetadataComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        allowed_flex_drop: Array::<ContractAddress>,
    ) {
        self.erc721_metadata.initializer(owner);
        self.erc721.initializer(name, symbol);
        self.current_token_id.write(1);

        self.src5.register_interface(I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID);

        let mut enumerate_allowed_flex_drop = self.enumerated_allowed_flex_drop.read();
        enumerate_allowed_flex_drop.from_array(@allowed_flex_drop);
        self.enumerated_allowed_flex_drop.write(enumerate_allowed_flex_drop);

        let allowed_flex_drop_length: u32 = allowed_flex_drop.len().try_into().unwrap();
        let mut index: u32 = 0;
        loop {
            if (index == allowed_flex_drop_length) {
                break;
            }

            let flex_drop = allowed_flex_drop.at(index);
            self.allowed_flex_drop.write(*flex_drop, true);
            index += 1;
        };
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        UpdateAllowedFlexDrop: UpdateAllowedFlexDrop,
        #[flat]
        ERC721MetadataEvent: ERC721MetadataComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct UpdateAllowedFlexDrop {
        new_flex_drop: Array::<ContractAddress>,
    }

    #[abi(embed_v0)]
    impl NonFungibleFlexDropTokenImpl of INonFungibleFlexDropToken<ContractState> {
        // update FlexDrop contract addresses
        fn update_allowed_flex_drop(
            ref self: ContractState, allowed_flex_drop: Array::<ContractAddress>
        ) {
            self.ownable.assert_only_owner();
            let mut enumerated_allowed_flex_drop = self.enumerated_allowed_flex_drop.read();
            let enumerated_allowed_flex_drop_length = enumerated_allowed_flex_drop.len();
            let new_allowed_flex_drop_length = allowed_flex_drop.len();

            // Reset the old mapping.
            let mut index_enumerate: u32 = 0;
            let cp_enumerated_allowed = enumerated_allowed_flex_drop.array();
            loop {
                if index_enumerate == enumerated_allowed_flex_drop_length {
                    break;
                }
                let old_allowed_flex_drop = cp_enumerated_allowed.at(index_enumerate);
                self.allowed_flex_drop.write(*old_allowed_flex_drop, false);
                index_enumerate += 1;
            };

            // Set the new mapping for allowed FlexDrop contracts.
            let mut index_new_allowed: u32 = 0;
            let cp_new_allowed = allowed_flex_drop.clone();
            loop {
                if index_new_allowed == new_allowed_flex_drop_length {
                    break;
                }

                self.allowed_flex_drop.write(*cp_new_allowed.at(index_new_allowed), true);
                index_new_allowed += 1;
            };

            enumerated_allowed_flex_drop.from_array(@allowed_flex_drop);
            self.enumerated_allowed_flex_drop.write(enumerated_allowed_flex_drop);
            self.emit(UpdateAllowedFlexDrop { new_flex_drop: allowed_flex_drop })
        }

        // mint tokens, restricted to the FlexDrop contract
        fn mint_flex_drop(ref self: ContractState, minter: ContractAddress, quantity: u64) {
            self.reentrancy_guard.start();
            let flex_drop = get_caller_address();
            self.assert_allowed_flex_drop(flex_drop);

            assert(
                self.get_total_minted() + quantity <= self.get_max_supply(),
                'Exceeds maximum total supply'
            );

            self.safe_mint_flex_drop(minter, quantity);
            self.reentrancy_guard.end();
        }

        fn update_public_drop(
            ref self: ContractState, flex_drop: ContractAddress, public_drop: PublicDrop
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);

            assert(
                public_drop.start_time > 0 && public_drop.start_time + 3600 <= public_drop.end_time,
                'Wrong start and end time'
            );

            IFlexDropDispatcher { contract_address: flex_drop }.update_public_drop(public_drop);
        }

        fn update_creator_payout(
            ref self: ContractState, flex_drop: ContractAddress, payout_address: ContractAddress
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);

            IFlexDropDispatcher { contract_address: flex_drop }
                .update_creator_payout_address(payout_address);
        }

        fn update_fee_recipient(
            ref self: ContractState,
            flex_drop: ContractAddress,
            fee_recipient: ContractAddress,
            allowed: bool
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);

            IFlexDropDispatcher { contract_address: flex_drop }
                .update_allowed_fee_recipient(fee_recipient, allowed)
        }

        // update payer address for paying gas fee of minting NFT
        fn update_payer(
            ref self: ContractState,
            flex_drop: ContractAddress,
            payer: ContractAddress,
            allowed: bool
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);

            IFlexDropDispatcher { contract_address: flex_drop }.update_payer(payer, allowed);
        }

        fn multi_configure(ref self: ContractState, config: MultiConfigureStruct) {
            self.ownable.assert_only_owner();

            let mut max_supply = config.max_supply;
            if max_supply == 0 {
                max_supply = BoundedU64::max();
            }

            self.set_max_supply(max_supply);
            self.set_base_uri(config.base_uri);
            self.set_contract_uri(config.contract_uri);

            let public_drop = config.public_drop;
            if public_drop.start_time != 0 && public_drop.end_time != 0 {
                self.update_public_drop(config.flex_drop, public_drop);
            }

            if !config.creator_payout_address.is_zero() {
                self.update_creator_payout(config.flex_drop, config.creator_payout_address);
            }

            if config.allowed_fee_recipients.len() > 0 {
                let cp_allowed_fee_recipients = config.allowed_fee_recipients.clone();
                let mut index: u32 = 0;
                loop {
                    if index == cp_allowed_fee_recipients.len() {
                        break;
                    }
                    self
                        .update_fee_recipient(
                            config.flex_drop, *cp_allowed_fee_recipients.at(index), true
                        );
                    index += 1;
                };
            }

            if config.disallowed_fee_recipients.len() > 0 {
                let cp_disallowed_fee_recipients = config.disallowed_fee_recipients.clone();
                let mut index: u32 = 0;
                loop {
                    if index == cp_disallowed_fee_recipients.len() {
                        break;
                    }
                    self
                        .update_fee_recipient(
                            config.flex_drop, *cp_disallowed_fee_recipients.at(index), false
                        );
                    index += 1;
                };
            }

            if config.allowed_payers.len() > 0 {
                let cp_allowed_payers = config.allowed_payers.clone();
                let mut index: u32 = 0;
                loop {
                    if index == cp_allowed_payers.len() {
                        break;
                    }
                    self.update_payer(config.flex_drop, *cp_allowed_payers.at(index), true);
                    index += 1;
                };
            }

            if config.disallowed_payers.len() > 0 {
                let cp_disallowed_payers = config.disallowed_payers.clone();
                let mut index: u32 = 0;
                loop {
                    if index == cp_disallowed_payers.len() {
                        break;
                    }
                    self.update_payer(config.flex_drop, *cp_disallowed_payers.at(index), false);
                    index += 1;
                };
            }
        }

        // return (number minted, current total supply, max supply)
        fn get_mint_state(self: @ContractState, minter: ContractAddress) -> (u64, u64, u64) {
            let total_minted = self.total_minted_per_wallet.read(minter);
            let current_total_supply = self.get_total_minted();
            let max_supply = self.get_max_supply();
            (total_minted, current_total_supply, max_supply)
        }

        fn get_current_token_id(self: @ContractState) -> u256 {
            self.current_token_id.read()
        }
    }

    #[generate_trait]
    impl InternalFlexDropToken of InternalFlexDropTokenTrait {
        fn safe_mint_flex_drop(ref self: ContractState, to: ContractAddress, quantity: u64) {
            let mut current_token_id = self.get_current_token_id();
            let base_uri = self.get_base_uri();

            self.current_token_id.write(current_token_id + quantity.into());
            self.total_minted.write(self.get_total_minted() + quantity);

            let mut index: u64 = 0;
            loop {
                if index == quantity {
                    break;
                }
                self.erc721._safe_mint(to, current_token_id, ArrayTrait::<felt252>::new().span());
                self.erc721._set_token_uri(current_token_id, base_uri);
                current_token_id += 1;
                index += 1;
            }
        }

        fn assert_allowed_flex_drop(self: @ContractState, flex_drop: ContractAddress) {
            assert(self.allowed_flex_drop.read(flex_drop), 'Only allowed FlexDrop');
        }

        fn get_total_minted(self: @ContractState) -> u64 {
            self.total_minted.read()
        }

        fn assert_owner_or_self(self: @ContractState) {
            let caller = get_caller_address();
            assert(
                caller == self.ownable.owner() || caller == get_contract_address(), 'Only owner'
            );
        }
    }
}
