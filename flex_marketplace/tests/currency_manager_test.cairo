use snforge_std::{start_prank, CheatTarget};
use flex::marketplace::currency_manager::{
    ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait
};
use tests::utils::{setup, initialize_test, ACCOUNT1, OWNER};


#[test]
fn test_add_currency_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.currency_manager.contract_address), OWNER());

    dsp.currency_manager.add_currency(ACCOUNT1());

    assert!(dsp.currency_manager.is_currency_whitelisted(ACCOUNT1()));
}

#[test]
#[should_panic(
    expected: (
        "CurrencyManager: currency 710010689975950048888168914535176849151458040976071544013000098827867207947 already whitelisted",
    )
)]
fn test_add_currency_fails_currency_already_whitelisted() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.currency_manager.contract_address), OWNER());

    dsp.currency_manager.add_currency(mocks.erc20);
}

#[test]
fn test_remove_currency_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.currency_manager.contract_address), OWNER());
    dsp.currency_manager.remove_currency(mocks.erc20);

    assert!(!dsp.currency_manager.is_currency_whitelisted(mocks.erc20));
}

#[test]
#[should_panic(expected: ("CurrencyManager: currency 4702676443917603889 not whitelisted",))]
fn test_remove_currency_fails_currency_not_whitelisted() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.currency_manager.contract_address), OWNER());

    dsp.currency_manager.remove_currency(ACCOUNT1());
}

// TESTS VIEWS
#[test]
fn test_is_currency_whitelisted() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    assert!(dsp.currency_manager.is_currency_whitelisted(mocks.erc20));
}

#[test]
fn test_whitelisted_currency_count() {
    let dsp = setup();
    initialize_test(dsp);

    assert!(dsp.currency_manager.whitelisted_currency_count() == 1);
}
#[test]
fn test_whitelisted_currency() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let whitelisted_currency = dsp.currency_manager.whitelisted_currency(1);
    assert!(whitelisted_currency == mocks.erc20);
}

