![overview](./assets/logo.png)

# Flex Contracts Monorepo

## Repository Structure
1. **`stakingpool`**
   Includes implementation of the staking NFT pool contracts.
   - **Purpose**: Stake NFTs (ERC721) to earn time-based rewards.
   - **Features**:
     - NFT staking with rewards.
     - Customizable reward parameters.
     - Secure staking and unstaking.

2. **`openedition`**
   Includes implementation of the marketplace contracts.
   - **Purpose**: Open-edition NFT minting with flexible configurations.
   - **Contracts**:
     - **ERC721OpenEditionMultiMetadata**: Handles metadata, flexible drops, and owner controls.
     - **ERC721OpenEdition**: StarkNet ERC-721 implementation for open-edition tokens.
     - **FlexDrop**: Manages minting phases and whitelist minting.

3. **`marketplace`**
   Includes implementation of the marketplace contracts.
   - **Purpose**: Manage decentralized trading, auctions, and royalty fees.
   - **Contracts**:
        - **CurrencyManager**: Whitelists accepted currencies.
        - **ExecutionManager**: Manages execution strategies.
        - **Marketplace**: Matches orders, manages fees, and secures trades.
        - **RoyaltyFeeManager**: Calculates and distributes royalties.
        - **Proxy**: Enables contract upgrades.
        - **RoyaltyFeeManager**:Handles NFT royalty fees using ERC-2981 standards.
        - **RoyaltyFeeRegistry**:enforces and manages royalty fees , allowing updates,    retrieval of royalty details.
        - **Signature_Checkers2**:verifies digital signatures on StarkNet.
        - **StrategyStandardSaleForFixedPrice**:Implements fixed-price sale strategy.
        - **TransferManagementNFT**-Manages NFT transfers in StarkNet marketplaces.
        - **ERC1155TransferManager**-Manages secure ERC-1155 token transfers.
        - **TransferSelectorNFT**-Manages and assigns transfer managers for ERC-721/ERC-1155 tokens.


## Key Features
- **NFT Staking**: Stake ERC721 tokens to earn rewards based on staking duration.
- **Open-Edition Minting**:
  - Supports multiple metadata sets.
  - Flexible minting phases.
  - Whitelist minting.
- **Marketplace**:
  - Auction and fixed-price sales.
  - Royalty management.
  - Secure, upgradeable contracts.




## Visual Overview
![Overview](./assets/marketplace-overview.png)

### Key Actions
- **List NFTs**
  ![Listing](./assets/marketplace-listing.png)
- **Buy NFTs**
  ![Buy](./assets/marketplace-buy.png)
- **Make Offers**
  ![Make Offer](./assets/marketplace-make-offer.png)
- **Accept Offers**
  ![Accept Offer](./assets/marketplace-accept-offer.png)



## Development Setup
You will need to have Scarb and Starknet Foundry installed on your system. Refer to the documentations below:
-   [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/index.html)
-   [Scarb](https://docs.swmansion.com/scarb/download.html)
To use this repository, first clone it:
```
git clone git@github.com:Flex-NFT-Marketplace/Flex-Marketplace-Contract.git
```
### Building contracts
To build the contracts, run the command:
```
scarb build
```
Note: Use scarb version `2.6.3`.
### Running Tests
To run the tests contained within the `tests` folder, run the command:
```
scarb test
```



## Notes
- Ensure you use `scarb` version `2.6.3` for compatibility.