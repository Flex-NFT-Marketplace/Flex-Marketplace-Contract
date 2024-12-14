#[starknet::contract]
mod ERC6105 {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl ERC6105Impl of erc_6105_no_intermediary_nft_trading_protocol::interfaces::erc6105::IERC6105<
        ContractState
    > {
        fn list_item(
            ref self: ContractState,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress
        ) {}

        fn list_item_with_benchmark(
            ref self: ContractState,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress,
            benchmark_price: u256
        ) {}

        fn delist_item(ref self: ContractState, token_id: u256) {}

        fn buy_item(
            ref self: ContractState,
            token_id: u256,
            sale_price: u256,
            supported_token: ContractAddress
        ) {}

        fn get_listing(self: @ContractState, token_id: u256) -> (u256, u64, ContractAddress, u256) {
            let address: ContractAddress = 0.try_into().unwrap();
            return (0, 0, address, 0);
        }
    }
}
