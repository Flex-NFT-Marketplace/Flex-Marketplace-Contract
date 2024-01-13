use tests::utils::{setup, initialize_test};

#[test]
fn test_add_strategy_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_add_strategy_fails_strategy_already_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_remove_strategy_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_remove_strategy_fails_strategy_not_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

// TESTS VIEWS
#[test]
fn is_strategy_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn get_whitelisted_strategies_count() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn get_whitelisted_strategy() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
