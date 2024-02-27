%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

//
// TransferManagerERC721
//
// Allows the transfer of ERC721 tokens
//

@contract_interface
namespace IERC721 {
    func transferFrom(_from: felt, to: felt, tokenId: Uint256) {
    }
}

//
// Storage
//

@storage_var
func _marketplace() -> (address: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    _marketplace.write(address);
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
func marketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    let (address) = _marketplace.read();
    return (address,);
}

//
// Externals
//

// Transfer ERC721 token
@external
func transferNonFungibleToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, _from: felt, to: felt, tokenId: Uint256, amount: felt
) {
    let (caller) = get_caller_address();
    let (address) = marketplace();
    assert caller = address;
    IERC721.transferFrom(contract_address=collection, _from=_from, to=to, tokenId=tokenId);
    return ();
}

@external
func updateMarketplace{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    Ownable_only_owner();
    _marketplace.write(address);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
