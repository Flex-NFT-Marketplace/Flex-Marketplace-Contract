use tests::utils::{setup, initialize_test};

#[test]
fn test_cancel_all_orders_for_sender_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_cancel_all_orders_for_sender_fails_wrong_min_nonce() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_carcel_maker_order_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_carcel_maker_order_fails_wrong_min_nonce() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_match_ask_with_taker_bid_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_match_ask_with_taker_bid_fails_invalid_caller() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_ask_with_taker_bid_fails_maker_ask_not_ask_orde() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_ask_with_taker_bid_fails_taker_bid_is_ask_order() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_ask_with_taker_bid_fails_order_cannot_be_executed() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}
#[test]
fn test_match_bid_with_taker_ask_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_match_bid_with_taker_ask_fails_invalid_caller_address() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_bid_with_taker_ask_fails_maker_bid_is_ask_order() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_bid_with_taker_ask_fails_taker_ask_is_not_an_ask_order() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_match_bid_with_taker_ask_fails_taker_ask_cannot_be_executed() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_execute_auction_sale_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_invalid_caller_address() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_maker_ask_not_maker_order() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_maker_bid_is_maker_order() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_caller_not_relayer() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_strategy_cannot_be_executed() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_update_hash_domain() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_protocol_fee_recepient() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_currency_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_execution_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_royalty_fee_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_transfer_selector_NFT() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_signature_checker() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

// TESTS VIWES

#[test]
fn test_get_hash_domain() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_protocol_fee_recipient() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_currency_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_execution_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_royalty_fee_manager() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_transfer_selector_NFT() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_signature_checker() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn get_user_min_order_nonce() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_is_user_order_nonce_executed_or_cancelled() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

// TESTS INTERNALS
#[test]
fn test_transfer_fees_and_funds_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_transfer_fees_and_funds_fails_amount_is_zero() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_transfer_non_fungible_token_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_transfer_non_fungible_token_fails_invalid_amount() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_transfer_non_fungible_token_fails_invalid_transfer_manager() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_calculate_protocol_fee_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_validate_order_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_order_is_cancelled() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_invalid_min_nonce() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_invalid_order_signer() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_invalid_order_amount() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_currency_not_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_validate_order_fails_strategy_not_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

