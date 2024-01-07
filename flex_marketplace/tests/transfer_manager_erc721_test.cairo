use tests::utils::{setup, initialize_test};

#[test]
fn test_transfer_non_fungible_token_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_transfer_non_fungible_token_fails_caller_not_marketplace() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_update_marketplace_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}


// TESTS VIEWSqs
#[test]
fn test_get_marketplace() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
