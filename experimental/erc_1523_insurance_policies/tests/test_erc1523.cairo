use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, declare, ContractClassTrait
};

use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};

use erc_1523_insurance_policies::types::{Policy, State};
use erc_1523_insurance_policies::interfaces::{IERC1523Dispatcher, IERC1523DispatcherTrait};

fn NAME() -> ByteArray {
    let name: ByteArray = "name";
    name
}
fn SYMBOL() -> ByteArray {
    let symbol: ByteArray = "symbol";
    symbol
}
fn BASE_URI() -> ByteArray {
    let base_uri: ByteArray = "base_uri";
    base_uri
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

fn POLICY() -> Policy {
    let policy = Policy {
        policy_holder: OWNER(),
        premium: 200_000,
        coverage_period_start: get_block_timestamp().into(),
        coverage_period_end: 60,
        risk: "car insurance coverage",
        underwriter: UNDERWRITER(),
        metadataURI: "uri/v1",
        state: State::Active,
    };

    policy
}


fn setup() -> IERC1523Dispatcher {
    let contract_class = declare("ERC1523").unwrap();

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
fn test_get_all_user_policies() {
    let dispatcher = setup();
    let amount = 5;

    for _ in 0..amount {
        dispatcher.create_policy(POLICY());
    };

    let user_policies = dispatcher.get_all_user_policies(OWNER());

    assert(user_policies.len() == amount, 'wrong amount');
}

#[test]
fn test_update_policy_state() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    dispatcher.update_policy_state(id, State::Claimed);

    let policy = dispatcher.get_policy(id);

    assert(policy.state == State::Claimed, 'wrong state');
}


#[test]
#[should_panic(expected: ('wrong policy holder',))]
fn test_transfer_policy_with_not_owner() {
    let dispatcher = setup();

    let id = dispatcher.create_policy(POLICY());

    start_cheat_caller_address(dispatcher.contract_address, BOB());
    dispatcher.transfer_policy(id, BOB());
    stop_cheat_caller_address(dispatcher.contract_address);
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

    assert(policy.policy_holder == BOB(), 'wrong policy holder');
    assert(erc721_dispatcher.owner_of(id) == BOB(), 'wrong owner');
}
