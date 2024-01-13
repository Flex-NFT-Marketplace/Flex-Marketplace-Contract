use snforge_std::{start_prank, stop_prank, PrintTrait, CheatTarget};
use tests::utils::{
    setup, initialize_test, deploy_mock_nft, ACCOUNT1, ACCOUNT2, OWNER, ZERO_ADDRESS
};
use flex::marketplace::transfer_manager_ERC721::{
    ITransferManagerNFTDispatcher, ITransferManagerNFTDispatcherTrait
};

const TOKEN_ID: u256 = 1;

#[test]
fn test_transfer_non_fungible_token_success() {
    let dsp = setup();
    initialize_test(dsp);
    let collection = deploy_mock_nft();

    start_prank(
        CheatTarget::One(dsp.transfer_manager_erc721.contract_address),
        dsp.marketplace.contract_address
    );
    dsp
        .transfer_manager_erc721
        .transfer_non_fungible_token(collection, ACCOUNT1(), ACCOUNT2(), TOKEN_ID, 1);
}

#[test]
#[should_panic(expected: ("TransferManagerNFT: caller 0 is not MarketPlace",))]
fn test_transfer_non_fungible_token_fails_caller_not_marketplace() {
    let dsp = setup();
    initialize_test(dsp);
    let collection = deploy_mock_nft();

    start_prank(CheatTarget::One(dsp.transfer_manager_erc721.contract_address), ZERO_ADDRESS());
    dsp
        .transfer_manager_erc721
        .transfer_non_fungible_token(collection, ACCOUNT1(), ACCOUNT2(), TOKEN_ID, 1);
}

#[test]
fn test_update_marketplace_success() {
    let dsp = setup();
    initialize_test(dsp);
    let collection = deploy_mock_nft();
    let new_marketplace = starknet::contract_address_const::<'new_marketplace'>();

    start_prank(
        CheatTarget::One(dsp.transfer_manager_erc721.contract_address),
        dsp.marketplace.contract_address
    );
    dsp.transfer_manager_erc721.update_marketplace(new_marketplace);

    let actual_marketplace = dsp.transfer_manager_erc721.get_marketplace();

    assert(actual_marketplace == new_marketplace, 'update marketplace failed');
}

