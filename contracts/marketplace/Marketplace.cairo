%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt, assert_le, unsigned_div_rem, assert_nn
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

from contracts.marketplace.utils.OrderTypes import MakerOrder, TakerOrder

from contracts.marketplace.utils.reentrancyguard import ReentrancyGuard

//
// Marketplace
//
// Core contract of the marketplace
//

//
// Interfaces
//

@contract_interface
namespace IExecutionStrategy {
    func protocolFee() -> (fee: felt) {
    }

    func canExecuteTakerAsk(takerAsk: TakerOrder, makerBid: MakerOrder, extraParams_len: felt, extraParams: felt*) -> (
        canExecute: felt, tokenId: Uint256, amount: felt
    ) {
    }

    func canExecuteTakerBid(takerBid: TakerOrder, makerAsk: MakerOrder) -> (
        canExecute: felt, tokenId: Uint256, amount: felt
    ) {
    }
}

@contract_interface
namespace IAuctionStrategy {
    func auctionRelayer() -> (relayer: felt) {
    }

    func canExecuteAuctionSale(makerAsk: MakerOrder, makerBid: MakerOrder) -> (
        canExecute: felt, tokenId: Uint256, amount: felt
    ) {
    }
}

@contract_interface
namespace ISignatureChecker {
    func computeMakerOrderHash(hashDomain: felt, order: MakerOrder) -> (hash: felt) {
    }

    func verifyMakerOrderSignature(hashDomain: felt, order: MakerOrder, orderSignature_len: felt, orderSignature: felt*) {
    }
}

@contract_interface
namespace ICurrencyManager {
    func isCurrencyWhitelisted(currency: felt) -> (whitelisted: felt) {
    }
}

@contract_interface
namespace IExecutionManager {
    func isStrategyWhitelisted(strategy: felt) -> (whitelisted: felt) {
    }
}

@contract_interface
namespace IRoyaltyFeeManager {
    func calculateRoyaltyFeeAndGetRecipient(collection: felt, tokenId: Uint256, amount: felt) -> (
        receiver: felt, royaltyAmount: felt
    ) {
    }
}

@contract_interface
namespace IERC20 {
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) {
    }
}

@contract_interface
namespace ITransferSelectorNFT {
    func checkTransferManagerForToken(collection: felt) -> (manager: felt) {
    }
}

@contract_interface
namespace ITransferManagerNFT {
    func transferNonFungibleToken(
        collection: felt, _from: felt, to: felt, tokenId: Uint256, amount: felt
    ) {
    }
}

//
// Storage
//

@storage_var
func _hashDomain() -> (hash: felt) {
}

@storage_var
func _protocolFeeRecipient() -> (recipient: felt) {
}

@storage_var
func _currencyManager() -> (manager: felt) {
}

@storage_var
func _executionManager() -> (manager: felt) {
}

@storage_var
func _royaltyFeeManager() -> (manager: felt) {
}

@storage_var
func _transferSelectorNFT() -> (selector: felt) {
}

@storage_var
func _signatureChecker() -> (checker: felt) {
}

@storage_var
func _userMinOrderNonce(user: felt) -> (nonce: felt) {
}

@storage_var
func _isUserOrderNonceExecutedOrCancelled(user: felt, nonce: felt) -> (executedOrCancelled: felt) {
}

//
// Events
//

@event
func CancelAllOrders(user: felt, newMinNonce: felt, timestamp: felt) {
}

@event
func CancelOrder(user: felt, orderNonce: felt, timestamp: felt) {
}

@event
func NewHashDomain(hash: felt, timestamp: felt) {
}

@event
func NewProtocolFeeRecipient(recipient: felt, timestamp: felt) {
}

@event
func NewCurrencyManager(manager: felt, timestamp: felt) {
}

@event
func NewExecutionManager(manager: felt, timestamp: felt) {
}

@event
func NewRoyaltyFeeManager(manager: felt, timestamp: felt) {
}

@event
func NewTransferSelectorNFT(selector: felt, timestamp: felt) {
}

@event
func NewSignatureChecker(checker: felt, timestamp: felt) {
}

@event
func RoyaltyPayment(
    collection: felt,
    tokenId: Uint256,
    royaltyRecipient: felt,
    currency: felt,
    amount: felt,
    timestamp: felt,
) {
}

