use core::array::ArrayTrait;
use snforge_std::{ declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp, ContractClass };
use stakingpool::interfaces::IFlexStakingPool::{
IFlexStakingPoolDispatcher, IFlexStakingPoolDispatcherTrait
};

use starknet::{ContractAddress,SyscallResultTrait, get_block_timestamp};
use openzeppelin::presets::{account::Account, erc721::ERC721};

const ONE_YEAR: u64 = 31536000; // 365 days in seconds
const TOKEN_ID: u256 = 1;

// Sets up the environment for testing
fn set_up() ->(    
    IFlexStakingPoolDispatcher, 
    ContractAddress, 
    ContractAddress, 
    ContractAddress, 
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress) {

        // Declare and deploy the account contracts
        let account_class = declare("Account").unwrap();
        let owner_contract_addres = deploy_account(account_class, 'Owner');
        let test_user_contract_addres = deploy_account(account_class, 'Alex');

        // Declare and deploy the ERC721 contract mock
        let erc721_hash = declare("ERC721").unwrap();
        let first_test_collection = deploy_erc721(erc721_hash, owner_contract_addres, 1);
        let second_test_collection = deploy_erc721(erc721_hash, owner_contract_addres, 2);
        let third_test_collection = deploy_erc721(erc721_hash, owner_contract_addres, 3);
        let fourth_test_collection = deploy_erc721(erc721_hash, owner_contract_addres, 4);

        // Declare and deploy the FlexStakingPool contract
        let contract = declare("FlexStakingPool").unwrap();
        let mut constructor_calldata = array![owner_contract_addres.try_into().unwrap()];
        let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap_syscall();
        let dispatcher = IFlexStakingPoolDispatcher { contract_address };

        (
            dispatcher,
            contract_address,
            owner_contract_addres,
            first_test_collection,
            test_user_contract_addres,
            second_test_collection,
            third_test_collection,
            fourth_test_collection
         )
}

// Deploys an account contract
fn deploy_account(account_class: ContractClass, name: felt252) -> ContractAddress {
    let mut constructor_calldata: Array<felt252> = array![name];
    let (contract_address, _) = account_class.deploy(@constructor_calldata).unwrap_syscall();
    contract_address
}

// Deploys an ERC721 contract mock
fn deploy_erc721(
    erc721_hash: ContractClass,
    recipient: ContractAddress,
    id: u256
) -> ContractAddress {
    let erc721_name: ByteArray = "Mock ERC721";
    let erc721_symbol: ByteArray = "FLX";
    let erc721_base_uri: ByteArray = "";
    let mut ids: Array<u256> = array![id];
    let token_ids = ids.span();

    let mut erc721_constructor_data: Array<felt252> = array![];
    erc721_name.serialize(ref erc721_constructor_data);
    erc721_symbol.serialize(ref erc721_constructor_data);
    erc721_base_uri.serialize(ref erc721_constructor_data);
    recipient.serialize(ref erc721_constructor_data);
    token_ids.serialize(ref erc721_constructor_data);

    let (collection, _) = erc721_hash.deploy(@erc721_constructor_data).unwrap_syscall();
    collection
}

// Sets up the call for the stakeNFT function
fn stake_NFT(
    stakingpool_dispatcher:IFlexStakingPoolDispatcher,
    stakingpool_address: ContractAddress,
    collection: ContractAddress,
    owner_contract_addres: ContractAddress,
    id: u256
) {
    start_prank(CheatTarget::Multiple(array![stakingpool_address, collection]), owner_contract_addres);
    stakingpool_dispatcher.setAllowedCollection(collection, true);
    stakingpool_dispatcher.setTimeUnit(collection, 3600); // one hour
    stakingpool_dispatcher.setRewardPerUnitTime(collection, 300);
    stakingpool_dispatcher.stakeNFT(collection, id);

    stop_prank(CheatTarget::Multiple(array![stakingpool_address, collection]));
}

// Helper function to get staking points
fn get_points(
    creator_contract_address:ContractAddress,
    stakingpool_address:ContractAddress,
    token_id:u256,
    item_addres:ContractAddress,
    stakingpool_dispatcher:IFlexStakingPoolDispatcher
  ) -> (u256, u256)  
  {
    let block_time = get_block_timestamp();
    start_warp(CheatTarget::Multiple(array![stakingpool_address]), block_time+ONE_YEAR+1);
    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);

    let result_total_points = stakingpool_dispatcher.getUserTotalPoint(creator_contract_address);
    let result_point_by_item = stakingpool_dispatcher.getUserPointByItem(creator_contract_address, item_addres, token_id);

    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));
    stop_warp(CheatTarget::Multiple(array![stakingpool_address]));

    (result_total_points, result_point_by_item)
}

// Tests for unauthorized collection staking
#[test]
#[should_panic(expected: 'Only Allowed Collection')]
fn test__unauthorized_collection(){
    let (stakingpool_dispatcher,
        stakingpool_address,
        creator_contract_address,
        first_test_collection,
        _,
        _,
        _,
        _
    ) = set_up();

    start_prank(CheatTarget::Multiple(array![stakingpool_address, first_test_collection]), creator_contract_address);
    stakingpool_dispatcher.stakeNFT(first_test_collection, TOKEN_ID);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address, first_test_collection]));
}


