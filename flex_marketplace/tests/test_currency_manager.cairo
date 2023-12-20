use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, start_spoof,
    CheatTarget, stop_spoof, cheatcodes
};
use starknet::{ContractAddress, contract_address_const,};
use flex::marketplace::currency_manager::{ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait};

fn RECIPIENT() -> ContractAddress {
    return contract_address_const::<'RECIPIENT'>();
}

fn SPENDER() -> ContractAddress {
    return contract_address_const::<'RECIPIENT'>();
}

fn OWNER() -> ContractAddress {
    return contract_address_const::<'OWNER'>();
}

fn deploy_contract() -> Result<ContractAddress, RevertedTransaction> {
    let contract = declare('CurrencyManager');
    let constructor_calldata = array![];
    contract.deploy(@constructor_calldata)
}

#[test]
fn test_ownership() {
    let contract_address =
            match deploy_contract(
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };
    let currency_manager = ICurrencyManagerDispatcher {contract_address};
    currency_manager.initializer(OWNER(), OWNER());
    assert(currency_manager.contract_owner()==OWNER(), 'owner mismatch');
}