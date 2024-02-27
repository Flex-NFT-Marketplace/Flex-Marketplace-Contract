// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
    assert_nn,
    assert_nn_le,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from contracts.openzeppelin.access.ownable.library import Ownable
from contracts.marketplace.utils.reentrancyguard import ReentrancyGuard
from contracts.marketplace.utils.merkle import merkle_verify
from contracts.openzeppelin.upgrades.library import Proxy

// Sale status
const NOT_STARTED_OR_PAUSED = 0;
const WHITELIST_SALE_STARTED = 1;
const PUBLIC_SALE_STARTED = 10;

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
    func totalSupply() -> (totalSupply: Uint256) {
    }

    func mint(to: felt) {
    }
}

//
// Storage
//

@storage_var
func Minter_collection() -> (collection: felt) {
}

@storage_var
func Minter_currency() -> (currency: felt) {
}

@storage_var
func Minter_sale_status() -> (status: felt) {
}

@storage_var
func Minter_max_supply() -> (max_supply: felt) {
}

@storage_var
func Minter_mint_price_whitelist() -> (price: felt) {
}

@storage_var
func Minter_mint_price_public() -> (price: felt) {
}

// only used during whitelist sale
@storage_var
func Minter_merkle_root_whitelist() -> (merkle_root: felt) {
}

// only used during public sale
@storage_var
func Minter_max_mint_per_account() -> (max_mint: felt) {
}

// only used during public sale
@storage_var
func Minter_account_max_mint_exclude_whitelist() -> (exclude: felt) {
}

@storage_var
func Minter_max_mint_per_call_whitelist() -> (max_mint: felt) {
}

@storage_var
func Minter_max_mint_per_call_public() -> (max_mint: felt) {
}

@storage_var
func Minter_num_minted_whitelist(account: felt) -> (num_minted: felt) {
}

@storage_var
func Minter_num_minted_total(account: felt) -> (num_minted: felt) {
}

@storage_var
func Minter_sale_recipient() -> (recipient: felt) {
}

@storage_var
func Minter_fee_recipient() -> (recipient: felt) {
}

@storage_var
func Minter_fee() -> (fee: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt,
    currency: felt,
    max_supply: felt,
    mint_price_whitelist: felt,
    mint_price_public: felt,
    merkle_root_whitelist: felt,
    max_mint_per_account: felt,
    account_max_mint_exclude_whitelist: felt,
    max_mint_per_call_whitelist: felt,
    max_mint_per_call_public: felt,
    sale_recipient: felt,
    fee_recipient: felt,
    fee: felt,
    owner: felt,
    proxy_admin: felt,
) {
    Proxy.initializer(proxy_admin);
    Minter_collection.write(collection);
    Minter_currency.write(currency);
    Minter_max_supply.write(max_supply);
    Minter_mint_price_whitelist.write(mint_price_whitelist);
    Minter_mint_price_public.write(mint_price_public);
    Minter_merkle_root_whitelist.write(merkle_root_whitelist);
    Minter_max_mint_per_account.write(max_mint_per_account);
    Minter_account_max_mint_exclude_whitelist.write(account_max_mint_exclude_whitelist);
    Minter_max_mint_per_call_whitelist.write(max_mint_per_call_whitelist);
    Minter_max_mint_per_call_public.write(max_mint_per_call_public);
    Minter_sale_recipient.write(sale_recipient);
    Minter_fee_recipient.write(fee_recipient);
    Minter_fee.write(fee);
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

@view
func collection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collection: felt
) {
    let (collection) = Minter_collection.read();
    return (collection,);
}

@view
func currency{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    currency: felt
) {
    let (currency) = Minter_currency.read();
    return (currency,);
}

@view
func saleStatus{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    status: felt
) {
    let (status) = Minter_sale_status.read();
    return (status,);
}

@view
func maxSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    maxSupply: felt
) {
    let (maxSupply) = Minter_max_supply.read();
    return (maxSupply,);
}

@view
func mintPriceWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    price: felt
) {
    let (price) = Minter_mint_price_whitelist.read();
    return (price,);
}

@view
func mintPricePublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    price: felt
) {
    let (price) = Minter_mint_price_public.read();
    return (price,);
}

@view
func merkleRootWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    merkleRoot: felt
) {
    let (merkleRoot) = Minter_merkle_root_whitelist.read();
    return (merkleRoot,);
}

@view
func maxMintPerAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    maxMint: felt
) {
    let (maxMint) = Minter_max_mint_per_account.read();
    return (maxMint,);
}

@view
func accountMaxMintExcludeWhitelist{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> (exclude: felt) {
    let (exclude) = Minter_account_max_mint_exclude_whitelist.read();
    return (exclude,);
}

@view
func maxMintPerCallWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    maxMint: felt
) {
    let (maxMint) = Minter_max_mint_per_call_whitelist.read();
    return (maxMint,);
}

