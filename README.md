# Flex Contracts Monorepo

## Overview
This repository contains contracts for managing staking, open-edition NFT minting, and a marketplace.

## Repository Structure
1. **`stakingpool`**
   - **Purpose**: Stake NFTs (ERC721) to earn time-based rewards.
   - **Features**:
     - NFT staking with rewards.
     - Customizable reward parameters.
     - Secure staking and unstaking.

2. **`openedition`**
   - **Purpose**: 

#### Contract Configuration

- **Eligible Collections:** Only NFTs from collections that have been approved by the contract owner can be staked.
- **Reward Calculation:** The contract owner sets the time unit (in seconds) and the reward per unit time for each collection. These parameters determine how rewards accumulate for staked NFTs.

#### Security Considerations

- The contract implements reentrancy protection to secure staking and unstaking operations.
- Only the contract owner has the authority to modify which NFT collections are eligible for staking and to set the reward parameters.
  

1. `openedition`: Includes implementation of open-editions NFT minting mechanism contracts.
   
 **The List of contracts in openedition**
  1. ERC721OpenEditionMultiMetadata Contract
  2. ERC721OpenEdition Contract
  3. FlexDrop Contract

### ERC721OpenEditionMultiMetadata

The `ERC721OpenEditionMultiMetadata` contract is designed to handle complex interactions between its various functions and components to enable flexible minting phases, secure operations, and dynamic configuration for ERC721 Open Edition Token. It supports multiple metadata. It uses components imported from Alexandria Storage, OpenZeppelin,openedition utils. ETC.

### contract features
  1. **ERC721OpenEditionMultiMetadata Management**
  This contract is built to leverage the `ERC721MultiMetadataComponent` from openzeppelin which allows it to handle multiple sets of metadata of the ERC721OpenEdition Token.

  2. **Integration of FlexDrop logic**
  The contract integrates the `IFlexDropDispatcher` and `INonFungibleFlexDropToken` interfaces from openedition used for creation and management of the drop phases. This mechanism is designed to facilitate flexible minting and phase management, allowing drops to be updated, extended, or configured.

  3. **Validation of Allowed FlexDrop Contract**
  This contract has a mapping and a list tracking the "allowed" FlexDrop contract `allowed_flex_drop`; This means that Only contract listed  in the mapping is allowed to interact with the minting functionalities. This access control logic makes the contract more secure, restricting minting of the ERC721OpenEdition token to the approved contract address.

  4. **Phase Management**
  The contract includes functions for creating, updating, and managing phases of drops. It uses PhaseDrop structures and allows different minting conditions based on phases, which adds more control and scheduling to how and when tokens can be minted. This is especially useful for open edition drops where tokens might be minted in large quantities within set timeframes or conditions.

  5. **Ownership Control**
  The contract utilizes the`OwnableComponent` by adding functions like `assert_owner_or_self`, which ensures that certain actions can only be performed by either the contract itself or the owner. This provides enhanced control over who can actually call these functions.

  6. **Reentrancy Protection**
  This contract has `ReentrancyGuardComponent` for protecting the contract against reentrancy attacks. This means that, an external contract can not call a function from the contract before the initial function execution is completed.

  7. **ERC721OpenEditionMultiMetadata Configuration**
  Through the multi_configure function, this contract allows the owner to set multiple parameters, such as `base_uri` and `contract_uri`, phase details, and allowed payer for gas fee. This congiguration makes the contract flexible and easier to manage.


### ERC721OpenEdition Contract
 The `ERC721OpenEdition` contract is a StarkNet smart contract that is designed to integrate the functionalities of an ERC-721 (NFT) standards and flex-drop for minting of the openedition token.
 The contract imports the `OwnableComponent` from openzeppelin to authourise only the owner to call state changing functions, `ReentrancyGuardComponent` for prevent the contract from vulnerabilities or malicious actors. ETC.
 Anytime state changing transactions are executed in the contract, the contract emit  events that log the changes.For example an event emitted in the contract is; UpdateAllowedFlexDrop event, it will send a notification when the allowed flex drop is updated.

