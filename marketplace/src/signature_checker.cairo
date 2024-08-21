use starknet::ContractAddress;

use marketplace::utils::order_types::MakerOrder;

#[starknet::interface]
trait ISignatureChecker<TState> {
    fn initializer(ref self: TState, proxy_admin: ContractAddress);
    fn compute_maker_order_hash(self: @TState, hash_domain: felt252, order: MakerOrder) -> felt252;
    fn verify_maker_order_signature(
        self: @TState, hash_domain: felt252, order: MakerOrder, order_signature: Span<felt252>
    );
}
