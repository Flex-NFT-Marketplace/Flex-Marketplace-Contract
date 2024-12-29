## Marketplace
Implementation of the marketplace contracts
##### Marketplace Contracts List

* CurrencyManager
* ExecutionManager
* Marketplace 
* Proxy
* RoyaltyFeeManager
* RoyaltyFeeRegistry
* SignatureChecker2
* StrategyHighestBidderAuctionSale
* StrategyStandardSaleForFixedPrice
* TransferManagerNFT
* ERC1155TransferManager
* TransferSelectorNFT



**CurrencyManager**

The CurrencyManager contract allows the owner to manage a whitelist of currencies, storing them and their indices using LegacyMap.

***Key Features***
 - **Ownership Control**: Only the owner can modify the whitelist using OpenZeppelin's `OwnableComponent`.  
 - **Whitelisting Currencies**: The owner can add or remove currencies from the whitelist.  
 - **Event-Driven**: Events notify changes to the whitelist for transparency and communication. 


***Contract Functions***

1. `initializer(ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress)` :
   
   Sets up the initial state of the contract. assigns the owner and ensures that the contract can only be initialized once. If the contract has already been initialized, it will throw an error. It also calls the initializer function of the OwnableComponent to manage ownership logic.

2. `add_currency(ref self: ContractState, currency: ContractAddress)` :

    Allows the contract owner to add a new currency to the whitelist. It first checks if the currency is already whitelisted by looking up its index. If not, it increments the count of whitelisted currencies, adds the new currency to the list, and updates the mapping of currency indices. Then emits a `CurrencyWhitelisted` event with the current timestamp.

3. `remove_currency(ref self: ContractState, currency: ContractAddress)` :

   Allows the owner to remove a currency from the whitelist. verifies whether the currency is currently whitelisted by checking its index. If whitelisted, it replaces the currency with the last one in the list, updates the indices, and reduces the count of whitelisted currencies also emits a `CurrencyRemoved` event with the current timestamp.

4. `is_currency_whitelisted(self: @ContractState, currency: ContractAddress) -> bool` :

    This function checks if a given currency is on the whitelist by looking up its index. If the index is non-zero, the currency is considered whitelisted, and the function returns true; otherwise, it returns `false`.

5. `whitelisted_currency_count(self: @ContractState) -> usize` :

    Returns the total number of currencies currently on the whitelist. It simply reads the `whitelisted_currency_count` from storage, which tracks how many currencies have been added to the whitelist.

6.  `whitelisted_currency(self: @ContractState, index: usize) -> ContractAddress` :

    Retrieves the currency at a specific position in the whitelist based on the provided index. It looks up the currency’s address in the list and returns it. useful for iterating through or displaying the list of whitelisted currencies.

**ExecutionManager**
The ExecutionManager contract manages a whitelist of authorized strategies, with ownership control via OwnableComponent.

***Key Features***
 - **Ownership and Access Control**: The contract uses `OwnableComponent` to restrict critical functions to the owner.  
 - **Strategy Whitelisting**: The contract manages a whitelist of execution strategies by their `ContractAddress`.  
 - **Event Emission**: Events are emitted when strategies are added or removed, ensuring transparency.

***Contract Functions***
1. `initializer(ref self: ContractState, owner: ContractAddress)` :
   
    Initializes the contract, setting up the initial state and assigning the owner. ensures the contract is only initialized once by checking if it has already been initialized `(assert!(!self.initialized.read(), "ExecutionManager: already initialized");)`. Once initialized, the `OwnableComponent` is set up with the provided owner address.

2. `add_strategy(ref self: ContractState, strategy: ContractAddress)` :

    Allows the owner to add a new strategy to the whitelist. checks if the strategy is already whitelisted using the `whitelisted_strategies_index` map. If not, the strategy is added, the strategy count is incremented, and a `StrategyWhitelisted` event is emitted.

3. `remove_strategy(ref self: ContractState, strategy: ContractAddress)` :

    Allows the owner to remove a strategy from the whitelist. It verifies that the strategy is currently whitelisted, then removes it and adjusts the indices in the list. A `StrategyRemoved` event is emitted to inform external observers of the change.

