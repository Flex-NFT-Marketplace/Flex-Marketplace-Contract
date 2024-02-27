%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math_cmp import is_le, is_nn_le
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

from contracts.marketplace.utils.merkle import merkle_verify

//
// StrategyAnyItemFromCollectionForFixedPrice
//
// Strategy to send an order at a fixed price that can be
// matched by any tokenId for the collection
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

@view
func computeHash{pedersen_ptr: HashBuiltin*, range_check_ptr}(low: felt, high: felt) -> (
    hash: felt
) {
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=low, y=high);
    return (hash,);
}

@view
func merkleVerify{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    leaf: Uint256, root: felt, proof_len: felt, proof: felt*
) -> (verified: felt) {
    let (hash) = computeHash(leaf.low, leaf.high);
    let (verified) = merkle_verify(hash, root, proof_len, proof);
    return (verified,);
}

// Check whether a taker ask order can be executed against a maker bid
@view
func canExecuteTakerAsk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerAsk: TakerOrder, makerBid: MakerOrder, extraParams_len: felt, extraParams: felt*
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    alloc_locals;

    let makerBidParamsIsZero = is_nn_le(makerBid.params, 0);
    let (verified) = merkleVerify(
        leaf=takerAsk.tokenId,
        root=makerBid.params,
        proof_len=extraParams_len,
        proof=extraParams,
    );
    let makerBidParamsIsZeroOrMerkleVerified = is_le(1, makerBidParamsIsZero + verified);

    local priceMatch;
    if (makerBid.price == takerAsk.price) {
        priceMatch = 1;
    } else {
        priceMatch = 0;
    }

    let (timestamp) = get_block_timestamp();
    let startTimeValid = is_le(makerBid.startTime, timestamp);
    let endTimeValid = is_le(timestamp, makerBid.endTime);
    local canExecute;
    if (makerBidParamsIsZeroOrMerkleVerified + priceMatch + startTimeValid + endTimeValid == 4) {
        canExecute = 1;
    } else {
        canExecute = 0;
    }
    return (canExecute, takerAsk.tokenId, makerBid.amount);
}

// Check whether a taker bid order can be executed against a maker ask
// It cannot execute but it is left for compatibility purposes with the interface
@view
func canExecuteTakerBid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerBid: TakerOrder, makerAsk: MakerOrder
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    return (0, Uint256(0, 0), 0);
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
