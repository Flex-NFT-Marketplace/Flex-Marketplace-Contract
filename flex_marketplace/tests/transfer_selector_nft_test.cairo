use tests::utils::{setup, initialize_test};

#[test]
fn test_add_collection_transfer_manager_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_add_collection_transfer_manager_fails_invalid_collection() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
#[should_panic()]
fn test_add_collection_transfer_manager_fails_invalid_transfer_manager() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_remove_collection_transfer_manager_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
#[should_panic()]
fn test_remove_collection_transfer_manager_fails_invalid_transfer_manager() {
    let dsp = setup();
    initialize_test(dsp);
    assert(false, '');
// TODO
}

#[test]
fn test_update_TRANSFER_MANAGER_ERC721_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

#[test]
fn test_update_TRANSFER_MANAGER_ERC1155_success() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

// TESTS VIEWS
#[test]
fn test_get_INTERFACE_ID_ERC721() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_get_INTERFACE_ID_ERC1155() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_get_TRANSFER_MANAGER_ERC721() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_get_TRANSFER_MANAGER_ERC1155() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_get_transfer_manager_selector_for_collection() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}
#[test]
fn test_check_transfer_manager_for_token() {
    let dsp = setup();
    initialize_test(dsp);
// TODO
}

