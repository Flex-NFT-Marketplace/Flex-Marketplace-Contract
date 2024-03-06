use tests::utils::{
    Dispatchers, HASH_DOMAIN, RECIPIENT, OWNER, PROXY_ADMIN, ACCOUNT1, ACCOUNT2, deploy_mock_1155,
    deploy_mock_erc20, deploy_mock_nft, deploy_mock_execution_strategy, FEE_LIMIT
};
use starknet::ContractAddress;
use flex::marketplace::{
    marketplace::{IMarketPlaceDispatcher, IMarketPlaceDispatcherTrait},
    execution_manager::{IExecutionManagerDispatcher, IExecutionManagerDispatcherTrait},
    royalty_fee_manager::{IRoyaltyFeeManagerDispatcher, IRoyaltyFeeManagerDispatcherTrait},
    royalty_fee_registry::{IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait},
    currency_manager::{ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait},
    transfer_manager_ERC1155::{
        IERC1155TransferManagerDispatcher, IERC1155TransferManagerDispatcherTrait
    },
    transfer_manager_ERC721::{ITransferManagerNFTDispatcher, ITransferManagerNFTDispatcherTrait},
    transfer_selector_NFT::{ITransferSelectorNFTDispatcher, ITransferSelectorNFTDispatcherTrait}
};
use flex::mocks::account::Account;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};

#[derive(Copy, Drop)]
struct Mocks {
    erc20: ContractAddress,
    erc721: ContractAddress,
    erc1155: ContractAddress,
    strategy: ContractAddress,
}


fn initialize_test(dsp: Dispatchers) -> Mocks {
    // initialize marketplace
    dsp
        .marketplace
        .initializer(
            HASH_DOMAIN,
            RECIPIENT(),
            dsp.currency_manager.contract_address,
            dsp.execution_manager.contract_address,
            dsp.fee_manager.contract_address,
            dsp.signature_checker.contract_address,
            OWNER(),
            PROXY_ADMIN()
        );
    // Initialise CurrencyManager
    dsp.currency_manager.initializer(OWNER(), PROXY_ADMIN());
    // Initialise ExecutionManager
    dsp.execution_manager.initializer(OWNER());
    // Initialise RoyaltyFeeManager
    dsp.fee_manager.initializer(dsp.fee_registry.contract_address, OWNER());
    // Initialise RoyaltyFeeRegistry
    dsp.fee_registry.initializer(FEE_LIMIT, OWNER());
    // Initialise TransferSelectorNFT
    dsp
        .transfer_selector
        .initializer(
            dsp.transfer_manager_erc721.contract_address,
            dsp.transfer_manager_erc1155.contract_address,
            OWNER(),
        );
    // Initialise TransferManagerNFT
    dsp
        .transfer_manager_erc721
        .initializer(dsp.marketplace.contract_address, OWNER(), PROXY_ADMIN());
    // Initialise TransferManagerERC1155
    dsp.transfer_manager_erc1155.initializer(dsp.marketplace.contract_address, OWNER());

    let erc20 = deploy_mock_erc20();
    let erc721 = deploy_mock_nft();
    let erc1155 = deploy_mock_1155();
    let strategy = deploy_mock_execution_strategy();

    start_prank(CheatTarget::All(()), OWNER());

    dsp.execution_manager.add_strategy(strategy);
    dsp.currency_manager.add_currency(erc20);
    dsp
        .transfer_selector
        .add_collection_transfer_manager(erc721, dsp.transfer_manager_erc721.contract_address);
    dsp.marketplace.update_transfer_selector_NFT(dsp.transfer_selector.contract_address);
    dsp.fee_registry.update_royalty_fee_limit(1000);
    dsp.fee_registry.update_royalty_info_collection(erc721, OWNER(), OWNER(), 1000);
    stop_prank(CheatTarget::All(()));

    Mocks { erc20, erc721, erc1155, strategy, }
}

fn deploy_mock_accounts(public_keys: Array<felt252>) -> Array<ContractAddress> {
    let contract = declare('Account');

    let len = public_keys.len();
    let mut i = 0;

    let mut accounts: Array<ContractAddress> = ArrayTrait::<ContractAddress>::new();

    loop {
        if (i == len) {
            break;
        }
        let account = contract.deploy(@array![*public_keys.at(i)]).expect('Failed Account');
        accounts.append(account);

        i += 1;
    };
    accounts
}
