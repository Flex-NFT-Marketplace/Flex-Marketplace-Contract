# ERC1523: Insurance Policy Standard for NFTs on Starknet

## About

[ERC1523](https://eips.ethereum.org/EIPS/eip-1523) is a standard interface for insurance policies represented as non-fungible tokens (NFTs) on Starknet. This implementation extends ERC721 to provide functionality specific to insurance policies, enabling the creation, management, and transfer of tokenized insurance policies.

## Motivation

Insurance policies as NFTs enable transparent, immutable, and transferable insurance contracts on the blockchain. This standard provides a unified interface for creating, managing, and transferring tokenized insurance policies.

## Contract Interface

### Core Functions

```cairo
#[abi(embed_v0)]
trait IERC1523 {
    fn create_policy(ref self: ContractState, policy: Policy) -> u256;
    fn update_policy_state(ref self: ContractState, token_id: u256, state: State);
    fn get_policy(self: @ContractState, token_id: u256) -> Policy;
    fn get_all_user_policies(self: @ContractState, user: ContractAddress) -> Array<Policy>;
    fn get_user_policy_amount(self: @ContractState, user: ContractAddress) -> u64;
    fn transfer_policy(ref self: ContractState, token_id: u256, to: ContractAddress);
}
```

### Key Structures

```cairo
struct Policy {
    policy_holder: ContractAddress,
    coverage_period_start: u256,
    coverage_period_end: u256,
    risk: ByteArray,
    underwriter: ContractAddress,
    metadataURI: ByteArray,
    state: State
}
```

## Starknet-Specific Implementation Details

### Components and Storage

The implementation uses OpenZeppelin's component system:

```cairo
component!(path: ERC721Component, storage: erc721, event: ERC721Event);
component!(path: SRC5Component, storage: src5, event: SRC5Event);
```

### Storage structure:

```cairo
#[storage]
struct Storage {
    #[substorage(v0)]
    erc721: ERC721Component::Storage,
    #[substorage(v0)]
    src5: SRC5Component::Storage,
    token_count: u256,
    policies: Map<u256, Policy>,
    user_policies: Map<ContractAddress, Vec<u256>>,
}
```

### Events

The contract emits events for policy creation:

```cairo
#[event]
struct PolicyCreated {
    token_id: u256,
    policy_holder: ContractAddress,
    coverage_period_start: u256,
    coverage_period_end: u256,
    risk: ByteArray,
    underwriter: ContractAddress,
    metadataURI: ByteArray,
}
```

## Key Differences from Ethereum Implementation

1. Syntax and Type System

   - Uses ContractAddress instead of Ethereum's address
   - Utilizes Cairo's ByteArray for string data
   - Implements component-based architecture using OpenZeppelin's components

2. Storage Management

   - Uses Starknet's storage maps and vectors

3. Event System

   - Uses Starknet's event system with #[event] attribute
   - Implements flat event hierarchies for better indexing

## Usage Example

```cairo
// Initialize the contract
let contract = ERC1523::constructor("Insurance Policies", "INS", "base_uri");

// Create a new policy
let policy = Policy {
    policy_holder: caller_address,
    coverage_period_start: start_time,
    coverage_period_end: end_time,
    risk: risk_description,
    underwriter: underwriter_address,
    metadataURI: metadata_uri,
    state: State::Active
};

let token_id = contract.create_policy(policy);

// Query user's policies
let user_policies = contract.get_all_user_policies(user_address);

// Transfer a policy
contract.transfer_policy(token_id, new_holder_address);
```

### ⛏️ Compile

```bash
scarb build
```

### 💄 Code style

```bash
scarb fmt
```

### 🌡️ Test

```bash
scarb test
```

## 📄 License

This implementation is released under the Apache license.
