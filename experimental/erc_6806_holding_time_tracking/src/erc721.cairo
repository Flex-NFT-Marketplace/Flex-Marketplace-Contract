use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC721<TContractState> {
    fn get_name(self: @TContractState) -> felt252;
    fn get_symbol(self: @TContractState) -> felt252;
    fn get_token_uri(self: @TContractState, token_id: u256) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);

    fn get_holding_info(self: @TContractState, token_id: u256) -> (ContractAddress, u64);
    fn set_holding_time_whitelisted_address(ref self: TContractState, account: ContractAddress, ignore_reset: bool);
}

#[starknet::contract]
pub mod ERC721 {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess
    };
    use core::num::traits::Zero;
    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: Map::<u256, ContractAddress>,
        balances: Map::<ContractAddress, u256>,
        token_approvals: Map::<u256, ContractAddress>,
        operator_approvals: Map::<(ContractAddress, ContractAddress), bool>,
        token_uri: Map<u256, felt252>,
        holder: Map<u256, ContractAddress>,
        hold_start: Map<u256, u64>,
        holding_time_whitelist: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        Transfer: Transfer,
        ApprovalForAll: ApprovalForAll
    }

    ////////////////////////////////
    // Approval event emitted on token approval
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // Transfer event emitted on token transfer
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    ////////////////////////////////
    // ApprovalForAll event emitted on approval for operators
    ////////////////////////////////
    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState, _name: felt252, _symbol: felt252) {
        self.name.write(_name);
        self.symbol.write(_symbol);
    }

    #[abi(embed_v0)]
    impl IERC721Impl of super::IERC721<ContractState> {
        fn get_holding_info(self: @ContractState, token_id: u256) -> (ContractAddress, u64) {
            let holder = self.holder.read(token_id);
            let hold_start = self.hold_start.read(token_id);
            let current_time = get_block_timestamp();
            let holding_time = current_time - hold_start;
            (holder, holding_time)
        }

        fn set_holding_time_whitelisted_address(
            ref self: ContractState, account: ContractAddress, ignore_reset: bool
        ) {

            self.holding_time_whitelist.write(account, ignore_reset);
        }

        ////////////////////////////////
        // get_name function returns token name
        ////////////////////////////////
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        ////////////////////////////////
        // get_symbol function returns token symbol
        ////////////////////////////////
        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        ////////////////////////////////
        // token_uri returns the token uri
        ////////////////////////////////
        fn get_token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.read(token_id)
        }

        ////////////////////////////////
        // balance_of function returns token balance
        ////////////////////////////////
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(account.is_zero(), 'ERC721: address zero');
            self.balances.read(account)
        }

        ////////////////////////////////
        // owner_of function returns owner of token_id
        ////////////////////////////////
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.owners.read(token_id);
            owner
        }

        ////////////////////////////////
        // get_approved function returns approved address for a token
        ////////////////////////////////
        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_approvals.read(token_id)
        }

        ////////////////////////////////
        // is_approved_for_all function returns approved operator for a token
        ////////////////////////////////
        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.operator_approvals.read((owner, operator))
        }

        ////////////////////////////////
        // approve function approves an address to spend a token
        ////////////////////////////////
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self.owner_of(token_id);
            assert(to != owner, 'Approval to current owner');
            assert(
                get_caller_address() == owner
                    || self.is_approved_for_all(owner, get_caller_address()),
                'Not token owner'
            );
            self.token_approvals.write(token_id, to);
            self.emit(Approval { owner: self.owner_of(token_id), to: to, token_id: token_id });
        }

        ////////////////////////////////
        // set_approval_for_all function approves an operator to spend all tokens
        ////////////////////////////////
        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let owner = get_caller_address();
            assert(owner != operator, 'ERC721: approve to caller');
            self.operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner: owner, operator: operator, approved: approved });
        }

        ////////////////////////////////
        // transfer_from function is used to transfer a token
        ////////////////////////////////
        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'neither owner nor approved'
            );
            self._transfer(from, to, token_id);
        }


        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self._mint(to, token_id);
        }
    }

    #[generate_trait]
    impl ERC721HelperImpl of ERC721HelperTrait {

        fn _after_token_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            first_token_id: u256,
        ) {
            // Check if either address is whitelisted
            if self.holding_time_whitelist.read(from) || self.holding_time_whitelist.read(to) {
                return ();
            }

            let current_holder = self.holder.read(first_token_id);
            if current_holder != to {
                self.holder.write(first_token_id, to);
                self.hold_start.write(first_token_id, get_block_timestamp());
            }
        }

        ////////////////////////////////
        // internal function to check if a token exists
        ////////////////////////////////
        fn _exists(self: @ContractState, token_id: u256) -> bool {
            // check that owner of token is not zero
            self.owner_of(token_id).is_zero()
        }

        ////////////////////////////////
        // _is_approved_or_owner checks if an address is an approved spender or owner
        ////////////////////////////////
        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self.owners.read(token_id);
            spender == owner
                || self.is_approved_for_all(owner, spender)
                || self.get_approved(token_id) == spender
        }

        ////////////////////////////////
        // internal function that sets the token uri
        ////////////////////////////////
        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uri.write(token_id, token_uri)
        }

        ////////////////////////////////
        // internal function that performs the transfer logic
        ////////////////////////////////
        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            // check that from address is equal to owner of token
            assert(from == self.owner_of(token_id), 'ERC721: Caller is not owner');
            // check that to address is not zero
            assert(to.is_zero(), 'ERC721: transfer to 0 address');

            // remove previously made approvals
            self.token_approvals.write(token_id, Zero::zero());

            // increase balance of to address, decrease balance of from address
            self.balances.write(from, self.balances.read(from) - 1.into());
            self.balances.write(to, self.balances.read(to) + 1.into());

            // make the user the holder
            self.hold_start.write(token_id, get_block_timestamp());

            // emit the Transfer event
            self.emit(Transfer { from: from, to: to, token_id: token_id });
        }

        ////////////////////////////////
        // _mint function mints a new token to the to address
        ////////////////////////////////
        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(to.is_zero(), 'TO_IS_ZERO_ADDRESS');

            // Ensures token_id is unique
            assert(!self.owner_of(token_id).is_non_zero(), 'ERC721: Token already minted');

            // Increase receiver balance
            let receiver_balance = self.balances.read(to);
            self.balances.write(to, receiver_balance + 1.into());

            // Update token_id owner
            self.owners.write(token_id, to);

            // emit Transfer event
            self.emit(Transfer { from: Zero::zero(), to: to, token_id: token_id });
        }

        ////////////////////////////////
        // _burn function burns token from owner's account
        ////////////////////////////////
        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self.owner_of(token_id);

            // Clear approvals
            self.token_approvals.write(token_id, Zero::zero());

            // Decrease owner balance
            let owner_balance = self.balances.read(owner);
            self.balances.write(owner, owner_balance - 1.into());

            // Delete owner
            self.owners.write(token_id, Zero::zero());
            // emit the Transfer event
            self.emit(Transfer { from: owner, to: Zero::zero(), token_id: token_id });
        }
    }
}