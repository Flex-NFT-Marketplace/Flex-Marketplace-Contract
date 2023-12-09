// SPDX-License-Identifier: Apache 2.0
// Immutable Cairo Contracts v0.3.0

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC721_Bridgeable {
    func permissionedMint(account: felt, tokenId: Uint256) {
    }

    func permissionedBurn(tokenId: Uint256) {
    }
}
