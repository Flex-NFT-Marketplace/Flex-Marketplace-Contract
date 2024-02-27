// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt, assert_le, assert_not_zero, assert_not_equal, assert_nn, split_felt
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from contracts.marketplace.utils.reentrancyguard import ReentrancyGuard
from contracts.openzeppelin.access.ownable.library import Ownable
from contracts.openzeppelin.upgrades.library import Proxy

const WAD = 10 ** 18;

struct PoolType {
    TOKEN: felt,  // 0
    NFT: felt,    // 1
    TRADE: felt,  // 2
}

//
// Interfaces
//

@contract_interface
namespace IERC20 {
    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
}

@contract_interface
namespace IERC721 {
    func transferFrom(_from: felt, to: felt, tokenId: Uint256) {
    }
}

@contract_interface
namespace IBondingCurve {
    func validateDelta(delta: felt) -> (valid: felt) {
    }

    func validateSpotPrice(spotPrice: felt) -> (valid: felt) {
    }

    func getBuyInfo(
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
    }

    func getSellInfo(
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
    }
}

@contract_interface
namespace IPairFactory {
    func protocolFeeRecipient() -> (recipient: felt) {
    }

    func protocolFeeMultiplier() -> (multiplier: felt) {
    }
}

//
// Storage
//

@storage_var
func Pair_MAX_FEE() -> (fee: felt) {
}

@storage_var
func Pair_factory() -> (res: felt) {
}

@storage_var
func Pair_bondingCurve() -> (curve: felt) {
}

@storage_var
func Pair_nft() -> (res: felt) {
}

@storage_var
func Pair_poolType() -> (type: felt) {
}

@storage_var
func Pair_token() -> (res: felt) {
}

// The current price of the NFT
// This is generally used to mean the immediate sell price for the next marginal NFT.
// However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
// Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
@storage_var
func Pair_spotPrice() -> (price: felt) {
}

// The parameter for the pair's bonding curve.
// Units and meaning are bonding curve dependent.
@storage_var
func Pair_delta() -> (res: felt) {
}

// The spread between buy and sell prices, set to be a multiplier we apply to the buy price
// Fee is only relevant for TRADE pools
// Units are in base 1e18
@storage_var
func Pair_fee() -> (res: felt) {
}

// If set to 0, NFTs/tokens sent by traders during trades will be sent to the pair.
// Otherwise, assets will be sent to the set address. Not available for TRADE pools.
@storage_var
func Pair_assetRecipient() -> (recipient: felt) {
}

//
// Events
//

@event
func SwapNFTInPair(
    caller: felt,
    currency: felt,
    outputAmount: felt,
    collection: felt,
    nftAmount: felt,
) {
}

@event
func SwapNFTOutPair(
    caller: felt,
    currency: felt,
    inputAmount: felt,
    collection: felt,
    nftAmount: felt,
) {
}

@event
func SpotPriceUpdate(newSpotPrice: felt) {
}

@event
func TokenWithdrawal(token: felt, amount: felt) {
}

@event
func NFTWithdrawal(nft: felt) {
}

@event
func DeltaUpdate(newDelta: felt) {
}

@event
func FeeUpdate(newFee: felt) {
}

@event
func AssetRecipientChange(address: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    factory: felt,
    bondingCurve: felt,
    nft: felt,
    poolType: felt,
    token: felt,
    owner: felt,
    assetRecipient: felt,
    delta: felt,
    fee: felt,
    spotPrice: felt,
    proxy_admin: felt,
) {
    let (caller) = get_caller_address();
    with_attr error_message("caller not factory") {
        assert_not_zero(caller);
        assert_not_zero(factory);
        assert caller = factory;
    }

    Proxy.initializer(proxy_admin);

    // 90%
    Pair_MAX_FEE.write(9 / 10 * WAD);

    Pair_factory.write(factory);
    Pair_bondingCurve.write(bondingCurve);
    Pair_nft.write(nft);
    Pair_poolType.write(poolType);
    Pair_token.write(token);
    Ownable.initializer(owner);

    if (poolType != PoolType.TRADE) {
        with_attr error_message("Only Trade Pools can have nonzero fee") {
            assert fee = 0;
        }
        Pair_assetRecipient.write(assetRecipient);
    } else {
        let (max_fee) = Pair_MAX_FEE.read();
        with_attr error_message("Trade fee must be less than 90%") {
            assert_lt(fee, max_fee);
        }
        with_attr error_message("Trade pools can't set asset recipient") {
            assert assetRecipient = 0;
        }
        Pair_fee.write(fee);
    }

    let (isDeltaValid) = IBondingCurve.validateDelta(
        contract_address=bondingCurve,
        delta=delta
    );
    let (isSpotPriceValid) = IBondingCurve.validateSpotPrice(
        contract_address=bondingCurve,
        spotPrice=spotPrice
    );
    with_attr error_message("Invalid delta for curve") {
        assert isDeltaValid = TRUE;
    }
    with_attr error_message("Invalid new spot price for curve") {
        assert isSpotPriceValid = TRUE;
    }
    Pair_delta.write(delta);
    Pair_spotPrice.write(spotPrice);

    return ();
}

