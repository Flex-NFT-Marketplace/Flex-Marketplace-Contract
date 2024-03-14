#[starknet::component]
mod ERC721MetadataComponent {
    use flex::marketplace::openedition::interfaces::IFlexDropContractMetadata::IFlexDropContractMetadata;
    use starknet::{ContractAddress, get_caller_address};
    use integer::{U64PartialOrd, BoundedU64};

    #[storage]
    struct Storage {
        max_supply: u64,
        token_base_uri: felt252,
        contract_uri: felt252,
        owner: ContractAddress
    }

    mod Errors {
        const NOT_OWNER: felt252 = 'Caller is not the owner';
        const ZERO_ADDRESS_CALLER: felt252 = 'Caller is the zero address';
        const ZERO_ADDRESS_OWNER: felt252 = 'New owner is the zero address';
    }

    #[embeddable_as(FlexDropContractMetadataImpl)]
    impl FlexDropContractMetadata<
        TContractState, +HasComponent<TContractState>
    > of IFlexDropContractMetadata<ComponentState<TContractState>> {
        fn set_base_uri(ref self: ComponentState<TContractState>, new_token_uri: felt252) {
            self.assert_only_owner();
            self._set_token_base_uri(new_token_uri);
        }

        fn set_contract_uri(ref self: ComponentState<TContractState>, new_contract_uri: felt252) {
            self.assert_only_owner();
            self._set_contract_uri(new_contract_uri);
        }

        fn set_max_supply(ref self: ComponentState<TContractState>, new_max_supply: u64) {
            self.assert_only_owner();
            self._set_max_supply(new_max_supply);
        }

        fn get_base_uri(self: @ComponentState<TContractState>) -> felt252 {
            self.token_base_uri.read()
        }

        fn get_contract_uri(self: @ComponentState<TContractState>) -> felt252 {
            self.contract_uri.read()
        }

        fn get_max_supply(self: @ComponentState<TContractState>) -> u64 {
            self.max_supply.read()
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// Sets the contract's initial owner.
        ///
        /// This function should be called at construction time.
        fn initializer(
            ref self: ComponentState<TContractState>,
            owner: ContractAddress,
            token_base_uri: felt252
        ) {
            self.owner.write(owner);
            self._set_token_base_uri(token_base_uri);
        }

        fn _set_token_base_uri(ref self: ComponentState<TContractState>, new_token_uri: felt252) {
            self.token_base_uri.write(new_token_uri);
        }

        fn _set_contract_uri(ref self: ComponentState<TContractState>, new_contract_uri: felt252) {
            self.contract_uri.write(new_contract_uri);
        }

        fn _set_max_supply(ref self: ComponentState<TContractState>, new_max_supply: u64) {
            assert(
                U64PartialOrd::lt(new_max_supply, BoundedU64::max()),
                'Cannot Exceed MaxSupply Of U64'
            );
            self.max_supply.write(new_max_supply);
        }

        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let owner: ContractAddress = self.owner.read();
            let caller: ContractAddress = get_caller_address();

            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            assert(caller == owner, Errors::NOT_OWNER);
        }
    }
}
