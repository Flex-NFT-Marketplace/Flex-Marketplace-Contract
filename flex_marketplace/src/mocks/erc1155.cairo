const IERC1155_ID: felt252 = 0x6114a8f75559e1b39fcba08ce02961a1aa082d9256a158dd3e64964e4b1b52;

#[starknet::interface]
trait IERC1155<TContractState> {
    fn safe_transfer_from(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        id: u256,
        amount: u128,
        data: Span<felt252>
    );
}

#[starknet::contract]
mod ERC1155 {
    #[storage]
    struct Storage {}

    #[external(v0)]
    impl ERC1155Impl of super::IERC1155<ContractState> {
        fn safe_transfer_from(
            ref self: ContractState,
            from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            id: u256,
            amount: u128,
            data: Span<felt252>
        ) {}
    }
}

