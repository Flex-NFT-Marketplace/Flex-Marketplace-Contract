use starknet::{ContractAddress, contract_address_const, ClassHash, class_hash_const};

use snforge_std::{start_prank, CheatTarget, declare};

use flex::marketplace::royalty_fee_manager::{
    RoyaltyFeeManager, IRoyaltyFeeManagerDispatcher, IRoyaltyFeeManagerDispatcherTrait
};
use flex::marketplace::royalty_fee_registry::{
    RoyaltyFeeRegistry, IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait
};

use openzeppelin::upgrades::UpgradeableComponent::Upgraded;

use tests::utils::{
    setup, initialize_test, deploy_mock_nft, pop_log, assert_no_events_left, OWNER, ACCOUNT1,
    RECIPIENT
};


fn UPGRADE_CLASSHASH() -> ClassHash {
    RoyaltyFeeManager::TEST_CLASS_HASH.try_into().unwrap()
}

fn CLASS_HASH_ZERO() -> ClassHash {
    class_hash_const::<0>()
}

fn COLLECTION() -> ContractAddress {
    contract_address_const::<'COLLECTION'>()
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn given_caller_has_no_owner_role_then_test_upgrade_fails() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_manager.contract_address), ACCOUNT1());
    dsp.fee_manager.upgrade(UPGRADE_CLASSHASH());
}

#[test]
#[should_panic(expected: ('Class hash cannot be zero', 'ENTRYPOINT_FAILED',))]
fn test_upgrade_with_class_hash_zero() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_manager.contract_address), OWNER());
    dsp.fee_manager.upgrade(CLASS_HASH_ZERO());
}

#[test]
fn test_upgrade_event_when_successful() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_manager.contract_address), OWNER());
    dsp.fee_manager.upgrade(UPGRADE_CLASSHASH());

    let event = pop_log::<Upgraded>(dsp.fee_manager.contract_address).unwrap();
    assert(event.class_hash == UPGRADE_CLASSHASH(), 'Invalid class hash');

    assert_no_events_left(dsp.fee_manager.contract_address);
}

#[test]
fn test_INTERFACE_ID_ERC2981() {
    let dsp = setup();
    initialize_test(dsp);

    // assert the returned felt252 is equal to 0x2a55205a
    assert!(dsp.fee_manager.INTERFACE_ID_ERC2981() == 0x2a55205a, "wrong interface");
}

#[test]
fn test_calculate_royalty_fee_and_get_recipient_success() {
    let dsp = setup();
    initialize_test(dsp);

    // deploy the nft, mint to ACCOUNT1 and ACCOUNT2 in constructor
    let nft_address = deploy_mock_nft();

    start_prank(CheatTarget::One(dsp.fee_registry.contract_address), OWNER());

    // set royalty fee info in fee registry contract 
    dsp.fee_registry.update_royalty_info_collection(COLLECTION(), OWNER(), RECIPIENT(), 1);
    dsp.fee_registry.update_royalty_info_collection(COLLECTION(), OWNER(), RECIPIENT(), 2);

    // call fee_manager
    start_prank(CheatTarget::One(dsp.fee_manager.contract_address), OWNER());

    dsp.fee_manager.calculate_royalty_fee_and_get_recipient(COLLECTION(), 1, 1);
    dsp.fee_manager.calculate_royalty_fee_and_get_recipient(COLLECTION(), 2, 1);
}

#[test]
fn test_get_royalty_fee_registry() {
    let dsp = setup();
    initialize_test(dsp);

    // ensure the address saved in storage matches the address from the dsp 
    assert!(
        dsp
            .fee_manager
            .get_royalty_fee_registry()
            .contract_address == dsp
            .fee_registry
            .contract_address,
        "wrong fee registry"
    );
}

