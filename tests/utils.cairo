use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
    get_caller_address, class_hash::ClassHash
};
use snforge_std::{
    PrintTrait, declare, ContractClassTrait, start_warp, start_prank, stop_prank, CheatTarget
};
use snforge_std::signature::{KeyPairTrait, KeyPair};
use snforge_std::signature::stark_curve::{
    StarkCurveKeyPairImpl, StarkCurveSignerImpl, StarkCurveVerifierImpl
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
use flex::mocks::erc721::ERC721;
use flex::mocks::erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use flex::mocks::erc1155::ERC1155;
use flex::mocks::strategy::Strategy;
use flex::mocks::account::Account;

const HASH_DOMAIN: felt252 = 'HASH_DOMAIN';
const FEE_LIMIT: u128 = 1_000;
const E18: u128 = 1_000_000_000_000_000_000;
const PRICE: u256 = 1000_000_000_000_000_000_000;
const SUPPLY: u256 = 1_000_000_000_000_000_000_000_000;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    marketplace: IMarketPlaceDispatcher,
    currency_manager: ICurrencyManagerDispatcher,
    execution_manager: IExecutionManagerDispatcher,
    royalty_manager: IRoyaltyFeeManagerDispatcher,
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
    contract_address_const::<'ACCOUNT1'>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<'ACCOUNT2'>()
}
fn ACCOUNT3() -> ContractAddress {
    contract_address_const::<'ACCOUNT3'>()
}
fn ACCOUNT4() -> ContractAddress {
    contract_address_const::<'ACCOUNT4'>()
}
fn PROXY_ADMIN() -> ContractAddress {
    contract_address_const::<'PROXY_ADMIN'>()
}
fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}
fn RELAYER() -> ContractAddress {
    contract_address_const::<'RELAYER'>()
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
        royalty_manager: IRoyaltyFeeManagerDispatcher { contract_address: royalty },
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

#[derive(Copy, Drop)]
struct Mocks {
    account: ContractAddress,
    erc20: ContractAddress,
    erc721: ContractAddress,
    erc1155: ContractAddress,
    strategy: ContractAddress,
    maker_signature: (felt252, felt252),
    taker_signature: (felt252, felt252),
    key_pair: KeyPair<felt252, felt252>,
}

fn initialize_test(dsp: Dispatchers) -> Mocks {
    // Initialise MarketPlace
    dsp
        .marketplace
        .initializer(
            HASH_DOMAIN,
            RECIPIENT(),
            dsp.currency_manager.contract_address,
            dsp.execution_manager.contract_address,
            dsp.royalty_manager.contract_address,
            dsp.signature_checker.contract_address,
            OWNER(),
            PROXY_ADMIN()
        );
    // Initialise CurrencyManager
    dsp.currency_manager.initializer(OWNER(), PROXY_ADMIN());
    // Initialise ExecutionManager
    dsp.execution_manager.initializer(OWNER());
    // Initialise RoyaltyFeeManager
    dsp.royalty_manager.initializer(dsp.fee_registry.contract_address, OWNER());
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

    let key_pair = KeyPairTrait::<felt252, felt252>::generate();
    let msg_hash = 123456;
    let (r1, s1): (felt252, felt252) = key_pair.sign(msg_hash);

    let msg_hash = 654321;
    let (r2, s2): (felt252, felt252) = key_pair.sign(msg_hash);

    let account = deploy_mock_account(key_pair.public_key);
    let erc20 = deploy_mock_erc20();
    let erc721 = deploy_mock_nft();
    let erc1155 = deploy_mock_1155();
    let strategy = deploy_mock_execution_strategy();

    start_prank(CheatTarget::All(()), OWNER());

    IERC20Dispatcher { contract_address: erc20 }.transfer(ACCOUNT1(), (1000 * E18).into());
    IERC20Dispatcher { contract_address: erc20 }.transfer(account, (1000 * E18).into());

    dsp.execution_manager.add_strategy(strategy);
    dsp.currency_manager.add_currency(erc20);

    dsp
        .transfer_selector
        .add_collection_transfer_manager(erc721, dsp.transfer_manager_erc721.contract_address);

    dsp.marketplace.update_transfer_selector_NFT(dsp.transfer_selector.contract_address);

    dsp.fee_registry.update_royalty_fee_limit(1000);

    dsp.fee_registry.update_royalty_info_collection(erc721, OWNER(), RECIPIENT(), 1000);

    stop_prank(CheatTarget::All(()));

    start_prank(CheatTarget::One(erc20), ACCOUNT1());
    IERC20CamelDispatcher { contract_address: erc20 }
        .approve(dsp.marketplace.contract_address, SUPPLY);

    start_prank(CheatTarget::One(erc20), account);
    IERC20CamelDispatcher { contract_address: erc20 }
        .approve(dsp.marketplace.contract_address, SUPPLY);
    stop_prank(CheatTarget::One(erc20));

    Mocks {
        account,
        erc20,
        erc721,
        erc1155,
        strategy,
        maker_signature: (r1, s1),
        taker_signature: (r2, s2),
        key_pair
    }
}

fn deploy_mock_1155() -> ContractAddress {
    let contract = declare('ERC1155');
    contract.deploy(@array![]).expect('failed marketplace')
}

fn deploy_mock_nft() -> ContractAddress {
    let contract = declare('ERC721');
    contract.deploy(@array![]).expect('failed ERC721')
}

fn deploy_mock_execution_strategy() -> ContractAddress {
    let contract = declare('Strategy');
    contract.deploy(@array![]).expect('failed ExecutionStrategy')
}

fn deploy_mock_account(public_key: felt252) -> ContractAddress {
    let contract = declare('Account');
    contract.deploy(@array![public_key]).expect('failed account')
}

fn deploy_mock_erc20() -> ContractAddress {
    let contract = declare('ERC20');
    let calldata: Array<felt252> = array![
        'name', 'symbol', SUPPLY.try_into().unwrap(), 0, OWNER().into()
    ];
    contract.deploy(@calldata).expect('failed erc20')
}

#[test]
fn deploy_test() {
    let dsp = setup();
    initialize_test(dsp);
}