@view
func maxMintPerCallPublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    maxMint: felt
) {
    let (maxMint) = Minter_max_mint_per_call_public.read();
    return (maxMint,);
}

@view
func numMintedWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (numMinted: felt) {
    let (numMinted) = Minter_num_minted_whitelist.read(account);
    return (numMinted,);
}

@view
func numMintedTotal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (numMinted: felt) {
    let (numMinted) = Minter_num_minted_total.read(account);
    return (numMinted,);
}

@view
func saleRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    recipient: felt
) {
    let (recipient) = Minter_sale_recipient.read();
    return (recipient,);
}

@view
func feeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    recipient: felt
) {
    let (recipient) = Minter_fee_recipient.read();
    return (recipient,);
}

@view
func fee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (fee: felt) {
    let (fee) = Minter_fee.read();
    return (fee,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner,);
}

@view
func computeHash{pedersen_ptr: HashBuiltin*, range_check_ptr}(x: felt, y: felt) -> (hash: felt) {
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=x, y=y);
    return (hash,);
}

@view
func merkleVerify{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, maxMint: felt, merkleRoot: felt, proof_len: felt, proof: felt*
) -> (verified: felt) {
    let (hash) = computeHash(account, maxMint);
    let (verified) = merkle_verify(hash, merkleRoot, proof_len, proof);
    return (verified,);
}

//
// Externals
//

@external
func setCollection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newCollection: felt
) {
    Ownable.assert_only_owner();
    Minter_collection.write(newCollection);
    return ();
}

@external
func setCurrency{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newCurrency: felt
) {
    Ownable.assert_only_owner();
    Minter_currency.write(newCurrency);
    return ();
}

@external
func startWhitelistSale{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Minter_sale_status.write(WHITELIST_SALE_STARTED);
    return ();
}

@external
func startPublicSale{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Minter_sale_status.write(PUBLIC_SALE_STARTED);
    return ();
}

@external
func pauseSale{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Minter_sale_status.write(NOT_STARTED_OR_PAUSED);
    return ();
}

@external
func setMaxSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newMaxSupply: felt
) {
    Ownable.assert_only_owner();
    Minter_max_supply.write(newMaxSupply);
    return ();
}

@external
func setMintPriceWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newPrice: felt
) {
    Ownable.assert_only_owner();
    Minter_mint_price_whitelist.write(newPrice);
    return ();
}

@external
func setMintPricePublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newPrice: felt
) {
    Ownable.assert_only_owner();
    Minter_mint_price_public.write(newPrice);
    return ();
}

@external
func setMerkleRootWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newMerkleRoot: felt
) {
    Ownable.assert_only_owner();
    Minter_merkle_root_whitelist.write(newMerkleRoot);
    return ();
}

@external
func setMaxMintPerAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newMaxMint: felt
) {
    Ownable.assert_only_owner();
    Minter_max_mint_per_account.write(newMaxMint);
    return ();
}

@external
func excludeWhitelistForAccountMaxMint{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    Ownable.assert_only_owner();
    Minter_account_max_mint_exclude_whitelist.write(TRUE);
    return ();
}

@external
func includeWhitelistForAccountMaxMint{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    Ownable.assert_only_owner();
    Minter_account_max_mint_exclude_whitelist.write(FALSE);
    return ();
}

@external
func setMaxMintPerCallWhitelist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newMaxMint: felt
) {
    Ownable.assert_only_owner();
    Minter_max_mint_per_call_whitelist.write(newMaxMint);
    return ();
}

@external
func setMaxMintPerCallPublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newMaxMint: felt
) {
    Ownable.assert_only_owner();
    Minter_max_mint_per_call_public.write(newMaxMint);
    return ();
}

@external
func setSaleRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newRecipient: felt
) {
    Ownable.assert_only_owner();
    Minter_sale_recipient.write(newRecipient);
    return ();
}

@external
func setFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newRecipient: felt
) {
    Ownable.assert_only_owner();
    Minter_fee_recipient.write(newRecipient);
    return ();
}

