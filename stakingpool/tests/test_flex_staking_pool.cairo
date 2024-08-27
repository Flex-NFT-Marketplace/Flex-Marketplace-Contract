use core::serde::Serde;
use core::array::ArrayTrait;
use core::result::ResultTrait;
use core::starknet::SyscallResultTrait;
use snforge_std::{ declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp };
use stakingpool::interfaces::IFlexStakingPool::{
IFlexStakingPoolDispatcher, IFlexStakingPoolDispatcherTrait
};

use starknet::{ContractAddress};
use starknet::contract_address_const;
use openzeppelin::presets::{account::Account, erc721::ERC721};



fn deploy_flex_staking_pool() ->(IFlexStakingPoolDispatcher, ContractAddress, ContractAddress, ContractAddress){
    // account preset class hash
    let account_class_hash = declare("Account").unwrap();

    // deploy creator account
    let mut creator_constructor_calldata: Array<felt252> = array!['CREATOR'];
    let (creator_contract_address, _) = account_class_hash
        .deploy(@creator_constructor_calldata).unwrap_syscall();

    //     let mut creator_constructor_calldata: Array<felt252> = array!['Juan'];
    // let (creator_contract_addressJ, _) = account_class_hash
    //     .deploy(@creator_constructor_calldata).unwrap_syscall();

    let erc20_name: ByteArray = "Mock ERC721";
    let erc20_symbol: ByteArray = "FLX";
    let base_uri: ByteArray = "";
    let recipient: ContractAddress = creator_contract_address;
    let mut test: Array<u256> = ArrayTrait::new();
    let mut erc20_constructor_calldata: Array<felt252> = ArrayTrait::new();
    test.append(1);
    let token_ids = test.span();
    erc20_name.serialize(ref erc20_constructor_calldata);
    erc20_symbol.serialize(ref erc20_constructor_calldata);
    base_uri.serialize(ref erc20_constructor_calldata);
    recipient.serialize(ref erc20_constructor_calldata);
    token_ids.serialize(ref erc20_constructor_calldata);



    
    let erc721_hash = declare("ERC721").unwrap();
    println!("Prueba");

    let (collection, _) = erc721_hash.deploy(@erc20_constructor_calldata).unwrap_syscall();
    println!("Prueba2");




    

    let contract = declare("FlexStakingPool").unwrap();
    // let owner: ContractAddress = contract_address_const::<'ownable'>();
    let mut constructor_calldata = array![creator_contract_address.try_into().unwrap()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap_syscall();
    let dispatcher = IFlexStakingPoolDispatcher { contract_address };
    (dispatcher, contract_address, creator_contract_address, collection)
}

// #[test]
// fn test_contract() {
//     let(stakingpoolAux, stakingpoolAddres, owner) = deploy_flex_staking_pool();
//     let new_owner: ContractAddress = contract_address_const::<'new_owner'>();
//     let result = stakingpoolAux.getUserTotalPoint(new_owner);
//     println!("contract result: {:?}", result);
//     let aux = 100;
//     assert(aux == 100, 'exito');
// }

#[test]
fn test_stake_nft() {
    let (stakingpoolDispatcher, stakingpoolAddress, creator_contract_address, collection) = deploy_flex_staking_pool();

    // Define the test collection address and token ID
    // let collection =  contract_address_const::<'0x1234'>();
    // let sender = starknet::contract_address_const::<0x01>();
    let id :u256 = 1;
    let timeStamp :u64 = 200000000000000000;
    let mut multipleAddres: Array<ContractAddress> = ArrayTrait::new();
    let mut multipleAddres2: Array<ContractAddress> = ArrayTrait::new();
    multipleAddres.append(stakingpoolAddress);
    multipleAddres.append(collection);
    multipleAddres2.append(stakingpoolAddress);
    multipleAddres2.append(collection);

    start_prank(CheatTarget::Multiple(multipleAddres), creator_contract_address);



    stakingpoolDispatcher.setAllowedCollection(collection, true);

    stakingpoolDispatcher.stakeNFT(collection, id);
    start_warp(CheatTarget::Multiple(multipleAddres2), timeStamp);
    let resultTotalPoints = stakingpoolDispatcher.getUserTotalPoint(creator_contract_address);
    let resultPointByItem = stakingpoolDispatcher.getUserPointByItem(creator_contract_address, collection, id);

    println!("resultTotalPoints: {:?}", resultTotalPoints);
    println!("resultPointByItem: {:?}", resultPointByItem);
    
    assert(resultTotalPoints == 1, 'error');
    assert(resultPointByItem == 1, 'error');
    stop_prank(CheatTarget::One(stakingpoolAddress));
}

// #[test]
// fn test_unstakeNFT_nft(){
//     let (stakingpoolDispatcher, stakingpoolAddress, owner) = deploy_flex_staking_pool();

//         // Define the test collection address and token ID
//         let collection =  contract_address_const::<'0x1234'>();
//         let id :u256 = 1;
//         stakingpoolDispatcher.setAllowedCollection(collection, true);

//         stakingpoolDispatcher.stakeNFT(collection, id);
//         stakingpoolDispatcher.unstakeNFT(collection, id);

//         let resultTotalPoints = stakingpoolDispatcher.getUserTotalPoint(owner);
//         let resultPointByItem = stakingpoolDispatcher.getUserPointByItem(owner, collection, id);
        
//         assert(resultTotalPoints == 0, 'error');
//         assert(resultPointByItem == 0, 'error');

// }