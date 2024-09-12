use core::clone::Clone;
use core::starknet::SyscallResultTrait;
use core::serde::Serde;
use core::array::ArrayTrait;
use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};
use openedition::interfaces::INonFungibleFlexDropToken::{
    INonFungibleFlexDropToken, INonFungibleFlexDropTokenDispatcher,
    INonFungibleFlexDropTokenDispatcherTrait
};
use openedition::utils::openedition::{PhaseDrop, MultiConfigureStruct};
use openzeppelin::presets::{account::Account, erc20::ERC20};

fn __setup__() -> (
    ContractAddress,
    INonFungibleFlexDropTokenDispatcher,
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
    let mut user_one_constructor_calldata: Array<felt252> = array!['BOB'];
    let (user_one_contract_address, _) = account_class_hash
        .deploy(@user_one_constructor_calldata)
        .unwrap_syscall();

    // deploy user two account
    let mut user_two_constructor_calldata: Array<felt252> = array!['ALICE'];
    let (user_two_contract_address, _) = account_class_hash
        .deploy(@user_two_constructor_calldata)
        .unwrap_syscall();

    // mock ERC20 class hash
    let erc20_class_hash = declare("ERC20").unwrap();

    // deploy mock ERC20
    let erc20_name: ByteArray = "Mock ERC20";
    let erc20_symbol: ByteArray = "MMM";
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

    // FlexDrop class hash
    let flex_drop_class_hash = declare("FlexDrop").unwrap();

    // deploy FlexDrop

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

    let (contract_address, _) = contract_class_hash.deploy(@constructor_calldata).unwrap_syscall();
    let dispatcher = INonFungibleFlexDropTokenDispatcher { contract_address: contract_address };

    (
        contract_address,
        dispatcher,
        creator_contract_address,
        user_one_contract_address,
        user_two_contract_address,
        erc20_contract_address
    )
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_unauthorized_update_allowed_flex_drop() {
    let (_, dispatcher, _, user_one_contract_address, user_two_contract_address, _) = __setup__();

    let allowed_flex_drop: Array<ContractAddress> = array![
        user_one_contract_address, user_two_contract_address
    ];

    dispatcher.update_allowed_flex_drop(allowed_flex_drop);
}

#[test]
fn test_update_allowed_flex_drop() {
    let (
        contract_address,
        dispatcher,
        creator_contract_address,
        user_one_contract_address,
        user_two_contract_address,
        _
    ) =
        __setup__();

    let allowed_flex_drops: Array<ContractAddress> = array![
        user_one_contract_address, user_two_contract_address
    ];

    start_prank(CheatTarget::One(contract_address), creator_contract_address);
    dispatcher.update_allowed_flex_drop(allowed_flex_drops.clone());

    assert(allowed_flex_drops.span() == dispatcher.get_allowed_flex_drops(), 'invalid flex drops');

    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic(expected: ('Only allowed FlexDrop',))]
fn test_unauthorized_mint_flex_drop() {
    let (_, dispatcher, _, _, user_two_contract_address, _) = __setup__();

    dispatcher
        .mint_flex_drop(user_two_contract_address, 2.try_into().unwrap(), 1.try_into().unwrap());
}

#[test]
fn test_mint_flex_drop() {
    let (contract_address, dispatcher, _, user_one_contract_address, _, _) = __setup__();

    start_prank(CheatTarget::One(contract_address), user_one_contract_address);
    dispatcher
        .mint_flex_drop(user_one_contract_address, 2.try_into().unwrap(), 1.try_into().unwrap());

    assert(
        dispatcher
            .get_mint_state(
                user_one_contract_address, 2.try_into().unwrap()
            ) == (1, 1, 18446744073709551614),
        'invalid mint state'
    );

    assert(dispatcher.get_current_token_id() == 2, 'invalid current token id');

    stop_prank(CheatTarget::One(contract_address));
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_unauthorized_create_new_phase_drop_caller_not_owner() {
    let (
        _,
        dispatcher,
        creator_contract_address,
        user_one_contract_address,
        _,
        erc20_contract_address
    ) =
        __setup__();

    let phase_detail = PhaseDrop {
        mint_price: 1000,
        currency: erc20_contract_address,
        start_time: get_block_timestamp(),
        end_time: get_block_timestamp() + 84600,
        max_mint_per_wallet: 10,
        phase_type: 1
    };

    dispatcher
        .create_new_phase_drop(user_one_contract_address, phase_detail, creator_contract_address);
}

#[test]
#[should_panic(expected: ('Only allowed FlexDrop',))]
fn test_unauthorized_create_new_phase_drop_invalid_flex_drop() {
    let (
        contract_address,
        dispatcher,
        creator_contract_address,
        _,
        user_two_contract_address,
        erc20_contract_address
    ) =
        __setup__();

    let phase_detail = PhaseDrop {
        mint_price: 1000,
        currency: erc20_contract_address,
        start_time: get_block_timestamp(),
        end_time: get_block_timestamp() + 84600,
        max_mint_per_wallet: 10,
        phase_type: 1
    };

    start_prank(CheatTarget::One(contract_address), creator_contract_address);
    dispatcher
        .create_new_phase_drop(user_two_contract_address, phase_detail, creator_contract_address);
    stop_prank(CheatTarget::One(contract_address));
}
// #[test]
// fn test_create_new_phase_drop() {
//     let (
//         contract_address,
//         dispatcher,
//         creator_contract_address,
//         user_one_contract_address,
//         _,
//         erc20_contract_address
//     ) =
//         __setup__();

//     let phase_detail = PhaseDrop {
//         mint_price: 1000,
//         currency: erc20_contract_address,
//         start_time: get_block_timestamp(),
//         end_time: get_block_timestamp() + 84600,
//         max_mint_per_wallet: 10,
//         phase_type: 1
//     };

//     start_prank(CheatTarget::One(contract_address), creator_contract_address);
//     dispatcher
//         .create_new_phase_drop(user_one_contract_address, phase_detail, creator_contract_address);
//     stop_prank(CheatTarget::One(contract_address));
// }


