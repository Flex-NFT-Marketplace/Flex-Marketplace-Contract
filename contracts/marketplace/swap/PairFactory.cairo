// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, assert_not_zero, assert_nn, split_felt
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address, deploy
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.access.ownable.library import Ownable
from contracts.openzeppelin.upgrades.library import Proxy

const WAD = 10 ** 18;

//
// Interfaces
//

@contract_interface
namespace IERC20 {
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) {
    }
}

@contract_interface
namespace IERC721 {
    func transferFrom(_from: felt, to: felt, tokenId: Uint256) {
    }
}

@contract_interface
namespace IPair {
    func token() -> (address: felt) {
    }

    func nft() -> (address: felt) {
    }

    func owner() -> (address: felt) {
    }
}

//
// Storage
//

@storage_var
func PairFactory_MAX_PROTOCOL_FEE() -> (fee: felt) {
}

@storage_var
func PairFactory_proxyClassHash() -> (proxyClass: felt) {
}

@storage_var
func PairFactory_pairClassHash() -> (pairClass: felt) {
}

@storage_var
func PairFactory_protocolFeeRecipient() -> (recipient: felt) {
}

@storage_var
func PairFactory_protocolFeeMultiplier() -> (multiplier: felt) {
}

@storage_var
func PairFactory_bondingCurveAllowed(curve: felt) -> (allowed: felt) {
}

@storage_var
func PairFactory_currencyAllowed(currency: felt) -> (allowed: felt) {
}

//
// Events
//

@event
func NewPair(poolAddress: felt) {
}

@event
func TokenDeposit(poolAddress: felt) {
}

@event
func NFTDeposit(poolAddress: felt) {
}

@event
func ProxyClassHashUpdate(proxyClass: felt) {
}

@event
func PairClassHashUpdate(pairClass: felt) {
}

@event
func ProtocolFeeRecipientUpdate(recipientAddress: felt) {
}

@event
func ProtocolFeeMultiplierUpdate(newMultiplier: felt) {
}

@event
func BondingCurveStatusUpdate(bondingCurve: felt, isAllowed: felt) {
}

@event
func CurrencyStatusUpdate(currency: felt, isAllowed: felt) {
}

@event
func ContractDeployed(
    address: felt,
    deployer: felt,
    unique: felt,
    classHash: felt,
    calldata_len: felt,
    calldata: felt*,
    salt: felt
) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxyClass: felt,
    pairClass: felt,
    recipient: felt,
    multiplier: felt,
    owner: felt,
    proxy_admin: felt,
) {
    Proxy.initializer(proxy_admin);

    // 10%
    PairFactory_MAX_PROTOCOL_FEE.write(1 / 10 * WAD);

    PairFactory_proxyClassHash.write(proxyClass);
    PairFactory_pairClassHash.write(pairClass);
    PairFactory_protocolFeeRecipient.write(recipient);

    assert_nn(multiplier);
    let (max_protocol_fee) = PairFactory_MAX_PROTOCOL_FEE.read();
    with_attr error_message("Fee too large") {
        assert_le(multiplier, max_protocol_fee);
    }
    PairFactory_protocolFeeMultiplier.write(multiplier);

    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

@view
func MAX_PROTOCOL_FEE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    fee: felt
) {
    let (fee) = PairFactory_MAX_PROTOCOL_FEE.read();
    return (fee,);
}

@view
func proxyClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    proxyClass: felt
) {
    let (proxyClass) = PairFactory_proxyClassHash.read();
    return (proxyClass,);
}

@view
func pairClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    pairClass: felt
) {
    let (pairClass) = PairFactory_pairClassHash.read();
    return (pairClass,);
}

@view
func protocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    recipient: felt
) {
    let (recipient) = PairFactory_protocolFeeRecipient.read();
    return (recipient,);
}

@view
func protocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    multiplier: felt
) {
    let (multiplier) = PairFactory_protocolFeeMultiplier.read();
    return (multiplier,);
}

@view
func bondingCurveAllowed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(curve: felt) -> (allowed: felt) {
    let (allowed) = PairFactory_bondingCurveAllowed.read(curve=curve);
    return (allowed,);
}

@view
func currencyAllowed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(currency: felt) -> (allowed: felt) {
    let (allowed) = PairFactory_currencyAllowed.read(currency=currency);
    return (allowed,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner,);
}

//
// Externals
//

