use flexhaus::collectible::FlexHausCollectible;

use flexhaus::interface::IFlexHausCollectible::{
    IFlexHausCollectible, IFlexHausCollectibleDispatcher, IFlexHausCollectibleDispatcherTrait
};
use core::starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait, load
};

use core::traits::TryInto;

use super::utils::{owner, factory, another_factory, minter, deploy_flex_haus_collectible};

#[test]
fn test_constructor() {
    let (collectible, _) = deploy_flex_haus_collectible();

    assert_eq!(collectible.total_supply(), 100, "Total supply should be 100");
    assert_eq!(collectible.get_base_uri(), "https://example.com/", "Base URI should match");
}

#[test]
fn test_set_base_uri_by_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Cheat caller to be the factory
    start_cheat_caller_address(contract_address, factory());

    // Set new base URI
    collectible.set_base_uri("https://new-uri.com/");
    assert_eq!(collectible.get_base_uri(), "https://new-uri.com/", "Base URI should be updated");
}

#[test]
#[should_panic(expected: ('Only Flex Haus Factory',))]
fn test_set_base_uri_not_by_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Try to set base URI by non-factory address
    start_cheat_caller_address(contract_address, minter());
    collectible.set_base_uri("https://unauthorized.com/");
}

#[test]
fn test_add_and_remove_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Cheat caller to be the owner
    start_cheat_caller_address(contract_address, owner());

    // Add a new factory
    collectible.add_factory(another_factory());

    // Try to remove the factory
    collectible.remove_factory(another_factory());
}

#[test]
#[should_panic(expected: ('Factory already added',))]
fn test_add_existing_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Cheat caller to be the owner
    start_cheat_caller_address(contract_address, owner());

    // Try to add the same factory twice
    collectible.add_factory(factory());
}

#[test]
#[should_panic(expected: ('Factory not added',))]
fn test_remove_non_existing_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Cheat caller to be the owner
    start_cheat_caller_address(contract_address, owner());

    // Try to remove a factory that hasn't been added
    collectible.remove_factory(another_factory());
}

#[test]
#[should_panic(expected: ('Only Flex Haus Factory',))]
fn test_mint_not_by_factory() {
    let (collectible, contract_address) = deploy_flex_haus_collectible();

    // Try to mint by non-factory address
    start_cheat_caller_address(contract_address, minter());
    collectible.mint_collectible(minter());
}
