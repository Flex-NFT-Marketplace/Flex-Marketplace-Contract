use core::array::ArrayTrait;
use starknet::{ContractAddress, SyscallResultTrait, get_block_timestamp};
use snforge_std::{declare, ContractClassTrait, ContractClass, CheatTarget, start_prank, stop_prank};
use openedition::interfaces::IFlexDrop::{
    IFlexDrop, IFlexDropDispatcherTrait, IFlexDropDispatcher,
};
use openedition::interfaces::INonFungibleFlexDropToken::{
    INonFungibleFlexDropToken, INonFungibleFlexDropTokenDispatcher,
    INonFungibleFlexDropTokenDispatcherTrait
};
use openedition::interfaces::ICurrencyManager::{
    ICurrencyManager, ICurrencyManagerDispatcherTrait, ICurrencyManagerDispatcher,
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
    PhaseDrop
) {

        // Declare and deploy the account contracts
        let account_class = declare("Account").unwrap();
        let owner_contract_address = deploy_account(account_class, 'Owner');
        let user_one_contract_address = deploy_account(account_class, 'Adam');
        let user_two_contract_address = deploy_account(account_class, 'Eve');

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

        // Declare and deploy the Currency Manager
        let contract_address_currency_manager = deploy_currency_manager();
        let currency_manager_dispatcher = ICurrencyManagerDispatcher { contract_address: contract_address_currency_manager};

        // Declare and deploy the FlexDrop contract
        let contract = declare("FlexDrop").unwrap();
        let mut constructor_calldata: Array<felt252> = ArrayTrait::new();

        // Initialize constructor parameters
        let owner: ContractAddress = owner_contract_address;
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
        currency_manager_dispatcher.serialize(ref constructor_calldata);
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

        let allowed_flex_drop: Array<ContractAddress> = array![contract_address_flex_drop];
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
            phase_details
        )
}

// Deploys an account contract
fn deploy_account(account_class: ContractClass, name: felt252) -> ContractAddress {
    let mut constructor_calldata: Array<felt252> = array![name];
    let (contract_address, _) = account_class.deploy(@constructor_calldata).unwrap_syscall();
    contract_address
}

// Deploys currency manager
fn deploy_currency_manager() -> ContractAddress {
    let contract_class = declare("CurrencyManager").unwrap();
    let (contract_address, _) = contract_class.deploy(@array![]).unwrap();
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

// Tests for unauthorized mint public
#[test]
#[should_panic(expected: ('Only allowed public',))]
fn test_unauthorized_mint_public() {
    let (
        dispatcher_flex_drop, 
        dispatcher_token, 
        _, 
        _, 
        _, 
        _, 
        user_one_contract_address, 
        user_two_contract_address, 
        phase_details
    ) = __setup__();

    dispatcher_token { contract_address: user_one_contract_address }.create_new_phase_drop(user_one_contract_address, phase_detail, user_one_contract_address);

    dispatcher_flex_drop.mint_public(user_two_contract_address, 1, user_two_contract_address, user_two_contract_address, 5, true);
}

// Test for mint public
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
        phase_details
    ) = __setup__();

    start_prank(CheatTarget::Multiple(array![contract_address_flex_drop, contract_address_token]), owner_contract_address);

    dispatcher_token.create_new_phase_drop(owner_contract_address, phase_details, owner_contract_address);

    dispatcher_flex_drop.mint_public(user_one_contract_address, 1, user_one_contract_address, user_one_contract_address, 5, true);

    assert(dispatcher_token.get_mint_state(user_one_contract_address, 1) == (1, 1, 1),'invalid mint state');

    assert(dispatcher_token.get_current_token_id() == 2, 'invalid current token id');

    stop_prank(CheatTarget::Multiple(array![contract_address_flex_drop, contract_address_token]));
}

// Test for unauthorized update payer
#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_unauthorized_update_payer() {
    let (_, dispatcher, _, user_one_contract_address, user_two_contract_address, _) = __setup__();

    // Unauthorized user attempting to update payer
    let payer = user_one_contract_address;

    dispatcher.update_payer(payer, true);
}