- **Functions in the  ERC721OpenEdition Contract**:
 
  1. `constructor(ref self: ContractState, creator: ContractAddress, name: ByteArray, symbol: ByteArray, token_base_uri: ByteArray,
  allowed_flex_drop: Array::<ContractAddress>)`:
  The contract's `constructor` function intializes  parameters which will be exectuted once when the contract is deployed.
  That means this parameters can not be changed after the contract is deployed

  2. `update_allowed_flex_drop(ref self: ContractState, allowed_flex_drop: Array::<ContractAddress>)`: The function is designed to manage the FlexDrop by updating the State with the new allowed flex drop when this function is called. It loops the allpwed flex drop, checks the length and increase it by 1 to include the index of the new allowed flex drop.

  3. `mint_flex_drop(ref self: ContractState, minter: ContractAddress, phase_id: u64, quantity: u64)`: This function allows FlexDrop contracts to mint the RC721OpenEdition NFT. It utilizes reentrancy protection and it internally calls `safe_mint_flex_drop` to perform the minting of the token explicitly specifying the required parameters.

  4. `create_new_phase_drop(ref self: ContractState, flex_drop: ContractAddress, phase_detail: PhaseDrop, fee_recipient: ContractAddress)`: This function interacts with the FlexDrop dispatcher to initiate new minting phases. The function asserts for the restriction of only owner and also for the allowed flex drop. 

  5. `update_phase_drop(ref self: ContractState, flex_drop: ContractAddress, phase_id: u64, phase_detail: PhaseDrop)`:This function updates the details of existing phaseDrops in the contract. It has a check for access control through the `assert_owner_or_self` to ensures that only the contract owner or the contract itself  can execute the function and also validation  check through  `assert_allowed_flex_drop`. It also allows for modifying the minting conditions within existing phase.

  6. `update_creator_payout(ref self: ContractState, flex_drop: ContractAddress, payout_address: ContractAddress) `: This function is designed to update the payout address for FlexDrop by changing the address that receives payouts with correct`payout_address` as specified in the function parameters. It as checks who execute the function through `assert_owner_or_self` to ensures of the ownable logic.

  7. `update_payer(ref self: ContractState, flex_drop: ContractAddress, payer: ContractAddress, allowed: bool)`: The function updates the address for paying gas fee of minting the NFT in the contract. It checks if the payers address to update the contract state is allowed, if yes it returns true; else it returns false. It asserts for the authourised caller of the function and allowed flex drop.

  8. ` multi_configure(ref self: ContractState, config: MultiConfigureStruct)`: This function which is only executed by the owner of the contract enables dynamic changes like setting the `base_uri`and `contract_uri` if their length is > 0, updating `phase_drops`, and modifies `update_creator_payout` and `update_payer` with configured parameters. It also update the`create_new_phase_drop` and `update_phase_drop` function based on the provided configuration Parameters.

  9. `get_mint_state(self: @ContractState, minter: ContractAddress, phase_id: u64) -> (u64, u64, u64)`: This function provides information on the minting state, such as the `total_minted` token per a wallet address,The `current_total_supply` of the erc721openedition token that is minted.

  10. `get_current_token_id(self:@ContractState) -> u256`: This function reads the `ContractState` and return the id of the current erc721openedition token that has been minted.

  11. `get_allowed_flex_drops(self:@ContractState) -> Span::<ContractAddress>`: The function is executed to retrieve and return the list of currently allowed FlexDrop addresses from the contract's storage.

  12. `safe_mint_flex_drop(ref self: ContractState, to: ContractAddress, phase_id: u64, quantity: u64)`: This is an internal function that performs the minting operation. It mints tokens to the `ContractAddress`, taking into consideration the parameters specified and also ensuring they are no reentrancy attacks. this function updates the `index` and `current_token_id` in the contract.

  13. `assert_allowed_flex_drop(self: @ContractState, flex_drop: ContractAddress)`: This function is put in place to check whether a FlexDrop address is allowed to execute minting and phase update functions. It reverts a message which reads `Only allowed FlexDrop'` if the address calling the functions with the check are not allowed.
  
  14. `get_total_minted(self: @ContractState) -> u64 `: The function reads the contract state retrieves the `total_minted` value of OpenEdition Non-Fungible Token minted in the contract.
 
  15. `assert_owner_or_self(self: @ContractState)`: This function is put in place verifies that the contract utilizes the ownable logic. That is, only the contract owner or the contract itself can perform state changing updates, used across multiple functions that require access control.
  

