// SPDX-License-Identifier: Apache 2.0
// Immutable Cairo Contracts v0.3.0

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC2981_Unidirectional {
    func royaltyInfo(tokenId: Uint256, salePrice: Uint256) -> (
        receiver: felt, royaltyAmount: Uint256
    ) {
    }

    func getDefaultRoyalty() -> (receiver: felt, feeBasisPoints: felt) {
    }

    func setDefaultRoyalty(receiver: felt, feeBasisPoints: felt) {
    }

    func resetDefaultRoyalty() {
    }

    func setTokenRoyalty(tokenId: Uint256, receiver: felt, feeBasisPoints: felt) {
    }

    func resetTokenRoyalty(tokenId: Uint256) {
    }
}
