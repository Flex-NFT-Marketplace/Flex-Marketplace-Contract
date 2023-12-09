%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub, uint256_eq, uint256_lt
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

//
// CurrencyManager
//
// Allows adding/removing of currencies for trading on the marketplace
//

//
// Storage
//

@storage_var
func _whitelistedCurrenciesCount() -> (count: Uint256) {
}

@storage_var
func _whitelistedCurrencies(index: Uint256) -> (currency: felt) {
}

@storage_var
func _whitelistedCurrenciesIndex(currency: felt) -> (index: Uint256) {
}

//
// Events
//

@event
func CurrencyRemoved(currency: felt, timestamp: felt) {
}

@event
func CurrencyWhitelisted(currency: felt, timestamp: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt, proxy_admin: felt) {
    Proxy.initializer(proxy_admin);
    Ownable_initializer(owner);
    return ();
}

//
// Getters
//

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable_get_owner();
    return (owner,);
}

// Returns if a currency is in the system
@view
func isCurrencyWhitelisted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    currency: felt
) -> (whitelisted: felt) {
    alloc_locals;
    let (local index: Uint256) = _whitelistedCurrenciesIndex.read(currency);
    let (whitelisted) = uint256_lt(Uint256(0, 0), index);
    return (whitelisted,);
}

// View number of whitelisted currencies
@view
func whitelistedCurrenciesCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (count: Uint256) {
    alloc_locals;
    let (local count: Uint256) = _whitelistedCurrenciesCount.read();
    return (count,);
}

// View whitelisted currency address at index (index starts from 1)
@view
func whitelistedCurrency{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (currency: felt) {
    let (currency) = _whitelistedCurrencies.read(index);
    return (currency,);
}

//
// Externals
//

// Add a currency in the system
@external
func addCurrency{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(currency: felt) {
    alloc_locals;
    Ownable_only_owner();
    let (local index: Uint256) = _whitelistedCurrenciesIndex.read(currency);
    let (notWhitelisted) = uint256_eq(index, Uint256(0, 0));
    assert notWhitelisted = 1;
    let (local count: Uint256) = _whitelistedCurrenciesCount.read();
    let (local newCount: Uint256, _) = uint256_add(count, Uint256(1, 0));

    _whitelistedCurrencies.write(index=newCount, value=currency);
    _whitelistedCurrenciesIndex.write(currency=currency, value=newCount);
    _whitelistedCurrenciesCount.write(newCount);

    let (timestamp) = get_block_timestamp();
    CurrencyWhitelisted.emit(currency=currency, timestamp=timestamp);
    return ();
}

// Remove a currency from the system
@external
func removeCurrency{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    currency: felt
) {
    alloc_locals;
    Ownable_only_owner();
    let (local index: Uint256) = _whitelistedCurrenciesIndex.read(currency);
    let (whitelisted) = uint256_lt(Uint256(0, 0), index);
    assert whitelisted = 1;
    let (local count: Uint256) = _whitelistedCurrenciesCount.read();
    let (local newCount: Uint256) = uint256_sub(count, Uint256(1, 0));

    let (currencyAtLastIndex) = _whitelistedCurrencies.read(count);
    _whitelistedCurrencies.write(index=index, value=currencyAtLastIndex);
    _whitelistedCurrencies.write(index=count, value=0);
    _whitelistedCurrenciesIndex.write(currency=currency, value=Uint256(0, 0));
    _whitelistedCurrenciesCount.write(newCount);

    let (timestamp) = get_block_timestamp();
    CurrencyRemoved.emit(currency=currency, timestamp=timestamp);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
