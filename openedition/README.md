## ERC721OpenEditionMultiMetadata
The `ERC721OpenEditionMultiMetadata` contract enables flexible minting phases, secure operations, and dynamic configuration for ERC721 Open Edition Tokens. It supports multiple metadata and uses components from Alexandria Storage, OpenZeppelin, and OpenEdition utils.

### Key Features
1. **Metadata Management:** Uses `ERC721MultiMetadataComponent` from OpenZeppelin to handle multiple metadata sets.
2. **FlexDrop Integration:** Integrates `IFlexDropDispatcher` and `INonFungibleFlexDropToken` for flexible minting and phase management.
3. **Access Control:** Restricts minting functionalities to approved `allowed_flex_drop` contracts.
4. **Phase Management:** Allows creation, updating, and management of drop phases with different minting conditions.
5. **Ownership Control:** Utilizes `OwnableComponent` to ensure only the owner or contract can perform certain actions.
6. **Reentrancy Protection:** Includes `ReentrancyGuardComponent` to prevent reentrancy attacks.
7. **Configuration:** Through `multi_configure`, allows setting multiple parameters like `base_uri`, `contract_uri`, phase details, and allowed payers for gas fees.

## ERC721OpenEdition Contract
The `ERC721OpenEdition` contract is a StarkNet smart contract that integrates ERC-721 standards and flex-drop for minting open edition tokens. It uses `OwnableComponent` to restrict state-changing functions to the owner and `ReentrancyGuardComponent` to prevent attacks. The contract emits events, such as `UpdateAllowedFlexDrop`, to log changes like updates to the allowed flex drop.

### Functions in the  ERC721OpenEdition Contract
1. **`constructor(ref self: ContractState, creator: ContractAddress, name: ByteArray, symbol: ByteArray, token_base_uri: ByteArray, allowed_flex_drop: Array::<ContractAddress>)`**: Initializes parameters once on contract deployment; cannot be changed afterward.

2. **`update_allowed_flex_drop(ref self: ContractState, allowed_flex_drop: Array::<ContractAddress>)`**: Updates the state with new allowed flex drop addresses, increasing the allowed list by 1.

3. **`mint_flex_drop(ref self: ContractState, minter: ContractAddress, phase_id: u64, quantity: u64)`**: Allows FlexDrop contracts to mint ERC721OpenEdition NFTs, using reentrancy protection and calling `safe_mint_flex_drop` internally.

4. **`create_new_phase_drop(ref self: ContractState, flex_drop: ContractAddress, phase_detail: PhaseDrop, fee_recipient: ContractAddress)`**: Initiates new minting phases by interacting with the FlexDrop dispatcher, restricted to the owner and allowed flex drop contracts.

5. **`update_phase_drop(ref self: ContractState, flex_drop: ContractAddress, phase_id: u64, phase_detail: PhaseDrop)`**: Updates phase details with owner-only access, ensuring correct flex drop validation.

6. **`update_creator_payout(ref self: ContractState, flex_drop: ContractAddress, payout_address: ContractAddress)`**: Updates the payout address for FlexDrop, restricted to the owner or contract itself.

7. **`update_payer(ref self: ContractState, flex_drop: ContractAddress, payer: ContractAddress, allowed: bool)`**: Updates the payer address for minting gas fees, ensuring the address is allowed and authorized.

8. **`multi_configure(ref self: ContractState, config: MultiConfigureStruct)`**: Allows the owner to dynamically configure parameters like `base_uri`, `contract_uri`, phase drops, and payout/payee updates.

9. **`get_mint_state(self: @ContractState, minter: ContractAddress, phase_id: u64) -> (u64, u64, u64)`**: Retrieves minting state details like total minted tokens per wallet and current total supply.

10. **`get_current_token_id(self:@ContractState) -> u256`**: Returns the ID of the current minted ERC721OpenEdition token.

11. **`get_allowed_flex_drops(self:@ContractState) -> Span::<ContractAddress>`**: Retrieves the list of allowed FlexDrop contract addresses from the contract storage.