@event
func TakerAsk(
    orderHash: felt,
    orderNonce: felt,
    taker: felt,
    maker: felt,
    strategy: felt,
    currency: felt,
    collection: felt,
    tokenId: Uint256,
    amount: felt,
    price: felt,
    timestamp: felt,
) {
}

@event
func TakerBid(
    orderHash: felt,
    orderNonce: felt,
    taker: felt,
    maker: felt,
    strategy: felt,
    currency: felt,
    collection: felt,
    tokenId: Uint256,
    amount: felt,
    price: felt,
    originalTaker: felt,
    timestamp: felt,
) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    hash: felt,
    recipient: felt,
    currency: felt,
    execution: felt,
    feeManager: felt,
    checker: felt,
    owner: felt,
    proxy_admin: felt,
) {
    Proxy.initializer(proxy_admin);
    _hashDomain.write(hash);
    _protocolFeeRecipient.write(recipient);
    _currencyManager.write(currency);
    _executionManager.write(execution);
    _royaltyFeeManager.write(feeManager);
    _signatureChecker.write(checker);
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
func hashDomain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (hash: felt) {
    let (hash) = _hashDomain.read();
    return (hash,);
}

@view
func protocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    recipient: felt
) {
    let (recipient) = _protocolFeeRecipient.read();
    return (recipient,);
}

@view
func currencyManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    manager: felt
) {
    let (manager) = _currencyManager.read();
    return (manager,);
}

@view
func executionManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    manager: felt
) {
    let (manager) = _executionManager.read();
    return (manager,);
}

@view
func royaltyFeeManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    manager: felt
) {
    let (manager) = _royaltyFeeManager.read();
    return (manager,);
}

@view
func transferSelectorNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    selector: felt
) {
    let (selector) = _transferSelectorNFT.read();
    return (selector,);
}

@view
func signatureChecker{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    checker: felt
) {
    let (checker) = _signatureChecker.read();
    return (checker,);
}

@view
func userMinOrderNonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user: felt
) -> (nonce: felt) {
    let (nonce) = _userMinOrderNonce.read(user);
    return (nonce,);
}

@view
func isUserOrderNonceExecutedOrCancelled{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(user: felt, nonce: felt) -> (executedOrCancelled: felt) {
    let (executedOrCancelled) = _isUserOrderNonceExecutedOrCancelled.read(user=user, nonce=nonce);
    return (executedOrCancelled,);
}

//
// Externals
//

// Cancel all pending orders for a sender
@external
func cancelAllOrdersForSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    minNonce: felt
) {
    let (caller) = get_caller_address();
    let (currentMinNonce) = _userMinOrderNonce.read(caller);
    assert_lt(currentMinNonce, minNonce);
    assert_lt(minNonce, currentMinNonce + 500000);
    _userMinOrderNonce.write(user=caller, value=minNonce);

    let (timestamp) = get_block_timestamp();
    CancelAllOrders.emit(user=caller, newMinNonce=minNonce, timestamp=timestamp);
    return ();
}

// Cancel maker order
@external
func cancelMakerOrder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    orderNonce: felt
) {
    let (caller) = get_caller_address();
    let (currentMinNonce) = _userMinOrderNonce.read(caller);
    assert_le(currentMinNonce, orderNonce);
    _isUserOrderNonceExecutedOrCancelled.write(user=caller, nonce=orderNonce, value=1);

    let (timestamp) = get_block_timestamp();
    CancelOrder.emit(user=caller, orderNonce=orderNonce, timestamp=timestamp);
    return ();
}

