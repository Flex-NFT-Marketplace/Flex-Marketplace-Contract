use tests::utils::{setup, initialize_test};
use poseidon::poseidon_hash_span;

use snforge_std::signature::stark_curve::{
    StarkCurveKeyPairImpl, StarkCurveSignerImpl
};
use flex::marketplace::signature_checker2::{ISignatureChecker2Dispatcher, ISignatureChecker2DispatcherTrait,STARKNET_MESSAGE, HASH_MESSAGE_SELECTOR};
use flex::marketplace::utils::order_types::MakerOrder;

#[test]
fn test_compute_maker_order_hash_success(hash_domain: felt252) {
    let dsp = setup();
    initialize_test(dsp);

    let maker_order: MakerOrder = Default::default();

    let hash_message_params = array![
        HASH_MESSAGE_SELECTOR,
        maker_order.is_order_ask.into(),
        maker_order.signer.into(),
        maker_order.collection.into(),
        maker_order.price.into(),
        maker_order.token_id.try_into().unwrap(),
        maker_order.amount.into(),
        maker_order.strategy.into(),
        maker_order.currency.into(),
        maker_order.nonce.into(),
        maker_order.start_time.into(),
        maker_order.end_time.into(),
        maker_order.min_percentage_to_ask.into(),
        maker_order.params,
        14
    ];

    let hash_message = poseidon_hash_span(hash_message_params.span());

    let hash_params = array![
        STARKNET_MESSAGE, hash_domain, maker_order.signer.into(), hash_message, 4
    ];

    let order_hash = poseidon_hash_span(hash_params.span());

    assert(order_hash == dsp.signature_checker.compute_maker_order_hash(hash_domain, maker_order), 'Failed hash computation');
}

#[test]
fn test_verify_maker_order_signature_success(hash_domain: felt252) {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    let mut maker_order: MakerOrder = Default::default();

    maker_order.signer = mocks.account;

    let hash_message_params = array![
        HASH_MESSAGE_SELECTOR,
        maker_order.is_order_ask.into(),
        maker_order.signer.into(),
        maker_order.collection.into(),
        maker_order.price.into(),
        maker_order.token_id.try_into().unwrap(),
        maker_order.amount.into(),
        maker_order.strategy.into(),
        maker_order.currency.into(),
        maker_order.nonce.into(),
        maker_order.start_time.into(),
        maker_order.end_time.into(),
        maker_order.min_percentage_to_ask.into(),
        maker_order.params,
        14
    ];

    let hash_message = poseidon_hash_span(hash_message_params.span());

    let hash_params = array![
        STARKNET_MESSAGE, hash_domain, maker_order.signer.into(), hash_message, 4
    ];

    let order_hash = poseidon_hash_span(hash_params.span());
    let (r, s) : (felt252, felt252) = mocks.key_pair.sign(order_hash);
    dsp.signature_checker.verify_maker_order_signature(hash_domain, maker_order, array![r, s]);
}
