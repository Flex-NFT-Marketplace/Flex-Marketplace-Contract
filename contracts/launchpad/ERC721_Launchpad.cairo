%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_check,
    uint256_add,
)
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.memcpy import memcpy

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

from immutablex.starknet.auxiliary.erc2981.unidirectional_mutable import (
    ERC2981_UniDirectional_Mutable,
)

from ERC721_Metadata_base import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setBaseTokenURI,
)

from utils.merkle import merkle_verify

//
// Storage
//

// @storage_var
// func Token_URI(index: felt) -> (uri: felt) {
// }

// @storage_var
// func Token_uri_len_() -> (uri_len: felt) {
// }

@storage_var
func Contract_URI(index: felt) -> (uri: felt) {
}

@storage_var
func Contract_uri_len_() -> (uri_len: felt) {
}

@storage_var
func freemint_has_claimed(leaf: felt) -> (freemint_claimed: Uint256) {
}

@storage_var
func whitelist_has_claimed(leaf: felt) -> (whitelist_claimed: Uint256) {
}

@storage_var
func og_has_claimed(leaf: felt) -> (og_claimed: felt) {
}

@storage_var
func max_supply() -> (supply: Uint256) {
}

@storage_var
func next_token() -> (token_id: Uint256) {
}

@storage_var
func sale_phase() -> (phase: felt) {
}

@storage_var
func eth_token_address() -> (eth_address: felt) {
}

@storage_var
func recipient_address() -> (sale_recipient: felt) {
}

@storage_var
func freemint_max_supply() -> (freemint_supply: Uint256) {
}

@storage_var
func freemint_merkle_root() -> (freemint_root: felt) {
}

@storage_var
func whitelist_max_supply() -> (whitelist_supply: Uint256) {
}

@storage_var
func whitelist_price() -> (whitelist_price_amount: Uint256) {
}

@storage_var
func whitelist_merkle_root() -> (whitelist_root: felt) {
}

@storage_var
func og_max_supply() -> (og_supply: Uint256) {
}

@storage_var
func og_price() -> (og_price_amount: Uint256) {
}

@storage_var
func og_merkle_root() -> (og_root: felt) {
}

@storage_var
func publicmint_max_supply() -> (publicmint_supply: Uint256) {
}

@storage_var
func publicmint_price() -> (publicmint_price_amount: Uint256) {
}

@storage_var
func owner_address() -> (owner_contract_address: felt) {
}

@storage_var
func call_once() -> (called: felt) {
}

//
// Constructor
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    symbol: felt,
    owner_contract: felt,
    collection_number: Uint256,
    freemint_number_limit: Uint256,
    freemint_root: felt,
    og_number_limit: Uint256,
    og_root: felt,
    og_mint_price: Uint256,
    whitelist_number_limit: Uint256,
    whitelist_root: felt,
    whitelist_mint_price: Uint256,
    publicmint_number_limit: Uint256,
    publicmint_mint_price: Uint256,
    eth_contract_address: felt,
    sale_recipient_address: felt,
    default_royalty_receiver: felt,
    default_royalty_fee_basis_points: felt,
    proxy_admin: felt,
) {
    let (called: felt) = call_once.read();
    assert called = 0;
    ERC721.initializer(name, symbol);
    Proxy.initializer(proxy_admin);
    ERC721Enumerable.initializer();
    ERC721_Metadata_initializer();
    Ownable.initializer(owner_contract);
    ERC2981_UniDirectional_Mutable.initializer(
        default_royalty_receiver, default_royalty_fee_basis_points
    );
    max_supply.write(collection_number);

    freemint_max_supply.write(freemint_number_limit);
    freemint_merkle_root.write(value=freemint_root);

    whitelist_max_supply.write(whitelist_number_limit);
    whitelist_price.write(whitelist_mint_price);
    whitelist_merkle_root.write(value=whitelist_root);

    og_max_supply.write(og_number_limit);
    og_price.write(og_mint_price);
    og_merkle_root.write(value=og_root);

    publicmint_max_supply.write(publicmint_number_limit);
    publicmint_price.write(publicmint_mint_price);

    next_token.write(Uint256(1, 0));
    sale_phase.write(-1);
    call_once.write(1);
    eth_token_address.write(eth_contract_address);
    recipient_address.write(sale_recipient_address);

    owner_address.write(owner_contract);

    return ();
}