4. `is_strategy_whitelisted(self: @ContractState, strategy: ContractAddress) -> bool` :

    Checks if a specific strategy is whitelisted. returns `true` if the strategy is on the whitelist and `false` if it is not. This is crucial for determining the validity of a strategy before execution.

5. `get_whitelisted_strategies_count(self: @ContractState) -> usize` :

    Returns the total number of whitelisted strategies. It provides a simple way to retrieve the size of the whitelist, which can be useful for iterating over all strategies or for display purposes.

6. `get_whitelisted_strategy(self: @ContractState, index: usize) -> ContractAddress` :

    Retrieves a strategy from the whitelist based on its index. It allows external contracts or users to access specific strategies by their position in the list, enabling iteration or specific strategy retrieval for execution or analysis.

**MarketPlace**
Manages decentralized asset trading on Starknet, ensuring secure transactions with ownership, upgradability, and reentrancy protection. Its modular design allows for flexibility and future enhancements.

***key Features***
 - **Initialization and Ownership**: The contract initializes essential parameters and uses `OwnableComponent` for ownership control, allowing only the owner to perform privileged actions.  
 -  **Upgradability**: The contract is upgradeable via `UpgradeableComponent`, ensuring future enhancements without system disruption.  
 -  **Order Management**: Users can cancel specific or all active orders for flexibility in the trading process.  
 -  **Order Matching**: The contract matches orders between buyers and sellers, ensuring correct fee transfer and asset movement.  
 -  **Auction Handling**: The contract supports auction sales, allowing dynamic pricing through bidding.  
 -  **Fee and Royalty Management**: It manages protocol fees and royalties, updating manager contracts as needed.  
 -  **Signature Verification**: The contract verifies the authenticity of orders using `signature_checker` to ensure transaction integrity.  
 -  **Security and Reentrancy Protection**: It uses `ReentrancyGuardComponent` to prevent reentrancy attacks, ensuring secure execution.

***Contract Functions***


1. `initializer()` :

    Initializes the contract by setting up critical state variables like the hash domain, protocol fee recipient, and various managers (currency, execution, royalty, etc.). It also assigns ownership and administrative roles.

2. `upgrade()` :

    Allows the contract owner to upgrade the contract's logic by providing a new class hash.essential for maintaining the contract's functionality over time.

3. `cancel_all_orders_for_sender()` :

    Cancels all orders for the sender with a nonce greater than a specified minimum.emits an event to notify the marketplace of the cancellation.

4. `cancel_maker_order()` :

    Cancels a specific order based on its nonce.ensures that the order is not executed or canceled multiple times and emits an event upon successful cancellation.

5. `match_ask_with_taker_bid()` :

    Matches a taker bid with a maker ask, facilitating a transaction between the buyer and seller it validates the orders, transfers fees, funds, and the NFT, and then emits an event to record the transaction.

6. `match_bid_with_taker_ask()` :

    Matches a taker ask with a maker bid, enabling the sale of an asset to the highest bidder. This follows similar steps as match_ask_with_taker_bid() but in reverse order, ensuring that all conditions are met before executing the sale.

7. `execute_auction_sale()` :

    Executes a sale through an auction mechanism, matching the highest bid with the reserve price. It handles the transfer of assets and funds and ensures the auction rules are followed.

8. `update_hash_domain()` :

    Updates the hash domain used for computing order hashes. This function can be used to modify the underlying cryptographic parameters of the marketplace.

9.  `update_protocol_fee_recepient()` :

    Allows the contract owner to update the recipient of protocol fees, enabling dynamic management of fee collection.

10. `update_currency_manager()`, `update_execution_manager()`, `update_royalty_fee_manager()`, `update_transfer_selector_NFT()`, `update_signature_checker()` :

    Allows the contract owner to update various managers responsible for different aspects of the marketplace, such as currency management, execution strategies, and signature verification.

