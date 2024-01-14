use snforge_std::{start_prank, stop_prank, PrintTrait, CheatTarget};

use flex::marketplace::transfer_manager_ERC1155::{
    IERC1155TransferManagerDispatcher, IERC1155TransferManagerDispatcherTrait
};
use tests::utils::{
    setup, initialize_test, ACCOUNT1, ACCOUNT2, OWNER, ZERO_ADDRESS, deploy_mock_1155
};

const TOKEN_ID: u256 = 1;

#[test]
fn test_transfer_non_fungible_token_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(
        CheatTarget::One(dsp.transfer_manager_erc1155.contract_address),
        dsp.marketplace.contract_address
    );
    dsp
        .transfer_manager_erc1155
        .transfer_non_fungible_token(
            mocks.erc1155, ACCOUNT1(), ACCOUNT2(), TOKEN_ID, 1, array![].span()
        );
}

#[test]
#[should_panic(expected: ("ERC1155TransferManager: caller 0 is not marketplace",))]
fn test_transfer_non_fungible_token_fails_caller_not_marketplace() {
    let dsp = setup();
    let mocks = initialize_test(dsp);

    start_prank(CheatTarget::One(dsp.transfer_manager_erc1155.contract_address), ZERO_ADDRESS());
    dsp
        .transfer_manager_erc1155
        .transfer_non_fungible_token(
            mocks.erc1155, ACCOUNT1(), ACCOUNT2(), TOKEN_ID, 1, array![].span()
        );
}

#[test]
fn test_update_marketplace_success() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let new_marketplace = starknet::contract_address_const::<'new_marketplace'>();

    start_prank(CheatTarget::One(dsp.transfer_manager_erc1155.contract_address), OWNER());
    dsp.transfer_manager_erc1155.update_marketplace(new_marketplace);

    let actual_marketplace = dsp.transfer_manager_erc1155.get_marketplace();

    assert(actual_marketplace == new_marketplace, 'update marketplace failed');
}