//
// Getters
//

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (token_uri_len: felt, token_uri: felt*) {
    let (token_uri_len, token_uri) = ERC721_Metadata_tokenURI(token_id);
    return (token_uri_len=token_uri_len, token_uri=token_uri);
}

@view
func currentPhase{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    phase: felt
) {
    let (phase: felt) = sale_phase.read();
    return (phase,);
}

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply,);
}

@view
func owner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    owner_contract_address: felt
) {
    let (owner_contract_address: felt) = owner_address.read();
    return (owner_contract_address,);
}

@view
func maxSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    maxSupply: Uint256
) {
    let (maxSupply: Uint256) = max_supply.read();
    return (maxSupply,);
}

@view
func freemintMaxSupplyId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    freemint_supply: Uint256
) {
    let (freemint_supply: Uint256) = freemint_max_supply.read();
    return (freemint_supply,);
}

@view
func whitelistMaxSupplyId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    whitelist_supply: Uint256
) {
    let (whitelist_supply: Uint256) = whitelist_max_supply.read();
    return (whitelist_supply,);
}

@view
func ogMaxSupplyId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    og_supply: Uint256
) {
    let (og_supply: Uint256) = og_max_supply.read();
    return (og_supply,);
}

@view
func publicmintMaxSupplyId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    publicmint_supply: Uint256
) {
    let (publicmint_supply: Uint256) = publicmint_max_supply.read();
    return (publicmint_supply,);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId,);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

// @view
// func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     tokenId: Uint256
// ) -> (uri_len: felt, uri: felt*) {
//     alloc_locals;
//     let (supply: Uint256) = totalSupply();
//     let (is_lt) = uint256_le(tokenId, supply);
//     with_attr error_message("Token Does Not Exist.") {
//         assert is_lt = 1;
//     }
//     let (tokenURI: felt*) = alloc();
//     let (tokenURI_len: felt) = Token_uri_len_.read();
//     local index = 0;
//     _getTokenURI(tokenURI_len, tokenURI, index);
//     let (local endingURI: felt*) = alloc();
//     assert endingURI[0] = tokenId.low + 48;
//     let (local final_tokenURI: felt*) = alloc();
//     memcpy(final_tokenURI, tokenURI, tokenURI_len);
//     memcpy(final_tokenURI + tokenURI_len, endingURI, 1);
//     return (uri_len=tokenURI_len + 1, uri=final_tokenURI);
// }

@view
func contractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    uri_len: felt, uri: felt*
) {
    let (uri_len: felt, uri: felt*) = getContractURI();
    return (uri_len=uri_len, uri=uri);
}

//
// View (royalties)
//

@view
func royaltyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, salePrice: Uint256
) -> (receiver: felt, royaltyAmount: Uint256) {
    let (supply: Uint256) = totalSupply();
    let (is_lt) = uint256_le(tokenId, supply);
    with_attr error_message("Token Does Not Exist.") {
        assert is_lt = 1;
    }
    let (receiver: felt, royaltyAmount: Uint256) = ERC2981_UniDirectional_Mutable.royalty_info(
        tokenId, salePrice
    );
    return (receiver, royaltyAmount);
}

// This function should not be used to calculate the royalty amount and simply exposes royalty info for display purposes.
// Use royaltyInfo to calculate royalty fee amounts for orders as per EIP2981.
@view
func getDefaultRoyalty{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    receiver: felt, feeBasisPoints: felt
) {
    let (receiver, fee_basis_points) = ERC2981_UniDirectional_Mutable.get_default_royalty();
    return (receiver, fee_basis_points);
}
//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ReentrancyGuard._start();
    ERC721.approve(to, tokenId);
    ReentrancyGuard._end();
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ReentrancyGuard._start();
    ERC721.set_approval_for_all(operator, approved);
    ReentrancyGuard._end();
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ReentrancyGuard._start();
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    ReentrancyGuard._end();
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ReentrancyGuard._start();
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    ReentrancyGuard._end();
    return ();
}

