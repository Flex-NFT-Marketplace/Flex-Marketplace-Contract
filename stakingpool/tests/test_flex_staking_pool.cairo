use snforge_std::{ declare, ContractClassTrait };
use stakingpool::interfaces::IFlexStakingPool::{
IFlexStakingPoolDispatcher, IFlexStakingPoolDispatcherTrait
};

use starknet::{ContractAddress};
use starknet::contract_address_const;
use stakingpool::FlexStakingPool::FlexStakingPool::__external::setAllowedCollection;


fn deploy_flex_staking_pool() ->(IFlexStakingPoolDispatcher, ContractAddress, ContractAddress){
    let contract = declare("FlexStakingPool").unwrap();
    let owner: ContractAddress = contract_address_const::<'ownable'>();
    let mut constructor_calldata = array![owner.into()];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let dispatcher = IFlexStakingPoolDispatcher { contract_address };
    (dispatcher, contract_address, owner)
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
    let (stakingpoolDispatcher, stakingpoolAddress, owner) = deploy_flex_staking_pool();

    // Define the test collection address and token ID
    let collection =  contract_address_const::<'0x1234'>();
    let id :u256 = 1;

    stakingpoolDispatcher.stakeNFT(collection, id);
    let resultTotalPoints = stakingpoolDispatcher.getUserTotalPoint(owner);
    let resultPointByItem = stakingpoolDispatcher.getUserPointByItem(owner, collection, id);
    
    assert(resultTotalPoints == 1, 'error');
    assert(resultPointByItem == 1, 'error');
}

#[test]
fn test_unstakeNFT_nft(){
    let (stakingpoolDispatcher, stakingpoolAddress, owner) = deploy_flex_staking_pool();

        // Define the test collection address and token ID
        let collection =  contract_address_const::<'0x1234'>();
        let id :u256 = 1;

        stakingpoolDispatcher.stakeNFT(collection, id);
        stakingpoolDispatcher.unstakeNFT(collection, id);

        let resultTotalPoints = stakingpoolDispatcher.getUserTotalPoint(owner);
        let resultPointByItem = stakingpoolDispatcher.getUserPointByItem(owner, collection, id);
        
        assert(resultTotalPoints == 0, 'error');
        assert(resultPointByItem == 0, 'error');

}