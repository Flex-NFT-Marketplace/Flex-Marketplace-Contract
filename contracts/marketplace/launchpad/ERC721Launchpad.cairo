// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_add

from contracts.openzeppelin.token.erc721.library import ERC721
from contracts.openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from contracts.openzeppelin.token.erc721.tokenURI_library import (
    ERC721_tokenURI,
    ERC721_setBaseTokenURI,
    ERC721_baseURI,
)
from contracts.openzeppelin.introspection.erc165.library import ERC165
from contracts.openzeppelin.access.ownable.library import Ownable
from contracts.openzeppelin.upgrades.library import Proxy

//
// Storage
//

@storage_var
func ERC721_minter() -> (minter: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

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
    let (balance) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (owner: felt) {
    let (owner) = ERC721.owner_of(token_id);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (approved: felt) {
    let (approved) = ERC721.get_approved(token_id);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func baseURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    baseURI_len: felt, baseURI: felt*
) {
    let (baseURI_len: felt, baseURI: felt*) = ERC721_baseURI();
    return (baseURI_len=baseURI_len, baseURI=baseURI);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    let exists = ERC721._exists(tokenId);
    with_attr error_message("ERC721_Metadata: URI query for nonexistent token") {
        assert exists = TRUE;
    }

    let (tokenURI_len: felt, tokenURI: felt*) = ERC721_tokenURI(tokenId);
    return (tokenURI_len=tokenURI_len, tokenURI=tokenURI);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply,);
}

@view
func tokenByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId,);
}

@view
func tokenOfOwnerByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner,);
}

@view
func minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (minter: felt) {
    let (minter) = ERC721_minter.read();
    return (minter,);
}

//
// Externals
//

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func setMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newMinter: felt) {
    Ownable.assert_only_owner();
    ERC721_minter.write(newMinter);
    return ();
}

@external
func setBaseURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    baseURI_len: felt, baseURI: felt*
) {
    Ownable.assert_only_owner();
    ERC721_setBaseTokenURI(baseURI_len, baseURI);
    return ();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(to: felt) {
    let (minter) = ERC721_minter.read();
    let (caller) = get_caller_address();
    with_attr error_message("ERC721: caller is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("ERC721: caller is not the minter") {
        assert minter = caller;
    }

    let (tokenId: Uint256) = totalSupply();
    let (newTokenId: Uint256, _) = uint256_add(tokenId, Uint256(1, 0));
    ERC721Enumerable._mint(to, newTokenId);
    return ();
}
