use flex::marketplace::utils::order_types::MakerOrder;
use starknet::ContractAddress;

trait ISignatureChecker2<TState> {
    fn initializer(ref self: TState, proxy_admin: ContractAddress);
    fn compute_maker_order_hash(self: @TState, hash_domain: felt252, order: MakerOrder) -> felt252;
    fn verify_maker_order_signature(
        self: @TState, hash_domain: felt252, order: MakerOrder, order_signature: Span<felt252>
    );
}

#[starknet::contract]
mod SignatureChecker2 {
    use flex::marketplace::utils::order_types::MakerOrder;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    impl SignatureChecker2Impl of super::ISignatureChecker2<ContractState> {
        fn initializer(ref self: ContractState, proxy_admin: ContractAddress) { // TODO
        }
        fn compute_maker_order_hash(
            self: @ContractState, hash_domain: felt252, order: MakerOrder
        ) -> felt252 {
            // TODO
            0
        }

        fn verify_maker_order_signature(
            self: @ContractState,
            hash_domain: felt252,
            order: MakerOrder,
            order_signature: Span<felt252>
        ) { // TODO
        }
    }
}