### FlexDrop Contract
The `FlexDrop` contract is designed for managing ERC721OpenEdition NFT drops with features such as the minting phase of the NFT, payment handling, whitelist minting, phase update amongst others. 

#### Contract Features 

This contract integrates imported interfaces and internal logic to manage flexible and secure NFT drops. It uses PausableComponent, security features such as reentrancy guard and ownership check from the openzeppelin. This ensures that the flexdrop securely managed.

The flex drop contract has structures(struct) for the storage, flexdrop minted, phase drop updated,creatorpayout updated, fee recipient updated, and payer updated. Aside the storage struct, every of the struct emits an event when they are updated. other events in this contract include; OwnableEvent, PausableEvent, and ReentrancyGuardEvent. 


- **Functions in the FlexDrop contract**

  1. `constructor(ref self: ContractState, owner: ContractAddress, currency_manager: ContractAddress, fee_currency: ContractAddress, fee_mint: u256, fee_mint_when_zero_price: u256, new_phase_fee: u256, domain_hash: felt252, validator: ContractAddress, signature_checker: ContractAddress,fee_recipients: Span::<ContractAddress>)`:This function initializes the contract with parameters setting it up to the intial state which will be exectuted once when the contract is deployed.

  2. `mint_public(ref self: ContractState, nft_address: ContractAddress, phase_id: u64, fee_recipient: ContractAddress, minter_if_not_payer: ContractAddress, quantity: u64, is_warpcast: bool)`: The function allow for public minting of the openedition NFT. It checks if the contract is not paused so as to prevent any action if it is. The contract checks reentrancy at the beginning and the end of the minting process. It validates the mint request, including phase status, allowed payer, and fee recipient. It also calculates the total mint price and processes the mint and pay.

  3. `whitelist_mint(ref self: ContractState, whitelist_data: WhiteListParam, fee_recipient: ContractAddress, proof: Array<felt252>)`: This function permits for minting of the openedition NFT for a whitelisted address based on the provided proof. It checks and validate the whitelist proof using the signature checker and checks if the proof is already used or if the address can mint the NFT in that particular phase. It protects for reentrancy at the beginning and end of minting. 

  4. `start_new_phase_drop(ref self: ContractState, phase_drop_id: u64, phase_drop: PhaseDrop, fee_recipient: ContractAddress)`: This function is designed to facilitate starting a new phase drop. It Checks if the caller is allowed. Most importanctly, the function asserts for only nonfungible flexdrop token, if the phase is not already started, that is; if its paused or unpaused. It checks the phase details and ensures that the required fee for starting a new phase drop is paid by which is an ERC20 token from the payer.

  5. `update_phase_drop(ref self: ContractState, phase_drop_id: u64, phase_drop: PhaseDrop)`: The function is designed to update the process of phase drops for the openedition NFT. It is done within the specified `start_time` and `timeout` for updating flexDrop. It checks to safegaurd against incorrect or unauthorized token type, for reentrancy at the beginning and end of the update process. It also emit an event for `PhaseDropUpdated`. 

  6. `update_creator_payout_address(ref self: ContractState, new_payout_address: ContractAddress)`: This function updates the payout address for the creator of  openedition NFT. Ensures the provided payout address is not address zero. It emits an event for `CreatorPayoutUpdated` to log the new payout address.

  7. `update_payer(ref self: ContractState, payer: ContractAddress, allowed: bool)`: This function adds the allowed payer for minting if allowed returns true and removes the payer if allowed returns false respectively as the case may be. It then emit an event for `PayerUpdated`.  Generally, It manages the list of allowed payers for the openedition NFT. 

  8. `pause(ref self: ContractState)` and `unpause(ref self: ContractState)`: These two functions are designed to enable or disable certain functions based on the contract state. The contract ensures that only the contract owner can call both the pause and the unpause functions respectfully.

  9. `change_currency_manager(ref self: ContractState, new_currency_manager: ContractAddress)`:This function is responsible for updating the currency manager contract address with the `new_currency_manager` strictly to be done by the contract owner thereby ensuring secure updates.

  10. `change_protocol_fee_mint(ref self: ContractState, new_fee_currency: ContractAddress, new_fee_mint: u256)`: This function is designed to update the minting fee and its currency in the contract. It checks if the old mint fee and currency differ then make changes for both to the  `new_fee_mint` and `new_fee_currency` respectively.

  11. `change_protocol_fee_mint_when_zero_price(ref self: ContractState, new_fee_currency: ContractAddress, new_fee_mint_when_zero_price: u256)`: The function checks if the `old_fee_mint_when_zero_price` is not equal to the `new_fee_mint_when_zero_price` then change the previous fee_mint to the new fee_mint and also update `fee_currency` when the mint price is zero.

  12. `update_protocol_fee_recipients(ref self: ContractState, fee_recipient: ContractAddress, allowed: bool)`: This function manages the  allowed address for the fee_recipient, ensuring that the allowed address is not an address zero or a duplicate fee recipient. If reverse is the case and all assertions for the two conditions do not pass, it through errors for `Only nonzero fee recipient` and `Duplicate fee recipient` respectively.

  13. `get_fee_currency(self: @ContractState) -> ContractAddress`: This function fetch and returns the `fee_currency` that is paid while minting the openedition NFT from the contract state.

  14. `get_fee_mint(self: @ContractState) -> u256` and `get_fee_mint_when_zero_price(self: @ContractState) -> u256`: The `get_fee_mint` function retrieves the fee that is paid for minting the NFT. While the `fee_mint_when_zero_price` function fetches the fee that is paid even when the mint price of the NFT is zero. 

  15. `get_new_phase_fee(self: @ContractState) -> u256`: This function retrieves and return the fee for new minting phase of the openedition NFT.

  16. `update_new_phase_fee(ref self: ContractState, new_fee: u256)`: This function leverages the ownable logic allowing only the owner to update the contract's state with the new fee to paid for each minting phase.

  17. `update_validator(ref self: ContractState, new_validator: ContractAddress)`, `get_validator(self: @ContractState) -> ContractAddress`: The `update_validator` function is primarily to update the new validator's address who is resposible for verifying signatures and proofs provided in the contract for specific functions. Only the contract owner is allowed to make this update.  For the `get_validator` function, it fetches and return the `new_validator` address that has been updated to ensure it is the right validator.

  18. `update_domain_hash(ref self: ContractState, new_domain_hash: felt252)`: This function is designed to update the contract's state with the `new_domain_hash` which is used by the contract to define the domain where certain transactions like proof verifications will be carried out. This function is only executed by the owner of the contract to ensure security and to restrict other addresses from having access to the function.

  19. `get_domain_hash(self: @ContractState) -> felt252`: This function retrieves and return the current domain hash that has been updated and is stored in the contract's state.

  20. `update_signature_checker(ref self: ContractState, new_signature_checker: ContractAddress)`: The function is designed to update the the contracts signature checker with the `new_signature_checker` in the contract's state. This function call is  restricted to only the contract owner.

  21. `get_signature_checker(self: @ContractState) -> ContractAddress`: This function fetches and return the contract's current signature checker from the contract state where it was stored.

  22. `get_phase_drop(self: @ContractState, nft_address: ContractAddress, phase_id: u64) -> PhaseDrop`: The `get_phase_drop` function retrieves the information of the phase drop associated with the specified `nft_address` and `phase_id`.

  23. `get_currency_manager(self: @ContractState) -> ContractAddress`: This function returns the `contract_address` of the current currency manager from the `currency_manager` storage. 

  24. `get_protocol_fee_recipients(self: @ContractState, fee_recipient: ContractAddress) -> bool`:This function checks if a specified `fee_recipient`address is actually the recipient of the protocol fee. If the address is the right address it returns true, else; it returns false.

  25. `get_creator_payout_address(self: @ContractState, nft_address: ContractAddress) -> ContractAddress`: This function retrieves the new `creator_payout_address` for making payment to the nft address from the contract's state which should not be an address zero.

  26. `get_enumerated_allowed_payer(self: @ContractState, nft_address: ContractAddress) -> Span::<ContractAddress>`: The function returns an an address from a list of addresses which is allowed to make payment for the `nft_address` provided. 

  27. `assert_only_non_fungible_flex_drop_token(self: @ContractState)`:This function writes a check to ensure that only supported NFT flex drops

  28.  `validate_new_phase_drop(self: @ContractState, phase_drop: @PhaseDrop)`:This function validates  the new phase drop configurations to ensure they meet the  supported standards. It asserts for start and end time for the phase drop to be as specified in the contract, the phase type which should == 1, the max mint Per wallet which should be > 0, and the whitelisted_currency.

  29. `assert_active_phase_drop(self: @ContractState, phase_drop: @PhaseDrop)`: To check that a phase drop is active, this function asserts that the phase drop's `start_time` is less than or equal the `block_time` and `end_time` is greater than the block time stamp else it reverts with the error message "public drop not active".

  30. `assert_whitelisted_currency(self: @ContractState, currency: @ContractAddress)`: This function asserts that a currency is verified by the currency manager as being whitelisted. If it's not whitelisted, the assertion will fail and revert with a "Currency not whitelisted" error message

  31. `assert_allowed_payer(self: @ContractState, nft_address: ContractAddress, payer: ContractAddress)`: This function checks that the specified payer's address is an allowed_payer. If the address is not allowed, it reverts with the "Only allowed payer" error message.

  32. `assert_valid_mint_quantity(self: @ContractState, nft_address: @ContractAddress, minter: @ContractAddress, phase_id: u64, quantity: u64, max_total_mint_per_wallet: u64,)`: The function is resposible for checking that; The minted quantity is greater than zero, the total minted quantity is less than or equal max total mint per wallet, The current supply and quantity is less than or equal total supply.

  33. `assert_allowed_fee_recipient(self: @ContractState, fee_recipient: @ContractAddress,)`: This function checks that the fee recipient is the allowed fee recipient in the flexDrop contract, if not it will revert that "only allowed fee recipient".

  34. `mint_and_pay(ref self: ContractState, nft_address: ContractAddress, payer: ContractAddress, minter: ContractAddress, is_warpcast: bool, phase_id: u64, quantity: u64, currency_address: ContractAddress, total_mint_price: u256, fee_recipient: ContractAddress, is_whitelist_mint: bool)`: The mint and pay function is reponsible for managing the minting of the NFT and all the payments made during the minting process. It calls the `split_payout` function to make the payment to all recipients. After the successful minting and  payments, an event is emitted for `flexDropMinted`.
 
  35. `split_payout(ref self: ContractState, from: ContractAddress, is_warpcast: bool, nft_address: ContractAddress, fee_recipient: ContractAddress, currency_address: ContractAddress, total_mint_price: u256, is_whitelist_mint: bool,)`: This function is designed to distribute fees from the openediton NFT minting process to address specified in the contract . It is called in the `mint_and_pay` function to split and send fees to each recipient who took part in the minting proccess like the creator.

  36. `remove_enumerated_allowed_payer(ref self: ContractState, nft_address: ContractAddress, to_remove: ContractAddress)`: The function loops through the list of allowed payers and remove a specified address of the `enumerated_allowed_payer` from the list.
 

3. `marketplace`: Includes implementation of the marketplace contracts

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

## Notes
- Ensure you use `scarb` version `2.6.3` for compatibility.