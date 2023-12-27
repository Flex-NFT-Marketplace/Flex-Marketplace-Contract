use starknet::ContractAddress;

use flex::marketplace::utils::order_types::MakerOrder;

const STARKNET_MESSAGE: felt252 = 110930206544689809660069706067448260453;

const HASH_MESSAGE_SELECTOR: felt252 =
    563771258078353655219004671487831885088158240957819730493696170021701903504;

trait ISignatureChecker2<TState> {
    fn initializer(ref self: TState, proxy_admin: ContractAddress);
    fn compute_maker_order_hash(self: @TState, hash_domain: felt252, order: MakerOrder) -> felt252;
    fn verify_maker_order_signature(
        self: @TState, hash_domain: felt252, order: MakerOrder, order_signature: Array<felt252>
    );
}

#[starknet::contract]
mod SignatureChecker2 {
    use flex::marketplace::signature_checker2::ISignatureChecker2;
    use starknet::ContractAddress;
    use poseidon::poseidon_hash_span;

    use openzeppelin::account::interface::{ISRC6CamelOnlyDispatcher, ISRC6CamelOnlyDispatcherTrait};

    use flex::marketplace::utils::order_types::MakerOrder;

    #[storage]
    struct Storage {}

    impl SignatureChecker2Impl of super::ISignatureChecker2<ContractState> {
        fn initializer(ref self: ContractState, proxy_admin: ContractAddress) { // TODO
        }
        fn compute_maker_order_hash(
            self: @ContractState, hash_domain: felt252, order: MakerOrder
        ) -> felt252 {
            let hash_message_params = array![
                super::HASH_MESSAGE_SELECTOR,
                order.is_order_ask.into(),
                order.signer.into(),
                order.collection.into(),
                order.price.into(),
                order.token_id.try_into().unwrap(),
                order.amount.into(),
                order.strategy.into(),
                order.currency.into(),
                order.nonce.into(),
                order.start_time.into(),
                order.end_time.into(),
                order.min_percentage_to_ask.into(),
                order.params,
                14
            ];
            let hash_message = poseidon_hash_span(hash_message_params.span());

            let hash_params = array![
                super::STARKNET_MESSAGE, hash_domain, order.signer.into(), hash_message, 4
            ];
            poseidon_hash_span(hash_params.span())
        }

        fn verify_maker_order_signature(
            self: @ContractState,
            hash_domain: felt252,
            order: MakerOrder,
            order_signature: Array<felt252>
        ) {
            let hash = self.compute_maker_order_hash(hash_domain, order);
            ISRC6CamelOnlyDispatcher { contract_address: order.signer }
                .isValidSignature(hash, order_signature);
        }
    }
}
