use starknet::ContractAddress;

const IERC7765_ID: felt252 = 0x268bbe921710b42e87712bcee4aabbbdb8cbc7357c63fadab829af96e720bd7;
const IERC7765_METADATA_ID: felt252 = 0x2de8c9aaf5439dd78e47cd7d4d2b480b0fa16524f156d6b326250c7c699f52;
const IERC7765_RECEIVER_ID: felt252 = 0x35d6ca22886b5b97fa088a439543db8a121ef5466930e998d501a711eb878d5;


#[starknet::interface]
pub trait IERC7765<TContractState> {

    // From ERC-721
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;

    // Specific to ERC7765
    fn is_exercisable(self: @TContractState, token_id: u256, privilege_id: u256, ) -> bool;
    fn is_exercised(self: @TContractState, token_id: u256, privilege_id: u256, ) -> bool;
    fn get_privilege_ids(self: @TContractState, token_id: u256) -> Array<u256>;
    fn exercise_privilege(ref self: TContractState, token_id: u256, to: ContractAddress, privilege_id: u256, calldata: Array<felt252>);

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


//
// ERC7765Receiver
//

#[starknet::interface]
trait IERC7765Receiver<TContractState> {
    fn on_erc7765_received(
        self: @TContractState,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
}