// Test for update payer
#[test]
fn test_update_payer() {
    let (
        dispatcher_flex_drop, 
        _, 
        contract_address_flex_drop, 
        _, 
        _, 
        owner_contract_address, 
        user_one_contract_address, 
        _,  
        _
    ) = __setup__();

    let payer = user_one_contract_address;

    start_prank(CheatTarget::One(contract_address_flex_drop), owner_contract_address);

    dispatcher_flex_drop.update_payer(payer, true); 

    let is_allowed = dispatcher_flex_drop.is_payer_allowed(payer);
    assert(is_allowed == true, 'Payer should be allowed');

    dispatcher_flex_drop.update_payer(payer, false); 

    let is_allowed = dispatcher_flex_drop.is_payer_allowed(payer);
    assert(is_allowed == false, 'Payer should be removed');

    stop_prank(CheatTarget::One(contract_address_flex_drop));
}

// Tests for update creator payout address
#[test]
fn test_update_creator_payout_address() {
    let (
        flex_drop_dispatcher,
        _,
        _,
        contract_address_token,
        _,
        owner_contract_address,
        user_one_contract_address,
        _,
        _
    ) = __setup__();

    // Call update_creator_payout_address
    let new_payout_address = user_one_contract_address;
    start_prank(owner_contract_address);
    flex_drop_dispatcher.update_creator_payout_address(new_payout_address).unwrap_syscall();
    stop_prank();

    // Verify that the creator payout address has been updated
    let updated_payout_address = flex_drop_dispatcher.get_creator_payout_address(contract_address_token);
    assert(updated_payout_address, new_payout_address);

}

// Tests for Whitelist mint 
#[test]
fn test_whitelist_mint() {
    let (
        flex_drop_dispatcher,
        token_dispatcher,
        _,
        contract_address_token,
        _,
        owner_contract_address,
        user_one_contract_address,
        _,
        phase_details
    ) = __setup__();

    // Simulate user minting with whitelist data
    let whitelist_data = WhiteListParam {
        nft_address: contract_address_token,
        minter: user_one_contract_address,
        phase_id: phase_details.phase_type
    };
    
    let proof = array[0x123456789]; 

    start_prank(user_one_contract_address);
    flex_drop_dispatcher.whitelist_mint(whitelist_data, owner_contract_address, proof).unwrap_syscall();
    stop_prank();

    // Assertions
    let (minted_amount, _, _) = token_dispatcher.get_mint_state(user_one_contract_address, phase_details.phase_type);
    assert(minted_amount, 1); 
}

// Tests for Start New Phase Drop
#[test]
fn test_start_new_phase_drop() {
    // Set up contracts and environment
    let (
        flex_drop_dispatcher,
        _,
        _,
        contract_address_token,
        erc20_contract_address,
        owner_contract_address,
        user_one_contract_address,
        _,
        _
    ) = __setup__();

    // New phase details
    let new_phase_id = 2;
    let new_phase_details = PhaseDrop {
        mint_price: 1500,
        currency: erc20_contract_address,
        start_time: get_block_timestamp(),
        end_time: get_block_timestamp() + 86400,
        max_mint_per_wallet: 5,
        phase_type: 1
    };

    // Call start_new_phase_drop
    start_prank(owner_contract_address);
    flex_drop_dispatcher.start_new_phase_drop(new_phase_id, new_phase_details, user_one_contract_address).unwrap_syscall();
    stop_prank();

    // Check the new phase is stored correctly
    let phase_drop = flex_drop_dispatcher.get_phase_drop(contract_address_token, new_phase_id);
    assert(phase_drop.mint_price, 1500);
    assert(phase_drop.max_mint_per_wallet, 5);
}

// Tests for Update Phase Drop
#[test]
fn test_update_phase_drop() {
    // Set up contracts and environment
    let (
        flex_drop_dispatcher,
        _,
        _,
        contract_address_token,
        erc20_contract_address,
        owner_contract_address,
        _,
        _,
        phase_details
    ) = __setup__();

    // Existing phase drop id and details to update
    let updated_phase_details = PhaseDrop {
        mint_price: 1200,
        currency: erc20_contract_address,
        start_time: get_block_timestamp(),
        end_time: get_block_timestamp() + 86400,
        max_mint_per_wallet: 8,
        phase_type: 1
    };

    // Call update_phase_drop
    start_prank(owner_contract_address);
    flex_drop_dispatcher.update_phase_drop(phase_details.phase_type, updated_phase_details).unwrap_syscall();
    stop_prank();

    // Check that the phase details are updated
    let updated_phase_drop = flex_drop_dispatcher.get_phase_drop(contract_address_token, phase_details.phase_type);
    assert(updated_phase_drop.mint_price, 1200);
    assert(updated_phase_drop.max_mint_per_wallet, 8);
}