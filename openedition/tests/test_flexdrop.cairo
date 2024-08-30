use core::clone::Clone;
use core::serde::Serde;
use core::array::ArrayTrait;
use starknet::{ContractAddress, SyscallResultTrait, get_block_timestamp};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};
use openedition::interfaces::IFlexDrop::{
    IFlexDropDispatcherTrait, IFlexDropDispatcher,
};
use openedition::interfaces::INonFungibleFlexDropToken::{
    INonFungibleFlexDropToken, INonFungibleFlexDropTokenDispatcher,
    INonFungibleFlexDropTokenDispatcherTrait
};
use openedition::utils::openedition::{PhaseDrop, MultiConfigureStruct};
use openzeppelin::presets::{account::Account, erc20::ERC20};

fn __setup__() -> (
    IFlexDropDispatcher,
    INonFungibleFlexDropTokenDispatcher,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress
) {

    // account preset class hash
    let account_class_hash = declare("Account").unwrap();

    // deploy creator account
    let mut creator_constructor_calldata: Array<felt252> = array!['CREATOR'];
    let (creator_contract_address, _) = account_class_hash
        .deploy(@creator_constructor_calldata)
        .unwrap_syscall();

    // deploy user one account
    let mut user_one_constructor_calldata: Array<felt252> = array!['ADAM'];
    let (user_one_contract_address, _) = account_class_hash
        .deploy(@user_one_constructor_calldata)
        .unwrap_syscall();

    // deploy user two account
    let mut user_two_constructor_calldata: Array<felt252> = array!['EVE'];
    let (user_two_contract_address, _) = account_class_hash
        .deploy(@user_two_constructor_calldata) 
        .unwrap_syscall();
    
    // mock ERC20 class hash
    let erc20_class_hash = declare("ERC20").unwrap();

    // deploy mock ERC20
    let erc20_name: ByteArray = "Mock ERC20";
    let erc20_symbol: ByteArray = "AAA";
    let supply: u256 = 10000;
    let recepient: ContractAddress = creator_contract_address;
    let mut erc20_constructor_calldata: Array<felt252> = ArrayTrait::new();
    erc20_name.serialize(ref erc20_constructor_calldata);
    erc20_symbol.serialize(ref erc20_constructor_calldata);
    supply.serialize(ref erc20_constructor_calldata);
    recepient.serialize(ref erc20_constructor_calldata);
    let (erc20_contract_address, _) = erc20_class_hash
        .deploy(@erc20_constructor_calldata)
        .unwrap_syscall();

    // Declare and deploy the FlexDrop contract
    let contract = declare("FlexDrop").unwrap();
    let mut constructor_calldata = array![creator_contract_address.try_into().unwrap()];
    let (contract_address_flex_drop, _) = contract.deploy(@constructor_calldata).unwrap_syscall();
    let dispatcher_flex_drop = IFlexDropDispatcher { contract_address: contract_address_flex_drop };
    
    // ERC721OpenEdition class hash
    let contract_class_hash = declare("ERC721OpenEdition").unwrap();

    // deploy ERC721OpenEdition
    let mut constructor_calldata: Array<felt252> = array![
        creator_contract_address.try_into().unwrap()
    ];

    let name: ByteArray = "ERC721 Open Edition";
    let symbol: ByteArray = "OE";
    let token_base_uri: ByteArray = "ipfs://abcdefghijklmnopqrstuvwxyz";

    name.serialize(ref constructor_calldata);
    symbol.serialize(ref constructor_calldata);
    token_base_uri.serialize(ref constructor_calldata);

    let allowed_flex_drop: Array<ContractAddress> = array![user_one_contract_address];
    allowed_flex_drop.serialize(ref constructor_calldata);

    let (contract_address_token, _) = contract_class_hash.deploy(@constructor_calldata).unwrap_syscall();
    let dispatcher_token = INonFungibleFlexDropTokenDispatcher { contract_address: contract_address_token };

    (
        dispatcher_flex_drop,
        dispatcher_token,
        contract_address_flex_drop,
        contract_address_token,
        creator_contract_address,
        user_one_contract_address,
        user_two_contract_address,
        erc20_contract_address
    )
}

