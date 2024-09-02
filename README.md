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
#### ERC721OpenEditionMultiMetadata
  The `ERC721OpenEditionMultiMetadata` contract is designed to handle complex interactions between its various functions and components to enable flexible minting phases, secure operations, and dynamic configuration for ERC721 Open Edition Token. It supports multiple metadata types and it integrates components from Alexandria Storage and OpenZeppelin.ETC.

- **Functions**:
  * **Constructor Function:**
   The contract's `constructor` function intializes with parameters like the`ref self` which is the `ContractState`, the `creator` of the contract wish is the `ContractAddress`, the `name` of the OpenEdition Non-Fungible Token, `symbol` of the Token in, and `token_base_uri` in `ByteArray`, `total_supply` of the OpenEdition Non-Fungible Token in `u64`, and the `allowed_flex_drop` which constatins an array where the `contracAddress` is gotten, which will all be exectuted once when the contract is deployed.
   * **update_allowed_flex_drop function:** The function manages the FlexDrop contract by updating the `ContractState` with the allowed flex drop `ContractAddress` when this function is called. It loops through the array of addresses to verify the `old_allowed_flex_drop`. It Sets the new mapping for allowed FlexDrop contracts with the new `allowed_flex_drop`. The`UpdateAllowedFlexDrop` event is then emitted to log for the new `allowed_flex_drop`.
   * **mint_flex_drop Function:** This function allows FlexDrop contracts to mint tokens, where the `minter` is `ContractAddress`. It utilizes reentrancy protection and it internally calls `safe_mint_flex_drop` to perform the minting of the OpenEdition Non-Fungible Token explicitly specifying the `phase_id`, 
   `quantity` to be minted ETC.
   * **create_new_phase_drop Fuction:** This function interacts with the FlexDrop dispatcher to initiate new minting phases. The function asserts for the restriction of only owner and also for the allowed flex drop. To start the new phase drop,it require parameters like `current_phase_id`, `phase_detail`which is the phaseDrop, and the `fee_recipient` which is the `ContractAddress `.ETC. 
   * **update_phase_drop Fuction:** This function updates the details of existing phaseDrops in the contract. It has a check for access control through the `assert_owner_or_self` to ensures that only the contract owner or the contract itself  can execute the function and also validation  check through  `assert_allowed_flex_drop`. It also allows for modifying the minting conditions like `phase_id` and `phase_detail` within existing phase.
   * **update_creator_payout Function:** This function updates the payout address for FlexDrop by changing the address that receives payouts with correct`payout_address` specified in the function parameters. It checks who execute the function through `assert_owner_or_self` to ensures that it is only the contract owner or the contract itself.
   * **update_payer Function:** The function updates the address for paying gas fee of minting the NFT in the contract. It has a parameter in place to check if the payers address to update the contract state with allowed and it returns a bolean, it has parameters for `payer` and the `flex_drop` which is the `ContractAddress`. It asserts for the caller of the function and allowed flex drop.
   * **multi_configure Function:** This function which is only executed by the owner of the contract enables dynamic changes like setting the `base_uri`and `contract_uri` if their length is > 0, updating `phase_drops`, and modifies `update_creator_payout` and `update_payer` with configured parameters. It also update the`create_new_phase_drop` and `update_phase_drop` function based on the provided configuration Parameters.
   * **get_mint_state Function:** This function provides information on the minting state, such as the `total_minted` token per a wallet address,The `current_total_supply` of the erc721 token that is minted. 
   * **get_current_token_id Function:** This function read the `ContractState` and return the id of the current token that has been minted.
   * **get_allowed_flex_drops Function:** The function is executed to retrieve the `enumerated_allowed_flex_drop` from the contract state which is the `ContractAddress` that is stored in an array.
   *  **safe_mint_flex_drop Function:** This is an internal function that performs the minting operation.It mints tokens to the `ContractAddress`, the `phase_id` and the  `quantity` of token to be minted are also specified. this function updates the `index` and `current_token_id` in the contract address.
   *  **assert_allowed_flex_drop:** This function checks whether a FlexDrop address is allowed to execute minting and phase update functions. It revert a message which reads `Only allowed FlexDrop'` if the address calling the functions with the check are not allowed.
   *   **get_total_minted Function:** The function gets the `total_minted` value of OpenEdition Non-Fungible Token minted in the contract. 
   * **assert_owner_or_self Function:** This function is put in place verifies that the contract utilizes the ownable modifier. that is, only the contract owner or the contract itself can perform state changing updates, used across multiple functions that require restricted access.

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