11. `get_hash_domain()`, `get_protocol_fee_recipient()`, `get_currency_manager()`, `get_execution_manager()`, `get_royalty_fee_manager()`, `get_transfer_selector_NFT()`, `get_signature_checker()` :

    These getter functions return the current state of various contract variables, allowing users and external systems to query important information about the marketplace's configuration.

12. `get_user_min_order_nonce()`:  

     Retrieves the minimum order nonce for a given user, which is used to track the user's active orders and prevent replay attacks.

14. `get_is_user_order_nonce_executed_or_cancelled()`:  

    Checks whether a specific order nonce has been executed or canceled, providing a way to verify the status of an order.



**Proxy**
The Proxy contract enables smart contract upgrades on StarkNet without disrupting the system or user interactions.

***key Features***

 - **Contract Upgradeability**: The Proxy contract enables upgrades via the `upgrade` function, replacing contract logic with a new `ClassHash`.  
 - **Admin Control**: The admin can be changed with `set_admin`, controlling upgrades and contract operations.  
 - **Default Fallback Mechanism**: Undefined function calls are forwarded to the current implementation via fallback functions.

 ***Contract Functions***

1. `upgrade(ref self: ContractState, new_implementation: ClassHash)` :

   Responsible for upgrading the contract's logic by updating the `ClassHash` to point to a new implementation. This allows the contract to evolve without changing its address or disrupting ongoing operations.

2. `set_admin(ref self: ContractState, new_admin: ContractAddress)` :
    
    Sets a new admin for the contract, transferring control and responsibility to the new address. The admin is the entity with the authority to upgrade the contract and manage its critical settings.

3.  `get_implementation(self: @ContractState) -> ClassHash` :
  
    This function returns the current implementation's `ClassHash`, allowing external parties to verify which contract logic is currently active.

4.  `get_admin(self: @ContractState) -> ContractAddress` :
  
    Retrieves the current admin's address, providing transparency regarding who controls the Proxy's upgrade functionality.

5.  `__default__(self: @ContractState, selector: felt252, calldata: Span<felt252>) -> Span<felt252>` :
   
    This fallback function is invoked when a call is made to a function that does not exist in the Proxy contract. It ensures that such calls are forwarded to the current implementation, maintaining the Proxy's role as a conduit for interacting with the underlying logic.

6.  `_l1_default__(self: @ContractState, selector: felt252, calldata: Span<felt252>)` :
  
    Similar to `__default__`, this function handles calls from Layer 1 (L1), ensuring that these calls are also forwarded to the appropriate implementation logic.

**RoyaltyFeeManager**
calculates and manages royalty fees for digital asset sales on StarkNet, using ERC-2981 standards and a royalty fee registry

***Key Feature***
 -  **Royalty Calculation and Distribution**: The contract calculates royalty fees and determines recipients using the `calculate_royalty_fee_and_get_recipient` function and ERC-2981.  
 -  **Integration with Royalty Fee Registry**: The contract interfaces with a `RoyaltyFeeRegistry` to fetch royalty fee data for collections.  
 -  **Support for ERC-2981 Standard**: The contract supports ERC-2981, allowing it to fetch royalty details directly from compliant collections.  
 - **Upgradeable Architecture**: The contract is upgradeable via the `upgrade` function, allowing logic changes without redeployment.  
 -  **Ownership and Access Control**: The contract uses `OwnableComponent` for ownership, restricting critical operations to the owner.
 
 ***Contract Functions***

1. `initializer(ref self: ContractState, fee_registry: ContractAddress, owner: ContractAddress)` :
   
    Initializes the contract, setting the ERC-2981 interface ID, linking the contract to the specified royalty fee registry, and assigning the contract's owner.called once during contract deployment to configure the initial state.

2. `upgrade(ref self: ContractState, impl_hash: ClassHash)` :
   
   Allows the contract owner to upgrade the contract by providing a new implementation `ClassHash`.crucial for maintaining the contract's flexibility and ensuring it can adapt to new requirements or improvements without redeploying.

3. `INTERFACE_ID_ERC2981(self: @ContractState) -> felt252` :
   
    Returns the unique identifier for the ERC-2981 interface, allowing the contract to check whether a given collection adheres to this standard.used in conjunction with other functions to determine how to calculate royalties.

