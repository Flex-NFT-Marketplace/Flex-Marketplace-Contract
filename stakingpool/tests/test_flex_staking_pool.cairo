use core::serde::Serde;
use core::array::ArrayTrait;
use core::result::ResultTrait;
use core::starknet::SyscallResultTrait;
use snforge_std::{ declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp };
use stakingpool::interfaces::IFlexStakingPool::{
IFlexStakingPoolDispatcher, IFlexStakingPoolDispatcherTrait
};


use starknet::{ContractAddress, get_block_timestamp};
use starknet::contract_address_const;
use openzeppelin::presets::{account::Account, erc721::ERC721};

const ONE_YEAR: u64 = 31536000; // 365 days

fn set_up() ->(IFlexStakingPoolDispatcher, ContractAddress, ContractAddress, ContractAddress){
    
     // declare and deploy owner contract
    let account_class = declare("Account").unwrap();
    let mut creator_constructor_calldata: Array<felt252> = array!['Owner'];
    let (owner_contract_addres, _) = account_class
        .deploy(@creator_constructor_calldata).unwrap_syscall();

    //set up data for erc721
    let erc721_name: ByteArray = "Mock ERC721";
    let erc721_symbol: ByteArray = "FLX";
    let erc721_base_uri: ByteArray = "";
    let erc721_recipient: ContractAddress = owner_contract_addres;
    let mut ids: Array<u256> = ArrayTrait::new();
    ids.append(1);
    let token_ids = ids.span();
    let mut erc721_constructor_data: Array<felt252> = ArrayTrait::new();
    erc721_name.serialize(ref erc721_constructor_data);
    erc721_symbol.serialize(ref erc721_constructor_data);
    erc721_base_uri.serialize(ref erc721_constructor_data);
    erc721_recipient.serialize(ref erc721_constructor_data);
    token_ids.serialize(ref erc721_constructor_data);

    // declare and deploy erc721 contract
    let erc721_hash = declare("ERC721").unwrap();
    let (collection, _) = erc721_hash.deploy(@erc721_constructor_data).unwrap_syscall();

    // declare and deploy FlexStakingPool contract
    let contract = declare("FlexStakingPool").unwrap();
    let mut constructor_calldata = array![owner_contract_addres.try_into().unwrap()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap_syscall();
    let dispatcher = IFlexStakingPoolDispatcher { contract_address };

    (dispatcher, contract_address, owner_contract_addres, collection )
}

fn call_stageNFT(stakingpoolDispatcher:IFlexStakingPoolDispatcher,stakingpoolAddress: ContractAddress, collection: ContractAddress, owner_contract_addres: ContractAddress, id: u256){
    start_prank(CheatTarget::Multiple(array![stakingpoolAddress, collection]), owner_contract_addres);
    stakingpoolDispatcher.setAllowedCollection(collection, true);
    stakingpoolDispatcher.setTimeUnit(collection, 5);
    stakingpoolDispatcher.setRewardPerUnitTime(collection, 300);
    stakingpoolDispatcher.stakeNFT(collection, id);

    stop_prank(CheatTarget::Multiple(array![stakingpoolAddress, collection]));
}

#[test]
fn test_stake_nft() {
    let (stakingpoolDispatcher, stakingpoolAddress, creator_contract_address, collection) = set_up();
    let block_time = get_block_timestamp();
    let id :u256 = 1;
    let timeStamp :u64 = 2629743;
    let mut multipleAddres: Array<ContractAddress> = ArrayTrait::new();
    let mut multipleAddres2: Array<ContractAddress> = ArrayTrait::new();
    multipleAddres.append(stakingpoolAddress);
    multipleAddres.append(collection);
    multipleAddres2.append(stakingpoolAddress);
    multipleAddres2.append(collection);
    call_stageNFT(stakingpoolDispatcher, stakingpoolAddress, collection, creator_contract_address, id);
    
    start_prank(CheatTarget::Multiple(array![stakingpoolAddress]), creator_contract_address);
    start_warp(CheatTarget::Multiple(array![collection, stakingpoolAddress]), block_time+timeStamp+1);
    // stakingpoolDispatcher.unstakeNFT(collection, id);
    
    let resultTotalPoints = stakingpoolDispatcher.getUserTotalPoint(creator_contract_address);
    let resultPointByItem = stakingpoolDispatcher.getUserPointByItem(creator_contract_address, collection, id);

    println!("resultTotalPoints: {:?}", resultTotalPoints);
    println!("resultPointByItem: {:?}", resultPointByItem);

    assert(resultTotalPoints == 0, 'error');
    assert(resultPointByItem == 0, 'error');
    stop_prank(CheatTarget::Multiple(array![stakingpoolAddress]));
    stop_warp(CheatTarget::Multiple(array![collection, stakingpoolAddress]));
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