//
// Getters
//

@view
func MAX_FEE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    fee: felt
) {
    let (fee) = Pair_MAX_FEE.read();
    return (fee,);
}

@view
func factory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = Pair_factory.read();
    return (res,);
}

@view
func bondingCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    curve: felt
) {
    let (curve) = Pair_bondingCurve.read();
    return (curve,);
}

@view
func nft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = Pair_nft.read();
    return (res,);
}

@view
func poolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    type: felt 
) {
    let (type) = Pair_poolType.read();
    return (type,);
}

@view
func token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = Pair_token.read();
    return (res,);
}

@view
func spotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    price: felt
) {
    let (price) = Pair_spotPrice.read();
    return (price,);
}

@view
func delta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = Pair_delta.read();
    return (res,);
}

@view
func fee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = Pair_fee.read();
    return (res,);
}

@view
func assetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    recipient: felt
) {
    let (recipient) = Pair_assetRecipient.read();
    return (recipient,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner,);
}

// Used as read function to query the bonding curve for buy pricing info
// numNFTs: The number of NFTs to buy from the pair
@view
func getBuyNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    numNFTs: felt,
) -> (
    newSpotPrice: felt,
    newDelta: felt,
    inputAmount: felt,
    protocolFee: felt
) {
    assert_nn(numNFTs);

    let (_bondingCurve) = Pair_bondingCurve.read();
    let (_spotPrice) = Pair_spotPrice.read();
    let (_delta) = Pair_delta.read();
    let (_fee) = Pair_fee.read();
    let (_factory) = Pair_factory.read();
    let (multiplier) = IPairFactory.protocolFeeMultiplier(
        contract_address=_factory
    );

    let (newSpotPrice, newDelta, inputAmount, protocolFee) = IBondingCurve.getBuyInfo(
        contract_address=_bondingCurve,
        spotPrice=_spotPrice,
        delta=_delta,
        numItems=numNFTs,
        feeMultiplier=_fee,
        protocolFeeMultiplier=multiplier
    );

    assert_nn(newSpotPrice);
    assert_nn(newDelta);
    assert_nn(inputAmount);
    assert_nn(protocolFee);

    return (
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        inputAmount=inputAmount,
        protocolFee=protocolFee
    );
}

// Used as read function to query the bonding curve for sell pricing info
// numNFTs: The number of NFTs to sell to the pair
@view
func getSellNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    numNFTs: felt,
) -> (
    newSpotPrice: felt,
    newDelta: felt,
    outputAmount: felt,
    protocolFee: felt
) {
    assert_nn(numNFTs);

    let (_bondingCurve) = Pair_bondingCurve.read();
    let (_spotPrice) = Pair_spotPrice.read();
    let (_delta) = Pair_delta.read();
    let (_fee) = Pair_fee.read();
    let (_factory) = Pair_factory.read();
    let (multiplier) = IPairFactory.protocolFeeMultiplier(
        contract_address=_factory
    );

    let (newSpotPrice, newDelta, outputAmount, protocolFee) = IBondingCurve.getSellInfo(
        contract_address=_bondingCurve,
        spotPrice=_spotPrice,
        delta=_delta,
        numItems=numNFTs,
        feeMultiplier=_fee,
        protocolFeeMultiplier=multiplier
    );

    assert_nn(newSpotPrice);
    assert_nn(newDelta);
    assert_nn(outputAmount);
    assert_nn(protocolFee);

    return (
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        outputAmount=outputAmount,
        protocolFee=protocolFee
    );
}

