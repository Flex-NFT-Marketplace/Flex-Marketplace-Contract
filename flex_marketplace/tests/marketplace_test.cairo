use snforge_std::{start_prank, stop_prank, PrintTrait, CheatTarget};
use tests::utils::{
    setup, initialize_test, deploy_mock_nft, ACCOUNT1, ACCOUNT2, OWNER, ZERO_ADDRESS, RELAYER,
    deploy_mock_execution_strategy, deploy_mock_account, deploy_mock_erc20, E18
};
use flex::marketplace::execution_manager::{
    IExecutionManagerDispatcher, IExecutionManagerDispatcherTrait
};
use flex::marketplace::marketplace::{IMarketPlaceDispatcher, IMarketPlaceDispatcherTrait};
use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};
use flex::DefaultContractAddress;

#[test]
fn test_cancel_all_orders_for_sender_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.cancel_all_orders_for_sender(1);
    let new_min_nonce = dsp.marketplace.get_user_min_order_nonce(ACCOUNT1());
    assert(new_min_nonce == 1, 'wrong min nonce');
}

#[test]
#[should_panic(expected: ("MarketPlace: current min nonce 0 is not < than 0",))]
fn test_cancel_all_orders_for_sender_fails_wrong_min_nonce() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.cancel_all_orders_for_sender(0);
}

#[test]
fn test_carcel_maker_order_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.cancel_maker_order(1);
    let is_orde_cancelled = dsp
        .marketplace
        .get_is_user_order_nonce_executed_or_cancelled(ACCOUNT1(), 1);
    assert(is_orde_cancelled, 'orded not cancelled');
}

#[test]
#[should_panic(expected: ("MarketPlace: current min nonce 0 is not < than 0",))]
fn test_carcel_maker_order_fails_wrong_min_nonce() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.cancel_maker_order(0);
}

#[test]
fn test_match_ask_with_taker_bid_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_order: MakerOrder = Default::default();
    maker_order.is_order_ask = true;
    maker_order.collection = mocks.erc721;
    maker_order.signer = mocks.account;
    maker_order.amount = 1;
    maker_order.strategy = mocks.strategy;
    maker_order.currency = mocks.erc20;

    let mut taker_bid: TakerOrder = Default::default();
    taker_bid.price = 1000000;
    taker_bid.taker = ACCOUNT1();

    dsp.marketplace.match_ask_with_taker_bid(taker_bid, maker_order, array![r, s], ACCOUNT1());
}

#[test]
#[should_panic(expected: "MarketPlace: invalid caller address 0",)]
fn test_match_ask_with_taker_bid_fails_invalid_caller() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ZERO_ADDRESS());
    let mut maker_order: MakerOrder = Default::default();
    let mut taker_bid: TakerOrder = Default::default();

    dsp.marketplace.match_ask_with_taker_bid(taker_bid, maker_order, array![r, s], ACCOUNT1());
}

#[test]
#[should_panic(expected: "MarketPlace: maker ask is not an ask order",)]
fn test_match_ask_with_taker_bid_fails_maker_ask_not_ask_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_order: MakerOrder = Default::default();
    let mut taker_bid: TakerOrder = Default::default();

    dsp.marketplace.match_ask_with_taker_bid(taker_bid, maker_order, array![r, s], ACCOUNT1());
}

#[test]
#[should_panic(expected: "MarketPlace: taker bid is an ask order",)]
fn test_match_ask_with_taker_bid_fails_taker_bid_is_ask_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_order: MakerOrder = Default::default();
    maker_order.is_order_ask = true;

    let mut taker_bid: TakerOrder = Default::default();
    taker_bid.is_order_ask = true;

    dsp.marketplace.match_ask_with_taker_bid(taker_bid, maker_order, array![r, s], ACCOUNT1());
}

#[test]
fn test_match_bid_with_taker_ask_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_bid: MakerOrder = Default::default();
    maker_bid.collection = mocks.erc721;
    maker_bid.signer = mocks.account;
    maker_bid.amount = 1;
    maker_bid.strategy = mocks.strategy;
    maker_bid.currency = mocks.erc20;

    let mut taker_ask: TakerOrder = Default::default();
    taker_ask.is_order_ask = true;
    taker_ask.price = 1000000;
    taker_ask.taker = ACCOUNT1();

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.match_bid_with_taker_ask(taker_ask, maker_bid, array![r, s], array![]);
}

#[test]
#[should_panic(expected: "MarketPlace: invalid caller address 0",)]
fn test_match_bid_with_taker_ask_fails_invalid_caller_address() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_bid: MakerOrder = Default::default();

    let mut taker_ask: TakerOrder = Default::default();
    taker_ask.is_order_ask = true;
    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ZERO_ADDRESS());
    dsp.marketplace.match_bid_with_taker_ask(taker_ask, maker_bid, array![r, s], array![]);
}

#[test]
#[should_panic(expected: "MarketPlace: maker bid is an ask order",)]
fn test_match_bid_with_taker_ask_fails_maker_bid_is_ask_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_bid: MakerOrder = Default::default();
    maker_bid.is_order_ask = true;

    let mut taker_ask: TakerOrder = Default::default();

    dsp.marketplace.match_bid_with_taker_ask(taker_ask, maker_bid, array![r, s], array![]);
}

