use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

// use erc_4907_rental_nft::IHelloStarknetSafeDispatcher;
// use erc_4907_rental_nft::IHelloStarknetSafeDispatcherTrait;
// use erc_4907_rental_nft::IHelloStarknetDispatcher;
// use erc_4907_rental_nft::IHelloStarknetDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