@external
func setFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newFee: felt) {
    Ownable.assert_only_owner();
    Minter_fee.write(newFee);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    numMint: felt, maxMintPerAccountWhitelist: felt, proof_len: felt, proof: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();

    let (_collection) = Minter_collection.read();
    let (status) = Minter_sale_status.read();
    let (caller) = get_caller_address();
    let (numMinted) = IERC721.totalSupply(contract_address=_collection);
    let (maxMint) = Minter_max_supply.read();

    with_attr error_message("Minter: collection is not set") {
        assert_not_zero(_collection);
    }

    with_attr error_message("Minter: sale is not active") {
        assert_not_zero(status);
    }

    with_attr error_message("Minter: caller is the zero address") {
        assert_not_zero(caller);
    }

    with_attr error_message("Minter: number to mint has to be more than zero") {
        assert_nn_le(1, numMint);
    }

    assert_nn(maxMintPerAccountWhitelist);

    with_attr error_message("Minter: max supply is not set") {
        assert_not_zero(maxMint);
    }

    with_attr error_message("Minter: exceeds max supply") {
        assert_le(numMinted.low + numMint, maxMint);
    }

    let (maxMintPerAccountPublic) = Minter_max_mint_per_account.read();
    let (excludeWhitelist) = Minter_account_max_mint_exclude_whitelist.read();
    let (_maxMintPerCallWhitelist) = Minter_max_mint_per_call_whitelist.read();
    let (_maxMintPerCallPublic) = Minter_max_mint_per_call_public.read();
    let (accountNumMintedWhitelist) = Minter_num_minted_whitelist.read(caller);
    let (accountNumMintedTotal) = Minter_num_minted_total.read(caller);

    if (status == WHITELIST_SALE_STARTED) {
        let (merkleRoot) = Minter_merkle_root_whitelist.read();
        let (verified) = merkleVerify(
            account=caller,
            maxMint=maxMintPerAccountWhitelist,
            merkleRoot=merkleRoot,
            proof_len=proof_len,
            proof=proof,
        );
        with_attr error_message("Minter: verification failed") {
            assert verified = TRUE;
        }

        with_attr error_message("Minter: exceeds max mint per account") {
            assert_le(accountNumMintedWhitelist + numMint, maxMintPerAccountWhitelist);
        }

        with_attr error_message("Minter: exceeds max mint per call") {
            assert_le(numMint, _maxMintPerCallWhitelist);
        }

        Minter_num_minted_whitelist.write(
            account=caller, value=accountNumMintedWhitelist + numMint
        );
        Minter_num_minted_total.write(account=caller, value=accountNumMintedTotal + numMint);

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    local condition;
    condition = status + excludeWhitelist;

    // status == PUBLIC_SALE_STARTED and excludeWhitelist == TRUE
    if (condition == 11) {
        with_attr error_message("Minter: exceeds max mint per account") {
            assert_le(
                accountNumMintedTotal - accountNumMintedWhitelist + numMint, maxMintPerAccountPublic
            );
        }

        with_attr error_message("Minter: exceeds max mint per call") {
            assert_le(numMint, _maxMintPerCallPublic);
        }

        Minter_num_minted_total.write(account=caller, value=accountNumMintedTotal + numMint);

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // status == PUBLIC_SALE_STARTED and excludeWhitelist == FALSE
    if (condition == 10) {
        with_attr error_message("Minter: exceeds max mint per account") {
            assert_le(accountNumMintedTotal + numMint, maxMintPerAccountPublic);
        }

        with_attr error_message("Minter: exceeds max mint per call") {
            assert_le(numMint, _maxMintPerCallPublic);
        }

        Minter_num_minted_total.write(account=caller, value=accountNumMintedTotal + numMint);

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    local mintPrice;
    local totalPrice;
    let (_mintPriceWhitelist) = Minter_mint_price_whitelist.read();
    let (_mintPricePublic) = Minter_mint_price_public.read();
    if (status == WHITELIST_SALE_STARTED) {
        mintPrice = _mintPriceWhitelist;
    } else {
        mintPrice = _mintPricePublic;
    }
    totalPrice = mintPrice * numMint;
    let (_currency) = Minter_currency.read();
    let (_saleRecipient) = Minter_sale_recipient.read();
    let (_feeRecipient) = Minter_fee_recipient.read();
    let (_fee) = Minter_fee.read();
    let (feeAmount, remainder) = unsigned_div_rem(totalPrice * _fee, 10000);

    let amountNotZero = is_not_zero(feeAmount);
    let recipientNotZero = is_not_zero(_feeRecipient);
    if (amountNotZero + recipientNotZero == 2) {
        IERC20.transferFrom(
            contract_address=_currency,
            sender=caller,
            recipient=_feeRecipient,
            amount=Uint256(feeAmount, 0),
        );

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let amountNotZero = is_not_zero(totalPrice - feeAmount);
    let recipientNotZero = is_not_zero(_saleRecipient);
    if (amountNotZero + recipientNotZero == 2) {
        IERC20.transferFrom(
            contract_address=_currency,
            sender=caller,
            recipient=_saleRecipient,
            amount=Uint256(totalPrice - feeAmount, 0),
        );

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    _mintBatch(to=caller, numMint=numMint);

    ReentrancyGuard._end();
    return ();
}

@external
func premint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, numMint: felt
) {
    Ownable.assert_only_owner();
    _mintBatch(to=to, numMint=numMint);
    return ();
}

//
// Private
//

func _mintBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, numMint: felt
) {
    assert_nn(numMint);

    if (numMint == 0) {
        return ();
    }

    let (collection) = Minter_collection.read();
    IERC721.mint(contract_address=collection, to=to);
    _mintBatch(to=to, numMint=numMint - 1);
    return ();
}