12. **`safe_mint_flex_drop(ref self: ContractState, to: ContractAddress, phase_id: u64, quantity: u64)`**: Internal minting function that ensures reentrancy protection and updates `index` and `current_token_id`.

13. **`assert_allowed_flex_drop(self: @ContractState, flex_drop: ContractAddress)`**: Ensures only allowed FlexDrop contracts can execute minting and phase updates, reverting unauthorized calls.

14. **`get_total_minted(self: @ContractState) -> u64`**: Retrieves the total number of minted OpenEdition NFTs in the contract.

15. **`assert_owner_or_self(self: @ContractState)`**: Ensures that only the contract owner or the contract itself can execute state-changing functions.


##  FlexDrop Contract
The `FlexDrop` contract is designed for managing ERC721OpenEdition NFT drops with features such as the minting phase of the NFT, payment handling, whitelist minting, phase update amongst others. 

#### Key Features

- Integrates imported interfaces and internal logic for flexible and secure NFT drops.
- Uses `PausableComponent`, reentrancy guard, and ownership checks from OpenZeppelin for secure management.
- Has structures for storage, minted flexdrops, updated phase drops, creator payouts, fee recipients, and payers.
- Each structure emits an event when updated.
- Additional events include `OwnableEvent`, `PausableEvent`, and `ReentrancyGuardEvent`.

### Functions in the FlexDrop Contract:

1. **`constructor(ref self: ContractState, owner: ContractAddress, currency_manager: ContractAddress, fee_currency: ContractAddress, fee_mint: u256, fee_mint_when_zero_price: u256, new_phase_fee: u256, domain_hash: felt252, validator: ContractAddress, signature_checker: ContractAddress, fee_recipients: Span::<ContractAddress>)`**: Initializes the contract with parameters, executed once upon deployment.

2. **`mint_public(ref self: ContractState, nft_address: ContractAddress, phase_id: u64, fee_recipient: ContractAddress, minter_if_not_payer: ContractAddress, quantity: u64, is_warpcast: bool)`**: Allows public minting, checks contract state, validates mint request, and processes minting and payment.

3. **`whitelist_mint(ref self: ContractState, whitelist_data: WhiteListParam, fee_recipient: ContractAddress, proof: Array<felt252>)`**: Allows whitelisted minting, verifies proof, and ensures reentrancy protection.

4. **`start_new_phase_drop(ref self: ContractState, phase_drop_id: u64, phase_drop: PhaseDrop, fee_recipient: ContractAddress)`**: Starts a new phase drop with phase details and required fee payment.

5. **`update_phase_drop(ref self: ContractState, phase_drop_id: u64, phase_drop: PhaseDrop)`**: Updates existing phase drop details, checks phase validity, and ensures reentrancy.

6. **`update_creator_payout_address(ref self: ContractState, new_payout_address: ContractAddress)`**: Updates creator payout address, emits `CreatorPayoutUpdated` event.

7. **`update_payer(ref self: ContractState, payer: ContractAddress, allowed: bool)`**: Adds/removes allowed payer for minting, emits `PayerUpdated` event.

8. **`pause(ref self: ContractState)` and `unpause(ref self: ContractState)`**: Pauses or unpauses functions, callable only by the contract owner.

9. **`change_currency_manager(ref self: ContractState, new_currency_manager: ContractAddress)`**: Updates the currency manager contract address, only by the contract owner.

10. **`change_protocol_fee_mint(ref self: ContractState, new_fee_currency: ContractAddress, new_fee_mint: u256)`**: Updates minting fee and currency.

11. **`change_protocol_fee_mint_when_zero_price(ref self: ContractState, new_fee_currency: ContractAddress, new_fee_mint_when_zero_price: u256)`**: Updates mint fee when the price is zero.

12. **`update_protocol_fee_recipients(ref self: ContractState, fee_recipient: ContractAddress, allowed: bool)`**: Manages allowed fee recipients, ensuring no duplicates or zero addresses.

13. **`get_fee_currency(self: @ContractState) -> ContractAddress`**: Returns the fee currency used for minting.

