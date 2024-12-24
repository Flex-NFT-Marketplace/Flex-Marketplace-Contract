use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC721<TState> {
    fn balance_of(self: @TState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn safe_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
}

#[starknet::interface]
pub trait IERC5585<TState> {
    fn get_rights(self: @TState) -> Array<felt252>;
    fn authorize_user(ref self: TState, token_id: u256, user: ContractAddress, duration: u64);
    fn authorize_user_with_rights(
        ref self: TState,
        token_id: u256,
        user: ContractAddress,
        rights: Array<felt252>,
        duration: u64
    );
    fn transfer_user_rights(ref self: TState, token_id: u256, new_user: ContractAddress);
    fn extend_duration(ref self: TState, token_id: u256, user: ContractAddress, duration: u64);
    fn update_user_rights(
        ref self: TState, token_id: u256, user: ContractAddress, rights: Array<felt252>
    );
    fn get_expires(self: @TState, token_id: u256, user: ContractAddress) -> u64;
    fn get_user_rights(self: @TState, token_id: u256, user: ContractAddress) -> Array<felt252>;
    fn update_user_limit(ref self: TState, user_limit: u256);
    fn update_reset_allowed(ref self: TState, reset_allowed: bool);
    fn check_authorization_availability(self: @TState, token_id: u256) -> bool;
    fn reset_user(ref self: TState, token_id: u256, user: ContractAddress);
}
