#[starknet::interface]
trait IERC1155<TContractState> {
    fn safe_transfer_from(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        id: u256,
        amount: u256,
        data: Array<u8>
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
            amount: u256,
            data: Array<u8>
        ) {}
    }
}

