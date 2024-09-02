![overview](./assets/logo.png)

# Flex Contracts Monorepo

## Repository Structure

The repository is organized into the following directories:

1. `stakingpool`: Includes implementation of the staking NFT pool contracts.
#### Overview
The `StakingPool` contract allows users to stake their NFTs (ERC721 tokens) from specified eligible collections and earn rewards over time. This mechanism is designed to incentivize NFT holders by rewarding them based on the duration their NFTs remain staked.

#### Key Features

- **NFT Staking:** Users can stake their NFTs from collections that are approved by the contract owner.
- **Reward Accumulation:** Rewards are earned based on the amount of time an NFT is staked. The longer an NFT is staked, the more rewards it accrues.
- **Flexibility:** The contract supports various NFT collections, each with customizable reward parameters set by the contract owner.

#### Staking Process

 **Stake an NFT:**
   - Users call the `stakeNFT` function, providing the collection address and the token ID of the NFT they wish to stake.
   - Once staked, the NFT is locked in the contract and cannot be transferred until it is unstaked.

 **Unstake an NFT:**
   - Users can call the `unstakeNFT` function to retrieve their staked NFT.
   - During the unstaking process, any accumulated rewards are claimed and credited to the user.

 **Claiming Rewards:**
   - Rewards are calculated based on the staking duration and the reward rate set for the NFT collection.
   - Users can view their accumulated rewards for each staked NFT using the `getUserPointByItem` function.

#### Contract Configuration

- **Eligible Collections:** Only NFTs from collections that have been approved by the contract owner can be staked.
- **Reward Calculation:** The contract owner sets the time unit (in seconds) and the reward per unit time for each collection. These parameters determine how rewards accumulate for staked NFTs.

#### Security Considerations

- The contract implements reentrancy protection to secure staking and unstaking operations.
- Only the contract owner has the authority to modify which NFT collections are eligible for staking and to set the reward parameters.

2. `openedition`: Includes implementation of open-editions NFT minting mechanism contracts.
3. `marketplace`: Includes implementation of the marketplace contracts.

#### Development Setup

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
3. `marketplace`: Includes implementation of the marketplace contracts.


### Marketplace Contracts

#### Marketplace Contracts List

* CurrencyManager
* ExecutionManager
* Marketplace Contract
* Proxy
* RoyaltyFeeManager
* RoyaltyFeeRegistry
* SignatureChecker2
* StrategyHighestBidderAuctionSale
* StrategyStandardSaleForFixedPrice
* TransferManagerNFT
* ERC1155TransferManager
* TransferSelectorNFT

#### CurrencyManager 
  The `CurrencyManager` contract is designed to manage a whitelist of currencies. It operates under the control of an owner who has the authority to add or remove currencies from this list. The contract stores whitelisted currencies and their indices using a `LegacyMap` and maintains a separate `LegacyMap` to track each currency's index.

#### Contract Features
1. **Ownership Control**  
The contract is built on the concept of ownership. It uses OpenZeppelin's `OwnableComponent`, meaning only the owner of the contract has the power to make changes, such as adding or removing currencies from the whitelist. This ensures that the whitelist is securely managed.

2. **Whitelisting Currencies**
  The core function of this contract is to manage a whitelist of currencies. Think of the whitelist as a VIP list of currencies that are allowed to participate in the system. The contract lets the owner add new currencies to this list and remove them when they’re no longer needed.

3. **Event-Driven** 
The contract is designed to be very communicative. Every time a currency is added or removed from the whitelist, the contract emits an event, like sending out a notification. These events are crucial for keeping other parts of the system, or even external systems, informed about the changes.

#### Contract Functions

1. `initializer(ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress)` :
   
    This function sets up the initial state of the contract. It assigns the owner and ensures that the contract can only be initialized once. If the contract has already been initialized, it will throw an error. It also calls the initializer function of the OwnableComponent to manage ownership logic.

2. `add_currency(ref self: ContractState, currency: ContractAddress)` :
  This function allows the contract owner to add a new currency to the whitelist. It first checks if the currency is already whitelisted by looking up its index. If not, it increments the count of whitelisted currencies, adds the new currency to the list, and updates the mapping of currency indices. It then emits a `CurrencyWhitelisted` event with the current timestamp.

