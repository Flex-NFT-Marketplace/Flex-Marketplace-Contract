// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Future Rewards (nFR) Token Standard.
 */
interface IERC5173 is IERC165 {
    event FRClaimed(address indexed account, uint256 indexed amount);
    event FRDistributed(uint256 indexed tokenId, uint256 indexed soldPrice, uint256 indexed allocatedFR);
    event Listed(uint256 indexed tokenId, uint256 indexed salePrice);
    event Unlisted(uint256 indexed tokenId);
    event Bought(uint256 indexed tokenId, uint256 indexed salePrice);

    function list(uint256 tokenId, uint256 salePrice) external;
    function unlist(uint256 tokenId) external;
    function buy(uint256 tokenId) external payable;
    function releaseFR(address payable account) external;
    function retrieveFRInfo(uint256 tokenId) external view returns (
        uint8, uint256, uint256, uint256, uint256, address[] memory
    );
    function retrieveAllottedFR(address account) external view returns (uint256);
    function retrieveListInfo(uint256 tokenId) external view returns (uint256, address, bool);
}