#[test]
#[should_panic()]
fn test_match_bid_with_taker_ask_fails_taker_ask_is_not_an_ask_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r, s) = mocks.maker_signature;

    let mut maker_bid: MakerOrder = Default::default();

    let mut taker_ask: TakerOrder = Default::default();

    dsp.marketplace.match_bid_with_taker_ask(taker_ask, maker_bid, array![r, s], array![]);
}

#[test]
fn test_execute_auction_sale_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r1, s1) = mocks.maker_signature;
    let (r2, s2) = mocks.taker_signature;

    let mut maker_ask: MakerOrder = Default::default();
    maker_ask.is_order_ask = true;
    maker_ask.strategy = mocks.strategy;
    maker_ask.signer = mocks.account;
    maker_ask.amount = 1;
    maker_ask.collection = mocks.erc721;
    maker_ask.currency = mocks.erc20;

    let mut maker_bid: MakerOrder = Default::default();
    maker_bid.signer = mocks.account;
    maker_bid.strategy = mocks.strategy;
    maker_bid.price = 1_000_000;
    maker_bid.amount = 1;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), RELAYER());
    dsp.marketplace.execute_auction_sale(maker_ask, array![r1, s1], maker_bid, array![r2, s2]);
}

#[test]
#[should_panic(expected: "MarketPlace: invalid caller address 0",)]
fn test_execute_auction_sale_fails_invalid_caller_address() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r1, s1) = mocks.maker_signature;
    let (r2, s2) = mocks.taker_signature;

    let mut maker_ask: MakerOrder = Default::default();

    let mut maker_bid: MakerOrder = Default::default();

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ZERO_ADDRESS());
    dsp.marketplace.execute_auction_sale(maker_ask, array![r1, s1], maker_bid, array![r2, s2]);
}

#[test]
#[should_panic(expected: "MarketPlace: maker ask is not an ask order",)]
fn test_execute_auction_sale_fails_maker_ask_not_maker_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r1, s1) = mocks.maker_signature;
    let (r2, s2) = mocks.taker_signature;

    let mut maker_ask: MakerOrder = Default::default();

    let mut maker_bid: MakerOrder = Default::default();

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), RELAYER());
    dsp.marketplace.execute_auction_sale(maker_ask, array![r1, s1], maker_bid, array![r2, s2]);
}

#[test]
#[should_panic()]
fn test_execute_auction_sale_fails_maker_bid_is_maker_order() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r1, s1) = mocks.maker_signature;
    let (r2, s2) = mocks.taker_signature;

    let mut maker_ask: MakerOrder = Default::default();

    let mut maker_bid: MakerOrder = Default::default();
    maker_bid.is_order_ask = true;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), RELAYER());
    dsp.marketplace.execute_auction_sale(maker_ask, array![r1, s1], maker_bid, array![r2, s2]);
}

#[test]
#[should_panic(expected: "MarketPlace: caller is not relayer",)]
fn test_execute_auction_sale_fails_caller_not_relayer() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (r1, s1) = mocks.maker_signature;
    let (r2, s2) = mocks.taker_signature;

    let mut maker_ask: MakerOrder = Default::default();
    maker_ask.is_order_ask = true;
    maker_ask.strategy = mocks.strategy;
    maker_ask.signer = mocks.account;
    maker_ask.amount = 1;
    maker_ask.collection = mocks.erc721;
    maker_ask.currency = mocks.erc20;

    let mut maker_bid: MakerOrder = Default::default();
    maker_bid.signer = mocks.account;
    maker_bid.strategy = mocks.strategy;
    maker_bid.price = 1_000_000;
    maker_bid.amount = 1;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), ACCOUNT1());
    dsp.marketplace.execute_auction_sale(maker_ask, array![r1, s1], maker_bid, array![r2, s2]);
}

#[test]
fn test_update_hash_domain() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let new_hash_domain = 'new_hash_domain';

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_hash_domain(new_hash_domain);
    let actual = dsp.marketplace.get_hash_domain();
    assert(actual == new_hash_domain, 'failed hash domain update');
}

#[test]
fn test_update_protocol_fee_recepient() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_protocol_fee_recepient(ACCOUNT1());
    let actual = dsp.marketplace.get_protocol_fee_recipient();
    assert(actual == ACCOUNT1(), 'failed fee recipient update');
}

#[test]
fn test_update_currency_manager() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_currency_manager(ACCOUNT1());
    let actual = dsp.marketplace.get_currency_manager();
    assert(actual == ACCOUNT1(), 'failed currency manager update');
}

#[test]
fn test_update_execution_manager() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_execution_manager(ACCOUNT1());
    let actual = dsp.marketplace.get_execution_manager();
    assert(actual == ACCOUNT1(), 'failed execution manager update');
}

#[test]
fn test_update_royalty_fee_manager() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_royalty_fee_manager(ACCOUNT1());
    let actual = dsp.marketplace.get_royalty_fee_manager();
    assert(actual == ACCOUNT1(), 'failed royalty manager update');
}

#[test]
fn test_update_transfer_selector_NFT() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_transfer_selector_NFT(ACCOUNT1());
    let actual = dsp.marketplace.get_transfer_selector_NFT();
    assert(actual == ACCOUNT1(), 'failed selector nft update');
}

#[test]
fn test_update_signature_checker() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), OWNER());
    dsp.marketplace.update_signature_checker(ACCOUNT1());
    let actual = dsp.marketplace.get_signature_checker();
    assert(actual == ACCOUNT1(), 'failed selector sig checker');
}

