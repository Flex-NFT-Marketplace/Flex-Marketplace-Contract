use starknet::ContractAddress;

#[starknet::interface]
trait ITransferManagerNFT<TState> {
    fn initializer(ref self: TState, marketplace: ContractAddress, owner: ContractAddress,);
    fn transfer_non_fungible_token(
        ref self: TState,
        collection: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u128,
        data: Span<felt252>,
    );
    fn update_marketplace(ref self: TState, new_address: ContractAddress);
    fn get_marketplace(self: @TState) -> ContractAddress;
}
