use flexhaus::collectible::FlexHausCollectible;
use flexhaus::factory::FlexHausFactory;
use starknet::{ClassHash, ContractAddress, contract_address_const};

use flexhaus::interface::IFlexHausCollectible::{
    IFlexHausCollectible, IFlexHausCollectibleDispatcher, IFlexHausCollectibleDispatcherTrait
};
use flexhaus::interface::IFlexHausFactory::{
    IFlexHausFactory, IFlexHausFactoryDispatcher, IFlexHausFactoryDispatcherTrait
};

use openzeppelin::utils::serde::SerializedAppend;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait
};

fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn name() -> ByteArray {
    "FlexHausCollectible"
}

fn symbol() -> ByteArray {
    "FHC"
}

fn base_uri() -> ByteArray {
    "https://example.com/"
}

fn total_supply() -> u256 {
    100
}

fn factory() -> ContractAddress {
    contract_address_const::<'factory'>()
}

fn another_factory() -> ContractAddress {
    contract_address_const::<'another_factory'>()
}

fn minter() -> ContractAddress {
    contract_address_const::<'minter'>()
}

fn protocol_fee() -> u256 {
    100
}

fn protocol_currency() -> ContractAddress {
    contract_address_const::<'protocol_fee_address'>()
}

fn fee_recipient() -> ContractAddress {
    contract_address_const::<'fee_recipient'>()
}

fn signer() -> ContractAddress {
    contract_address_const::<'signer'>()
}

fn flex_haus_collectible_class() -> ClassHash {
    declare("FlexHausCollectible").unwrap().contract_class().class_hash.deref()
}

fn deploy_flex_haus_collectible() -> (IFlexHausCollectibleDispatcher, ContractAddress) {
    let contract = declare("FlexHausCollectible").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(owner());
    calldata.append_serde(name());
    calldata.append_serde(symbol());
    calldata.append_serde(base_uri());
    calldata.append_serde(total_supply());
    calldata.append_serde(factory());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let dispatcher = IFlexHausCollectibleDispatcher { contract_address };

    (dispatcher, contract_address)
}

fn deploy_flex_haus_factory() -> (IFlexHausFactoryDispatcher, ContractAddress) {
    let contract = declare("FlexHausFactory").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(owner());
    calldata.append_serde(protocol_fee());
    calldata.append_serde(protocol_currency());
    calldata.append_serde(fee_recipient());
    calldata.append_serde(signer());
    calldata.append_serde(flex_haus_collectible_class());

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    let dispatcher = IFlexHausFactoryDispatcher { contract_address };

    (dispatcher, contract_address)
}