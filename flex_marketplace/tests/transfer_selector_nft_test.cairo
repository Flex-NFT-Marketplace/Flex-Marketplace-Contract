use starknet::{ContractAddress, contract_address_const};
use snforge_std::{start_prank, CheatTarget};
use flex::marketplace::transfer_selector_NFT::{
    TransferSelectorNFT, ITransferSelectorNFTDispatcher, ITransferSelectorNFTDispatcherTrait
};
use tests::utils::{setup, initialize_test, OWNER, ZERO_ADDRESS, ACCOUNT1};

fn COLLECTION() -> ContractAddress {
    contract_address_const::<'COLLECTION'>()
}

#[test]
fn test_add_collection_transfer_manager_success() {
    let dsp = setup();
    initialize_test(dsp);
    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp
        .transfer_selector
        .add_collection_transfer_manager(
            COLLECTION(), dsp.transfer_manager_erc721.contract_address
        );

    let actual_transfer_manager = dsp
        .transfer_selector
        .get_transfer_manager_selector_for_collection(COLLECTION());
    assert!(
        actual_transfer_manager == dsp.transfer_manager_erc721.contract_address,
        "Wrong transfer manager set"
    );
}

#[test]
#[should_panic(expected: ("TransferSelectorNFT: invalid collection 0",))]
fn test_add_collection_transfer_manager_fails_invalid_collection() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp
        .transfer_selector
        .add_collection_transfer_manager(
            ZERO_ADDRESS(), dsp.transfer_manager_erc721.contract_address
        );
}

#[test]
#[should_panic(expected: ("TransferSelectorNFT: invalid transfer manager 0",))]
fn test_add_collection_transfer_manager_fails_invalid_transfer_manager() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp.transfer_selector.add_collection_transfer_manager(COLLECTION(), ZERO_ADDRESS());
}

#[test]
fn test_remove_collection_transfer_manager_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp
        .transfer_selector
        .add_collection_transfer_manager(
            COLLECTION(), dsp.transfer_manager_erc721.contract_address
        );

    dsp.transfer_selector.remove_collection_transfer_manager(COLLECTION());
    let actual_transfer_manager = dsp
        .transfer_selector
        .get_transfer_manager_selector_for_collection(COLLECTION());
    assert!(actual_transfer_manager == ZERO_ADDRESS(), "Wrong transfer manager removed");
}

#[test]
#[should_panic(expected: ("TransferSelectorNFT: tried to remove an invalid transfer manager: 0",))]
fn test_remove_collection_transfer_manager_fails_invalid_transfer_manager() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp.transfer_selector.remove_collection_transfer_manager(COLLECTION());
}

#[test]
fn test_update_TRANSFER_MANAGER_ERC721_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp.transfer_selector.update_TRANSFER_MANAGER_ERC721(ACCOUNT1());
    let new_manager = dsp.transfer_selector.get_TRANSFER_MANAGER_ERC721();
    assert(new_manager == ACCOUNT1(), 'wrong new manager');
}

#[test]
fn test_update_TRANSFER_MANAGER_ERC1155_success() {
    let dsp = setup();
    initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp.transfer_selector.update_TRANSFER_MANAGER_ERC1155(ACCOUNT1());
    let new_manager = dsp.transfer_selector.get_TRANSFER_MANAGER_ERC1155();
    assert(new_manager == ACCOUNT1(), 'wrong new manager');
}

// TESTS VIEWS
#[test]
fn test_get_INTERFACE_ID_ERC721() {
    let dsp = setup();
    initialize_test(dsp);

    assert!(dsp.transfer_selector.get_INTERFACE_ID_ERC721() == 0x80ac58cd, "wrong interface 721");
}

#[test]
fn test_get_INTERFACE_ID_ERC1155() {
    let dsp = setup();
    initialize_test(dsp);

    assert!(dsp.transfer_selector.get_INTERFACE_ID_ERC1155() == 0xd9b67a26, "wrong interface 1155");
}

#[test]
fn test_check_transfer_manager_for_token() {
    let dsp = setup();
    initialize_test(dsp);
    start_prank(CheatTarget::One(dsp.transfer_selector.contract_address), OWNER());
    dsp
        .transfer_selector
        .add_collection_transfer_manager(
            COLLECTION(), dsp.transfer_manager_erc721.contract_address
        );

    let actual_manager = dsp.transfer_selector.check_transfer_manager_for_token(COLLECTION());
    assert(
        actual_manager == dsp.transfer_manager_erc721.contract_address, 'wrong transfer manager'
    );
}

