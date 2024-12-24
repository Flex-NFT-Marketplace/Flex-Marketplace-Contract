#[starknet::contract]
mod ERC5585NFTAuthorization {
    use crate::interface::{IERC721, IERC5585};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc721::ERC721Component::InternalTrait as ERC721InternalTrait;
    use openzeppelin_token::erc721::ERC721Component::ComponentState;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_access::ownable::OwnableComponent;
    use core::zeroable::Zeroable;

    // Add these component declarations
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // Add these implementations
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl ERC721Hooks of ERC721Component::ERC721HooksTrait<ContractState> {
        fn before_update(
            ref self: ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {}

        fn after_update(
            ref self: ComponentState<ContractState>,
            to: ContractAddress,
            token_id: u256,
            auth: ContractAddress
        ) {}
    }

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        user_records: LegacyMap::<(u256, ContractAddress), UserRecord>,
        available_rights: LegacyMap::<felt252, bool>,
        user_limit: u256,
        reset_allowed: bool,
        user_count: LegacyMap::<u256, u256>,
        user_rights: LegacyMap::<(u256, ContractAddress, felt252), bool>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        AuthorizeUser: AuthorizeUser,
        UpdateUserLimit: UpdateUserLimit
    }

    #[derive(Drop, starknet::Event)]
    struct AuthorizeUser {
        #[key]
        token_id: u256,
        #[key]
        user: ContractAddress,
        rights: Array<felt252>,
        expires: u64
    }

    #[derive(Drop, starknet::Event)]
    struct UpdateUserLimit {
        user_limit: u256
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        owner: ContractAddress,
        initial_user_limit: u256,
        initial_rights: Array<felt252>
    ) {
        // Initialize ERC721
        self.erc721.initializer(name, symbol, base_uri);

        // Initialize Ownable
        self.ownable.initializer(owner);

        // Initialize ERC5585
        self.user_limit.write(initial_user_limit);
        self.reset_allowed.write(true);

        // Set available rights
        let mut i: usize = 0;
        loop {
            if i >= initial_rights.len() {
                break;
            }
            self.available_rights.write(*initial_rights.at(i), true);
            i += 1;
        }
    }

    #[external(v0)]
    impl ERC5585Impl of IERC5585<ContractState> {
        fn get_rights(self: @ContractState) -> Array<felt252> {
            // Return list of available rights
            let mut rights = ArrayTrait::new();
            // Implementation to collect all available rights
            rights
        }

        fn authorize_user(
            ref self: ContractState, token_id: u256, user: ContractAddress, duration: u64
        ) {
            self.assert_only_token_owner(token_id);
            assert(duration > 0, 'Invalid duration');

            // Check user limit
            let current_users = self.user_count.read(token_id);
            assert(current_users < self.user_limit.read(), 'User limit exceeded');

            // Create full rights array
            let rights = self.get_rights();

            self._authorize_user(token_id, user, rights, duration);
        }

        fn authorize_user_with_rights(
            ref self: ContractState,
            token_id: u256,
            user: ContractAddress,
            rights: Array<felt252>,
            duration: u64
        ) {
            self.assert_only_token_owner(token_id);
            self.validate_rights(@rights);

            self._authorize_user(token_id, user, rights, duration);
        }

        fn transfer_user_rights(
            ref self: ContractState, token_id: u256, new_user: ContractAddress
        ) {
            let caller = get_caller_address();
            let user_record = self.user_records.read((token_id, caller));
            assert(user_record.expires > get_block_timestamp(), 'Authorization expired');

            // Transfer the rights
            self
                .user_records
                .write(
                    (token_id, caller),
                    UserRecord { user: Zeroable::zero(), rights: ArrayTrait::new(), expires: 0 }
                );

            self
                .user_records
                .write(
                    (token_id, new_user),
                    UserRecord {
                        user: new_user, rights: user_record.rights, expires: user_record.expires
                    }
                );
        }

