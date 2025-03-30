use core::array::ArrayTrait;
use core::byte_array::ByteArray;
use core::debug::PrintTrait;
use core::starknet::storage::{
    Map, MutableTrait, MutableVecTrait, StoragePointerReadAccess, StoragePointerWriteAccess, Vec,
    VecTrait,
};
use core::starknet::{
    ClassHash, ContractAddress, contract_address_const, deploy_syscall, get_block_timestamp,
    get_caller_address, get_contract_address, get_tx_info,
};
use core::traits::Into;
use flexhaus::mocks::MockSigner::MockSigner;
use flexhaus::collectible::FlexHausCollectible;
use flexhaus::factory::FlexHausFactory::FlexHausFactory;
use flexhaus::interface::IFlexHausCollectible::{
    IFlexHausCollectibleMixinDispatcher, IFlexHausCollectibleMixinDispatcherTrait,
};
use flexhaus::interface::IFlexHausFactory::{
    CollectibleRarity, DropDetail, IFlexHausFactory, IFlexHausFactoryDispatcher,
    IFlexHausFactoryDispatcherTrait,
};
use hash::{HashStateExTrait, HashStateTrait};
use openzeppelin::account::interface::{AccountABIDispatcher, AccountABIDispatcherTrait};
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use pedersen::PedersenTrait;
use snforge_std::{
    ContractClass, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, load,
    spy_events, start_cheat_block_timestamp, start_cheat_caller_address,
    start_cheat_caller_address_global, stop_cheat_block_timestamp, stop_cheat_caller_address,
    stop_cheat_caller_address_global, test_address, mock_call, start_mock_call, stop_mock_call,
};

// Helper functions
fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn addr1() -> ContractAddress {
    contract_address_const::<'addr1'>()
}

fn protocol_fee() -> u256 {
    0.into()
}

fn fee_recipient() -> ContractAddress {
    contract_address_const::<'fee_recipient'>()
}

fn flex_haus_collectible_class() -> ClassHash {
    let collectible_contract = declare("FlexHausCollectible").unwrap().contract_class();
    *collectible_contract.class_hash
}

fn attacker() -> ContractAddress {
    contract_address_const::<'attacker'>()
}

fn deploy_mock_signer() -> ContractAddress {
    let mock_signer_contract = declare("MockSigner").unwrap().contract_class();
    let (contract_address, _) = mock_signer_contract.deploy(@array![]).unwrap();
    contract_address
}