// Match a takerBid with a makerAsk
@external
func matchAskWithTakerBid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerBid: TakerOrder, makerAsk: MakerOrder, makerAskSignature_len: felt, makerAskSignature: felt*, customNonFungibleTokenRecipient: felt
) {
    alloc_locals;
    ReentrancyGuard._start();

    assert makerAsk.isOrderAsk = 1;
    assert takerBid.isOrderAsk = 0;
    let (caller) = get_caller_address();
    assert_not_zero(caller);
    assert caller = takerBid.taker;

    // Validate the maker ask order
    _validateOrder(makerAsk, makerAskSignature_len, makerAskSignature);

    let (canExecute, tokenId, amount) = IExecutionStrategy.canExecuteTakerBid(
        contract_address=makerAsk.strategy, takerBid=takerBid, makerAsk=makerAsk
    );

    assert canExecute = 1;

    _isUserOrderNonceExecutedOrCancelled.write(user=makerAsk.signer, nonce=makerAsk.nonce, value=1);

    // Execution part 1/2
    _transferFeesAndFunds(
        strategy=makerAsk.strategy,
        collection=makerAsk.collection,
        tokenId=tokenId,
        currency=makerAsk.currency,
        _from=takerBid.taker,
        to=makerAsk.signer,
        amount=takerBid.price,
        minPercentageToAsk=makerAsk.minPercentageToAsk,
    );

    // Execution part 2/2
    local nonFungibleTokenRecipient;
    if (customNonFungibleTokenRecipient == 0) {
        nonFungibleTokenRecipient = takerBid.taker;
    } else {
        nonFungibleTokenRecipient = customNonFungibleTokenRecipient;
    }

    _transferNonFungibleToken(
        collection=makerAsk.collection,
        _from=makerAsk.signer,
        to=nonFungibleTokenRecipient,
        tokenId=tokenId,
        amount=amount,
    );

    let (checker) = signatureChecker();
    let (hash) = hashDomain();
    let (orderHash) = ISignatureChecker.computeMakerOrderHash(
        contract_address=checker, hashDomain=hash, order=makerAsk
    );
    let (timestamp) = get_block_timestamp();
    TakerBid.emit(
        orderHash=orderHash,
        orderNonce=makerAsk.nonce,
        taker=nonFungibleTokenRecipient,
        maker=makerAsk.signer,
        strategy=makerAsk.strategy,
        currency=makerAsk.currency,
        collection=makerAsk.collection,
        tokenId=tokenId,
        amount=amount,
        price=takerBid.price,
        originalTaker=takerBid.taker,
        timestamp=timestamp,
    );

    ReentrancyGuard._end();
    return ();
}

// Match a takerAsk with a makerBid
@external
func matchBidWithTakerAsk{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    takerAsk: TakerOrder, makerBid: MakerOrder, makerBidSignature_len: felt, makerBidSignature: felt*, extraParams_len: felt, extraParams: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();

    assert makerBid.isOrderAsk = 0;
    assert takerAsk.isOrderAsk = 1;
    let (caller) = get_caller_address();
    assert_not_zero(caller);
    assert caller = takerAsk.taker;

    // Validate the maker bid order
    _validateOrder(makerBid, makerBidSignature_len, makerBidSignature);

    let (canExecute, tokenId, amount) = IExecutionStrategy.canExecuteTakerAsk(
        contract_address=makerBid.strategy, takerAsk=takerAsk, makerBid=makerBid, extraParams_len=extraParams_len, extraParams=extraParams
    );

    assert canExecute = 1;

    _isUserOrderNonceExecutedOrCancelled.write(user=makerBid.signer, nonce=makerBid.nonce, value=1);

    // Execution part 1/2
    _transferNonFungibleToken(
        collection=makerBid.collection,
        _from=takerAsk.taker,
        to=makerBid.signer,
        tokenId=tokenId,
        amount=amount,
    );

    // Execution part 2/2
    _transferFeesAndFunds(
        strategy=makerBid.strategy,
        collection=makerBid.collection,
        tokenId=tokenId,
        currency=makerBid.currency,
        _from=makerBid.signer,
        to=takerAsk.taker,
        amount=takerAsk.price,
        minPercentageToAsk=takerAsk.minPercentageToAsk,
    );

    let (checker) = signatureChecker();
    let (hash) = hashDomain();
    let (orderHash) = ISignatureChecker.computeMakerOrderHash(
        contract_address=checker, hashDomain=hash, order=makerBid
    );
    let (timestamp) = get_block_timestamp();
    TakerAsk.emit(
        orderHash=orderHash,
        orderNonce=makerBid.nonce,
        taker=takerAsk.taker,
        maker=makerBid.signer,
        strategy=makerBid.strategy,
        currency=makerBid.currency,
        collection=makerBid.collection,
        tokenId=tokenId,
        amount=amount,
        price=takerAsk.price,
        timestamp=timestamp,
    );

    ReentrancyGuard._end();
    return ();
}