// Tests for staking when the caller is not the owner
#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test__should_panic_when_caller_is_not_owner(){
    let (
        stakingpool_dispatcher,
        stakingpool_address,
        _,
        first_test_collection,
        test_user_contract_addres,
        _,
        _,
        _
    ) = set_up();

    start_prank(CheatTarget::Multiple(array![stakingpool_address, first_test_collection]), test_user_contract_addres);
    stakingpool_dispatcher.setAllowedCollection(first_test_collection, true);
    stakingpool_dispatcher.stakeNFT(first_test_collection, TOKEN_ID);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address, first_test_collection]));
}

// Tests for unstaking without staking first
#[test]
#[should_panic(expected: 'Not Item Owner')]
fn test_unstake_without_stake() {
    let (stakingpool_dispatcher,
        stakingpool_address,
        creator_contract_address,
        first_test_collection,
        _,
        _,
        _,
        _
    ) = set_up();

    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);
    stakingpool_dispatcher.unstakeNFT(first_test_collection, TOKEN_ID);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));
}

// Tests basic staking and unstaking
#[test]
fn test_basic_stake_unstake() {
    let (
        stakingpool_dispatcher,
        stakingpool_address,
        creator_contract_address,
        first_test_collection,
        _,
        _,
        _,
        _
    ) = set_up();

    stake_NFT(stakingpool_dispatcher, stakingpool_address, first_test_collection, creator_contract_address, TOKEN_ID);

    let  (result_total_points, result_point_by_item) = get_points(
        creator_contract_address,
        stakingpool_address,
        TOKEN_ID,
        first_test_collection,
        stakingpool_dispatcher
    );

    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);
    stakingpool_dispatcher.unstakeNFT(first_test_collection, TOKEN_ID);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));

    assert(result_total_points > 0, 'User should have total points');
    assert(result_point_by_item > 0, 'User should have points by item');
}

// Tests multiple overlapping staking and unstaking
#[test]
fn test_multiple_overlapping_stake_unstake() {
    let (
        stakingpool_dispatcher,
        stakingpool_address,
        creator_contract_address,
        first_test_collection,
        _,
        second_test_collection,
        third_test_collection,
        fourth_test_collection
    ) = set_up();
    
    let first_token_id :u256 = 1;
    let second_token_id :u256 = 2;
    let third_token_id :u256 = 3;
    let fourth_token_id :u256 = 4;
    let total_Stake_Points:u256 = 5256000;
    let stake_points_by_item:u256 = 2628000;

    // Stake first two collections
    stake_NFT(stakingpool_dispatcher, stakingpool_address, first_test_collection, creator_contract_address, first_token_id);
    stake_NFT(stakingpool_dispatcher, stakingpool_address, second_test_collection, creator_contract_address, second_token_id);
    

   let  (result_total_points, result_point_by_item) = get_points(
    creator_contract_address,
    stakingpool_address,
    first_token_id,
    first_test_collection,
    stakingpool_dispatcher
);

    assert(result_total_points == total_Stake_Points, 'User should have total points');
    assert(result_point_by_item == stake_points_by_item, 'User should have points by item');


    // Unstake first collection
    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);
    stakingpool_dispatcher.unstakeNFT(first_test_collection, first_token_id);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));


    // Stake third testing collection
    stake_NFT(stakingpool_dispatcher, stakingpool_address, third_test_collection, creator_contract_address, third_token_id);

    let  (second_result_total_points, second_result_point_by_item) = get_points(
        creator_contract_address,
        stakingpool_address,
        second_token_id,
        second_test_collection,
        stakingpool_dispatcher
    );

    assert(second_result_total_points == total_Stake_Points, 'User should have total points');
    assert(second_result_point_by_item == stake_points_by_item, 'User should have points by item');

    // Unstake second and third testing collections
    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);
    stakingpool_dispatcher.unstakeNFT(second_test_collection, second_token_id);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));

    start_prank(CheatTarget::Multiple(array![stakingpool_address]), creator_contract_address);
    stakingpool_dispatcher.unstakeNFT(third_test_collection, third_token_id);
    stop_prank(CheatTarget::Multiple(array![stakingpool_address]));


    // Stake fourth testing collection
    stake_NFT(stakingpool_dispatcher, stakingpool_address, fourth_test_collection, creator_contract_address, fourth_token_id);
    
    let  (third_result_total_points, third_result_point_by_item) = get_points(
        creator_contract_address, stakingpool_address,
        fourth_token_id,
        fourth_test_collection,
        stakingpool_dispatcher
    );

    // Both asserts are done with stake_points_by_item because there is only one item
    assert(third_result_total_points  == stake_points_by_item, 'User should have total points');
    assert(third_result_point_by_item == stake_points_by_item, 'User should have points by item');
}