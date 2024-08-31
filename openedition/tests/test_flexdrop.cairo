use core::clone::Clone;
use core::serde::Serde;
use core::array::ArrayTrait;
use starknet::{ContractAddress, SyscallResultTrait, get_block_timestamp};
use snforge_std::{declare, ContractClassTrait, ContractClass, CheatTarget, start_prank, stop_prank};
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
    ContractAddress,
    ContractAddress,
    ContractAddress,
    PhaseDrop
) {

        // Declare and deploy the account contracts
        let account_class = declare("Account").unwrap();
        let owner_contract_address = deploy_account(account_class, 'Owner');
        let user_one_contract_address = deploy_account(account_class, 'Adam');
        let user_two_contract_address = deploy_account(account_class, 'Eve');

        // Declare and deploy the ERC721 contract mock
        let erc721_hash = declare("ERC721").unwrap();
        let first_test_collection = deploy_erc721(erc721_hash, owner_contract_address, 1);
        let second_test_collection = deploy_erc721(erc721_hash, owner_contract_address, 2);

        // Declare and deploy the ERC20 contract mock
        let erc20_class_hash = declare("ERC20").unwrap();
        let erc20_name: ByteArray = "Mock ERC20";
        let erc20_symbol: ByteArray = "AAA";
        let supply: u256 = 10000;
        let recepient: ContractAddress = owner_contract_address;
        let mut erc20_constructor_calldata: Array<felt252> = ArrayTrait::new();
        erc20_name.serialize(ref erc20_constructor_calldata);
        erc20_symbol.serialize(ref erc20_constructor_calldata);
        supply.serialize(ref erc20_constructor_calldata);
        recepient.serialize(ref erc20_constructor_calldata);
        let (erc20_contract_address, _) = erc20_class_hash.deploy(@erc20_constructor_calldata).unwrap_syscall();

        // Declare and deploy the FlexDrop contract
        let contract = declare("FlexDrop").unwrap();
        let mut constructor_calldata: Array<felt252> = ArrayTrait::new();

        // Initialize constructor parameters
        let owner: ContractAddress = owner_contract_address;
        let currency_manager: ContractAddress = owner_contract_address;
        let fee_currency: ContractAddress = erc20_contract_address;
        let fee_mint: u256 = 100;
        let fee_mint_when_zero_price: u256 = 0;
        let new_phase_fee: u256 = 50;
        let domain_hash: felt252 = (0x1234abcd);
        let validator: ContractAddress = user_one_contract_address;
        let signature_checker: ContractAddress = user_one_contract_address;
        let fee_recipients = array![owner_contract_address, user_one_contract_address];
 
        // Serialize each parameter and add it to the constructor_calldata
        owner.serialize(ref constructor_calldata);
        currency_manager.serialize(ref constructor_calldata);
        fee_currency.serialize(ref constructor_calldata);
        fee_mint.serialize(ref constructor_calldata);
        fee_mint_when_zero_price.serialize(ref constructor_calldata);
        new_phase_fee.serialize(ref constructor_calldata);
        domain_hash.serialize(ref constructor_calldata);
        validator.serialize(ref constructor_calldata);
        signature_checker.serialize(ref constructor_calldata);

        // Serialize the array of fee recipients (as Span)
        fee_recipients.span().serialize(ref constructor_calldata);

        let (contract_address_flex_drop, _) = contract.deploy(@constructor_calldata).unwrap_syscall();
        let dispatcher_flex_drop = IFlexDropDispatcher { contract_address: contract_address_flex_drop };

        // Declare and deploy the ERC721OpenEdition contract
        let contract_class_hash = declare("ERC721OpenEdition").unwrap();
        let mut constructor_calldata: Array<felt252> = array![owner_contract_address.try_into().unwrap()];

        let name: ByteArray = "ERC721 Open Edition";
        let symbol: ByteArray = "OE";
        let token_base_uri: ByteArray = "ipfs://abcdefghijklmnopqrstuvwxyz";

        name.serialize(ref constructor_calldata);
        symbol.serialize(ref constructor_calldata);
        token_base_uri.serialize(ref constructor_calldata);

        let allowed_flex_drop: Array<ContractAddress> = array![user_one_contract_address, owner_contract_address];
        allowed_flex_drop.serialize(ref constructor_calldata);

        let (contract_address_token, _) = contract_class_hash.deploy(@constructor_calldata).unwrap_syscall();
        let dispatcher_token = INonFungibleFlexDropTokenDispatcher { contract_address: contract_address_token };

        // Define Phase Drop
        let phase_details = PhaseDrop {
            mint_price: 1000,
            currency: erc20_contract_address,
            start_time: get_block_timestamp(),
            end_time: get_block_timestamp() + 84600,
            max_mint_per_wallet: 10,
            phase_type: 1
        };

        (
            dispatcher_flex_drop,
            dispatcher_token,
            contract_address_flex_drop,
            contract_address_token,
            erc20_contract_address,
            owner_contract_address,
            user_one_contract_address,
            user_two_contract_address,
            first_test_collection,
            second_test_collection,
            phase_details
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

// Test suite
// #[test]
// #[should_panic(expected: ('Only allowed public',))]
// fn test_unauthorized_mint_public() {
//     let (_, dispatcher, _, _, user_two_contract_address, _) = __setup__();

//     dispatcher
//         .mint_flex_drop(user_two_contract_address, 2.try_into().unwrap(), 1.try_into().unwrap());
// }

#[test]
fn test_mint_public() {
    let (
        dispatcher_flex_drop, 
        dispatcher_token, 
        contract_address_flex_drop, 
        contract_address_token, 
        _, 
        owner_contract_address, 
        user_one_contract_address, 
        _, 
        _, 
        _, 
        phase_details
    ) = __setup__();
    println!("Setup Passed");

    start_prank(CheatTarget::Multiple(array![contract_address_flex_drop, contract_address_token]), owner_contract_address);
    println!("0");

    dispatcher_token.create_new_phase_drop(owner_contract_address, phase_details, owner_contract_address);
    println!("1");

    dispatcher_flex_drop.start_new_phase_drop(1, phase_details, user_one_contract_address);
    println!("2");

    dispatcher_flex_drop.mint_public(user_one_contract_address, 1, user_one_contract_address, user_one_contract_address, 5, true);
    println!("3");

    assert(dispatcher_token.get_mint_state(user_one_contract_address, 1) == (1, 1, 1),'invalid mint state');
    println!("4");

    assert(dispatcher_token.get_current_token_id() == 2, 'invalid current token id');
    println!("5");

    stop_prank(CheatTarget::Multiple(array![contract_address_flex_drop, contract_address_token]));
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
//         owner_contract_address,
//         user_one_contract_address,
//         user_two_contract_address,
//         _
//     ) = __setup__();

//     let payer = user_one_contract_address;

//     // Act as the contract owner
//     start_prank(CheatTarget::One(contract_address), owner_contract_address);
//     dispatcher.update_payer(payer, true); // Update payer to allowed
//     stop_prank(CheatTarget::One(contract_address));

//     // Validate that the payer is now in the allowed list
//     assert(
//         dispatcher.allowed_payer.read((contract_address, payer)) == true,
//         'Payer should be allowed'
//     );

//     // Remove payer
//     start_prank(CheatTarget::One(contract_address), owner_contract_address);
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
//         owner_contract_address,
//         user_one_contract_address,
//         _
//     ) = __setup__();

//     let new_payout_address = ContractAddress::from(0x1234);

//     // Act as the contract owner
//     start_prank(CheatTarget::One(contract_address), owner_contract_address);
//     dispatcher.update_creator_payout_address(new_payout_address);
//     stop_prank(CheatTarget::One(contract_address));

//     // Validate that the payout address was updated
//     assert(
//         dispatcher.creator_payout_address.read(contract_address) == new_payout_address,
//         'Payout address should be updated'
//     );
// }