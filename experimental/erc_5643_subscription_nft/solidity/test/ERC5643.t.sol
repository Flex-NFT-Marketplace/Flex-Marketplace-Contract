// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "../src/ERC5643.sol";

contract ERC5643Mock is ERC5643 {
    constructor(string memory name_, string memory symbol_) ERC5643(name_, symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract ERC5643Test is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    address user1;
    uint256 tokenId;
    ERC5643Mock erc5643;

    function setUp() public {
        tokenId = 1;
        user1 = address(0x1);

        erc5643 = new ERC5643Mock("erc5369", "ERC5643");
        erc5643.mint(user1, tokenId);
    }

    function testRenewalValid() public {
        vm.warp(1000);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 3000);
        erc5643.renewSubscription(tokenId, 2000);
    }

    function testRenewalNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                address(this),
                tokenId
            )
        );
        erc5643.renewSubscription(tokenId, 2000);
    }

    function testCancelValid() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 0);
        erc5643.cancelSubscription(tokenId);
    }

    function testCancelNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                address(this),
                tokenId
            )
        );
        erc5643.cancelSubscription(tokenId);
    }

    function testExpiresAt() public {
        vm.warp(1000);

        assertEq(erc5643.expiresAt(tokenId), 0);
        vm.startPrank(user1);
        erc5643.renewSubscription(tokenId, 2000);
        assertEq(erc5643.expiresAt(tokenId), 3000);

        erc5643.cancelSubscription(tokenId);
        assertEq(erc5643.expiresAt(tokenId), 0);
    }
}
