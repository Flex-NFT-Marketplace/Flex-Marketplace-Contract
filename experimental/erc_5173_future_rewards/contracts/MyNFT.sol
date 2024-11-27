// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC5173.sol";

/**
 * @dev Implementation of the nFR Standard (ERC-5173) as an extension of ERC-721.
 */
contract MyNFT is ERC721, IERC5173, Ownable {
    // using SafeMath for uint256;

    struct FRInfo {
        uint8 numGenerations;
        uint256 percentOfProfit; // Scaled by 1e18
        uint256 successiveRatio; // Geometric sequence common ratio
        uint256 lastSoldPrice;
        uint256 ownerAmount;
        address[] addressesInFR;
    }

    struct ListInfo {
        uint256 salePrice;
        address lister;
        bool isListed;
    }

    mapping(uint256 => FRInfo) private _frInfo;
    mapping(uint256 => ListInfo) private _listInfo;
    mapping(address => uint256) private _allottedFR;

    uint256 private constant PERCENT_SCALE = 1e18;

    constructor(address initialOwner) ERC721("MyNFT", "MNFT") Ownable(initialOwner) {}

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);

        // Initialize FRInfo for the token
        _frInfo[tokenId] = FRInfo({
            numGenerations: 10,
            percentOfProfit: 5e16, 
            successiveRatio: 8e17,
            lastSoldPrice: 0,
            ownerAmount: 0,
            addressesInFR: new address[](0)
        });
    }

    function list(uint256 tokenId, uint256 salePrice) public virtual override {
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "Not authorized");
        _listInfo[tokenId] = ListInfo(salePrice, msg.sender, true);
        emit Listed(tokenId, salePrice);
    }

    function unlist(uint256 tokenId) public virtual override {
        require(_listInfo[tokenId].lister == msg.sender, "Not lister");
        delete _listInfo[tokenId];
        emit Unlisted(tokenId);
    }

    function buy(uint256 tokenId) public payable virtual override {
        ListInfo memory listing = _listInfo[tokenId];
        require(listing.isListed, "Token not listed");
        require(msg.value == listing.salePrice, "Incorrect value sent");

        // Process Sale
        address seller = listing.lister;
        _transfer(seller, msg.sender, tokenId);

        // Distribute FR
        _distributeFR(tokenId, msg.value);

        delete _listInfo[tokenId];
        emit Bought(tokenId, msg.value);
    }

    function releaseFR(address payable account) public virtual override {
        uint256 amount = _allottedFR[account];
        require(amount > 0, "No funds to claim");

        _allottedFR[account] = 0;
        account.transfer(amount);

        emit FRClaimed(account, amount);
    }

    function retrieveFRInfo(uint256 tokenId) public view override returns (
        uint8, uint256, uint256, uint256, uint256, address[] memory
    ) {
        FRInfo memory fr = _frInfo[tokenId];
        return (fr.numGenerations, fr.percentOfProfit, fr.successiveRatio, fr.lastSoldPrice, fr.ownerAmount, fr.addressesInFR);
    }

    function retrieveAllottedFR(address account) public view override returns (uint256) {
        return _allottedFR[account];
    }

    function retrieveListInfo(uint256 tokenId) public view override returns (uint256, address, bool) {
        ListInfo memory listing = _listInfo[tokenId];
        return (listing.salePrice, listing.lister, listing.isListed);
    }

    // Util functions
    function _distributeFR(uint256 tokenId, uint256 soldPrice) internal virtual {
        FRInfo storage fr = _frInfo[tokenId];

        uint256 profit = soldPrice - fr.lastSoldPrice;
        uint256 totalReward = (profit * fr.percentOfProfit) / PERCENT_SCALE;
        uint256 successiveRatio = fr.successiveRatio;

        uint256[] memory rewards = _calculateFR(totalReward, successiveRatio, fr.addressesInFR.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            _allottedFR[fr.addressesInFR[i]] = _allottedFR[fr.addressesInFR[i]] + rewards[i];
        }

        fr.lastSoldPrice = soldPrice;
        emit FRDistributed(tokenId, soldPrice, totalReward);
    }

    function _calculateFR(uint256 totalReward, uint256 successiveRatio, uint256 numRecipients) internal pure returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](numRecipients);
        uint256 denominator = 1e18 - successiveRatio ** numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            rewards[i] = (totalReward * (successiveRatio ** i)) / denominator;     
        }

        return rewards;
    }
}