%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

from contracts.marketplace.utils.OrderTypes import MakerOrder, TakerOrder

//
// StrategyPrivateSale
//
// Strategy to set up an order that can only be executed by
// a specific address
//

//
// Storage
//

// 200 = 2%, 500 = 5%
@storage_var
func _protocolFee() -> (fee: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fee: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    _protocolFee.write(fee);
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
func protocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (fee: felt) {
    let (fee) = _protocolFee.read();
    return (fee,);
}

// Check whether a taker ask order can be executed against a maker bid
// It cannot execute but it is left for compatibility purposes with the interface
@view
func canExecuteTakerAsk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerAsk: TakerOrder, makerBid: MakerOrder, extraParams_len: felt, extraParams: felt*
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    return (0, Uint256(0, 0), 0);
}

// Check whether a taker bid order can be executed against a maker ask
@view
func canExecuteTakerBid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerBid: TakerOrder, makerAsk: MakerOrder
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    alloc_locals;

    // Target buyer match
    assert makerAsk.params = takerBid.taker;

    local priceMatch;
    if (makerAsk.price == takerBid.price) {
        priceMatch = 1;
    } else {
        priceMatch = 0;
    }
    let (tokenIdMatch) = uint256_eq(makerAsk.tokenId, takerBid.tokenId);
    let (timestamp) = get_block_timestamp();
    let startTimeValid = is_le(makerAsk.startTime, timestamp);
    let endTimeValid = is_le(timestamp, makerAsk.endTime);
    local canExecute;
    if (priceMatch + tokenIdMatch + startTimeValid + endTimeValid == 4) {
        canExecute = 1;
    } else {
        canExecute = 0;
    }
    return (canExecute, makerAsk.tokenId, makerAsk.amount);
}

//
// Externals
//

// Update protocol fee
@external
func updateProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(fee: felt) {
    Ownable_only_owner();
    _protocolFee.write(fee);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