fn deploy_flex_haus_factory() -> (IFlexHausFactoryDispatcher, ContractAddress) {
    let protocol_currency: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();

    let mock_signer_address = contract_address_const::<'addr1'>();

    let contract = declare("FlexHausFactory").unwrap().contract_class();

    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(owner());
    calldata.append_serde(protocol_fee().into());
    calldata.append_serde(protocol_currency);
    calldata.append_serde(fee_recipient());
    calldata.append_serde(mock_signer_address);
    calldata.append_serde(flex_haus_collectible_class());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let dispatcher = IFlexHausFactoryDispatcher { contract_address };

    (dispatcher, contract_address)
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 400000,
)]
fn test_constructor() {
    let protocol_currency: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();

    let (factory, _) = deploy_flex_haus_factory();

    assert_eq!(factory.get_protocol_fee(), protocol_fee());
    assert_eq!(factory.get_protocol_currency(), protocol_currency);
    assert_eq!(factory.get_fee_recipient(), fee_recipient());
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 400000,
)]
fn test_create_collectible() {
    let (mut factory, _) = deploy_flex_haus_factory();
    let mut _events_spy = spy_events();

    let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5 };

    let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3 };

    let base_uri = ByteArray { data: array![], pending_word: 'ipfs://', pending_word_len: 15 };

    let total_supply: u256 = 1000.into();

    assert_gt!(total_supply, 0, "Total supply should be greater than 0");
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();

    start_cheat_caller_address_global(eth_rich_address);

    let protocol_fee = factory.get_protocol_fee();

    let dispatcher = ERC20ABIDispatcher { contract_address: factory.get_protocol_currency() };

    dispatcher.transfer(owner(), protocol_fee);

    // Create a collectible
    factory.create_collectible(name, symbol, base_uri, total_supply, 'common');

    let collectibles = factory.get_all_collectibles_addresses();
    assert_eq!(collectibles.len(), 1, "Should create 1 collectible");
    assert_eq!(ArrayTrait::len(@collectibles), 1, "Should create 1 collectible");
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 400000,
)]
fn test_create_drop() {
    let (factory, contract_address) = deploy_flex_haus_factory();

    // Create a collectible first
    let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5 };
    let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3 };
    let base_uri = ByteArray { data: array![], pending_word: 'ipfs://', pending_word_len: 15 };

    start_cheat_caller_address(contract_address, owner());
    factory.create_collectible(name, symbol, base_uri, 1000.into(), 'common');
    stop_cheat_caller_address(contract_address);

    let collectibles = factory.get_all_collectibles_addresses();
    let collectible_address = collectibles.at(0);

    // Create a drop
    start_cheat_caller_address(contract_address, owner());
    factory
        .create_drop(
            *collectible_address,
            1, // drop_type
            500.into(), // secure_amount
            true, // is_random_to_subscribers
            1, // from_top_supporter
            10, // to_top_supporter
            get_block_timestamp() + 100, // start_time
            get_block_timestamp() + 3600 // expire_time
        );
    stop_cheat_caller_address(contract_address);

    // Verify the drop details
    let drop_detail = factory.get_collectible_drop(*collectible_address);
    assert_eq!(drop_detail.drop_type, 1, "Drop type should be 1");
    assert_eq!(drop_detail.secure_amount, 500.into(), "Secure amount should be 500");
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 601698,
)]
fn test_claim_collectible() {
    let (factory, contract_address) = deploy_flex_haus_factory();
    let signer_address: ContractAddress = test_address();

    // Mock the `is_valid_signature` function
    let function_selector = selector!("is_valid_signature");
    let return_data = 'VALID';
    start_mock_call(signer_address, function_selector, return_data);

    // Create a collectible
    let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5 };
    let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3 };
    let base_uri = ByteArray { data: array![], pending_word: 'ipfs://', pending_word_len: 15 };
    let total_supply: u256 = 1000.into();
    let rarity: felt252 = 'common';

    start_cheat_caller_address(contract_address, owner());
    factory.create_collectible(name, symbol, base_uri, total_supply, rarity);
    stop_cheat_caller_address(contract_address);

    let collectibles = factory.get_all_collectibles_addresses();
    let collectible_address = collectibles.at(0);

    // Create a drop
    let drop_type: u8 = 1;
    let secure_amount: u256 = 500.into();
    let is_random_to_subscribers: bool = true;
    let from_top_supporter: u64 = 1;
    let to_top_supporter: u64 = 10;
    let start_time: u64 = get_block_timestamp() + 100;
    let expire_time: u64 = start_time + 3600;

    start_cheat_caller_address(contract_address, owner());
    factory.create_drop(
        *collectible_address,
        drop_type,
        secure_amount,
        is_random_to_subscribers,
        from_top_supporter,
        to_top_supporter,
        start_time,
        expire_time,
    );
    stop_cheat_caller_address(contract_address);

    // Set block timestamp to a value after the drop's expire_time
    start_cheat_block_timestamp(contract_address, expire_time + 10);

    // Define collectible keys
    let mut keys: Array<felt252> = array![];
    keys.append(0x123.into());
    keys.append(0x456.into());

    // Claim the collectible
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();

    start_cheat_caller_address(contract_address, eth_rich_address);
    factory.claim_collectible(*collectible_address, keys);
    stop_cheat_caller_address(contract_address);

    stop_cheat_block_timestamp(contract_address);

    // Stop mocking the `is_valid_signature` function
    stop_mock_call(signer_address, function_selector);
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 601698,
)]
fn test_update_collectible_drop_phase() {
    let (factory, contract_address) = deploy_flex_haus_factory();
    let mut events_spy = spy_events();

    // Create a collectible first
    let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5 };
    let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3 };
    let base_uri = ByteArray { data: array![], pending_word: 'ipfs://', pending_word_len: 15 };
    let total_supply: u256 = 1000.into();
    let rarity: felt252 = 'common';

    start_cheat_caller_address(contract_address, owner());
    factory.create_collectible(name, symbol, base_uri, total_supply, rarity);
    stop_cheat_caller_address(contract_address);

    let collectibles = factory.get_all_collectibles_addresses();
    let collectible_address = collectibles.at(0);

    // Create a drop
    let drop_type: u8 = 1;
    let secure_amount: u256 = 500.into();
    let is_random_to_subscribers: bool = true;
    let from_top_supporter: u64 = 1;
    let to_top_supporter: u64 = 10;
    let start_time: u64 = get_block_timestamp() + 3600;
    let expire_time: u64 = start_time + 3600;

    start_cheat_caller_address(contract_address, owner());
    factory.create_drop(
        *collectible_address,
        drop_type,
        secure_amount,
        is_random_to_subscribers,
        from_top_supporter,
        to_top_supporter,
        start_time,
        expire_time,
    );
    stop_cheat_caller_address(contract_address);

    // Update the drop details
    let new_drop_type: u8 = 2;
    let new_secure_amount: u256 = 300.into();
    let new_is_random_to_subscribers: bool = false;
    let new_from_top_supporter: u64 = 2;
    let new_to_top_supporter: u64 = 8;
    let new_start_time: u64 = get_block_timestamp() + 7200;
    let new_expire_time: u64 = new_start_time + 7200;

    start_cheat_caller_address(contract_address, owner());
    factory.update_collectible_drop_phase(
        *collectible_address,
        new_drop_type,
        new_secure_amount,
        new_is_random_to_subscribers,
        new_from_top_supporter,
        new_to_top_supporter,
        new_start_time,
        new_expire_time,
    );
    stop_cheat_caller_address(contract_address);

    // Verify the updated drop details
    let updated_drop_detail = factory.get_collectible_drop(*collectible_address);
    assert_eq!(updated_drop_detail.drop_type, new_drop_type.into(), "Drop type should be updated");
    assert_eq!(updated_drop_detail.secure_amount, new_secure_amount, "Secure amount should be updated");
    assert_ne!(updated_drop_detail.is_random_to_subscribers, new_is_random_to_subscribers, "Random to subscribers should be updated");
    assert_eq!(updated_drop_detail.from_top_supporter, new_from_top_supporter, "From top supporter should be updated");
    assert_eq!(updated_drop_detail.to_top_supporter, new_to_top_supporter, "To top supporter should be updated");
    assert_eq!(updated_drop_detail.start_time, new_start_time, "Start time should be updated");
    assert_eq!(updated_drop_detail.expire_time, new_expire_time, "Expire time should be updated");

     // Verify the `UpdateDrop` event
     events_spy.assert_emitted(
        @array![
            (
                contract_address,
                FlexHausFactory::Event::UpdateDrop(
                    FlexHausFactory::UpdateDrop {
                        collectible: *collectible_address,
                        drop_type: new_drop_type,
                        secure_amount: new_secure_amount,
                        is_random_to_subscribers: new_is_random_to_subscribers,
                        from_top_supporter: new_from_top_supporter,
                        to_top_supporter: new_to_top_supporter,
                        start_time: new_start_time,
                        expire_time: new_expire_time,
                    },
                ),
            ),
        ],
    );
}