14. **`get_fee_mint(self: @ContractState) -> u256` and `get_fee_mint_when_zero_price(self: @ContractState) -> u256`**: Retrieves the mint fee for general and zero price cases.

15. **`get_new_phase_fee(self: @ContractState) -> u256`**: Retrieves the fee for the new minting phase.

16. **`update_new_phase_fee(ref self: ContractState, new_fee: u256)`**: Allows the owner to update the minting phase fee.

17. **`update_validator(ref self: ContractState, new_validator: ContractAddress)`, `get_validator(self: @ContractState) -> ContractAddress`**: Updates and retrieves the validator’s address responsible for signature verification.

18. **`update_domain_hash(ref self: ContractState, new_domain_hash: felt252)`**: Updates the domain hash, restricted to the owner.

19. **`get_domain_hash(self: @ContractState) -> felt252`**: Retrieves the current domain hash.

20. **`update_signature_checker(ref self: ContractState, new_signature_checker: ContractAddress)`**: Updates the signature checker address, restricted to the owner.

21. **`get_signature_checker(self: @ContractState) -> ContractAddress`**: Retrieves the current signature checker address.

22. **`get_phase_drop(self: @ContractState, nft_address: ContractAddress, phase_id: u64) -> PhaseDrop`**: Retrieves phase drop information based on `nft_address` and `phase_id`.

23. **`get_currency_manager(self: @ContractState) -> ContractAddress`**: Returns the current currency manager address.

24. **`get_protocol_fee_recipients(self: @ContractState, fee_recipient: ContractAddress) -> bool`**: Checks if the address is a valid fee recipient.

25. **`get_creator_payout_address(self: @ContractState, nft_address: ContractAddress) -> ContractAddress`**: Retrieves the creator’s payout address for a specific NFT.

26. **`get_enumerated_allowed_payer(self: @ContractState, nft_address: ContractAddress) -> Span::<ContractAddress>`**: Returns a list of allowed payers for a specific NFT.

27. **`assert_only_non_fungible_flex_drop_token(self: @ContractState)`**: Ensures only supported NFT flex drops are used.

28. **`validate_new_phase_drop(self: @ContractState, phase_drop: @PhaseDrop)`**: Validates new phase drop configurations based on start/end times and other criteria.

29. **`assert_active_phase_drop(self: @ContractState, phase_drop: @PhaseDrop)`**: Asserts that the phase drop is active within the specified timeframe.

30. **`assert_whitelisted_currency(self: @ContractState, currency: @ContractAddress)`**: Ensures the currency is whitelisted for the minting process.

31. **`assert_allowed_payer(self: @ContractState, nft_address: ContractAddress, payer: ContractAddress)`**: Ensures the payer is allowed to mint the NFT.

32. **`assert_valid_mint_quantity(self: @ContractState, nft_address: @ContractAddress, minter: @ContractAddress, phase_id: u64, quantity: u64, max_total_mint_per_wallet: u64)`**: Validates the mint quantity and ensures limits are not exceeded.

33. **`assert_allowed_fee_recipient(self: @ContractState, fee_recipient: @ContractAddress)`**: Ensures only allowed fee recipients are used.

34. **`mint_and_pay(ref self: ContractState, nft_address: ContractAddress, payer: ContractAddress, minter: ContractAddress, is_warpcast: bool, phase_id: u64, quantity: u64, currency_address: ContractAddress, total_mint_price: u256, fee_recipient: ContractAddress, is_whitelist_mint: bool)`**: Manages minting and payments, and emits `flexDropMinted` event.

35. **`split_payout(ref self: ContractState, from: ContractAddress, is_warpcast: bool, nft_address: ContractAddress, fee_recipient: ContractAddress, currency_address: ContractAddress, total_mint_price: u256, is_whitelist_mint: bool)`**: Distributes minting fees to recipients.

36. **`remove_enumerated_allowed_payer(ref self: ContractState, nft_address: ContractAddress, to_remove: ContractAddress)`**: Removes a payer from the list of allowed payers.
