use snforge_std::{
    start_cheat_caller_address, start_cheat_block_timestamp, spy_events, EventSpyAssertionsTrait,
    declare, ContractClassTrait
};

use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use starknet::{ContractAddress, get_block_timestamp};

use erc_1523_insurance_policies::types::{Policy, State};
use erc_1523_insurance_policies::interfaces::{
    IERC1523PolicyMetadata, IERC1523, IERC1523Dispatcher, IERC1523DispatcherTrait
};

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

fn UNDERWRITER() -> ContractAddress {
    'underwriter'.try_into().unwrap()
}

fn POLICY() -> Policy {
    let policy = Policy {
        policyholder: OWNER(),
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
