// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import (
    assert_nn,
    assert_nn_le,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_le

const WAD = 10 ** 18;

@view
func validateDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    delta: felt,
) -> (valid: felt) {
    // For a linear curve, all values of delta are valid
    return (TRUE,);
}

@view
func validateSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spotPrice: felt,
) -> (valid: felt) {
    // For a linear curve, all values of spot price are valid
    return (TRUE,);
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
    with_attr error_message("Swap: numItems has to be more than zero") {
        assert_nn_le(1, numItems);
    }

    assert_nn(spotPrice);
    assert_nn(delta);

    // For a linear curve, the spot price increases by delta for each item bought
    let newSpotPrice = spotPrice + delta * numItems;
    assert_nn(newSpotPrice);

    // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
    // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
    // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
    // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
    // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
    // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
    let buySpotPrice = spotPrice + delta;

    // If we buy n items, then the total cost is equal to:
    // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
    // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
    // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
    let inputValue = numItems * buySpotPrice + (numItems * (numItems - 1) * delta) / 2;

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

    // We first calculate the change in spot price after selling all of the items
    local totalPriceDecrease = delta * numItems;

    // If the current spot price is less than the total amount that the spot price should change by...
    local newSpotPrice;
    local newNumItems;
    let lessThan = is_le(spotPrice, totalPriceDecrease - 1);
    if (lessThan == TRUE) {
        // Then we set the new spot price to be 0. (Spot price is never negative)
        newSpotPrice = 0;

        // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
        let (divValue, divRemainder) = unsigned_div_rem(spotPrice, delta);
        newNumItems = divValue + 1;
    } else {
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems

        // The new spot price is just the change between spot price and the total price change
        newSpotPrice = spotPrice - totalPriceDecrease;
        newNumItems = numItems;
    }

    // If we sell n items, then the total sale amount is:
    // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
    // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
    let outputValue = newNumItems * spotPrice - (newNumItems * (newNumItems - 1) * delta) / 2;

    // Account for the protocol fee, a flat percentage of the sell amount
    let (protocolFee, protocolFeeRemainder) = unsigned_div_rem(outputValue * protocolFeeMultiplier, WAD);

    // Account for the trade fee, only for Trade pools
    let (fee, feeRemainder) = unsigned_div_rem(outputValue * feeMultiplier, WAD);

    let finalOutputValue = outputValue - protocolFee - fee;

    return (newSpotPrice, delta, finalOutputValue, protocolFee);
}