@external
func freemint_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    proof_len: felt, proof: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    let (phase: felt) = sale_phase.read();
    with_attr error_message("Not Free Mint Phase.") {
        assert phase = 0;
    }

    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (freemint_max_supply: Uint256) = freemintMaxSupplyId();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(5, 0);
    let (is_lt) = uint256_lt(supply, freemint_max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }
    let (leaf) = hash2{hash_ptr=pedersen_ptr}(caller_address, amount_hash);
    let (freemint_claimed) = freemint_has_claimed.read(leaf);
    let (is_minted_lt) = uint256_lt(freemint_claimed, Uint256(5, 0));
    with_attr error_message("User Already Minted 5 NFTs") {
        assert is_minted_lt = 1;
    }
    let (freemint_root) = freemint_merkle_root.read();
    local root_loc = freemint_root;
    let (proof_valid) = merkle_verify(leaf, freemint_root, proof_len, proof);
    with_attr error_message("Proof not valid") {
        assert proof_valid = 1;
    }

    // Write mint record to has_claimed
    let (freemint_claimed_after_minted, _) = uint256_add(freemint_claimed, Uint256(1, 0));
    freemint_has_claimed.write(leaf, freemint_claimed_after_minted);

    // Mint
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func og_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    proof_len: felt, proof: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    let (phase: felt) = sale_phase.read();
    with_attr error_message("Not OG Mint Phase.") {
        assert phase = 1;
    }
    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (og_max_supply: Uint256) = ogMaxSupplyId();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(1, 0);
    let (is_lt) = uint256_lt(supply, og_max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }
    let (leaf) = hash2{hash_ptr=pedersen_ptr}(caller_address, amount_hash);
    let (og_claimed) = og_has_claimed.read(leaf);
    with_attr error_message("User Already Minted") {
        assert og_claimed = 0;
    }
    let (og_root) = og_merkle_root.read();
    local root_loc = og_root;
    let (proof_valid) = merkle_verify(leaf, og_root, proof_len, proof);
    with_attr error_message("Proof not valid") {
        assert proof_valid = 1;
    }

    // ETH Payment
    let (eth_address: felt) = eth_token_address.read();
    let (sale_recipient: felt) = recipient_address.read();
    let (og_price_amount: Uint256) = og_price.read();
    let (res) = IERC20.transferFrom(
        contract_address=eth_address,
        sender=caller_address,
        recipient=sale_recipient,
        amount=og_price_amount,
    );
    with_attr error_message("ETH transfer failed!") {
        assert res = 1;
    }

    // Write mint record to has_claimed
    og_has_claimed.write(leaf, 1);

    // Mint first time
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func whitelist_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    proof_len: felt, proof: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    let (phase: felt) = sale_phase.read();
    with_attr error_message("Not Whitelist Mint Phase.") {
        assert phase = 2;
    }
    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (whitelist_max_supply: Uint256) = whitelistMaxSupplyId();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(5, 0);
    let (is_lt) = uint256_lt(supply, whitelist_max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }
    let (leaf) = hash2{hash_ptr=pedersen_ptr}(caller_address, amount_hash);
    let (whitelist_claimed) = whitelist_has_claimed.read(leaf);
    let (is_minted_lt) = uint256_lt(whitelist_claimed, Uint256(5, 0));
    with_attr error_message("User Already Minted 5 NFTs") {
        assert is_minted_lt = 1;
    }
    let (whitelist_root) = whitelist_merkle_root.read();
    local root_loc = whitelist_root;
    let (proof_valid) = merkle_verify(leaf, whitelist_root, proof_len, proof);
    with_attr error_message("Proof not valid") {
        assert proof_valid = 1;
    }

    // ETH Payment
    let (eth_address: felt) = eth_token_address.read();
    let (sale_recipient: felt) = recipient_address.read();
    let (whitelist_price_amount: Uint256) = whitelist_price.read();
    let (res) = IERC20.transferFrom(
        contract_address=eth_address,
        sender=caller_address,
        recipient=sale_recipient,
        amount=whitelist_price_amount,
    );
    with_attr error_message("ETH transfer failed!") {
        assert res = 1;
    }

    // Write mint record to has_claimed
    let (whitelist_claimed_after_minted, _) = uint256_add(whitelist_claimed, Uint256(1, 0));
    whitelist_has_claimed.write(leaf, whitelist_claimed_after_minted);

    // Mint
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func publicmint_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    ReentrancyGuard._start();
    let (phase: felt) = sale_phase.read();
    with_attr error_message("Not Public Mint Phase.") {
        assert phase = 3;
    }
    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (publicmint_max_supply: Uint256) = publicmintMaxSupplyId();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(1, 0);
    let (is_lt) = uint256_lt(supply, publicmint_max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }

    // ETH Payment
    let (eth_address: felt) = eth_token_address.read();
    let (sale_recipient: felt) = recipient_address.read();
    let (publicmint_price_amount: Uint256) = publicmint_price.read();
    let (res) = IERC20.transferFrom(
        contract_address=eth_address,
        sender=caller_address,
        recipient=sale_recipient,
        amount=publicmint_price_amount,
    );
    with_attr error_message("ETH transfer failed!") {
        assert res = 1;
    }

    // Mint
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, tokenId);
    let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    next_token.write(next_tokenId);

    ReentrancyGuard._end();
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(token_id_mint: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();
    let (phase: felt) = sale_phase.read();
    with_attr error_message("Mint is not active.") {
        assert phase = 4;
    }
    let (caller_address) = get_caller_address();
    let (supply: Uint256) = totalSupply();
    let (max_supply: Uint256) = maxSupply();
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(1, 0);
    let (is_lt) = uint256_lt(supply, max_supply);
    with_attr error_message("Max Supply Reached") {
        assert is_lt = 1;
    }
    let (tokenId: Uint256) = next_token.read();
    ERC721Enumerable._mint(caller_address, token_id_mint);
    // let (next_tokenId, _) = uint256_add(tokenId, Uint256(1, 0));
    // next_token.write(next_tokenId);
    ReentrancyGuard._end();
    return ();
}