4. `calculate_royalty_fee_and_get_recipient(self: @ContractState, collection: ContractAddress, token_id: u256, amount: u128) -> (ContractAddress, u128)` :
   
    Calculates the royalty fee for a given sale and returns the recipient address and fee amount. It first checks the royalty fee registry, and if no data is found, it checks if the collection supports ERC-2981 to retrieve the necessary information. This function is central to ensuring that creators receive their due royalties during asset sales.

5. `get_royalty_fee_registry(self: @ContractState) -> IRoyaltyFeeRegistryDispatcher` :
    Returns the contract address of the linked royalty fee registry. The registry is where the contract looks first to find information about royalty fees for specific collections, making it an essential component of the overall royalty calculation process.

**RoyaltyFeeRegistry**
The `RoyaltyFeeRegistry` contract manages and enforces royalty fees on StarkNet, allowing the owner to set limits, update collection details, and retrieve royalty information.

***Key features***
 -  **Royalty Fee Management**: The contract registers and manages royalty fees, allowing the owner to update collection-specific information with `update_royalty_info_collection`.  
 -  **Ownership and Access Control**: Using `OwnableComponent`, only the owner can update fees or modify information, ensuring restricted access to critical functions.  
 -  **Event Emission for Transparency**: Events like `NewRoyaltyFeeLimit` and `RoyaltyFeeUpdate` log changes to royalty fees for transparency.  
 -  **Royalty Fee Limit Enforcement**: The contract enforces a maximum royalty fee limit, with the owner able to adjust it via `update_royalty_fee_limit`.  
 -  **Royalty Fee Calculation**: The `get_royalty_fee_info` function calculates royalty fees for transactions, ensuring correct distribution to recipients.


 ***Contract Functions***

1. `initializer(ref self: ContractState, fee_limit: u128, owner: ContractAddress)` :

    Initializes the contract, setting the maximum royalty fee limit and assigning ownership.ensures that the contract is only initialized once, preventing reconfiguration after deployment.Also checks that the initial fee limit is within the allowed maximum.

2. `update_royalty_fee_limit(ref self: ContractState, fee_limit: u128)` :

    Allows the contract owner to update the maximum allowable royalty fee limit.Ensures that the new limit is within the predefined maximum and emits an event to log the change. crucial for maintaining control over the fee structure as market conditions evolve.

3. `update_royalty_info_collection(ref self: ContractState, collection: ContractAddress, setter: ContractAddress, receiver: ContractAddress, fee: u128)` :

    Updates the royalty information for a specific digital asset collection. It records who set the royalty, who will receive it, and the percentage fee. It ensures that the fee does not exceed the limit set by the owner and emits an event to log the update. This is key to maintaining accurate and fair royalty distribution.

4. `get_royalty_fee_limit(self: @ContractState) -> u128` :

   Retrieves the current maximum royalty fee limit. used internally to validate that any updates to collection royalties do not exceed this limit. It also provides transparency by allowing anyone to check the enforced fee limit.

5. `get_royalty_fee_info(self: @ContractState, collection: ContractAddress, amount: u128) -> (ContractAddress, u128)` :

    Calculates the royalty amount for a given transaction and returns the recipient's address and the royalty amount.Ensures that the correct royalty is applied based on the transaction value and the fee percentage registered for the collection.

6. `get_royalty_fee_info_collection(self: @ContractState, collection: ContractAddress) -> (ContractAddress, ContractAddress, u128)` :

   Retrieves detailed royalty information for a specific collection, including the addresses of the setter and receiver, and the fee percentage. It provides transparency and allows stakeholders to verify the registered royalty details.

**Signature_Checkers2**
The SignatureChecker2 contract verifies digital signatures for Maker Orders and whitelist minting, ensuring authenticity and authorization.

***Key Feature***
 -  **WhiteListParam Structure**: Represents a whitelist entry with `phase_id`, `nft_address`, and minter to validate authorized NFT minting.  
 -  **Maker Order**: Contains order details like ask/bid, price, NFT collection, and validity period for marketplace transactions.  
 -  **Hash Constants**: Defines hash constants for generating unique identifiers during hashing processes for various structures.  

 ***Contract Functions***

