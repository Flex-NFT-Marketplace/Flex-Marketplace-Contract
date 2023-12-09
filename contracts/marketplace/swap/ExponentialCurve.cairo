// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import (
    assert_nn,
    assert_nn_le,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_le, is_nn_le

const WAD = 10 ** 18;
const MIN_PRICE = 10 ** 9;

func compute_pow{range_check_ptr}(spot: felt, delta: felt, c: felt) -> felt {
    if (c == 0) {
        return spot;
    }
    let (new_spot, _) = unsigned_div_rem(spot * delta, WAD);
    return compute_pow(new_spot, delta, c - 1);
}

func compute_inv_pow{range_check_ptr}(spot: felt, delta: felt, c: felt) -> felt {
    if (c == 0) {
        return spot;
    }
    let (new_spot, _) = unsigned_div_rem(spot * WAD, delta);
    return compute_inv_pow(new_spot, delta, c - 1);
}

@view
func validateDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    delta: felt,
) -> (valid: felt) {
    if (is_le(delta, WAD) == TRUE) {
        return (FALSE,);
    }
    return (TRUE,);
}

@view
func validateSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spotPrice: felt,
) -> (valid: felt) {
    return (is_nn_le(MIN_PRICE, spotPrice),);
}

@view
func getBuyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spotPrice: felt,
    delta: felt,
    numItems: felt,
    feeMultiplier: felt,
    protocolFeeMultiplier: felt,
) -> (
    newSpotPrice: felt,
    newDelta: felt,
    inputValue: felt,
    protocolFee: felt,
) {
    alloc_locals;

    with_attr error_message("Swap: numItems has to be more than zero") {
        assert_nn_le(1, numItems);
    }

    assert_nn(spotPrice);
    assert_nn(delta);

    let newSpotPrice = compute_pow(spotPrice, delta, numItems);

    // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
    // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
    // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S * delta).
    // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
    // If spot price for buy and sell differ by delta, then buying costs (S * delta) ETH.
    // The new spot price would become (S * delta), so selling would also yield (S * delta) ETH.
    let buySpotPrice = compute_pow(spotPrice, delta, 1);

    // If the user buys n items, then the total cost is equal to:
    // buySpotPrice + (delta * buySpotPrice) + (delta^2 * buySpotPrice) + ... (delta^(numItems - 1) * buySpotPrice)
    // This is equal to buySpotPrice * (delta^n - 1) / (delta - 1)
    local inputValue;
    if (numItems == 1) {
        inputValue = buySpotPrice;
    } else {
        let totalBuySpotPrice = compute_pow(buySpotPrice, delta, numItems);
        let (value, remainder) = unsigned_div_rem(
            (totalBuySpotPrice - buySpotPrice) * WAD, delta - WAD
        );
        inputValue = value;
    }

    // Account for the protocol fee, a flat percentage of the buy amount
    let (protocolFee, protocolFeeRemainder) = unsigned_div_rem(inputValue * protocolFeeMultiplier, WAD);

    // Account for the trade fee, only for Trade pools
    let (fee, feeRemainder) = unsigned_div_rem(inputValue * feeMultiplier, WAD);

    let finalInputValue = inputValue + protocolFee + fee;

    return (newSpotPrice, delta, finalInputValue, protocolFee);
}

@view
func getSellInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spotPrice: felt,
    delta: felt,
    numItems: felt,
    feeMultiplier: felt,
    protocolFeeMultiplier: felt,
) -> (
    newSpotPrice: felt,
    newDelta: felt,
    outputValue: felt,
    protocolFee: felt,
) {
    alloc_locals;

    with_attr error_message("Swap: numItems has to be more than zero") {
        assert_nn_le(1, numItems);
    }

    assert_nn(spotPrice);
    assert_nn(delta);

    // For an exponential curve, the spot price is divided by delta for each item sold
    // safe to convert newSpotPrice directly into uint128 since we know newSpotPrice <= spotPrice
    // and spotPrice <= type(uint128).max
    let newSpotPrice = compute_inv_pow(spotPrice, delta, numItems);

    // If the user sells n items, then the total revenue is equal to:
    // spotPrice + ((1 / delta) * spotPrice) + ((1 / delta)^2 * spotPrice) + ... ((1 / delta)^(numItems - 1) * spotPrice)
    // This is equal to spotPrice * (1 - (1 / delta^n)) / (1 - (1 / delta))
    local outputValue;
    if (numItems == 1) {
        outputValue = spotPrice;
    } else {
        let (value, remainder) = unsigned_div_rem(
            (spotPrice - newSpotPrice) * delta, delta - WAD
        );
        outputValue = value;
    }

    // Account for the protocol fee, a flat percentage of the sell amount
    let (protocolFee, protocolFeeRemainder) = unsigned_div_rem(outputValue * protocolFeeMultiplier, WAD);

    // Account for the trade fee, only for Trade pools
    let (fee, feeRemainder) = unsigned_div_rem(outputValue * feeMultiplier, WAD);

    let finalOutputValue = outputValue - protocolFee - fee;

    return (newSpotPrice, delta, finalOutputValue, protocolFee);
}
