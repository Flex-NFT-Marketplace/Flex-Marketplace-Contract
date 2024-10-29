use starknet::ContractAddress;
use alexandria_storage::list::{List, ListTrait};

#[starknet::interface]
pub trait IERC7765<TContractState> {

    // From ERC-721
    // fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
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

    // Specific to ERC7765
    fn is_exercisable(self: @TContractState, token_id: u256, privilege_id: u256, ) -> bool;
    fn is_exercised(self: @TContractState, token_id: u256, privilege_id: u256, ) -> bool;
    fn get_privilege_ids(self: @TContractState, token_id: u256) -> Array<u256>;
    fn exercise_privilege(ref self: TContractState, token_id: u256, to: ContractAddress, privilege_id: u256);

}

#[starknet::interface]
pub trait IERC7765Metadata<TContractState> {

    // From ERC-721
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn token_uri(self: @TContractState, token_id: u256) -> ByteArray;

    // Specific to ERC7765
    fn privilegeURI(self: @TContractState, privilege_id: u256) -> ByteArray;
}
