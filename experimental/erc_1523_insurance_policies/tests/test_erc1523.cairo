use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};

use erc_1523_insurance_policies::types::{InsurancePolicy, PolicyStatus};
use erc_1523_insurance_policies::interfaces::{IERC1523Dispatcher, IERC1523DispatcherTrait};

fn SYMBOL() -> ByteArray {
    let symbol: ByteArray = "symbol";
    symbol
}
fn BASE_URI() -> ByteArray {
    let base_uri: ByteArray = "base_uri";
    base_uri
}
fn NAME() -> ByteArray {
    let name: ByteArray = "name";
    name
}
fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}
fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}
fn UNDERWRITER() -> ContractAddress {
    'underwriter'.try_into().unwrap()
}
fn CARRIER() -> ContractAddress { 
    'carrier'.try_into().unwrap()
}
fn POLICY() -> InsurancePolicy {
    let policy = InsurancePolicy {
        policy_holder: OWNER(),
        premium: 200_000,
        coverage_period_start: get_block_timestamp().into(),
        coverage_period_end: 60,
        risk: "car insurance coverage",
        underwriter: UNDERWRITER(),
        metadataURI: "uri/v1",
        state: PolicyStatus::Active,
    };

    policy
}
// fn POLICY() -> InsurancePolicy { 
//     let current_timestamp = get_block_timestamp();
//     let policy = InsurancePolicy { 
//         policy_id: 1, 
//         policy_holder: OWNER(), 
//         carrier: CARRIER(), 
//         risk_type: 'car_insurance', 
//         premium: 200_000, 
//         coverage_amount: 50_000_000, 
//         coverage_period_start: current_timestamp, 
//         coverage_period_end: current_timestamp + 31536000, // 1 year from now
//         state: PolicyStatus::Active, 
//         additional_details: 'comprehensive coverage',
//         metadataURI: "uri/v1"
//     }; 
//     policy
// }

fn setup() -> IERC1523Dispatcher {
    let contract_class = declare("ERC1523").unwrap().contract_class();

    let mut calldata = array![];
    NAME().serialize(ref calldata);
    SYMBOL().serialize(ref calldata);
    BASE_URI().serialize(ref calldata);

    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();

    IERC1523Dispatcher { contract_address }
}

#[test]
fn test_create_policy() {
    let dispatcher = setup();
    let erc721_dispatcher = IERC721Dispatcher { contract_address: dispatcher.contract_address };

    let id = dispatcher.create_policy(POLICY());

    assert(id == 1, 'wrong id');
    assert(
        erc721_dispatcher.balance_of(OWNER()) == dispatcher.get_user_policy_amount(OWNER()).into(),
        'wrong balance'
    );
}