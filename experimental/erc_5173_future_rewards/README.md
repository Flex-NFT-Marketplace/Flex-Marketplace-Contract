# ERC5173: Future Rewards NFT Standard for Starknet
## About
A standard interface for NFTs with Future Rewards (FR) distribution capabilities on Starknet. [ERC5173](https://eips.ethereum.org/EIPS/eip-5173) extends ERC721 to enable automatic distribution of future profits to previous token holders based on a predefined reward structure.

## Motivation
This standard enables NFT holders to continue benefiting from future sales of their previously owned tokens through a systematic reward distribution mechanism. This creates a more engaging ecosystem where early supporters can participate in the future success of NFT assets.

## Specification
### Core Structures

```cairo
struct FRInfo {
    numGenerations: felt252,
    percentOfProfit: felt252,
    successiveRatio: felt252,
    lastSoldPrice: felt252,
    ownerAmount: felt252,
    addressesInFR: Vec<ContractAddress>,
}

struct ListInfo {
    salePrice: felt252,
    lister: ContractAddress,
    isListed: bool,
}
```

### Storage

```cairo
#[storage]
struct Storage {
    token_owners: Map<felt252, ContractAddress>,
    list_info: Map<felt252, ListInfo>,
    fr_info: Map<felt252, FRInfo>,
    reward_balances: Map<ContractAddress, felt252>,
    allotted_fr: Map<ContractAddress, felt252>,
    total_tokens: felt252,
    erc721_address: ContractAddress,
    erc20_address: ContractAddress,
}
```

### Core Functions

```cairo
trait IERC5173 {
    fn mint(ref self: ContractState, to: ContractAddress, token_id: felt252) -> felt252;
    
    fn transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, 
                tokenId: felt252, soldPrice: felt252);
    
    fn releaseFR(ref self: ContractState, account: ContractAddress);
}
```

## Cairo Implementation Details
### Key Differences from EVM Implementation

1. Type System

	- Uses felt252 instead of uint256 for numeric values
	- Uses ContractAddress instead of Ethereum's address
	- Implements Vector operations differently from Solidity arrays


2. Storage Pattern

	- Uses Starknet's storage maps instead of Solidity mappings
	- Implements efficient storage for FR distribution tracking
	- Uses component-based architecture for ERC721 integration


3. Future Rewards Distribution

	- Implements mathematical operations using Cairo's felt252 arithmetic
	- Handles precision with fixed-point arithmetic for reward calculations

## Future Rewards Distribution Algorithm
```cairo
fn _calculateFR(
    totalProfit: felt252, 
    buyerReward: felt252, 
    successiveRatio: felt252, 
    ownerAmount: felt252, 
    windowSize: usize
) -> Vec<felt252> {
    let mut distributions = Vec::new();
    let totalReward = (totalProfit * buyerReward) / 1_000_000_000_000_000_000; // 1e18
    
    for i in 0..windowSize {
        let reward = totalReward / pow(successiveRatio, i);
        if reward > 0 {
            distributions.push(reward);
        } else {
            break;
        }
    }
    distributions
}
```

## Usage Example
```cairo
let contract = ERC5173::constructor(erc721_address, erc20_address);

let token_id = contract.mint(recipient_address, token_id);

contract.transfer(
    from_address,
    to_address,
    token_id,
    sale_price
);

contract.releaseFR(claimer_address);
```

## Security Considerations

1. Reward Distribution

	- Precise handling of arithmetic operations to prevent overflow
	- Proper validation of reward calculations
	- Protection against reentrancy attacks during distributions


2. Token Transfers

	- Validation of ownership and approvals
	- Atomic execution of transfers and reward distributions
	- Proper handling of failed transfers

3. State Management

	- Proper updating of FR distribution state
	- Safe storage of historical ownership data
	- Protection against manipulation of reward calculations

## Testing Requirements

1. Token Operations

	- Minting with FR capabilities
	- Transfer with reward distribution
	- Multiple transfers and reward accumulation


2. Reward Distribution

	- Correct calculation of rewards
	- Distribution to multiple previous owners
	- Handling of edge cases (zero profits, maximum generations)


3. Reward Claims

	- Proper release of accumulated rewards
	- Validation of claim amounts
	- Prevention of double claims


## Integration Guidelines

1. ERC20 Token Integration
```cairo
let erc20_dispatcher = IERC20Dispatcher { contract_address: storage.erc20_address };
erc20_dispatcher.transfer(recipient, amount);
```

2. ERC721 Integration
```cairo
let erc721_dispatcher = IERC721Dispatcher { contract_address: storage.erc721_address };
erc721_dispatcher.transfer_from(from, to, token_id);
```