#[test]
#[fork(
    url: "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/VFVA--IYkSjn28CaMokBNYvFo5fZOw2n",
    block_number: 601698,
)]
fn test_update_collectible_detail() {
    let (factory, contract_address) = deploy_flex_haus_factory();
    let mut events_spy = spy_events();

    // Create a collectible first
    let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5 };
    let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3 };
    let base_uri = ByteArray { data: array![], pending_word: 'ipfs://', pending_word_len: 15 };
    let total_supply: u256 = 1000.into();
    let rarity: felt252 = 'common';

    start_cheat_caller_address(contract_address, owner());
    factory.create_collectible(name, symbol, base_uri, total_supply, rarity);
    stop_cheat_caller_address(contract_address);

    let collectibles = factory.get_all_collectibles_addresses();
    let collectible_address = collectibles.at(0);

    // Update collectible details
    let new_name = ByteArray { data: array![], pending_word: 'UpdatedNFT', pending_word_len: 10 };
    let new_symbol = ByteArray { data: array![], pending_word: 'UNFT', pending_word_len: 4 };
    let new_base_uri = ByteArray { data: array![], pending_word: 'ipfs://new', pending_word_len: 10 };
    let new_total_supply: u256 = 2000.into();
    let new_rarity: felt252 = 'rare';

    start_cheat_caller_address(contract_address, owner());
    factory.update_collectible_detail(
        *collectible_address,
        new_name,
        new_symbol,
        new_base_uri,
        new_total_supply,
        new_rarity,
    );
    stop_cheat_caller_address(contract_address);

    events_spy.assert_emitted(
        @array![
            (
                contract_address,
                FlexHausFactory::Event::UpdateCollectible(
                    FlexHausFactory::UpdateCollectible {
                        creator: owner(),
                        collectible: *collectible_address,
                        drop_amount: new_total_supply,
                        rarity: new_rarity,
                    },
                ),
            ),
        ],
    );
}