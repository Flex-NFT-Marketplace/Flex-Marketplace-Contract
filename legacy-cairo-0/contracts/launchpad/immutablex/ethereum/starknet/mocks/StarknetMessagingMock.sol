// SPDX-License-Identifier: Apache-2.0.
// Retrieved from https://github.com/starkware-libs/cairo-lang/blob/4e233516f52477ad158bc81a86ec2760471c1b65/src/starkware/starknet/testing/MockStarknetMessaging.sol
pragma solidity ^0.8.4;

import "immutablex/ethereum/starknet/core/StarknetMessaging.sol";

contract StarknetMessagingMock is StarknetMessaging {
    /**
      Mocks a message from L2 to L1.
    */
    function mockSendMessageFromL2(
        uint256 from_address,
        uint256 to_address,
        uint256[] calldata payload
    ) external {
        bytes32 msgHash = keccak256(
            abi.encodePacked(from_address, to_address, payload.length, payload)
        );
        l2ToL1Messages()[msgHash] += 1;
    }

    /**
      Mocks consumption of a message from L1 to L2.
    */
    function mockConsumeMessageToL2(
        uint256 from_address,
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external {
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                from_address,
                to_address,
                nonce,
                selector,
                payload.length,
                payload
            )
        );

        require(l1ToL2Messages()[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        l1ToL2Messages()[msgHash] -= 1;
    }
}
