use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address
};

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
        state: PolicyStatus::Created,
    };

    policy
}
fn ACTIVE_POLICY() -> InsurancePolicy {
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

#[test]
fn test_transfer_policy() {
    let dispatcher = setup();
    let erc721_dispatcher = IERC721Dispatcher { contract_address: dispatcher.contract_address };

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.transfer_policy(id, BOB());
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);

    assert(policy.policy_holder == BOB(), 'Wrong policy holder');
    assert(erc721_dispatcher.owner_of(id) == BOB(), 'wrong owner');
}

#[test]
#[should_panic(expected: ('Wrong policy holder',))]
fn test_transfer_policy_with_not_owner() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, BOB());
    dispatcher.transfer_policy(id, BOB());
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_update_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.update_policy(id, PolicyStatus::Claimed);
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);
    assert(policy.state == PolicyStatus::Claimed, 'Wrong state');
}

#[test]
fn test_activate_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.activate_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);
    assert(policy.state == PolicyStatus::Active, 'Policy not activated');
}

#[test]
#[should_panic(expected: ('Only policy holder can activate',))]
fn test_activate_policy_not_owner() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, BOB());
    dispatcher.activate_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_get_all_policies_by_owner() {
    let dispatcher = setup();
    let amount = 5;

    for _ in 0..amount {
        dispatcher.create_policy(POLICY());
    };

    let user_policies = dispatcher.get_policies_by_owner(OWNER());
    assert(user_policies.len() == amount, 'wrong amount');
}

#[test]
fn test_expire_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.expire_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);
    assert(policy.state == PolicyStatus::Expired, 'Policy not expired');
}

#[test]
fn test_cancel_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.cancel_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);
    assert(policy.state == PolicyStatus::Cancelled, 'Policy not cancelled');
}

#[test]
#[should_panic(expected: ('Only policy holder can cancel',))]
fn test_cancel_policy_not_owner() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, BOB());
    dispatcher.cancel_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic(expected: ('Policy already cancelled',))]
fn test_cancel_already_cancelled_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.cancel_policy(id);
    dispatcher.cancel_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_claim_policy() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(ACTIVE_POLICY());

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.claim_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);

    let policy = dispatcher.get_policy(id);
    assert(policy.state == PolicyStatus::Claimed, 'Policy not claimed');
}

#[test]
#[should_panic(expected: ('Policy must be active to claim',))]
fn test_claim_inactive_policy() {
    let mut policy = POLICY();
    policy.state = PolicyStatus::Expired;

    let dispatcher = setup();

    let id = dispatcher.create_policy(policy);

    start_cheat_caller_address(dispatcher.contract_address, OWNER());
    dispatcher.claim_policy(id);
    stop_cheat_caller_address(dispatcher.contract_address);
}
