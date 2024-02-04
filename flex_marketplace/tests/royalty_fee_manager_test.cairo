use tests::utils::{setup, initialize_test, RECIPIENT};
use flex::marketplace::royalty_fee_manager::{
    IRoyaltyFeeManagerDispatcher, IRoyaltyFeeManagerDispatcherTrait
};

#[test]
fn test_calculate_royalty_fee_and_get_recipient_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (receiver, royaltyAmount) = dsp
        .fee_manager
        .calculate_royalty_fee_and_get_recipient(mocks.erc721, 1, 1000);
    assert!(receiver == RECIPIENT(), "Unexpected returned receiver");
    assert!(royaltyAmount == 100, "Unexpected returned royalty amount");
}

#[test]
fn test_get_royalty_fee_registry() {
    let dsp = setup();
    initialize_test(dsp);

    let registry = dsp.fee_registry.contract_address;
    let fee_registry = dsp.fee_manager.get_royalty_fee_registry();

    assert!(registry == fee_registry.contract_address, "Unexpected returned Contract Address");
}
