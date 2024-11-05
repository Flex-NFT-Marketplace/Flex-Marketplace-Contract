//! Component implementing IERC5643.

#[starknet::component]
pub mod ERC5643Component {
    use core::num::traits::Zero;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use erc_5643_subscription_nft::erc5643::interface::{IERC5643, IERC5643_ID};

    #[storage]
    pub struct Storage {
        expirations: Map<u256, u64>,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        SubscriptionUpdate: SubscriptionUpdate,
    }

    /// Emitted when `token_id` subscription is updated.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct SubscriptionUpdate {
        #[key]
        pub token_id: u256,
        pub expiration: u64,
    }

    pub mod Errors {
        pub const SUBSCRIPTION_NOT_RENEWABLE: felt252 = 'ERC5643: sub not renewable';
    }

    //
    // External
    //

    #[embeddable_as(ERC5643Impl)]
    impl ERC5643<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IERC5643<ComponentState<TContractState>> {
        fn renew_subscription(
            ref self: ComponentState<TContractState>, token_id: u256, duration: u64
        ) {
            let erc721_component = get_dep_component!(@self, ERC721);
            let owner = erc721_component.owner_of(token_id);
            self._check_authorized(owner, get_caller_address(), token_id);

            let expiration = self.expirations.entry(token_id).read();
            let block_timestamp = get_block_timestamp();
            let current_expiration = if expiration < block_timestamp {
                block_timestamp
            } else {
                expiration
            };
            let new_expiration = if current_expiration == 0 {
                block_timestamp + duration
            } else {
                assert(self.is_renewable(token_id), Errors::SUBSCRIPTION_NOT_RENEWABLE);
                current_expiration + duration
            };

            self.expirations.entry(token_id).write(new_expiration);

            self.emit(SubscriptionUpdate { token_id, expiration: new_expiration });
        }

        fn cancel_subscription(ref self: ComponentState<TContractState>, token_id: u256) {
            let erc721_component = get_dep_component!(@self, ERC721);
            let owner = erc721_component.owner_of(token_id);
            self._check_authorized(owner, get_caller_address(), token_id);
            self.expirations.entry(token_id).write(0);
            self.emit(SubscriptionUpdate { token_id, expiration: 0 });
        }

        fn expires_at(self: @ComponentState<TContractState>, token_id: u256) -> u64 {
            self.expirations.entry(token_id).read()
        }

        fn is_renewable(self: @ComponentState<TContractState>, token_id: u256) -> bool {
            true
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IERC5643_ID);
        }

        fn _is_authorized(
            self: @ComponentState<TContractState>,
            owner: ContractAddress,
            spender: ContractAddress,
            token_id: u256
        ) -> bool {
            let erc721_component = get_dep_component!(self, ERC721);
            let is_approved_for_all = erc721_component.is_approved_for_all(owner, spender);

            !spender.is_zero()
                && (owner == spender
                    || is_approved_for_all
                    || spender == erc721_component.get_approved(token_id))
        }

        fn _check_authorized(
            self: @ComponentState<TContractState>,
            owner: ContractAddress,
            spender: ContractAddress,
            token_id: u256
        ) {
            // Non-existent token
            assert(!owner.is_zero(), ERC721Component::Errors::INVALID_TOKEN_ID);
            assert(
                self._is_authorized(owner, spender, token_id), ERC721Component::Errors::UNAUTHORIZED
            );
        }
    }
}
