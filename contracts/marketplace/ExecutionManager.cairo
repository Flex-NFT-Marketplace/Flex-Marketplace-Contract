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
// ExecutionManager
//
// Allows adding/removing of execution strategies for trading on the marketplace
//

//
// Storage
//

@storage_var
func _whitelistedStrategiesCount() -> (count: Uint256) {
}

@storage_var
func _whitelistedStrategies(index: Uint256) -> (strategy: felt) {
}

@storage_var
func _whitelistedStrategiesIndex(strategy: felt) -> (index: Uint256) {
}

//
// Events
//

@event
func StrategyRemoved(strategy: felt, timestamp: felt) {
}

@event
func StrategyWhitelisted(strategy: felt, timestamp: felt) {
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

// Returns if an execution strategy is in the system
@view
func isStrategyWhitelisted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    strategy: felt
) -> (whitelisted: felt) {
    alloc_locals;
    let (local index: Uint256) = _whitelistedStrategiesIndex.read(strategy);
    let (whitelisted) = uint256_lt(Uint256(0, 0), index);
    return (whitelisted,);
}

// View number of whitelisted strategies
@view
func whitelistedStrategiesCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (count: Uint256) {
    alloc_locals;
    let (local count: Uint256) = _whitelistedStrategiesCount.read();
    return (count,);
}

// View whitelisted strategy address at index (index starts from 1)
@view
func whitelistedStrategy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (strategy: felt) {
    let (strategy) = _whitelistedStrategies.read(index);
    return (strategy,);
}

//
// Externals
//

// Add an execution strategy in the system
@external
func addStrategy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(strategy: felt) {
    alloc_locals;
    Ownable_only_owner();
    let (local index: Uint256) = _whitelistedStrategiesIndex.read(strategy);
    let (notWhitelisted) = uint256_eq(index, Uint256(0, 0));
    assert notWhitelisted = 1;
    let (local count: Uint256) = _whitelistedStrategiesCount.read();
    let (local newCount: Uint256, _) = uint256_add(count, Uint256(1, 0));

    _whitelistedStrategies.write(index=newCount, value=strategy);
    _whitelistedStrategiesIndex.write(strategy=strategy, value=newCount);
    _whitelistedStrategiesCount.write(newCount);

    let (timestamp) = get_block_timestamp();
    StrategyWhitelisted.emit(strategy=strategy, timestamp=timestamp);
    return ();
}

// Remove an execution strategy from the system
@external
func removeStrategy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    strategy: felt
) {
    alloc_locals;
    Ownable_only_owner();
    let (local index: Uint256) = _whitelistedStrategiesIndex.read(strategy);
    let (whitelisted) = uint256_lt(Uint256(0, 0), index);
    assert whitelisted = 1;
    let (local count: Uint256) = _whitelistedStrategiesCount.read();
    let (local newCount: Uint256) = uint256_sub(count, Uint256(1, 0));

    let (strategyAtLastIndex) = _whitelistedStrategies.read(count);
    _whitelistedStrategies.write(index=index, value=strategyAtLastIndex);
    _whitelistedStrategies.write(index=count, value=0);
    _whitelistedStrategiesIndex.write(strategy=strategy, value=Uint256(0, 0));
    _whitelistedStrategiesCount.write(newCount);

    let (timestamp) = get_block_timestamp();
    StrategyRemoved.emit(strategy=strategy, timestamp=timestamp);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