3. `remove_currency(ref self: ContractState, currency: ContractAddress)` :
  This function allows the owner to remove a currency from the whitelist. It verifies whether the currency is currently whitelisted by checking its index. If whitelisted, the function replaces the currency with the last one in the list, updates the indices, and reduces the count of whitelisted currencies. It also emits a `CurrencyRemoved` event with the current timestamp.

4. `is_currency_whitelisted(self: @ContractState, currency: ContractAddress) -> bool` :
  This function checks if a given currency is on the whitelist by looking up its index. If the index is non-zero, the currency is considered whitelisted, and the function returns true; otherwise, it returns `false`.

5. `whitelisted_currency_count(self: @ContractState) -> usize` :
  This function returns the total number of currencies currently on the whitelist. It simply reads the `whitelisted_currency_count` from storage, which tracks how many currencies have been added to the whitelist.

6.  `whitelisted_currency(self: @ContractState, index: usize) -> ContractAddress` :
  This function retrieves the currency at a specific position in the whitelist based on the provided index. It looks up the currency’s address in the list and returns it. This is useful for iterating through or displaying the list of whitelisted currencies.

#### ExecutionManager Contracts
  The `ExecutionManager` contract is a core component designed to manage and control a list of strategies within a decentralized system. It maintains a whitelist of strategies, each identified by a `ContractAddress`, determining which strategies are authorized for execution. The contract leverages OpenZeppelin's `OwnableComponent`, ensuring that only the contract owner can modify the whitelist.

#### Contract Features
1. **Ownership and Access Control**
  The contract uses the `OwnableComponent` from OpenZeppelin to manage ownership. This component restricts critical functions so that only the contract's owner can execute them. This ensures that sensitive operations, like adding or removing strategies, are secure and only performed by an authorized entity.

2. **Strategy Whitelisting**
The core functionality of this contract is to manage a whitelist of execution strategies. Strategies are represented by their `ContractAddress`, and only those on the whitelist are valid for execution within the system.

3. **Event Emission**
The contract emits events whenever a strategy is added to or removed from the whitelist. This allows for transparency and traceability, enabling external observers to track changes to the list of approved strategies.

#### **Contract Functions**
1. `initializer(ref self: ContractState, owner: ContractAddress)`
This function initializes the contract, setting up the initial state and assigning the owner. It ensures the contract is only initialized once by checking if it has already been initialized `(assert!(!self.initialized.read(), "ExecutionManager: already initialized");)`. Once initialized, the `OwnableComponent` is set up with the provided owner address.

2. `add_strategy(ref self: ContractState, strategy: ContractAddress)`
This function allows the owner to add a new strategy to the whitelist. It checks if the strategy is already whitelisted using the `whitelisted_strategies_index` map. If not, the strategy is added, the strategy count is incremented, and a `StrategyWhitelisted` event is emitted.

3. `remove_strategy(ref self: ContractState, strategy: ContractAddress)`
This function allows the owner to remove a strategy from the whitelist. It verifies that the strategy is currently whitelisted, then removes it and adjusts the indices in the list. A `StrategyRemoved` event is emitted to inform external observers of the change.

4. `is_strategy_whitelisted(self: @ContractState, strategy: ContractAddress) -> bool`
This function checks if a specific strategy is whitelisted. It returns `true` if the strategy is on the whitelist and `false` if it is not. This function is crucial for determining the validity of a strategy before execution.

5. `get_whitelisted_strategies_count(self: @ContractState) -> usize`
This function returns the total number of whitelisted strategies. It provides a simple way to retrieve the size of the whitelist, which can be useful for iterating over all strategies or for display purposes.

6. `get_whitelisted_strategy(self: @ContractState, index: usize) -> ContractAddress`
This function retrieves a strategy from the whitelist based on its index. It allows external contracts or users to access specific strategies by their position in the list, enabling iteration or specific strategy retrieval for execution or analysis.

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