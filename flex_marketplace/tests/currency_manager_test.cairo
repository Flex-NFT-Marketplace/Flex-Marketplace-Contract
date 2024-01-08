use tests::utils::{setup, initialize_test};

#[test]
fn test_add_currency_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_add_currency_fails_currency_already_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_remove_currency_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_remove_currency_fails_currency_not_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

// TESTS VIEWS
#[test]
fn test_is_currency_whitelisted() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_whitelisted_currency_count() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_whitelisted_currency() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

