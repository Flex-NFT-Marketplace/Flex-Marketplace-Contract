
#[starknet::contract]
mod ERC7765Component {
    
    use starknet::{ContractAddress, get_caller_address};    
    use starknet::event::EventEmitter;
    use erc_7765_rwa_integration::interfaces::IERC7765::{IERC7765, IERC7765Metadata};
    use alexandria_storage::list::{List, ListTrait};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    struct Storage {
        ERC7765_creator: ContractAddress,
        ERC7765_name: ByteArray,
        ERC7765_symbol: ByteArray,
        ERC7765_owners: LegacyMap<u256, ContractAddress>,
        ERC7765_balances: LegacyMap<ContractAddress, u256>,
        ERC7765_token_approvals: LegacyMap<u256, ContractAddress>,
        ERC7765_operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        ERC7765_base_uri: ByteArray,
        ERC7765_privileges_count: u32,
        ERC7765_privileges_index: LegacyMap<u32, u256>,
        ERC7765_privileges_to_index: LegacyMap<u256, u32>,
        ERC7765_privilege_exercised: LegacyMap<(u256, u256), bool>,
        ERC7765_privileges: List<u256>
    }
    
    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        PrivilegeExercised: PrivilegeExercised,
    }

    /// Emitted when `token_id` token is transferred from `from` to `to`.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct Transfer {
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        #[key]
        pub token_id: u256
    }

    /// Emitted when `owner` enables `approved` to manage the `token_id` token.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct Approval {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub approved: ContractAddress,
        #[key]
        pub token_id: u256
    }

    /// Emitted when `owner` enables or disables (`approved`) `operator` to manage
    /// all of its assets.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct ApprovalForAll {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub operator: ContractAddress,
        pub approved: bool
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct PrivilegeExercised {
        #[key]
        pub to: ContractAddress,
        #[key]
        pub operator: ContractAddress,
        pub token_id: u256, 
        pub privilege_id: u256
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        creator: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        token_base_uri: ByteArray,
        privilege_ids: Array<u256>
    ) {
            self.ERC7765_creator.write(creator);
            self.ERC7765_name.write(name);
            self.ERC7765_symbol.write(symbol);
            self.ERC7765_base_uri.write(token_base_uri);


            let mut privileges = self.ERC7765_privileges.read();
            privileges.from_array(@privilege_ids);
            self.ERC7765_privileges.write(privileges);


            let privileges_len = privilege_ids.len().try_into().unwrap();
            let mut i: u32 = 1;
            loop {
                if i > privileges_len {
                    break;
                }

                self.ERC7765_privileges_index.write(i, *privilege_ids.at(i));
                self.ERC7765_privileges_to_index.write(*privilege_ids.at(i), i);
                i +=1;
            };
            self.ERC7765_privileges_count.write(privileges_len);

    }
    

    #[abi(embed_v0)]
    impl ERC7765Metadata of IERC7765Metadata<ContractState> {
        
        fn name(self: @ContractState) -> ByteArray {
            self.ERC7765_name.read()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.ERC7765_symbol.read()
        }
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.ERC7765_base_uri.read()
        }
    
        // Specific to ERC7765

        // TODO
        fn privilegeURI(self: @ContractState, privilege_id: u256) -> ByteArray{
            self.ERC7765_symbol.read()
        }
    }

    mod Errors {
        const INVALID_TOKEN_ID: felt252 = 'ERC721: invalid token ID';
        const INVALID_ACCOUNT: felt252 = 'ERC721: invalid account';
        const UNAUTHORIZED: felt252 = 'ERC721: unauthorized caller';
        const APPROVAL_TO_OWNER: felt252 = 'ERC721: approval to owner';
        const SELF_APPROVAL: felt252 = 'ERC721: self approval';
        const INVALID_RECEIVER: felt252 = 'ERC721: invalid receiver';
        const ALREADY_MINTED: felt252 = 'ERC721: token already minted';
        const WRONG_SENDER: felt252 = 'ERC721: wrong sender';
        const SAFE_MINT_FAILED: felt252 = 'ERC721: safe mint failed';
        const SAFE_TRANSFER_FAILED: felt252 = 'ERC721: safe transfer failed';
        const NOT_CREATOR: felt252 = 'Caller is not the creator';
        const ZERO_ADDRESS_CALLER: felt252 = 'Caller is the zero address';
        const ZERO_ADDRESS_CREATOR: felt252 = 'New creator is the zero address';
    }

    #[abi(embed_v0)]
    impl ERC7765 of IERC7765<ContractState> {

        // fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
        //     assert(!account.is_zero(), Errors::INVALID_ACCOUNT);
        //     self.ERC721_balances.read(account)
        // }
        
        // fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
        // fn safe_transfer_from(
        //     ref self: TContractState,
        //     from: ContractAddress,
        //     to: ContractAddress,
        //     token_id: u256,
        //     data: Span<felt252>
        // );
        // fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256);
        // fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
        // fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
        // fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
        // fn is_approved_for_all(
        //     self: @TContractState, owner: ContractAddress, operator: ContractAddress
        // ) -> bool;
    
        // // Specific to ERC7765

        fn is_exercisable(self: @ContractState, token_id: u256, privilege_id: u256, ) -> bool {
            !self.is_exercised(token_id, privilege_id)
        }

        fn is_exercised(self: @ContractState,  token_id: u256, privilege_id: u256, ) -> bool {
            self.ERC7765_privilege_exercised.read((token_id, privilege_id))
        }

        fn get_privilege_ids(self: @ContractState, token_id: u256) -> Array<u256> {
            self.ERC7765_privileges.read().array()
        }

        // TODO
        fn exercise_privilege(ref self: ContractState, token_id: u256, to: ContractAddress, privilege_id: u256) {

            self._assertOwner(token_id);
            self._assertPrivilegeExists(privilege_id);

            self.ERC7765_privilege_exercised.write((token_id, privilege_id), true);

            self.emit(PrivilegeExercised { to,  operator: to, token_id, privilege_id} );

        }
    }

    #[generate_trait]
    impl InternalImpl of InternalImplTrait {

        fn _assertOwner(self: @ContractState, token_id: u256) {
            assert(self.ERC7765_owners.read(token_id) == get_caller_address(), 'Caller is not the token owner');
        }

        fn _assertPrivilegeExists(self: @ContractState, token_id: u256) {
            assert(self.ERC7765_privileges_to_index.read(token_id) != 0, 'Invalid privilege id');
        }
    }

}