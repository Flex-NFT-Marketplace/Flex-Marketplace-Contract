%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

//
// TransferManagerERC1155
//
// Allows the transfer of ERC1155 tokens
//

@contract_interface
namespace IERC1155 {
    func safeTransferFrom(
        _from: felt, to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
    ) {
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

// Transfer ERC1155 token
@external
func transferNonFungibleToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, _from: felt, to: felt, tokenId: Uint256, amount: felt
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (address) = marketplace();
    assert caller = address;
    let (local data) = alloc();
    IERC1155.safeTransferFrom(
        contract_address=collection,
        _from=_from,
        to=to,
        id=tokenId,
        amount=Uint256(amount, 0),
        data_len=0,
        data=data,
    );
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
