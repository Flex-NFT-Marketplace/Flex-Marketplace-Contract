use starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
    get_caller_address, class_hash::ClassHash
};
use snforge_std::{
    declare, ContractClassTrait, start_warp, start_prank, stop_prank, PrintTrait, CheatTarget
};
use flex::marketplace::{
    marketplace::{MarketPlace, IMarketPlaceDispatcher, IMarketPlaceDispatcherTrait},
    currency_manager::{
        CurrencyManager, ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait
    },
    execution_manager::{
        ExecutionManager, IExecutionManagerDispatcher, IExecutionManagerDispatcherTrait
    },
    royalty_fee_manager::{
        RoyaltyFeeManager, IRoyaltyFeeManagerDispatcher, IRoyaltyFeeManagerDispatcherTrait
    },
    royalty_fee_registry::{
        RoyaltyFeeRegistry, IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait
    },
    signature_checker2::{
        SignatureChecker2, ISignatureChecker2Dispatcher, ISignatureChecker2DispatcherTrait
    },
    transfer_manager_ERC721::{
        TransferManagerNFT, ITransferManagerNFTDispatcher, ITransferManagerNFTDispatcherTrait
    },
    transfer_manager_ERC1155::{
        ERC1155TransferManager, IERC1155TransferManagerDispatcher,
        IERC1155TransferManagerDispatcherTrait
    },
    transfer_selector_NFT::{
        TransferSelectorNFT, ITransferSelectorNFTDispatcher, ITransferSelectorNFTDispatcherTrait
    },
};

const HASH_DOMAIN: felt252 = 'HASH_DOMAIN';
const FEE_LIMIT: u128 = 1_000;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    marketplace: IMarketPlaceDispatcher,
    currency_manager: ICurrencyManagerDispatcher,
    execution_manager: IExecutionManagerDispatcher,
    fee_manager: IRoyaltyFeeManagerDispatcher,
    fee_registry: IRoyaltyFeeRegistryDispatcher,
    signature_checker: ISignatureChecker2Dispatcher,
    transfer_selector: ITransferSelectorNFTDispatcher,
    transfer_manager_erc721: ITransferManagerNFTDispatcher,
    transfer_manager_erc1155: IERC1155TransferManagerDispatcher,
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}
fn RECIPIENT() -> ContractAddress {
    contract_address_const::<'RECIPIENT'>()
}
fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}
fn ACCOUNT3() -> ContractAddress {
    contract_address_const::<3>()
}
fn ACCOUNT4() -> ContractAddress {
    contract_address_const::<4>()
}
fn PROXY_ADMIN() -> ContractAddress {
    contract_address_const::<'PROXY_ADMIN'>()
}

fn setup() -> Dispatchers {
    let contract = declare('MarketPlace');
    let market = contract.deploy(@array![]).expect('failed marketplace');

    let contract = declare('CurrencyManager');
    let currency = contract.deploy(@array![]).expect('failed currency mgr');

    let contract = declare('ExecutionManager');
    let execution = contract.deploy(@array![]).expect('failed execution mgr');

    let contract = declare('RoyaltyFeeManager');
    let royalty = contract.deploy(@array![]).expect('failed royalty mgr');

    let contract = declare('RoyaltyFeeRegistry');
    let registry = contract.deploy(@array![]).expect('failed royalty reg');

    let contract = declare('SignatureChecker2');
    let signature = contract.deploy(@array![]).expect('failed sig checker');

    let contract = declare('TransferSelectorNFT');
    let selector = contract.deploy(@array![]).expect('failed transfer select');

    let contract = declare('ERC1155TransferManager');
    let transfer_erc1155 = contract.deploy(@array![]).expect('failed transfer select');

    let contract = declare('TransferManagerNFT');
    let transfer_erc721 = contract.deploy(@array![]).expect('failed transfer mgr');

    Dispatchers {
        marketplace: IMarketPlaceDispatcher { contract_address: market },
        currency_manager: ICurrencyManagerDispatcher { contract_address: currency },
        execution_manager: IExecutionManagerDispatcher { contract_address: execution },
        fee_manager: IRoyaltyFeeManagerDispatcher { contract_address: royalty },
        fee_registry: IRoyaltyFeeRegistryDispatcher { contract_address: registry },
        signature_checker: ISignatureChecker2Dispatcher { contract_address: signature },
        transfer_selector: ITransferSelectorNFTDispatcher { contract_address: selector },
        transfer_manager_erc721: ITransferManagerNFTDispatcher {
            contract_address: transfer_erc721
        },
        transfer_manager_erc1155: IERC1155TransferManagerDispatcher {
            contract_address: transfer_erc1155
        },
    }
}

fn initialize_test(dsp: Dispatchers) {
    // Initialise MarketPlace
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
    dsp.fee_manager.initializer(OWNER(), dsp.fee_registry.contract_address);
    // Initialise RoyaltyFeeRegistry
    dsp.fee_registry.initializer(FEE_LIMIT, OWNER());
    // Initialise TransferSelectorNFT
    dsp
        .transfer_selector
        .initializer(
            PROXY_ADMIN(),
            dsp.transfer_manager_erc721.contract_address,
            dsp.transfer_manager_erc1155.contract_address
        );
    // Initialise TransferManagerNFT
    dsp
        .transfer_manager_erc721
        .initializer(dsp.marketplace.contract_address, OWNER(), PROXY_ADMIN());
    // Initialise TransferManagerERC1155
    dsp.transfer_manager_erc1155.initializer(dsp.marketplace.contract_address, OWNER());
}

#[test]
fn deploy_test() {
    let dsp = setup();
    initialize_test(dsp);
}
