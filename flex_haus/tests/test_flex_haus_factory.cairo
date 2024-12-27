use flexhaus::factory::FlexHausFactory;
use starknet::ClassHash;

use flexhaus::interface::IFlexHausFactory::{
    IFlexHausFactory, IFlexHausFactoryDispatcher, IFlexHausFactoryDispatcherTrait
};

use core::starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait, load
};

use super::utils::{deploy_flex_haus_factory};

#[test]
fn test_create_collectible() {}

#[test]
fn test_create_drop() {}

#[test]
fn test_update_collection_drop_phase() {}

#[test]
fn test_update_collectible_detail() {}

#[test]
fn test_claim_collectible() {}

#[test]
fn test_set_protocol_fee() {}

#[test]
fn test_set_protocol_currency() {}

#[test]
fn test_set_fee_recipient() {}

#[test]
fn test_set_signer() {}

#[test]
fn test_set_flex_haus_collectible_class() {}

#[test]
fn test_set_min_duration_time_for_update() {}

#[test]
fn test_get_collectible_drop() {}

#[test]
fn test_get_protocol_fee() {}

#[test]
fn test_get_protocol_currency() {}

#[test]
fn test_get_fee_recipient() {}

#[test]
fn test_get_signer() {}

#[test]
fn test_get_flex_haus_collectible_class() {}

#[test]
fn test_get_min_duration_time_for_update() {}

#[test]
fn test_get_all_collectibles_addresses() {}

#[test]
fn test_get_total_collectibles_count() {}

#[test]
fn test_get_collectibles_of_owner() {}