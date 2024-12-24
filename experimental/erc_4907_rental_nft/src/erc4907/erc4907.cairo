#[starknet::component]
pub mod ERC4907Component {
    use core::num::traits::Zero;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use erc_4907_rental_nft::erc4907::interface::{IERC4907, IERC4907_ID};

    #[derive(Drop, Serde, starknet::Store)]
    pub struct UserInfo {
        user: ContractAddress,
        expires: u64,
    }

    #[storage]
    pub struct Storage {
        users: Map<u256, UserInfo>,
    }

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        UpdateUser: UpdateUser,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct UpdateUser {
        #[key]
        pub tokenId: u256,
        pub user: ContractAddress,
        pub expires: u64,
    }

    // ------------ External -------------

    #[embeddable_as(ERC4907Impl)]
    impl ERC4907<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of IERC4907<ComponentState<TContractState>> {
        fn setUser(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            user: ContractAddress,
            expires: u64,
        ) {
            let erc721_component = get_dep_component!(@self, ERC721);
            let owner = erc721_component.owner_of(token_id);
            self._check_authorized(owner, get_caller_address(), token_id);

            let userinfo = self.users.entry(token_id).read();
            let updated_userinfo = UserInfo { user: userinfo.user, expires: expires };
            self.users.entry(token_id).write(updated_userinfo);

            self.emit(UpdateUser { tokenId: token_id, user: user, expires: expires });
        }

        fn userOf(self: @ComponentState<TContractState>, token_id: u256) -> ContractAddress {
            let block_timestamp = get_block_timestamp();
            let user_info = self.users.entry(token_id).read();
            let expires = user_info.expires;

            if expires >= block_timestamp {
                user_info.user
            } else {
                Zero::zero()
            }
        }

        fn userExpires(self: @ComponentState<TContractState>, token_id: u256) -> u64 {
            self.users.entry(token_id).read().expires
        }
    }

    // -----------------Internal------------------

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
            src5_component.register_interface(IERC4907_ID);
        }

        fn _is_authorized(
            self: @ComponentState<TContractState>,
            owner: ContractAddress,
            spender: ContractAddress,
            token_id: u256,
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
            token_id: u256,
        ) {
            assert(!owner.is_zero(), ERC721Component::Errors::INVALID_TOKEN_ID);
            assert(
                self._is_authorized(owner, spender, token_id),
                ERC721Component::Errors::UNAUTHORIZED,
            );
        }

        // Use this api when adding ERC4907 component
        fn update(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
        ) {
            let mut erc721_component = get_dep_component_mut!(ref self, ERC721);
            erc721_component.update(to, tokenId, from);
            let user = self.users.entry(tokenId).read().user;
            let update_entry = UserInfo { user: Zero::zero(), expires: 0 };
            if from != to && user != Zero::zero() {
                self.users.entry(tokenId).write(update_entry);
                self.emit(UpdateUser { tokenId: tokenId, user: Zero::zero(), expires: 0 });
            }
        }
    }
}
