<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<p align="center">
  <img src="assets/logo.png" height="256">
</p>

# Flex Contracts

## Repository Structure

The repository is organized into the following directories:

-   `stakingpool`: Includes implementation of the staking NFT pool contracts.
-   `openedition`: Includes implementation of open-editions NFT minting mechanism contracts.
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

Note:

-   The `stakingpool` and `openedition` directories use scarb version `2.6.3`.
-   The `marketplace` directory uses scarb version `2.4.3`.

### Running Tests

To run the tests contained within the `tests` folder, run the command:

```
scarb test
```

### Marketplace Overview

<p align="center">
  <img src="assets/marketplace-overview.png" height="256">
</p>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
