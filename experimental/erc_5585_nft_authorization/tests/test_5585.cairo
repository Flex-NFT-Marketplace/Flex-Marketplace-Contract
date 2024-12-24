use starknet::testing::set_caller_address;
use starknet::testing::set_contract_address;
use starknet::testing::set_block_timestamp;
use starknet::ContractAddress;
use core::traits::Into;
use core::array::ArrayTrait;

use crate::erc5585::{ERC5585NFTAuthorization, IERC5585Dispatcher, IERC5585DispatcherTrait};

fn setup() -> (ContractAddress, IERC5585Dispatcher) {
    // Setup initial rights array
    let mut initial_rights = ArrayTrait::new();
    initial_rights.append('READ');
    initial_rights.append('WRITE');
    initial_rights.append('EXECUTE');

    // Deploy contract
    let owner = contract_address_const::<1>();
    let contract = deploy_contract(
        'ERC5585NFTAuthorization',
        array!['TestNFT', 'TEST', 'baseuri/', owner, 5_u256, initial_rights]
    );

    let dispatcher = IERC5585Dispatcher { contract_address: contract };
    (owner, dispatcher)
}

#[test]
fn test_initial_setup() {
    let (owner, dispatcher) = setup();

    // Test initial rights
    let rights = dispatcher.get_rights();
    assert(rights.len() == 3, 'Wrong initial rights count');

    // Test initial user limit
    assert(dispatcher.get_user_limit() == 5_u256, 'Wrong initial user limit');
}

#[test]
fn test_authorize_user() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let duration = 3600_u64; // 1 hour

    // Mint token first
    dispatcher.mint(owner, token_id);

    // Test basic authorization
    dispatcher.authorize_user(token_id, user, duration);

    let expires = dispatcher.get_expires(token_id, user);
    assert(expires > 0, 'Authorization not set');

    let user_rights = dispatcher.get_user_rights(token_id, user);
    assert(user_rights.len() == 3, 'Wrong rights count');
}

#[test]
fn test_authorize_user_with_rights() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let duration = 3600_u64;

    // Create specific rights
    let mut rights = ArrayTrait::new();
    rights.append('READ');

    dispatcher.mint(owner, token_id);
    dispatcher.authorize_user_with_rights(token_id, user, rights, duration);

    let user_rights = dispatcher.get_user_rights(token_id, user);
    assert(user_rights.len() == 1, 'Wrong specific rights count');
}

#[test]
fn test_transfer_user_rights() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let new_user = contract_address_const::<3>();
    let duration = 3600_u64;

    dispatcher.mint(owner, token_id);
    dispatcher.authorize_user(token_id, user, duration);

    set_caller_address(user);
    dispatcher.transfer_user_rights(token_id, new_user);

    assert(dispatcher.get_expires(token_id, user) == 0, 'Old user rights not cleared');
    assert(dispatcher.get_expires(token_id, new_user) > 0, 'New user rights not set');
}

#[test]
fn test_extend_duration() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let initial_duration = 3600_u64;
    let extension = 1800_u64;

    dispatcher.mint(owner, token_id);
    dispatcher.authorize_user(token_id, user, initial_duration);

    let initial_expires = dispatcher.get_expires(token_id, user);
    dispatcher.extend_duration(token_id, user, extension);

    let new_expires = dispatcher.get_expires(token_id, user);
    assert(new_expires > initial_expires, 'Duration not extended');
}

#[test]
fn test_update_user_rights() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let duration = 3600_u64;

    dispatcher.mint(owner, token_id);
    dispatcher.authorize_user(token_id, user, duration);

    let mut new_rights = ArrayTrait::new();
    new_rights.append('READ');
    dispatcher.update_user_rights(token_id, user, new_rights);

    let updated_rights = dispatcher.get_user_rights(token_id, user);
    assert(updated_rights.len() == 1, 'Rights not updated');
}

#[test]
fn test_user_limit() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let duration = 3600_u64;

    dispatcher.mint(owner, token_id);

    // Try to exceed user limit
    for i in 0
        ..6 {
            let user = contract_address_const::<i>();
            let result = dispatcher.authorize_user(token_id, user, duration);
            if i >= 5 {
                assert(result.is_err(), 'Should fail on exceeding limit');
            }
        }
}

#[test]
fn test_reset_user() {
    let (owner, dispatcher) = setup();
    set_caller_address(owner);

    let token_id = 1_u256;
    let user = contract_address_const::<2>();
    let duration = 3600_u64;

    dispatcher.mint(owner, token_id);
    dispatcher.authorize_user(token_id, user, duration);

    dispatcher.reset_user(token_id, user);
    assert(dispatcher.get_expires(token_id, user) == 0, 'User not reset');
}

#[test]
#[should_panic(expected: 'Not token owner')]
fn test_unauthorized_operations() {
    let (owner, dispatcher) = setup();
    let unauthorized = contract_address_const::<2>();
    set_caller_address(unauthorized);

    let token_id = 1_u256;
    let user = contract_address_const::<3>();
    let duration = 3600_u64;

    dispatcher.authorize_user(token_id, user, duration);
}
