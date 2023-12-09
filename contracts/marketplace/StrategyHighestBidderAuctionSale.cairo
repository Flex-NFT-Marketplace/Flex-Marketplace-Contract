%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_lt, assert_le
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

//
// StrategyHighestBidderAuctionSale
//
// Strategy that executes a timed auction sale
// to the highest bidder with an option to set a reserve price.
// Auction ends without a sale if there are no bids equal to or greater than reserve price.
// Any bids made in the last 10 minutes of an auction will extend each auction by 10 more minutes.
// Hence, makerAsk.endTime has a buffer of +7 days (604,800 seconds).
//

//
// Storage
//

// 200 = 2%, 500 = 5%
@storage_var
func _protocolFee() -> (fee: felt) {
}

// Auction relayer wallet address to facilitate sale completion.
// `canExecuteAuctionSale` transactions can only be completed by the relayer.
// Relayer calls the `executeAuctionSale` function on the Marketplace contract.
@storage_var
func _auctionRelayer() -> (relayer: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fee: felt, relayer: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    _protocolFee.write(fee);
    _auctionRelayer.write(relayer);
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
func auctionRelayer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    relayer: felt
) {
    let (relayer) = _auctionRelayer.read();
    return (relayer,);
}

// Check whether a taker ask order can be executed against a maker bid
@view
func canExecuteTakerAsk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerAsk: TakerOrder, makerBid: MakerOrder, extraParams_len: felt, extraParams: felt*
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    alloc_locals;
    local priceMatch;
    if (makerBid.price == takerAsk.price) {
        priceMatch = 1;
    } else {
        priceMatch = 0;
    }
    let (tokenIdMatch) = uint256_eq(makerBid.tokenId, takerAsk.tokenId);
    let (timestamp) = get_block_timestamp();
    let startTimeValid = is_le(makerBid.startTime, timestamp);
    let endTimeValid = is_le(timestamp, makerBid.endTime);
    local canExecute;
    if (priceMatch + tokenIdMatch + startTimeValid + endTimeValid == 4) {
        canExecute = 1;
    } else {
        canExecute = 0;
    }
    return (canExecute, makerBid.tokenId, makerBid.amount);
}

// Check whether an auction sale can be executed
@view
func canExecuteAuctionSale{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    makerAsk: MakerOrder, makerBid: MakerOrder
) -> (canExecute: felt, tokenId: Uint256, amount: felt) {
    alloc_locals;

    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=makerAsk.signer, y=makerAsk.nonce);
    assert makerBid.params = hash;
    assert makerAsk.collection = makerBid.collection;
    assert makerAsk.amount = makerBid.amount;
    assert makerAsk.strategy = makerBid.strategy;
    assert makerAsk.currency = makerBid.currency;

    // Starting price = makerAsk.price
    // Reserve price = makerAsk.params (if any)
    let reservePriceIsZero = is_nn_le(makerAsk.params, 0);

    if (reservePriceIsZero == 1) {
        // makerBid.price >= Starting price
        assert_le(makerAsk.price, makerBid.price);
    } else {
        // Reserve price > Starting price
        // makerBid.price >= Reserve price
        assert_lt(makerAsk.price, makerAsk.params);
        assert_le(makerAsk.params, makerBid.price);
    }

    let (tokenIdMatch) = uint256_eq(makerAsk.tokenId, makerBid.tokenId);
    let (timestamp) = get_block_timestamp();
    let makerAskStartTimeValid = is_le(makerAsk.startTime, timestamp);
    let makerAskEndTimeValid = is_le(timestamp, makerAsk.endTime);
    let makerBidStartTimeValid = is_le(makerBid.startTime, timestamp);
    let makerBidEndTimeValid = is_le(timestamp, makerBid.endTime);

    local canExecute;
    if (tokenIdMatch + makerAskStartTimeValid + makerAskEndTimeValid + makerBidStartTimeValid + makerBidEndTimeValid == 5) {
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

// Update auction relayer
@external
func updateAuctionRelayer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    relayer: felt
) {
    Ownable_only_owner();
    _auctionRelayer.write(relayer);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
