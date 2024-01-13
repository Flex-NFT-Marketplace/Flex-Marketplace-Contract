use tests::utils::{setup, initialize_test};

#[test]
fn test_update_royalty_fee_limit_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_update_royalty_fee_limit_fails_max_fee() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_update_royalty_info_collection_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_update_royalty_info_collection_fails_exceeds_fee_limit() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

// TESTS VIEWS
#[test]
fn test_get_royalty_fee_limit() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_get_royalty_fee_info() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_get_royalty_fee_info_collection() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
