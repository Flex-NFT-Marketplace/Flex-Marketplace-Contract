%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.uint256 import Uint256
from contracts.openzeppelin.upgrades.library import Proxy

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_get_owner,
    Ownable_transfer_ownership,
)

@contract_interface
namespace IRoyaltyFeeRegistry {
    func royaltyInfo(collection: felt, amount: felt) -> (receiver: felt, royaltyAmount: felt) {
    }
}

@contract_interface
namespace IERC165 {
    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }
}

// https://github.com/immutable/imx-starknet/blob/69205aca672b20f478b5419ff15c86f980805a15/docs/erc2981.md#contract-interface-erc2981
@contract_interface
namespace IERC2981 {
    func royaltyInfo(tokenId: Uint256, salePrice: Uint256) -> (
        receiver: felt, royaltyAmount: Uint256
    ) {
    }
}

//
// RoyaltyFeeManager
//
// Handles the logic to check and transfer royalty fees (if any)
//

//
// Storage
//

@storage_var
func _INTERFACE_ID_ERC2981() -> (interfaceID: felt) {
}

// Address of the RoyaltyFeeRegistry
@storage_var
func _royaltyFeeRegistry() -> (feeRegistry: felt) {
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    feeRegistry: felt, owner: felt, proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    _INTERFACE_ID_ERC2981.write(0x2a55205a);
    _royaltyFeeRegistry.write(feeRegistry);
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
func INTERFACE_ID_ERC2981{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    interfaceID: felt
) {
    let (interfaceID) = _INTERFACE_ID_ERC2981.read();
    return (interfaceID,);
}

@view
func royaltyFeeRegistry{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    feeRegistry: felt
) {
    let (feeRegistry) = _royaltyFeeRegistry.read();
    return (feeRegistry,);
}

// Calculate royalty fee and get recipient for a collection
@view
func calculateRoyaltyFeeAndGetRecipient{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(collection: felt, tokenId: Uint256, amount: felt) -> (receiver: felt, royaltyAmount: felt) {
    let (feeRegistry) = royaltyFeeRegistry();
    let (receiver, royaltyAmount) = IRoyaltyFeeRegistry.royaltyInfo(
        contract_address=feeRegistry, collection=collection, amount=amount
    );

    let receiverNotZero = is_not_zero(receiver);
    if (receiverNotZero == 1) {
        return (receiver, royaltyAmount);
    }

    let (interfaceIDERC2981) = INTERFACE_ID_ERC2981();
    let (supportsERC2981) = IERC165.supportsInterface(
        contract_address=collection, interfaceId=interfaceIDERC2981
    );
    if (supportsERC2981 == 1) {
        let (receiverERC2981, royaltyAmountERC2981) = IERC2981.royaltyInfo(
            contract_address=collection, tokenId=tokenId, salePrice=Uint256(amount, 0)
        );
        return (receiverERC2981, royaltyAmountERC2981.low);
    }

    return (receiver, royaltyAmount);
}

//
// Externals
//

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable_transfer_ownership(newOwner);
    return ();
}
