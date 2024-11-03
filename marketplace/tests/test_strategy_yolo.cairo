use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use starknet::deploy_syscall;
use marketplace::utils::order_types::{TakerOrder, MakerOrder, PendingRequest};
use marketplace::strategy_yolo_buy::{
    StrategyYoloBuy, IStrategyYoloBuyDispatcher, IStrategyYoloBuyDispatcherTrait
};
use serde::Serde;
use snforge_std::{
    declare, ContractClass, ContractClassTrait, CheatSpan, spy_events, EventSpyAssertionsTrait,
    EventSpy, Event, cheat_caller_address
};


fn deploy_contract() -> (ContractAddress, ContractAddress) {
    let owner = contract_address_const::<'owner'>();
    let fee = 100_u128;
    let randomness_contract = contract_address_const::<'randomness_contract'>();
    let mut calldata: Array<felt252> = array![owner.into(), fee.into(), randomness_contract];
    let contract = declare("StrategyYoloBuy").unwrap();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    (contract_address, owner)
}

fn get_future_time() -> u64 {
    let current_time = get_block_timestamp();
    let twenty_four_hours_in_seconds: u64 = 86400; // 24 hours * 60 minutes * 60 seconds
    let future_time = current_time + twenty_four_hours_in_seconds;
    future_time
}

#[test]
fn test_constructor() {
    let (contract_address, _) = deploy_contract();
    assert(
        IStrategyYoloBuyDispatcher { contract_address }.protocol_fee() == 100,
        'Incorrect protocol fee'
    );
}

#[test]
fn test_update_protocol_fee() {
    let (contract_address, owner) = deploy_contract();
    // Test that only the owner can update protocol fee
    let randomness_contract = contract_address_const::<'randomness_contract_V1'>();
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    IStrategyYoloBuyDispatcher { contract_address }.set_randomness_contract(randomness_contract);
}

#[test]
fn test_set_randomness_contract() {
    let (contract_address, owner) = deploy_contract();
    // Test that only the owner can update protocol fee
    let new_fee = 200_u128;
    cheat_caller_address(contract_address, owner, CheatSpan::TargetCalls(1));
    IStrategyYoloBuyDispatcher { contract_address }.update_protocol_fee(new_fee);
    assert_eq!(IStrategyYoloBuyDispatcher { contract_address }.protocol_fee(), new_fee);
}

#[test]
fn test_create_bid_successful() {
    let (contract_address, _) = deploy_contract();
    let taker = contract_address_const::<'taker'>();
    let signer = contract_address_const::<'signer'>();
    let seller = contract_address_const::<'seller'>();
    let collection = contract_address_const::<'collection'>();
    let currency = contract_address_const::<'currency'>();
    let taker_bid = TakerOrder {
        is_order_ask: false,
        taker: taker,
        price: 100,
        token_id: 1_u256,
        amount: 1,
        min_percentage_to_ask: 100,
        params: 0,
    };

    let maker_ask = MakerOrder {
        is_order_ask: true,
        signer: signer,
        collection: collection,
        price: 100,
        token_id: 1_u256,
        amount: 10,
        strategy: contract_address,
        currency: currency,
        start_time: 0,
        salt_nonce: 12345_u128,
        end_time: get_future_time(),
        min_percentage_to_ask: 9000,
        params: 0,
        seller: seller,
    };

    // Test a successful bid creation
    IStrategyYoloBuyDispatcher { contract_address }.create_bid(taker_bid, maker_ask);

    // spy
    // .assert_emitted(
    //     @array![
    //     ]
    // );

    let bid_request = IStrategyYoloBuyDispatcher { contract_address }.get_bid_request(taker_bid);
    assert_eq!(bid_request.finished, false, "Just created request");
}

#[test]
#[should_panic]
fn test_create_bid_failure_token_id_mismatch() {
    let (contract_address, _) = deploy_contract();
    let taker = contract_address_const::<'taker'>();
    let signer = contract_address_const::<'signer'>();
    let seller = contract_address_const::<'seller'>();
    let collection = contract_address_const::<'collection'>();
    let currency = contract_address_const::<'currency'>();
    let taker_bid = TakerOrder {
        is_order_ask: false,
        taker: taker,
        price: 100,
        token_id: 1_u256,
        amount: 1,
        min_percentage_to_ask: 100,
        params: 0,
    };

    let maker_ask = MakerOrder {
        is_order_ask: true,
        signer: signer,
        collection: collection,
        price: 100,
        token_id: 5_u256,
        amount: 10,
        strategy: contract_address,
        currency: currency,
        start_time: 0,
        salt_nonce: 12345_u128,
        end_time: get_future_time(),
        min_percentage_to_ask: 9000,
        params: 0,
        seller: seller,
    };

    IStrategyYoloBuyDispatcher { contract_address }.create_bid(taker_bid, maker_ask);
}
// #[test]
// fn test_can_execute_taker_bid() {
// }

// #[test]
// fn test_receive_random_words() {
// }