1. **Signature Verification** :
    Methods (`verify_maker_order_signature`, `verify_maker_order_signature_v2`) to verify the authenticity of a MakerOrder using its digital signature. This ensures that only orders signed by authorized entities can be executed.

2. **Hash Computation** :
   Provides functions (`compute_maker_order_hash`, `compute_message_hash`, etc.) to compute unique hashes for orders and whitelist entries. These hashes are essential for verifying the integrity and authenticity of the data.

3. **Whitelist Minting** :
  Includes functionality to handle whitelist minting, where a specific message hash is computed based on the whitelist data (`compute_whitelist_mint_message_hash`). This ensures that only those on the whitelist can mint NFTs during specific phases.

4. **Struct Hashing** :
  Defines several implementations of a `hash_struct` trait for different data types (`WhiteListParam`, `MakerOrder`, `u256`). This trait allows these structures to be hashed consistently, which is vital for their use in signature verification.


**StrategyHighestBidderAuctionSale**
The StrategyHighestBidderAuctionSale contract manages auction-based sales on Starknet, handling fees, execution checks, and upgradeability with ownership controls.

***Key Features***
 - **Ownership and Control**: Using `OwnableComponent`, only the owner can update fees or upgrade the contract, ensuring control over critical actions.  
 - **Protocol Fee Management**: The owner sets and updates a protocol fee for auction transactions, supporting platform revenue.  
 -  **Order Execution Checks**: The contract validates bid/ask execution by checking token IDs, time frames, and bid criteria.  
 - **Upgradeable Architecture**: With `UpgradeableComponent`, the contract can be upgraded without disrupting its state, enabling future improvements.


 ***Contract Functions***
1. `initializer` : Sets the initial protocol fee and assigns ownership of the contract. This function is crucial for setting up the contract’s parameters and ensuring that the correct entity has control.

2. `update_protocol_fee` : Allows the owner to modify the protocol fee. This function is restricted to the owner, ensuring that fee adjustments cannot be made arbitrarily.

3. `protocol_fee` : Returns the current protocol fee. This function provides transparency about the fee structure to users and other contracts interacting with this contract.

4. `can_execute_taker_ask` : Evaluates whether a taker’s ask can be executed against a maker’s bid. It checks conditions like token ID matching, valid auction times, and whether the bid is high enough. If all conditions are met, the function returns true along with the relevant token ID and price.

5. `can_execute_taker_bid` : Similar to the above, but for evaluating whether a taker’s bid can be executed against a maker’s ask. This function ensures that bids meet the criteria to proceed with the transaction.

6. `upgrade` : Allows the contract to be upgraded with a new implementation by the owner. This function is critical for maintaining the contract’s relevance and security as the underlying technology evolves.


**StrategyStandardSaleForFixedPrice**
The `StrategyStandardSaleForFixedPrice`, is designed to implement a strategy for fixed-price sales within a decentralized marketplace. It allows for the execution of orders where buyers and sellers can interact according to predefined rules, and it includes upgradability and ownership features for future modifications.


***Contract Features and Functions***

1. **Ownership and Upgradability** :
 Uses components from OpenZeppelin's OwnableComponent and UpgradeableComponent. These components ensure that only the owner of the contract can update critical parameters (like fees) or upgrade the contract to a new implementation.managed through the OwnableImpl and OwnableInternalImpl implementations, provides ownership-related functionalities, such as asserting ownership before performing certain actions.

2. **Protocol Fee Management** :
  The contract has a `protocol_fee` that can be initialized during the contract's deployment and later updated by the owner. This fee likely represents a percentage or fixed amount taken from each sale as a service fee for using the marketplace.

* `initializer` : This function sets the initial protocol fee and assigns the contract's owner.

* `update_protocol_fee` : Allows the owner to update the protocol fee. This function ensures that only the owner can make this change.

