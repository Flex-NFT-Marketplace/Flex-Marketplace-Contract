#[starknet::contract]
mod ERC721OpenEditionMultiMetadata {
    use alexandria_storage::list::ListTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use flex::marketplace::openedition::ERC721MultiMetadata::ERC721MultiMetadataComponent;
    use flex::marketplace::openedition::interfaces::IFlexDrop::{
        IFlexDropDispatcher, IFlexDropDispatcherTrait
    };
    use flex::marketplace::openedition::interfaces::INonFungibleFlexDropToken::{
        INonFungibleFlexDropToken, I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID
    };
    use flex::marketplace::utils::openedition::{PhaseDrop, MultiConfigureStruct};
    use alexandria_storage::list::List;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use integer::BoundedU64;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721MultiMetadataComponent, storage: erc721, event: ERC721Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent
    );

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721MultiMetadataComponent::ERC721Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721CamelImpl =
        ERC721MultiMetadataComponent::ERC721CamelOnlyImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721MetadataImpl =
        ERC721MultiMetadataComponent::ERC721MetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721MetadataCamelImpl =
        ERC721MultiMetadataComponent::ERC721MetadataCamelOnlyImpl<ContractState>;

    #[abi(embed_v0)]
    impl FlexDropContractMetadataImpl =
        ERC721MultiMetadataComponent::FlexDropContractMetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5CamelImple = SRC5Component::SRC5CamelImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl ERC721InternalImpl = ERC721MultiMetadataComponent::InternalImpl<ContractState>;

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
        current_phase_id: u64,
        #[substorage(v0)]
        erc721: ERC721MultiMetadataComponent::Storage,
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
        creator: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        token_base_uri: ByteArray,
        allowed_flex_drop: Array::<ContractAddress>,
    ) {
        self.ownable.initializer(creator);
        self.erc721.initializer(name, symbol, creator, token_base_uri);
        self.current_token_id.write(1);
        self.current_phase_id.write(1);

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
        ERC721Event: ERC721MultiMetadataComponent::Event,
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

            self.safe_mint_flex_drop(minter, quantity);
            self.reentrancy_guard.end();
        }

        fn create_new_phase_drop(
            ref self: ContractState,
            flex_drop: ContractAddress,
            phase_detail: PhaseDrop,
            fee_recipient: ContractAddress,
        ) {
            self.ownable.assert_only_owner();
            self.assert_allowed_flex_drop(flex_drop);
            let current_phase_id = self.current_phase_id.read();
            self.current_phase_id.write(current_phase_id + 1);

            IFlexDropDispatcher { contract_address: flex_drop }
                .start_new_phase_drop(current_phase_id, phase_detail, fee_recipient)
        }


        fn update_phase_drop(
            ref self: ContractState,
            flex_drop: ContractAddress,
            phase_id: u64,
            phase_detail: PhaseDrop
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);
            IFlexDropDispatcher { contract_address: flex_drop }
                .update_phase_drop(phase_id, phase_detail);
        }

        fn update_creator_payout(
            ref self: ContractState, flex_drop: ContractAddress, payout_address: ContractAddress
        ) {
            self.assert_owner_or_self();

            self.assert_allowed_flex_drop(flex_drop);

            IFlexDropDispatcher { contract_address: flex_drop }
                .update_creator_payout_address(payout_address);
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

            if config.base_uri.len() > 0 {
                self.set_base_uri(config.base_uri);
            }

            if config.contract_uri.len() > 0 {
                self.set_contract_uri(config.contract_uri);
            }

            let phase_drop = config.phase_drop;
            if phase_drop.phase_type != 0
                && phase_drop.start_time != 0
                && phase_drop.end_time != 0 {
                if config.new_phase {
                    self.create_new_phase_drop(config.flex_drop, phase_drop, config.fee_recipient);
                } else {
                    let current_id = self.current_phase_id.read();
                    self.update_phase_drop(config.flex_drop, current_id, phase_drop);
                }
            }

            if !config.creator_payout_address.is_zero() {
                self.update_creator_payout(config.flex_drop, config.creator_payout_address);
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

        // return (number minted, current total supply)
        fn get_mint_state(self: @ContractState, minter: ContractAddress) -> (u64, u64) {
            let total_minted = self.total_minted_per_wallet.read(minter);
            let current_total_supply = self.get_total_minted();
            (total_minted, current_total_supply)
        }

        fn get_current_token_id(self: @ContractState) -> u256 {
            self.current_token_id.read()
        }

        fn get_allowed_flex_drops(self: @ContractState) -> Span::<ContractAddress> {
            self.enumerated_allowed_flex_drop.read().array().span()
        }
    }

    #[generate_trait]
    impl InternalFlexDropToken of InternalFlexDropTokenTrait {
        fn safe_mint_flex_drop(ref self: ContractState, to: ContractAddress, quantity: u64) {
            let mut current_token_id = self.get_current_token_id();

            self
                .total_minted_per_wallet
                .write(to, self.total_minted_per_wallet.read(to) + quantity);
            self.current_token_id.write(current_token_id + quantity.into());
            self.total_minted.write(self.get_total_minted() + quantity);

            let mut index: u64 = 0;
            loop {
                if index == quantity {
                    break;
                }
                self.erc721._safe_mint(to, current_token_id, ArrayTrait::<felt252>::new().span());
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
