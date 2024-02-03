use tests::utils::{setup, initialize_test, OWNER, ACCOUNT1, RECIPIENT};
use snforge_std::{start_prank, CheatTarget};
use flex::marketplace::royalty_fee_registry::{
    IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait
};
use starknet::{contract_address_const};

const NEW_FEE_LIMIT: u128 = 2_000;
const FEE: u128 = 1_000;


#[test]
fn test_update_royalty_fee_limit_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_registry.contract_address), OWNER());
    dsp.fee_registry.update_royalty_fee_limit(NEW_FEE_LIMIT);
}

#[test]
#[should_panic(expected: "RoyaltyFeeRegistry: fee_limit 10000 exceeds MAX_FEE")]
fn test_update_royalty_fee_limit_fails_max_fee() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_registry.contract_address), OWNER());
    // expected error
    dsp.fee_registry.update_royalty_fee_limit(10_000);
}

#[test]
fn test_update_royalty_info_collection_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_registry.contract_address), OWNER());
    dsp.fee_registry.update_royalty_info_collection(mocks.erc721, ACCOUNT1(), RECIPIENT(), FEE);
}

#[test]
#[should_panic(expected: "RoyaltyFeeRegistry: fee 3000 exceeds fee limit 1000")]
fn test_update_royalty_info_collection_fails_exceeds_fee_limit() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.fee_registry.contract_address), OWNER());
    dsp.fee_registry.update_royalty_info_collection(mocks.erc721, ACCOUNT1(), RECIPIENT(), 3000);
}

// TESTS VIEWS
#[test]
fn test_get_royalty_fee_limit() {
    let dsp = setup();
    initialize_test(dsp);
    let fee_limit: u128 = dsp.fee_registry.get_royalty_fee_limit();
    assert!(fee_limit == FEE, "Unexpected Fee Limit");
}

#[test]
fn test_get_royalty_fee_info() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    let (receiver, amount) = dsp.fee_registry.get_royalty_fee_info(mocks.erc721, FEE);
    assert!(amount == 100, "Unexpected returned fee info");
    assert!(receiver == RECIPIENT(), "Unexpected returned receipient");
}
#[test]
fn test_get_royalty_fee_info_collection() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    let (setter, receiver, fee) = dsp.fee_registry.get_royalty_fee_info_collection(mocks.erc721);
    assert!(setter == OWNER());
    assert!(receiver == RECIPIENT());
    assert!(fee == FEE);
}
