%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_block_timestamp
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

//
// TransferSelectorNFT
//
// Selects the NFT transfer manager based on a collection address
//

@contract_interface
namespace IERC165 {
    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }
}

//
// Storage
//

@storage_var
func _INTERFACE_ID_ERC721() -> (interfaceID: felt) {
}

@storage_var
func _INTERFACE_ID_ERC1155() -> (interfaceID: felt) {
}

@storage_var
func _TRANSFER_MANAGER_ERC721() -> (manager: felt) {
}

@storage_var
func _TRANSFER_MANAGER_ERC1155() -> (manager: felt) {
}

// Map collection address to transfer manager address
@storage_var
func _transferManagerSelectorForCollection(collection: felt) -> (manager: felt) {
}

//
// Events
//

@event
func CollectionTransferManagerAdded(collection: felt, transferManager: felt, timestamp: felt) {
}

@event
func CollectionTransferManagerRemoved(collection: felt, timestamp: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    transferManagerERC721: felt, transferManagerERC1155: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    _INTERFACE_ID_ERC721.write(0x80ac58cd);
    _INTERFACE_ID_ERC1155.write(0xd9b67a26);
    _TRANSFER_MANAGER_ERC721.write(transferManagerERC721);
    _TRANSFER_MANAGER_ERC1155.write(transferManagerERC1155);
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
func INTERFACE_ID_ERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    interfaceID: felt
) {
    let (interfaceID) = _INTERFACE_ID_ERC721.read();
    return (interfaceID,);
}

@view
func INTERFACE_ID_ERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    interfaceID: felt
) {
    let (interfaceID) = _INTERFACE_ID_ERC1155.read();
    return (interfaceID,);
}

@view
func TRANSFER_MANAGER_ERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    manager: felt
) {
    let (manager) = _TRANSFER_MANAGER_ERC721.read();
    return (manager,);
}

@view
func TRANSFER_MANAGER_ERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (manager: felt) {
    let (manager) = _TRANSFER_MANAGER_ERC1155.read();
    return (manager,);
}

@view
func transferManagerSelectorForCollection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(collection: felt) -> (manager: felt) {
    let (manager) = _transferManagerSelectorForCollection.read(collection);
    return (manager,);
}

// Check the transfer manager for a token
@view
func checkTransferManagerForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt
) -> (transferManager: felt) {
    let (transferManager) = transferManagerSelectorForCollection(collection);
    let managerNotZero = is_not_zero(transferManager);
    if (managerNotZero == 1) {
        return (transferManager,);
    }

    let (transferManagerERC721) = TRANSFER_MANAGER_ERC721();
    let (interfaceIDERC721) = INTERFACE_ID_ERC721();
    let (supportsERC721) = IERC165.supportsInterface(
        contract_address=collection, interfaceId=interfaceIDERC721
    );
    if (supportsERC721 == 1) {
        return (transferManagerERC721,);
    }

    let (transferManagerERC1155) = TRANSFER_MANAGER_ERC1155();
    let (interfaceIDERC1155) = INTERFACE_ID_ERC1155();
    let (supportsERC1155) = IERC165.supportsInterface(
        contract_address=collection, interfaceId=interfaceIDERC1155
    );
    if (supportsERC1155 == 1) {
        return (transferManagerERC1155,);
    }

    return (0,);
}

//
// Externals
//

// Add a transfer manager for a collection
@external
func addCollectionTransferManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collection: felt, transferManager: felt
) {
    Ownable_only_owner();
    assert_not_zero(collection);
    assert_not_zero(transferManager);
    _transferManagerSelectorForCollection.write(collection=collection, value=transferManager);

    let (timestamp) = get_block_timestamp();
    CollectionTransferManagerAdded.emit(
        collection=collection, transferManager=transferManager, timestamp=timestamp
    );
    return ();
}

// Remove a transfer manager for a collection
@external
func removeCollectionTransferManager{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(collection: felt) {
    Ownable_only_owner();
    let (transferManager) = transferManagerSelectorForCollection(collection);
    assert_not_zero(transferManager);
    _transferManagerSelectorForCollection.write(collection=collection, value=0);

    let (timestamp) = get_block_timestamp();
    CollectionTransferManagerRemoved.emit(collection=collection, timestamp=timestamp);
    return ();
}

@external
func update_TRANSFER_MANAGER_ERC721{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(manager: felt) {
    Ownable_only_owner();
    _TRANSFER_MANAGER_ERC721.write(manager);
    return ();
}

@external
func update_TRANSFER_MANAGER_ERC1155{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(manager: felt) {
    Ownable_only_owner();
    _TRANSFER_MANAGER_ERC1155.write(manager);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