@external
func setPhase{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(phase: felt) {
    ReentrancyGuard._start();
    Ownable.assert_only_owner();
    sale_phase.write(phase);
    ReentrancyGuard._end();
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ReentrancyGuard._start();
    ERC721.assert_only_token_owner(tokenId);
    ERC721Enumerable._burn(tokenId);
    ReentrancyGuard._end();
    return ();
}


@external
func setBaseURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt
) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();
    ERC721_Metadata_setBaseTokenURI(base_token_uri_len, base_token_uri, token_uri_suffix);
    ReentrancyGuard._end();
    return ();
}

@external
func setContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    contractURI_len: felt, contractURI: felt*
) {
    alloc_locals;
    ReentrancyGuard._start();
    Ownable.assert_only_owner();
    Contract_uri_len_.write(contractURI_len);
    local uri_index = 0;
    _storeContractRecursiveURI(contractURI_len, contractURI, uri_index);
    ReentrancyGuard._end();
    return ();
}

//
// External (royalties)
//

@external
func setDefaultRoyalty{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    receiver: felt, feeBasisPoints: felt
) {
    Ownable.assert_only_owner();
    ERC2981_UniDirectional_Mutable.set_default_royalty(receiver, feeBasisPoints);
    return ();
}

@external
func setTokenRoyalty{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, receiver: felt, feeBasisPoints: felt
) {
    Ownable.assert_only_owner();
    let (supply: Uint256) = totalSupply();
    let (is_lt) = uint256_le(tokenId, supply);
    with_attr error_message("Token Does Not Exist.") {
        assert is_lt = 1;
    }
    ERC2981_UniDirectional_Mutable.set_token_royalty(tokenId, receiver, feeBasisPoints);
    return ();
}

@external
func resetDefaultRoyalty{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    Ownable.assert_only_owner();
    ERC2981_UniDirectional_Mutable.reset_default_royalty();
    return ();
}

@external
func resetTokenRoyalty{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256
) {
    Ownable.assert_only_owner();
    let (supply: Uint256) = totalSupply();
    let (is_lt) = uint256_le(tokenId, supply);
    with_attr error_message("Token Does Not Exist.") {
        assert is_lt = 1;
    }
    ERC2981_UniDirectional_Mutable.reset_token_royalty(tokenId);
    return ();
}

func _storeContractRecursiveURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    len: felt, _uri: felt*, index: felt
) {
    if (index == len) {
        return ();
    }
    with_attr error_message("URI Empty") {
        assert_not_zero(_uri[index]);
    }
    Contract_URI.write(index, _uri[index]);
    _storeContractRecursiveURI(len=len, _uri=_uri, index=index + 1);
    return ();
}


func getContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    uri_len: felt, uri: felt*
) {
    alloc_locals;
    let (contractURI: felt*) = alloc();
    let (contractURI_len: felt) = Contract_uri_len_.read();
    local index = 0;
    _getContractURI(contractURI_len, contractURI, index);
    return (uri_len=contractURI_len, uri=contractURI);
}

func _getContractURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    uri_len: felt, uri: felt*, index: felt
) {
    if (index == uri_len) {
        return ();
    }
    let (base) = Contract_URI.read(index);
    assert [uri] = base;
    _getContractURI(uri_len=uri_len, uri=uri + 1, index=index + 1);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) -> () {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}