        fn extend_duration(
            ref self: ContractState, token_id: u256, user: ContractAddress, duration: u64
        ) {
            self.assert_only_token_owner(token_id);
            let mut user_record = self.user_records.read((token_id, user));
            assert(!user_record.user.is_zero(), 'Invalid user');

            let new_expires = get_block_timestamp() + duration;
            user_record.expires = new_expires;

            self.user_records.write((token_id, user), user_record);
            self
                .emit(
                    AuthorizeUser {
                        token_id, user, rights: user_record.rights, expires: new_expires
                    }
                );
        }

        fn update_user_rights(
            ref self: ContractState, token_id: u256, user: ContractAddress, rights: Array<felt252>
        ) {
            self.assert_only_token_owner(token_id);
            self.validate_rights(@rights);

            let mut user_record = self.user_records.read((token_id, user));
            assert(!user_record.user.is_zero(), 'Invalid user');

            user_record.rights = rights;
            self.user_records.write((token_id, user), user_record);

            self
                .emit(
                    AuthorizeUser {
                        token_id, user, rights: user_record.rights, expires: user_record.expires
                    }
                );
        }

        fn get_expires(self: @ContractState, token_id: u256, user: ContractAddress) -> u64 {
            self.user_records.read((token_id, user)).expires
        }

        fn get_user_rights(
            self: @ContractState, token_id: u256, user: ContractAddress
        ) -> Array<felt252> {
            self.user_records.read((token_id, user)).rights
        }

        fn update_user_limit(ref self: ContractState, user_limit: u256) {
            self.ownable.assert_only_owner();
            self.user_limit.write(user_limit);
            self.emit(UpdateUserLimit { user_limit });
        }

        fn update_reset_allowed(ref self: ContractState, reset_allowed: bool) {
            self.ownable.assert_only_owner();
            self.reset_allowed.write(reset_allowed);
        }

        fn check_authorization_availability(self: @ContractState, token_id: u256) -> bool {
            let current_users = self.user_count.read(token_id);
            current_users < self.user_limit.read()
        }

        fn reset_user(ref self: ContractState, token_id: u256, user: ContractAddress) {
            assert(self.reset_allowed.read(), 'Reset not allowed');
            self.assert_only_token_owner(token_id);

            self
                .user_records
                .write(
                    (token_id, user),
                    UserRecord { user: Zeroable::zero(), rights: ArrayTrait::new(), expires: 0 }
                );

            let current_users = self.user_count.read(token_id);
            self.user_count.write(token_id, current_users - 1);
        }
    }

    // Internal functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn assert_only_token_owner(self: @ContractState, token_id: u256) {
            let caller = get_caller_address();
            let owner = self.erc721.owner_of(token_id);
            assert(caller == owner, 'Not token owner');
        }

        fn validate_rights(self: @ContractState, rights: @Array<felt252>) {
            let mut i: usize = 0;
            loop {
                if i >= rights.len() {
                    break;
                }
                assert(self.available_rights.read(*rights.at(i)), 'Invalid right');
                i += 1;
            }
        }

        fn _authorize_user(
            ref self: ContractState,
            token_id: u256,
            user: ContractAddress,
            rights: Array<felt252>,
            duration: u64
        ) {
            let expires = get_block_timestamp() + duration;

            let rights_clone = rights.clone();
            let rights_for_loop = rights.clone();
            // Update user record
            self.user_records.write((token_id, user), UserRecord { user, rights, expires });

            // Update user count
            let current_users = self.user_count.read(token_id);
            self.user_count.write(token_id, current_users + 1);

            // Emit event
            self.emit(AuthorizeUser { token_id, user, rights: rights_clone, expires });
            let mut i: usize = 0;
            loop {
                if i >= rights_for_loop.len() {
                    break;
                }
                let right = *rights_for_loop.at(i);
                self.user_rights.write((token_id, user, right), true);
                i += 1;
            }
        }
    }


    // Types used in the contract

    #[derive(Drop, Serde, Copy, starknet::Store)]
    struct UserRecord {
        user: ContractAddress,
        rights: Array<felt252>,
        expires: u64
    }
}
