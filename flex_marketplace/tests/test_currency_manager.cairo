use flex::marketplace::currency_manager::{
    ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait
};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, start_spoof,
    CheatTarget, stop_spoof, cheatcodes
};
use starknet::{ContractAddress, contract_address_const,};

fn CURRENCY0() -> ContractAddress {
    return contract_address_const::<'CURRENCY0'>();
}

fn CURRENCY1() -> ContractAddress {
    return contract_address_const::<'CURRENCY1'>();
}

fn OWNER() -> ContractAddress {
    return contract_address_const::<'OWNER'>();
}

fn SECOND_OWNER() -> ContractAddress {
    return contract_address_const::<'SECOND_OWNER'>();
}

fn deploy_contract() -> Result<ContractAddress, RevertedTransaction> {
    let contract = declare('CurrencyManager');
    let constructor_calldata = array![];
    contract.deploy(@constructor_calldata)
}

#[test]
fn test_ownership() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    assert(currency_manager.contract_owner() == OWNER(), 'owner mismatch');
}

#[test]
fn test_add_currency() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.add_currency(CURRENCY0());
    assert(currency_manager.is_currency_whitelisted(CURRENCY0()) == true, 'should be whitelisted');
    assert(currency_manager.whitelisted_currency_count() == 1, 'should be one');
    assert(currency_manager.whitelisted_currency(1) == CURRENCY0(), 'should be currency0');
// assert(currency_manager.contract_owner()==OWNER(), 'owner mismatch');
}

#[test]
fn test_remove_currency() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.add_currency(CURRENCY0());
    currency_manager.add_currency(CURRENCY1());
    currency_manager.remove_currency(CURRENCY0());
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY0()) == false, 'should not be whitelisted'
    );
    assert(currency_manager.is_currency_whitelisted(CURRENCY1()) == true, 'should be whitelisted');
    assert(currency_manager.whitelisted_currency_count() == 1, 'should be one');
    assert(currency_manager.whitelisted_currency(1) == CURRENCY1(), 'should be currency1')
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_currency_not_owner() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    currency_manager.add_currency(CURRENCY0());
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_currency_not_owner() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.add_currency(CURRENCY0());
    stop_prank(CheatTarget::All);
    currency_manager.remove_currency(CURRENCY0());
}

#[test]
fn test_transfer_contract_ownership() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.transfer_contract_ownership(SECOND_OWNER());
    assert(currency_manager.contract_owner() == SECOND_OWNER(), 'second owner should be owner');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_transfer_contract_ownership_not_owner() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    currency_manager.transfer_contract_ownership(SECOND_OWNER());
}

#[test]
fn test_whitelisted_currency_count() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.add_currency(CURRENCY0());
    assert(currency_manager.whitelisted_currency_count() == 1, 'should be one');
    currency_manager.add_currency(CURRENCY1());
    assert(currency_manager.whitelisted_currency_count() == 2, 'should be two');
}


#[test]
fn test_whitelisted_currency() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());
    currency_manager.add_currency(CURRENCY0());
    currency_manager.add_currency(CURRENCY1());
    assert(currency_manager.whitelisted_currency(1) == CURRENCY0(), 'should be currency0');
    assert(currency_manager.whitelisted_currency(2) == CURRENCY1(), 'should be currency1');
    currency_manager.remove_currency(CURRENCY0());
    assert(currency_manager.whitelisted_currency(1) == CURRENCY1(), 'should be currency0');
}


#[test]
fn test_is_currency_whitelisted() {
    let contract_address = match deploy_contract() {
        Result::Ok(address) => address,
        Result::Err(msg) => panic(msg.panic_data),
    };
    let currency_manager = ICurrencyManagerDispatcher { contract_address };
    currency_manager.initializer(OWNER(), OWNER());
    start_prank(CheatTarget::All, OWNER());

    assert(
        currency_manager.is_currency_whitelisted(CURRENCY0()) == false, 'should not be whitelisted'
    );
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY1()) == false, 'should not whitelisted'
    );

    currency_manager.add_currency(CURRENCY0());
    assert(currency_manager.is_currency_whitelisted(CURRENCY0()) == true, 'should be whitelisted');
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY1()) == false, 'should not be whitelisted'
    );

    currency_manager.add_currency(CURRENCY1());
    assert(currency_manager.is_currency_whitelisted(CURRENCY0()) == true, 'should be whitelisted');
    assert(currency_manager.is_currency_whitelisted(CURRENCY1()) == true, 'should be whitelisted');

    currency_manager.remove_currency(CURRENCY0());
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY0()) == false, 'should not be whitelisted'
    );
    assert(currency_manager.is_currency_whitelisted(CURRENCY1()) == true, 'should be whitelisted');

    currency_manager.remove_currency(CURRENCY1());
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY0()) == false, 'should not be whitelisted'
    );
    assert(
        currency_manager.is_currency_whitelisted(CURRENCY1()) == false, 'should not whitelisted'
    );
}
