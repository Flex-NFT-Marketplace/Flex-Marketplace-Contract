use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::deploy_syscall;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, 
    spy_events, SpyOn, EventSpy, EventFetcher, Event
};

use flexhaus::collectible::FlexHausCollectible::{
    FlexHausCollectible, IFlexHausCollectibleDispatcher, 
    IFlexHausCollectibleDispatcherTrait
};

fn deploy_contract() -> (ContractAddress, IFlexHausCollectibleDispatcher) {
    let contract = declare("FlexHausCollectible");
    
    let owner = contract_address_const::<0x123>();
    let factory = contract_address_const::<0x456>();
    let name = "FlexHaus NFT";
    let symbol = "FLEX";
    let base_uri = "https://flexhaus.io/metadata/";
    let total_supply: u256 = 1000;

    let mut calldata = array![
        owner.into(),
        name.into(), 
        symbol.into(), 
        base_uri.into(),
        total_supply.into(),
        factory.into()
    ];

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IFlexHausCollectibleDispatcher { contract_address };

    (contract_address, dispatcher)
}

#[test]
fn test_constructor() {
    let (_, dispatcher) = deploy_contract();

    assert(dispatcher.total_supply() == 1000, 'Incorrect total supply');
    assert(dispatcher.get_base_uri() == "https://flexhaus.io/metadata/", 'Incorrect base URI');
}

#[test]
fn test_add_remove_factory() {
    let (contract_address, dispatcher) = deploy_contract();
    let owner = contract_address_const::<0x123>();
    let new_factory = contract_address_const::<0x789>();

    // Add factory as owner
    start_prank(CheatTarget::One(contract_address), owner);
    dispatcher.add_factory(new_factory);
    stop_prank(CheatTarget::One(contract_address));

    // Try removing factory as owner
    start_prank(CheatTarget::One(contract_address), owner);
    dispatcher.remove_factory(new_factory);
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic(expected: ('Only owner', ))]
fn test_add_factory_not_owner() {
    let (contract_address, dispatcher) = deploy_contract();
    let non_owner = contract_address_const::<0xABC>();
    let new_factory = contract_address_const::<0x789>();

    // Try to add factory as non-owner
    start_prank(CheatTarget::One(contract_address), non_owner);
    dispatcher.add_factory(new_factory);
}

#[test]
#[should_panic(expected: ('Factory already added', ))]
fn test_add_duplicate_factory() {
    let (contract_address, dispatcher) = deploy_contract();
    let owner = contract_address_const::<0x123>();
    let initial_factory = contract_address_const::<0x456>();

    // Try to add same factory again
    start_prank(CheatTarget::One(contract_address), owner);
    dispatcher.add_factory(initial_factory);
}

#[test]
fn test_mint_collectible() {
    let (contract_address, dispatcher) = deploy_contract();
    let factory = contract_address_const::<0x456>();
    let minter = contract_address_const::<0xABC>();

    // Mint collectible using the initial factory
    start_prank(CheatTarget::One(contract_address), factory);
    dispatcher.mint_collectible(minter);
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic(expected: ('Only Flex Haus Factory', ))]
fn test_mint_collectible_unauthorized() {
    let (contract_address, dispatcher) = deploy_contract();
    let non_factory = contract_address_const::<0xABC>();
    let minter = contract_address_const::<0xDEF>();

    // Try to mint collectible from unauthorized address
    start_prank(CheatTarget::One(contract_address), non_factory);
    dispatcher.mint_collectible(minter);
}

#[test]
fn test_update_contract_metadata() {
    let (contract_address, dispatcher) = deploy_contract();
    let factory = contract_address_const::<0x456>();

    // Update base URI
    start_prank(CheatTarget::One(contract_address), factory);
    dispatcher.set_base_uri("https://newuri.com/metadata/");
    assert(dispatcher.get_base_uri() == "https://newuri.com/metadata/", 'Base URI not updated');

    // Update name and symbol
    dispatcher.set_name("New FlexHaus NFT");
    dispatcher.set_symbol("NEW");
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic(expected: ('Only Flex Haus Factory', ))]
fn test_update_metadata_unauthorized() {
    let (contract_address, dispatcher) = deploy_contract();
    let non_factory = contract_address_const::<0xABC>();

    // Try to update metadata from unauthorized address
    start_prank(CheatTarget::One(contract_address), non_factory);
    dispatcher.set_base_uri("https://unauthorized.com/");
}