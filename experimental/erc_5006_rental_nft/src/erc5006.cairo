#[starknet::contract]
mod ERC5006 {
    use starknet::ContractAddress;
    use erc_5006_rental_nft::types::UserRecord;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl ERC5006Impl of erc_5006_rental_nft::interfaces::erc5006::IERC5006<ContractState> {
        fn usable_balance_of(
            self: @ContractState, account: ContractAddress, token_id: u256
        ) -> u256 {
            0
        }

        fn user_record_of(self: @ContractState, record_id: u256) -> UserRecord {
            let address: ContractAddress = 0.try_into().unwrap();
            UserRecord { token_id: 0, owner: address, amount: 0, user: address, expiry: 0 }
        }

        fn create_user_record(
            ref self: ContractState,
            owner: ContractAddress,
            user: ContractAddress,
            token_id: u256,
            amount: u64,
            expiry: u64
        ) -> u256 {
            0
        }

        fn delete_user_record(ref self: ContractState, record_id: u256) {}
    }
}
