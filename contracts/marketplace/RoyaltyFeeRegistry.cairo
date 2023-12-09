%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

//
// RoyaltyFeeRegistry
//
// Royalty fee registry for the marketplace
//

//
// Storage
//

struct FeeInfo {
    setter: felt,
    receiver: felt,
    fee: felt,
}

// 500 = 5%, 1,000 = 10%
@storage_var
func _royaltyFeeLimit() -> (feeLimit: felt) {
}

@storage_var
func _royaltyFeeInfoCollection(collection: felt) -> (feeInfo: FeeInfo) {
}

//
// Events
//

@event
func NewRoyaltyFeeLimit(feeLimit: felt, timestamp: felt) {
}

@event
func RoyaltyFeeUpdate(collection: felt, setter: felt, receiver: felt, fee: felt, timestamp: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    feeLimit: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    assert_le(feeLimit, 9500);
    _royaltyFeeLimit.write(feeLimit);
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

@view
func royaltyFeeLimit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    feeLimit: felt
) {
    let (feeLimit) = _royaltyFeeLimit.read();
    return (feeLimit,);
}

// Calculate royalty info for a collection sale
@view
func royaltyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, amount: felt
) -> (receiver: felt, royaltyAmount: felt) {
    let (feeInfo) = _royaltyFeeInfoCollection.read(collection);
    let (royaltyAmount, remainder) = unsigned_div_rem(amount * feeInfo.fee, 10000);
    return (feeInfo.receiver, royaltyAmount);
}

// View royalty info for a collection
@view
func royaltyFeeInfoCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt
) -> (setter: felt, receiver: felt, fee: felt) {
    let (feeInfo) = _royaltyFeeInfoCollection.read(collection);
    return (feeInfo.setter, feeInfo.receiver, feeInfo.fee);
}

//
// Externals
//

// Update royalty fee limit
@external
func updateRoyaltyFeeLimit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    feeLimit: felt
) {
    Ownable_only_owner();
    assert_le(feeLimit, 9500);
    _royaltyFeeLimit.write(feeLimit);
    let (timestamp) = get_block_timestamp();
    NewRoyaltyFeeLimit.emit(feeLimit=feeLimit, timestamp=timestamp);
    return ();
}

// Update royalty info for collection
@external
func updateRoyaltyInfoForCollection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(collection: felt, setter: felt, receiver: felt, fee: felt) {
    Ownable_only_owner();
    let (feeLimit) = royaltyFeeLimit();
    assert_le(fee, feeLimit);
    _royaltyFeeInfoCollection.write(
        collection=collection,
        value=FeeInfo(
        setter=setter,
        receiver=receiver,
        fee=fee
        ),
    );
    let (timestamp) = get_block_timestamp();
    RoyaltyFeeUpdate.emit(
        collection=collection, setter=setter, receiver=receiver, fee=fee, timestamp=timestamp
    );
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