// Execute auction sale (can only be called by auctionRelayer)
@external
func executeAuctionSale{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    makerAsk: MakerOrder, makerAskSignature_len: felt, makerAskSignature: felt*, makerBid: MakerOrder, makerBidSignature_len: felt, makerBidSignature: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();

    assert makerAsk.isOrderAsk = 1;
    assert makerBid.isOrderAsk = 0;
    let (caller) = get_caller_address();
    let (relayer) = IAuctionStrategy.auctionRelayer(contract_address=makerAsk.strategy);

    assert_not_zero(caller);
    assert caller = relayer;

    _validateOrder(makerAsk, makerAskSignature_len, makerAskSignature);
    _validateOrder(makerBid, makerBidSignature_len, makerBidSignature);

    let (canExecute, tokenId, amount) = IAuctionStrategy.canExecuteAuctionSale(
        contract_address=makerAsk.strategy, makerAsk=makerAsk, makerBid=makerBid
    );

    assert canExecute = 1;

    _isUserOrderNonceExecutedOrCancelled.write(user=makerAsk.signer, nonce=makerAsk.nonce, value=1);
    _isUserOrderNonceExecutedOrCancelled.write(user=makerBid.signer, nonce=makerBid.nonce, value=1);

    // Execution part 1/2
    _transferFeesAndFunds(
        strategy=makerAsk.strategy,
        collection=makerAsk.collection,
        tokenId=tokenId,
        currency=makerAsk.currency,
        _from=makerBid.signer,
        to=makerAsk.signer,
        amount=makerBid.price,
        minPercentageToAsk=makerAsk.minPercentageToAsk,
    );

    // Execution part 2/2
    _transferNonFungibleToken(
        collection=makerAsk.collection,
        _from=makerAsk.signer,
        to=makerBid.signer,
        tokenId=tokenId,
        amount=amount,
    );

    let (checker) = signatureChecker();
    let (hash) = hashDomain();
    let (orderHash) = ISignatureChecker.computeMakerOrderHash(
        contract_address=checker, hashDomain=hash, order=makerAsk
    );
    let (timestamp) = get_block_timestamp();
    TakerBid.emit(
        orderHash=orderHash,
        orderNonce=makerAsk.nonce,
        taker=makerBid.signer,
        maker=makerAsk.signer,
        strategy=makerAsk.strategy,
        currency=makerAsk.currency,
        collection=makerAsk.collection,
        tokenId=tokenId,
        amount=amount,
        price=makerBid.price,
        originalTaker=makerBid.signer,
        timestamp=timestamp,
    );

    ReentrancyGuard._end();
    return ();
}

@external
func updateHashDomain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) {
    Ownable_only_owner();
    _hashDomain.write(hash);

    let (timestamp) = get_block_timestamp();
    NewHashDomain.emit(hash=hash, timestamp=timestamp);
    return ();
}

@external
func updateProtocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt
) {
    Ownable_only_owner();
    _protocolFeeRecipient.write(recipient);

    let (timestamp) = get_block_timestamp();
    NewProtocolFeeRecipient.emit(recipient=recipient, timestamp=timestamp);
    return ();
}

@external
func updateCurrencyManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    manager: felt
) {
    Ownable_only_owner();
    assert_not_zero(manager);
    _currencyManager.write(manager);

    let (timestamp) = get_block_timestamp();
    NewCurrencyManager.emit(manager=manager, timestamp=timestamp);
    return ();
}

@external
func updateExecutionManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    manager: felt
) {
    Ownable_only_owner();
    assert_not_zero(manager);
    _executionManager.write(manager);

    let (timestamp) = get_block_timestamp();
    NewExecutionManager.emit(manager=manager, timestamp=timestamp);
    return ();
}

@external
func updateRoyaltyFeeManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    manager: felt
) {
    Ownable_only_owner();
    assert_not_zero(manager);
    _royaltyFeeManager.write(manager);

    let (timestamp) = get_block_timestamp();
    NewRoyaltyFeeManager.emit(manager=manager, timestamp=timestamp);
    return ();
}

@external
func updateTransferSelectorNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt
) {
    Ownable_only_owner();
    assert_not_zero(selector);
    _transferSelectorNFT.write(selector);

    let (timestamp) = get_block_timestamp();
    NewTransferSelectorNFT.emit(selector=selector, timestamp=timestamp);
    return ();
}

@external
func updateSignatureChecker{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    checker: felt
) {
    Ownable_only_owner();
    assert_not_zero(checker);
    _signatureChecker.write(checker);

    let (timestamp) = get_block_timestamp();
    NewSignatureChecker.emit(checker=checker, timestamp=timestamp);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}

//
// Internals
//

