![overview](./assets/logo.png)

# Flex Contracts Monorepo

## Repository Structure

The repository is organized into the following directories:

-   `stakingpool`: Includes implementation of the staking NFT pool contracts.
-   `openedition`: Includes implementation of open-editions NFT minting mechanism contracts.

### ERC721 contract

This contract is an implementation of an ERC-721 Open Edition NFT (Non-Fungible Token) contract on the Starknet blockchain, incorporating features from the OpenZeppelin library for secure and standardized functionality.

##### Key Components
**ERC721Component:** This provides the basic functionality for ERC-721 tokens, including minting, transferring, and metadata handling.

**SRC5Component:** Implements interface support detection, likely for custom or extended ERC-721 functionalities.

**OwnableComponent:** Implements ownership functionality, allowing only the owner of the contract to perform certain actions.

**ReentrancyGuardComponent** Provides protection against reentrancy attacks, ensuring that certain functions can't be executed multiple times concurrently.

**FlexDrop:** This contract integrates with a "FlexDrop" mechanism, allowing certain addresses (FlexDrop contracts) to mint NFTs.

**PhaseDrop:** Allows for the creation and management of phases for minting, including different configurations for each phase.

### ERC721OpenEditionMultiMetadata 
This contract defines ERC721OpenEditionMultiMetadata. It is built using several components from different libraries, which provide modular functionality like ownership, metadata handling, security, storage, and more.

#### Key features
* This contract imports various modules and components, including storage lists, OpenZeppelin components (like Ownable and ReentrancyGuard), and custom components for handling metadata and FlexDrop functionality.

* The contract is designed to handle an ERC721 token with extended metadata capabilities, specifically within the context of a FlexDrop system. The contract manages phases of drops, restricts minting to authorized FlexDrop contracts, and provides a flexible system for configuring and managing token drops.

### FlexDrop
The FlexDrop contract is a modular and extensible smart contract designed to manage NFT (Non-Fungible Token) drops with flexible configurations. 
#### Key Features:
**Phases Management:** The contract allows the creation, updating, and management of different phases for NFT drops, each with specific parameters like start/end times, minting limits, and associated currencies.

**Whitelist and Proof Verification:** It supports whitelist-based minting where a whitelist proof must be validated before minting. It ensures that the proof is not reused and verifies it against the validator and domain hash.

**Fee Management:** It includes mechanisms to manage protocol fees, including fees for starting new phases and minting when prices are set to zero. The contract allows for flexible fee recipient configurations, ensuring only allowed recipients can receive fees.

**Minting Process:** The contract provides functions to mint NFTs either publicly or through a whitelist. It handles payment, ensures the phase is active, and checks for valid recipients and quantities.

**Payer and Payout Management:** The contract supports the configuration of allowed payers for minting and allows updating of creator payout addresses, ensuring funds go to the correct recipients.

**Access Control and Pausability:** The contract includes standard access control features like ownership checks and the ability to pause or unpause certain operations, adding an extra layer of security.

**Signature and Currency Handling:** It integrates with external contracts for signature verification and currency management, ensuring flexibility in handling different types of currencies and validations.

-   `marketplace`: Includes implementation of the marketplace contracts.

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

### Marketplace Contracts

#### Overview
![overview](./assets/marketplace-overview.png)

#### Listing
![listing](./assets/marketplace-listing.png)

#### Buy
![buy](./assets/marketplace-buy.png)

#### Make Offer
![make-offer](./assets/marketplace-make-offer.png)

#### Accept Offer
![accept-offer](./assets/marketplace-accept-offer.png)