3. **Order Execution Logic** :
  The contract contains logic to determine whether an order can be executed based on predefined conditions, ensuring that the buyer (taker) and seller (maker) are in agreement on key parameters like price and token ID.

* `can_execute_taker_ask` : Validates whether a taker’s ask (selling request) can be matched with a maker’s bid (buying offer). It checks that the price and token ID match, and that the maker's bid is within a valid time range.

* `can_execute_taker_bid` : Similar to `can_execute_taker_ask` , but for matching a taker’s bid (buying request) with a maker’s ask (selling offer).

4. **Security and Validation** :
  Performs several checks to ensure the validity of orders. For example, it verifies that the order’s timing is correct (e.g., the current block timestamp is within the start and end time specified in the maker’s order) and that the price and token ID match between the buyer and seller. These checks ensure that transactions are fair and adhere to the agreed-upon terms, preventing issues like undercutting or executing orders that are no longer valid.

5. **Upgrade Mechanism** :
  The `upgrade` function allows the contract owner to upgrade the contract's implementation by providing a new class hash `impl_hash`. It is crucial for maintaining the contract's relevance and security over time as it allows for bug fixes, optimizations, and new features to be added without deploying a new contract.


**TransferManagementNFT**
It  is designed to manage the transfer of NFTs within a decentralized marketplace on StarkNet and ensures that NFT transfers are executed according to marketplace rules and ownership permissions.

 **Contracts and Features**

 ***Ownership Management***:
 - **Ownable Component** : The contract inherits ownership functionalities from OpenZeppelin's `OwnableComponent`. This allows only the designated owner to perform specific actions, such as initializing the contract or updating the marketplace address. The ownership logic is handled via the `OwnableImpl` and `OwnableInternalImpl` implementations.

* `Initializer` : The `initializer` function sets the contract’s marketplace address and assigns ownership. It ensures that the contract is configured correctly before any operations can take place.

 **NFT Transfer Functionality** :
 -  **transfer_non_fungible_token** : This function enables the transfer of NFTs (ERC-721 tokens) from one address to another. It ensures that only the authorized marketplace contract can initiate these transfers, adding a layer of security. The function utilizes the `IERC721CamelOnlyDispatcher` to perform the token transfer, enforcing that the caller is the marketplace.

* **Secure Transfer Verification** : Before executing a transfer, the contract verifies that the caller is indeed the marketplace contract. This prevents unauthorized transfers and ensures that the transfer logic aligns with marketplace transactions.

  **Marketplace Address Management** :
 - **update_marketplace** : This function allows the contract owner to update the address of the marketplace contract. This is useful if the marketplace contract needs to be replaced or upgraded, ensuring the `TransferManagerNFT` contract remains compatible with the correct marketplace.

 - **get_marketplace**: This function retrieves the current marketplace address stored in the contract. It ensures that the correct marketplace address is being used for validating transactions.


**ERC1155TransferManager**
Designed to manage the secure transfer of ERC-1155 tokens by restricting transfer functionality to a specific marketplace contract this incorporates ownership controls and is upgradeable, ensuring both security and flexibility in its deployment.

***Key Features***

 - **Ownership and Access Control**: Uses `OwnableComponent` to restrict critical actions to the owner, ensuring secure function execution.  
 -  **Upgradeable Contract**: Utilizes `UpgradeableComponent` to allow contract upgrades without disrupting existing functionality.  
 -  **NFT Transfer Management**: Manages ERC-1155 token transfers, allowing only the marketplace to initiate transfers.  
 -  **Event Emission**: Emits events for ownership and upgrades, enabling off-chain tracking of key state changes.

***Contract Functions***
1. `initializer(ref self: ContractState, marketplace: ContractAddress, owner: ContractAddress)`

    Initializes the contract by setting the marketplace address and the owner of the contract.Typically called once when the contract is deployed to set up the initial state.

2. `transfer_non_fungible_token(ref self: ContractState, collection: ContractAddress, from: ContractAddress, to: ContractAddress, token_id: u256, amount: u128, data: Span<felt252>)`

    Facilitates the transfer of ERC-1155 tokens from one address to another.Checks that the caller is the marketplace contract before proceeding with the transfer. It then interacts with the ERC-1155 token contract to execute the transfer.