// Transfer fees and funds to royalty recipient, protocol, and seller
func _transferFeesAndFunds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    strategy: felt,
    collection: felt,
    tokenId: Uint256,
    currency: felt,
    _from: felt,
    to: felt,
    amount: felt,
    minPercentageToAsk: felt,
) {
    alloc_locals;

    assert_nn(amount);

    // 1. Protocol fee
    let (protocolFeeAmount) = _calculateProtocolFee(strategy, amount);
    assert_nn(protocolFeeAmount);
    let (recipient) = protocolFeeRecipient();
    let amountNotZero = is_not_zero(protocolFeeAmount);
    let recipientNotZero = is_not_zero(recipient);
    if (amountNotZero + recipientNotZero == 2) {
        IERC20.transferFrom(
            contract_address=currency,
            sender=_from,
            recipient=recipient,
            amount=Uint256(protocolFeeAmount, 0),
        );

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // 2. Royalty fee
    let (manager) = royaltyFeeManager();
    let (recipient, royaltyAmount) = IRoyaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(
        contract_address=manager, collection=collection, tokenId=tokenId, amount=amount
    );
    assert_nn(royaltyAmount);
    let amountNotZero = is_not_zero(royaltyAmount);
    let recipientNotZero = is_not_zero(recipient);
    if (amountNotZero + recipientNotZero == 2) {
        IERC20.transferFrom(
            contract_address=currency,
            sender=_from,
            recipient=recipient,
            amount=Uint256(royaltyAmount, 0),
        );

        let (timestamp) = get_block_timestamp();
        RoyaltyPayment.emit(
            collection=collection,
            tokenId=tokenId,
            royaltyRecipient=recipient,
            currency=currency,
            amount=royaltyAmount,
            timestamp=timestamp,
        );

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // 3. Transfer final amount (post-fees) to seller
    IERC20.transferFrom(
        contract_address=currency,
        sender=_from,
        recipient=to,
        amount=Uint256(amount - protocolFeeAmount - royaltyAmount, 0),
    );

    return ();
}

// Transfer NFT
func _transferNonFungibleToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, _from: felt, to: felt, tokenId: Uint256, amount: felt
) {
    assert_nn(amount);

    let (selector) = transferSelectorNFT();
    let (manager) = ITransferSelectorNFT.checkTransferManagerForToken(
        contract_address=selector, collection=collection
    );
    assert_not_zero(manager);
    ITransferManagerNFT.transferNonFungibleToken(
        contract_address=manager,
        collection=collection,
        _from=_from,
        to=to,
        tokenId=tokenId,
        amount=amount,
    );
    return ();
}

// Calculate protocol fee for an execution strategy
func _calculateProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    executionStrategy: felt, amount: felt
) -> (feeAmount: felt) {
    let (fee) = IExecutionStrategy.protocolFee(contract_address=executionStrategy);
    let (feeAmount, remainder) = unsigned_div_rem(amount * fee, 10000);
    return (feeAmount,);
}

// Verify the validity of the maker order
func _validateOrder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    order: MakerOrder, orderSignature_len: felt, orderSignature: felt*
) {
    alloc_locals;

    // Verify whether order nonce has expired
    let (executedOrCancelled) = isUserOrderNonceExecutedOrCancelled(
        user=order.signer, nonce=order.nonce
    );
    let (minNonce) = userMinOrderNonce(user=order.signer);
    assert executedOrCancelled = 0;
    assert_le(minNonce, order.nonce);

    assert_not_zero(order.signer);
    assert_lt(0, order.amount);

    // Verify the validity of the signature
    let (checker) = signatureChecker();
    let (hash) = hashDomain();
    ISignatureChecker.verifyMakerOrderSignature(
        contract_address=checker, hashDomain=hash, order=order, orderSignature_len=orderSignature_len, orderSignature=orderSignature
    );

    // Verify whether the currency is whitelisted
    let (manager) = currencyManager();
    let (currencyWhitelisted) = ICurrencyManager.isCurrencyWhitelisted(
        contract_address=manager, currency=order.currency
    );
    assert currencyWhitelisted = 1;

    // Verify whether strategy can be executed
    let (manager) = executionManager();
    let (strategyWhitelisted) = IExecutionManager.isStrategyWhitelisted(
        contract_address=manager, strategy=order.strategy
    );
    assert strategyWhitelisted = 1;

    return ();
}
