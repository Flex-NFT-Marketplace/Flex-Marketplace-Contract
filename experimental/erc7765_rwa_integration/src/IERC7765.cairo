use starknet::ContractAddress;

#[starknet::interface]
trait ERC7765<TState> {

    fn isExercisable(self: @TState, to: u256, token_id: u256, privilege_id: u256, ) -> bool;
    fn isExercised(self: @TState, to: u256, token_id: u256, privilege_id: u256, ) -> bool;
    fn getPrivilegeIds(self: @TState, tokenId: u256) -> array[u256];

    
}


trait IERC7765Metadata<TState> {

    fn privilegeURI(self: @TState, privilege_id: u256) -> string;

}