3. `update_marketplace(ref self: ContractState, new_address: ContractAddress)`

    Allows the owner to update the marketplace contract address. It ensures that only the contract owner can make this change by using the ownership assertion provided by the OwnableComponent.

4. `get_marketplace(self: @ContractState) -> ContractAddress`

    Simple getter function that returns the current marketplace address stored in the contract. It is used to verify the marketplace address when needed, such as during token transfers.

**TransferSelectorNFT**
Designed to handle the management and selection of transfer managers for ERC-721 and ERC-1155 tokens.provides flexibility by allowing specific managers to be assigned to collections and ensures that only the correct managers are used for transfers also includes robust ownership controls and emits events for transparency in managing transfer-related operations.

***Key Features***

 -  **Multi-Token Transfer Management**: Manages ERC-721 and ERC-1155 transfers, selecting the appropriate manager for each token.  
 -   **Ownership and Access Control**: Uses `OwnableComponent` to restrict critical actions to the contract owner.  
 -  **Interface Identification**: Stores ERC-721 and ERC-1155 interface IDs to select the correct transfer manager.  
 -   **Collection-Specific Transfer Management**: Allows the owner to assign custom transfer managers to individual token collections.  
 -  **Event Emission**: Emits events when transfer managers are added or removed, ensuring transparency and traceability.

***Contract Function***
1. `initializer(ref self: ContractState, transfer_manager_ERC721: ContractAddress, transfer_manager_ERC1155: ContractAddress, owner: ContractAddress)` :
   Initializes the contract by setting the transfer managers for ERC-721 and ERC-1155 tokens and assigns the owner. Ensures that the contract is properly configured before any other operations can take place.

2. `add_collection_transfer_manager(ref self: ContractState, collection: ContractAddress, transfer_manager: ContractAddress)` :
   
   Allows the contract owner to associate a specific transfer manager with a particular token collection. Ensures that only valid addresses are used and emits an event to log the addition of the transfer manager.

3. `remove_collection_transfer_manager(ref self: ContractState, collection: ContractAddress)` :
   
   Allows the owner to remove the transfer manager associated with a specific collection. This function is useful when a collection no longer requires a custom transfer manager or when it needs to be reassigned. It also logs the removal via an event.

4. `update_TRANSFER_MANAGER_ERC721(ref self: ContractState, manager: ContractAddress)` :

   Lets the owner update the global transfer manager for ERC-721 tokens. It is essential for maintaining or upgrading the transfer mechanism for ERC-721 tokens across the platform.

5. `update_TRANSFER_MANAGER_ERC1155(ref self: ContractState, manager: ContractAddress)` :

    Similar to the ERC-721 update function, this allows the owner to update the transfer manager for ERC-1155 tokens, ensuring the platform can handle changes or improvements in ERC-1155 token transfer logic.

6. `get_INTERFACE_ID_ERC721(self: @ContractState) -> felt252`
   `get_INTERFACE_ID_ERC1155(self: @ContractState) -> felt252` :

    These getter functions return the interface IDs for ERC-721 and ERC-1155, respectively. They are used internally to determine the token standard of a collection when selecting the appropriate transfer manager.


7. `get_TRANSFER_MANAGER_ERC721(self: @ContractState) -> ContractAddress`
   `get_TRANSFER_MANAGER_ERC1155(self: @ContractState) -> ContractAddress` :

    Returns the current transfer manager addresses for ERC-721 and ERC-1155 tokens, respectively. They are vital for ensuring the correct manager is used when transferring tokens of these standards.

8. `get_transfer_manager_selector_for_collection(self: @ContractState, collection: ContractAddress) -> ContractAddress`
   `check_transfer_manager_for_token(self: @ContractState, collection: ContractAddress) -> ContractAddress` :

    Retrieves the transfer manager assigned to a specific collection, while the second checks and returns the appropriate transfer manager for a collection, considering both the assigned manager and the token standard. This logic ensures that the correct manager is used for each transfer operation.