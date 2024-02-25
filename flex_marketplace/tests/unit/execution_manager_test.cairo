use snforge_std::{start_prank, CheatTarget};
use flex::marketplace::execution_manager::{
    IExecutionManagerDispatcher, IExecutionManagerDispatcherTrait
};
use tests::utils::{setup, initialize_test, OWNER, ACCOUNT1, ACCOUNT2};


#[test]
fn test_add_strategy_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());
    dsp.execution_manager.add_strategy(ACCOUNT1());
}

#[test]
#[should_panic(expected: ("ExecutionManager: strategy 4702676443917603889 already whitelisted",))]
fn test_add_strategy_fails_strategy_already_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());
    // add strategy
    dsp.execution_manager.add_strategy(ACCOUNT1());
    // confirm if whitelisted
    let is_whitelisted = dsp.execution_manager.is_strategy_whitelisted(ACCOUNT1());
    assert!(is_whitelisted);

    // add same strategy again, expected error
    dsp.execution_manager.add_strategy(ACCOUNT1());
}

#[test]
fn test_remove_strategy_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());
    // add strategy
    dsp.execution_manager.add_strategy(ACCOUNT1());
    // confirm if whitelisted
    let mut is_whitelisted = dsp.execution_manager.is_strategy_whitelisted(ACCOUNT1());
    assert!(is_whitelisted);

    // proceed to remove the added strategy
    dsp.execution_manager.remove_strategy(ACCOUNT1());
    is_whitelisted = dsp.execution_manager.is_strategy_whitelisted(ACCOUNT1());
    assert!(!is_whitelisted);
}

#[test]
#[should_panic(expected: ("ExecutionManager: strategy 4702676443917603889 not whitelisted",))]
fn test_remove_strategy_fails_strategy_not_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());

    dsp.execution_manager.remove_strategy(ACCOUNT1());
}

// TESTS VIEWS
#[test]
fn is_strategy_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());

    dsp.execution_manager.add_strategy(ACCOUNT1());

    let is_whitelisted = dsp.execution_manager.is_strategy_whitelisted(ACCOUNT1());

    assert!(is_whitelisted);
}

#[test]
fn get_whitelisted_strategies_count() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());
    dsp.execution_manager.add_strategy(ACCOUNT1());
    dsp.execution_manager.add_strategy(ACCOUNT2());

    let whitelisted_count = dsp.execution_manager.get_whitelisted_strategies_count();

    assert!(whitelisted_count == 3, "COUNT ERROR: Expected 3 but found {}", whitelisted_count);
}

#[test]
fn get_whitelisted_strategy() {
    let dsp = setup();
    initialize_test(dsp);
    start_prank(CheatTarget::One(dsp.execution_manager.contract_address), OWNER());
    dsp.execution_manager.add_strategy(ACCOUNT1());

    let _strategy = dsp.execution_manager.get_whitelisted_strategy(2);

    assert!(_strategy == ACCOUNT1(), "STRATEGY ERROR");
}