// Returns the address that receives assets when a swap is done with this pair
// Can be set to another address by the owner, if set to address(0), defaults to the pair's own address
@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    assetRecipient: felt
) {
    let (_poolType) = Pair_poolType.read();
    let (_assetRecipient) = Pair_assetRecipient.read();
    let (self) = get_contract_address();

    // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
    // so just return address(this)
    if (_poolType == PoolType.TRADE) {
        return (assetRecipient=self);
    }

    // Otherwise, we return the recipient if it's been set
    // or replace it with address(this) if it's 0
    if (_assetRecipient == 0) {
        return (assetRecipient=self);
    }
    return (assetRecipient=_assetRecipient);
}

//
// Externals
//

@external
func swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nftIds_len: felt,
    nftIds: Uint256*,
    maxExpectedTokenInput: felt,
    nftRecipient: felt,
) -> (inputAmount: felt) {
    alloc_locals;

    ReentrancyGuard._start();

    assert_nn(maxExpectedTokenInput);

    let (_poolType) = Pair_poolType.read();
    with_attr error_message("Wrong Pool type") {
        assert (_poolType - PoolType.NFT) * (_poolType - PoolType.TRADE) = 0;
    }

    with_attr error_message("Must ask for > 0 NFTs") {
        assert_lt(0, nftIds_len);
    }

    // Call bonding curve for pricing information
    let (_bondingCurve) = Pair_bondingCurve.read();
    let (_factory) = Pair_factory.read();
    let (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
        nftIds_len,
        maxExpectedTokenInput,
        _bondingCurve,
        _factory
    );

    let (caller) = get_caller_address();
    let (_factory) = Pair_factory.read();
    _pullTokenInputAndPayProtocolFee(
        caller,
        inputAmount,
        _factory,
        protocolFee
    );

    let (_nft) = Pair_nft.read();
    _sendSpecificNFTsToRecipient(_nft, nftRecipient, nftIds_len, nftIds);

    // Do nothing since we transferred the exact input amount
    // _refundTokenToSender(inputAmount);

    let (_token) = Pair_token.read();
    SwapNFTOutPair.emit(
        caller=caller,
        currency=_token,
        inputAmount=inputAmount,
        collection=_nft,
        nftAmount=nftIds_len,
    );

    ReentrancyGuard._end();

    return (inputAmount=inputAmount);
}

@external
func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nftIds_len: felt,
    nftIds: Uint256*,
    minExpectedTokenOutput: felt,
    tokenRecipient: felt,
) -> (outputAmount: felt) {
    alloc_locals;

    ReentrancyGuard._start();

    assert_nn(minExpectedTokenOutput);

    let (_poolType) = Pair_poolType.read();
    with_attr error_message("Wrong Pool type") {
        assert (_poolType - PoolType.TOKEN) * (_poolType - PoolType.TRADE) = 0;
    }
    with_attr error_message("Must ask for > 0 NFTs") {
        assert_lt(0, nftIds_len);
    }

    // Call bonding curve for pricing information
    let (_bondingCurve) = Pair_bondingCurve.read();
    let (_factory) = Pair_factory.read();
    let (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(
        nftIds_len,
        minExpectedTokenOutput,
        _bondingCurve,
        _factory
    );

    _sendTokenOutput(tokenRecipient, outputAmount);

    let (_factory) = Pair_factory.read();
    _payProtocolFeeFromPair(_factory, protocolFee);

    let (_nft) = Pair_nft.read();
    let (caller) = get_caller_address();
    _takeNFTsFromSender(_nft, caller, nftIds_len, nftIds);

    let (_token) = Pair_token.read();
    SwapNFTInPair.emit(
        caller=caller,
        currency=_token,
        outputAmount=outputAmount,
        collection=_nft,
        nftAmount=nftIds_len,
    );

    ReentrancyGuard._end();

    return (outputAmount=outputAmount);
}

@external
func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newSpotPrice: felt
) {
    Ownable.assert_only_owner();

    assert_nn(newSpotPrice);

    let (_bondingCurve) = Pair_bondingCurve.read();
    let (isSpotPriceValid) = IBondingCurve.validateSpotPrice(
        contract_address=_bondingCurve,
        spotPrice=newSpotPrice
    );
    with_attr error_message("Invalid new spot price for curve") {
        assert isSpotPriceValid = TRUE;
    }
    Pair_spotPrice.write(newSpotPrice);

    SpotPriceUpdate.emit(newSpotPrice=newSpotPrice);
    return ();
}