@external
func createPairERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt,
    nft: felt,
    bondingCurve: felt,
    assetRecipient: felt,
    poolType: felt,
    delta: felt,
    fee: felt,
    spotPrice: felt,
    initialNFTIDs_len: felt,
    initialNFTIDs: Uint256*,
    initialTokenBalance: felt,
    salt: felt
) -> (pair: felt) {
    alloc_locals;

    assert_nn(delta);
    assert_nn(fee);
    assert_nn(spotPrice);

    let (currencyWhitelisted) = PairFactory_currencyAllowed.read(token);
    with_attr error_message("Currency not whitelisted") {
        assert currencyWhitelisted = 1;
    }

    let (bondingCurveWhitelisted) = PairFactory_bondingCurveAllowed.read(bondingCurve);
    with_attr error_message("Bonding curve not whitelisted") {
        assert bondingCurveWhitelisted = 1;
    }

    let (proxyClass) = proxyClassHash();
    let (pairClass) = pairClassHash();
    let (timestamp) = get_block_timestamp();
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=salt, y=timestamp);
    let (self) = get_contract_address();
    let (caller) = get_caller_address();
    let (proxyAdmin) = owner();

    let (local calldata: felt*) = alloc();
    assert calldata[0] = pairClass;
    // get_selector_from_name('initializer')
    assert calldata[1] = 0x2dd76e7ad84dbed81c314ffe5e7a7cacfb8f4836f01af4e913f275f89a3de1a;
    // length of subsequent elements in calldata
    assert calldata[2] = 11;
    // factory = self
    assert calldata[3] = self;
    assert calldata[4] = bondingCurve;
    assert calldata[5] = nft;
    assert calldata[6] = poolType;
    assert calldata[7] = token;
    // pair owner = caller
    assert calldata[8] = caller;
    assert calldata[9] = assetRecipient;
    assert calldata[10] = delta;
    assert calldata[11] = fee;
    assert calldata[12] = spotPrice;
    assert calldata[13] = proxyAdmin;

    // Deploy pair
    let (pair) = deploy(
        class_hash=proxyClass,
        contract_address_salt=hash,
        constructor_calldata_size=14,
        constructor_calldata=calldata,
        deploy_from_zero=FALSE,
    );

    ContractDeployed.emit(
        address=pair,
        deployer=self,
        unique=TRUE,
        classHash=proxyClass,
        calldata_len=14,
        calldata=calldata,
        salt=hash
    );

    // Transfer initial tokens to pair
    if (initialTokenBalance != 0) {
        _depositToken(token, caller, pair, initialTokenBalance);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // Transfer initial NFTs from sender to pair
    if (initialNFTIDs_len != 0) {
        _depositNFTs(nft, caller, pair, initialNFTIDs_len, initialNFTIDs);
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr : felt* = syscall_ptr;
        tempvar pedersen_ptr : HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    NewPair.emit(poolAddress=pair);

    return (pair=pair);
}

@external
func depositToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pair: felt,
    amount: felt,
) {
    let (caller) = get_caller_address();
    let (token) = IPair.token(contract_address=pair);
    let (pairOwner) = IPair.owner(contract_address=pair);

    with_attr error_message("caller not owner of pair") {
        assert caller = pairOwner;
    }

    _depositToken(token, caller, pair, amount);
    return ();
}

@external
func depositNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pair: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*,
) {
    with_attr error_message("tokenIds cannot be empty") {
        assert_nn_le(1, tokenIds_len);
    }

    let (caller) = get_caller_address();
    let (nft) = IPair.nft(contract_address=pair);
    let (pairOwner) = IPair.owner(contract_address=pair);

    with_attr error_message("caller not owner of pair") {
        assert caller = pairOwner;
    }

    _depositNFTs(nft, caller, pair, tokenIds_len, tokenIds);
    return ();
}

@external
func setProxyClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxyClass: felt
) {
    Ownable.assert_only_owner();
    assert_not_zero(proxyClass);
    PairFactory_proxyClassHash.write(proxyClass);
    ProxyClassHashUpdate.emit(proxyClass=proxyClass);
    return ();
}

@external
func setPairClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    pairClass: felt
) {
    Ownable.assert_only_owner();
    assert_not_zero(pairClass);
    PairFactory_pairClassHash.write(pairClass);
    PairClassHashUpdate.emit(pairClass=pairClass);
    return ();
}

@external
func setProtocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt
) {
    Ownable.assert_only_owner();
    assert_not_zero(recipient);
    PairFactory_protocolFeeRecipient.write(recipient);
    ProtocolFeeRecipientUpdate.emit(recipientAddress=recipient);
    return ();
}

@external
func setProtocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    multiplier: felt
) {
    Ownable.assert_only_owner();
    assert_nn(multiplier);
    let (max_protocol_fee) = PairFactory_MAX_PROTOCOL_FEE.read();
    with_attr error_message("Fee too large") {
        assert_le(multiplier, max_protocol_fee);
    }
    PairFactory_protocolFeeMultiplier.write(multiplier);
    ProtocolFeeMultiplierUpdate.emit(newMultiplier=multiplier);
    return ();
}

@external
func setBondingCurveAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    curve: felt, isAllowed: felt
) {
    Ownable.assert_only_owner();
    PairFactory_bondingCurveAllowed.write(curve=curve, value=isAllowed);
    BondingCurveStatusUpdate.emit(bondingCurve=curve, isAllowed=isAllowed);
    return ();
}

@external
func setCurrencyAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    currency: felt, isAllowed: felt
) {
    Ownable.assert_only_owner();
    PairFactory_currencyAllowed.write(currency=currency, value=isAllowed);
    CurrencyStatusUpdate.emit(currency=currency, isAllowed=isAllowed);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

//
// Internals
//

func _depositToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt,
    sender: felt,
    recipient: felt,
    amount: felt,
) {
    let (high, low) = split_felt(amount);
    IERC20.transferFrom(
        contract_address=token,
        sender=sender,
        recipient=recipient,
        amount=Uint256(low, high),
    );
    TokenDeposit.emit(poolAddress=recipient);
    return ();
}

func _depositNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft: felt,
    sender: felt,
    recipient: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*,
) {
    assert_nn(tokenIds_len);

    if (tokenIds_len == 0) {
        NFTDeposit.emit(poolAddress=recipient);
        return ();
    }

    IERC721.transferFrom(
        contract_address=nft,
        _from=sender,
        to=recipient,
        tokenId=[tokenIds],
    );
    _depositNFTs(
        nft=nft,
        sender=sender,
        recipient=recipient,
        tokenIds_len=tokenIds_len - 1,
        tokenIds=&tokenIds[1],
    );
    return ();
}