// Test suite
// #[test]
// #[should_panic(expected: ('Only allowed public',))]
// fn test_unauthorized_mint_public() {
//     let (_, dispatcher, _, _, user_two_contract_address, _) = __setup__();

//     dispatcher
//         .mint_flex_drop(user_two_contract_address, 2.try_into().unwrap(), 1.try_into().unwrap());
// }

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_mint_public() {
    let (dispatcher_flex_drop, dispatcher_token, contract_address_flex_drop, contract_address_token, _, user_one_contract_address, _, _) = __setup__();

    start_prank(CheatTarget::One(contract_address_flex_drop), user_one_contract_address);
    dispatcher_flex_drop
        .mint_public(contract_address_token, 1, user_one_contract_address, user_one_contract_address, 1000, true);

    assert(
        dispatcher_token.get_mint_state(user_one_contract_address, 1) == (1, 1, 18446744073709551614),
        'invalid mint state'
    );

    assert(dispatcher_token.get_current_token_id() == 2, 'invalid current token id');

    stop_prank(CheatTarget::One(contract_address_flex_drop));
}

// #[test]
// #[should_panic(expected: ('Caller is not the owner',))]
// fn test_unauthorized_update_payer() {
//     let (_, dispatcher, _, user_one_contract_address, user_two_contract_address, _) = __setup__();

//     // Unauthorized user (not owner) attempting to update payer
//     let payer = user_one_contract_address;

//     dispatcher.update_payer(payer, true);
// }

// #[test]
// fn test_update_payer() {
//     let (
//         contract_address,
//         dispatcher,
//         creator_contract_address,
//         user_one_contract_address,
//         user_two_contract_address,
//         _
//     ) = __setup__();

//     let payer = user_one_contract_address;

//     // Act as the contract owner
//     start_prank(CheatTarget::One(contract_address), creator_contract_address);
//     dispatcher.update_payer(payer, true); // Update payer to allowed
//     stop_prank(CheatTarget::One(contract_address));

//     // Validate that the payer is now in the allowed list
//     assert(
//         dispatcher.allowed_payer.read((contract_address, payer)) == true,
//         'Payer should be allowed'
//     );

//     // Remove payer
//     start_prank(CheatTarget::One(contract_address), creator_contract_address);
//     dispatcher.update_payer(payer, false); // Update payer to not allowed
//     stop_prank(CheatTarget::One(contract_address));

//     // Validate that the payer is now removed
//     assert(
//         dispatcher.allowed_payer.read((contract_address, payer)) == false,
//         'Payer should be removed'
//     );
// }

// #[test]
// #[should_panic(expected = 'Caller is not the owner')]
// fn test_unauthorized_update_creator_payout_address() {
//     let (_, dispatcher, _, user_one_contract_address, _) = __setup__();

//     // Unauthorized user (not owner) attempting to update the payout address
//     let new_payout_address = ContractAddress::from(0x1234);

//     // Attempting update from an unauthorized account
//     dispatcher.update_creator_payout_address(new_payout_address); // Expected to panic due to unauthorized access
// }

// #[test]
// fn test_update_creator_payout_address() {
//     let (
//         contract_address,
//         dispatcher,
//         creator_contract_address,
//         user_one_contract_address,
//         _
//     ) = __setup__();

//     let new_payout_address = ContractAddress::from(0x1234);

//     // Act as the contract owner
//     start_prank(CheatTarget::One(contract_address), creator_contract_address);
//     dispatcher.update_creator_payout_address(new_payout_address);
//     stop_prank(CheatTarget::One(contract_address));

//     // Validate that the payout address was updated
//     assert(
//         dispatcher.creator_payout_address.read(contract_address) == new_payout_address,
//         'Payout address should be updated'
//     );
// }