@external
func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newDelta: felt
) {
    Ownable.assert_only_owner();

    assert_nn(newDelta);

    let (_bondingCurve) = Pair_bondingCurve.read();
    let (isDeltaValid) = IBondingCurve.validateDelta(
        contract_address=_bondingCurve,
        delta=newDelta
    );
    with_attr error_message("Invalid delta for curve") {
        assert isDeltaValid = TRUE;
    }
    Pair_delta.write(newDelta);

    DeltaUpdate.emit(newDelta=newDelta);
    return ();
}

@external
func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newFee: felt
) {
    Ownable.assert_only_owner();

    assert_nn(newFee);

    let (_poolType) = Pair_poolType.read();

    with_attr error_message("Only for Trade pools") {
        assert _poolType = PoolType.TRADE;
    }

    let (max_fee) = Pair_MAX_FEE.read();
    with_attr error_message("Trade fee must be less than 90%") {
        assert_lt(newFee, max_fee);
    }

    Pair_fee.write(newFee);

    FeeUpdate.emit(newFee=newFee);
    return ();
}

@external
func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newRecipient: felt
) {
    Ownable.assert_only_owner();

    assert_not_zero(newRecipient);

    let (_poolType) = Pair_poolType.read();

    with_attr error_message("Not for Trade pools") {
        assert_not_equal(_poolType, PoolType.TRADE);
    }

    Pair_assetRecipient.write(newRecipient);

    AssetRecipientChange.emit(address=newRecipient);
    return ();
}

@external
func withdrawToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    a: felt,
    amount: felt,
) {
    Ownable.assert_only_owner();

    let (owner) = Ownable.owner();
    let (high, low) = split_felt(amount);

    IERC20.transfer(
        contract_address=a,
        recipient=owner,
        amount=Uint256(low, high),
    );

    TokenWithdrawal.emit(token=a, amount=amount);
    return ();
}

@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    a: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*,
) {
    Ownable.assert_only_owner();

    assert_nn(tokenIds_len);

    if (tokenIds_len == 0) {
        NFTWithdrawal.emit(nft=a);
        return ();
    }

    let (self) = get_contract_address();
    let (owner) = Ownable.owner();

    IERC721.transferFrom(
        contract_address=a,
        _from=self,
        to=owner,
        tokenId=[tokenIds],
    );
    withdrawERC721(
        a=a,
        tokenIds_len=tokenIds_len - 1,
        tokenIds=&tokenIds[1],
    );
    return ();
}

//
// Internals
//

func _calculateBuyInfoAndUpdatePoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    numNFTs: felt,
    maxExpectedTokenInput: felt,
    _bondingCurve: felt,
    _factory: felt
) -> (
    protocolFee: felt,
    inputAmount: felt
) {
    alloc_locals;

    assert_nn(numNFTs);
    assert_nn(maxExpectedTokenInput);

    let (currentSpotPrice) = Pair_spotPrice.read();
    let (currentDelta) = Pair_delta.read();
    let (_fee) = Pair_fee.read();
    let (_protocolFeeMultiplier) = IPairFactory.protocolFeeMultiplier(
        contract_address=_factory
    );

    let (newSpotPrice, newDelta, inputAmount, protocolFee) = IBondingCurve.getBuyInfo(
        contract_address=_bondingCurve,
        spotPrice=currentSpotPrice,
        delta=currentDelta,
        numItems=numNFTs,
        feeMultiplier=_fee,
        protocolFeeMultiplier=_protocolFeeMultiplier
    );

    with_attr error_message("In too many tokens") {
        assert_le(inputAmount, maxExpectedTokenInput);
    }

    if (currentSpotPrice != newSpotPrice) {
        Pair_spotPrice.write(newSpotPrice);
        SpotPriceUpdate.emit(newSpotPrice=newSpotPrice);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    if (currentDelta != newDelta) {
        Pair_delta.write(newDelta);
        DeltaUpdate.emit(newDelta=newDelta);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return (
        protocolFee=protocolFee,
        inputAmount=inputAmount
    );
}

func _calculateSellInfoAndUpdatePoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    numNFTs: felt,
    minExpectedTokenOutput: felt,
    _bondingCurve: felt,
    _factory: felt
) -> (
    protocolFee: felt,
    outputAmount: felt
) {
    alloc_locals;

    assert_nn(numNFTs);
    assert_nn(minExpectedTokenOutput);

    let (currentSpotPrice) = Pair_spotPrice.read();
    let (currentDelta) = Pair_delta.read();
    let (_fee) = Pair_fee.read();
    let (_protocolFeeMultiplier) = IPairFactory.protocolFeeMultiplier(
        contract_address=_factory
    );

    let (newSpotPrice, newDelta, outputAmount, protocolFee) = IBondingCurve.getSellInfo(
        contract_address=_bondingCurve,
        spotPrice=currentSpotPrice,
        delta=currentDelta,
        numItems=numNFTs,
        feeMultiplier=_fee,
        protocolFeeMultiplier=_protocolFeeMultiplier
    );

    with_attr error_message("Out too little tokens") {
        assert_le(minExpectedTokenOutput, outputAmount);
    }

    if (currentSpotPrice != newSpotPrice) {
        Pair_spotPrice.write(newSpotPrice);
        SpotPriceUpdate.emit(newSpotPrice=newSpotPrice);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    if (currentDelta != newDelta) {
        Pair_delta.write(newDelta);
        DeltaUpdate.emit(newDelta=newDelta);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return (
        protocolFee=protocolFee,
        outputAmount=outputAmount
    );
}

func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt,
    inputAmount: felt,
    _factory: felt,
    protocolFee: felt
) {
    assert_nn(inputAmount);
    assert_nn(protocolFee);

    let (_token) = Pair_token.read();
    let (_assetRecipient) = getAssetRecipient();
    let (_protocolFeeRecipient) = IPairFactory.protocolFeeRecipient(
        contract_address=_factory
    );
    let (high, low) = split_felt(inputAmount - protocolFee);

    IERC20.transferFrom(
        contract_address=_token,
        sender=_from,
        recipient=_assetRecipient,
        amount=Uint256(low, high),
    );

    if (protocolFee != 0) {
        IERC20.transferFrom(
            contract_address=_token,
            sender=_from,
            recipient=_protocolFeeRecipient,
            amount=Uint256(protocolFee, 0),
        );
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _factory: felt,
    protocolFee: felt
) {
    alloc_locals;

    assert_nn(protocolFee);

    let (self) = get_contract_address();
    let (_token) = Pair_token.read();
    let (_protocolFeeRecipient) = IPairFactory.protocolFeeRecipient(
        contract_address=_factory
    );
    let (pairTokenBalance) = IERC20.balanceOf(
        contract_address=_token,
        account=self
    );
    let (condition) = uint256_lt(pairTokenBalance, Uint256(protocolFee, 0));
    local finalProtocolFee;
    if (condition == 1) {
        finalProtocolFee = pairTokenBalance.low;
    } else {
        finalProtocolFee = protocolFee;
    }

    if (finalProtocolFee != 0) {
        IERC20.transfer(
            contract_address=_token,
            recipient=_protocolFeeRecipient,
            amount=Uint256(finalProtocolFee, 0),
        );
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenRecipient: felt,
    outputAmount: felt
) {
    assert_nn(outputAmount);

    let (_token) = Pair_token.read();
    let (high, low) = split_felt(outputAmount);

    if (outputAmount != 0) {
        IERC20.transfer(
            contract_address=_token,
            recipient=tokenRecipient,
            amount=Uint256(low, high),
        );
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _nft: felt,
    nftRecipient: felt,
    nftIds_len: felt,
    nftIds: Uint256*
) {
    assert_nn(nftIds_len);

    if (nftIds_len == 0) {
        return ();
    }

    let (self) = get_contract_address();

    IERC721.transferFrom(
        contract_address=_nft,
        _from=self,
        to=nftRecipient,
        tokenId=[nftIds],
    );
    _sendSpecificNFTsToRecipient(
        _nft=_nft,
        nftRecipient=nftRecipient,
        nftIds_len=nftIds_len - 1,
        nftIds=&nftIds[1],
    );
    return ();
}

func _takeNFTsFromSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _nft: felt,
    _from: felt,
    nftIds_len: felt,
    nftIds: Uint256*
) {
    assert_nn(nftIds_len);

    if (nftIds_len == 0) {
        return ();
    }

    let (_assetRecipient) = getAssetRecipient();

    IERC721.transferFrom(
        contract_address=_nft,
        _from=_from,
        to=_assetRecipient,
        tokenId=[nftIds],
    );
    _takeNFTsFromSender(
        _nft=_nft,
        _from=_from,
        nftIds_len=nftIds_len - 1,
        nftIds=&nftIds[1],
    );
    return ();
}
