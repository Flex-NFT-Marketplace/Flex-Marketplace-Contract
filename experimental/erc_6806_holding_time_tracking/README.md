<div align="center">
  <h1 align="center">Cairo ERC-6806 Holding Time Tracking</h1>
  <h3 align="center">Holding Time Tracking (ERC-6806) written in Cairo for Starknet.</h3>
</div>

### About

A Cairo implementation of [EIP-6806](https://eips.ethereum.org/EIPS/eip-6806). EIP-6806 is an Ethereum standard for Holding Time Tracking NFTs.

> ## ⚠️ WARNING! ⚠️
>
> This repo contains highly experimental code.
> Expect rapid iteration.
> **Use at your own risk.**

### Project setup

#### 📦 Requirements

- [scarb](https://docs.swmansion.com/scarb/)
- [starknet-foundry](https://github.com/foundry-rs/starknet-foundry)

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

## ERC-6806 Details

### Overview
ERC-6806 is a standard for Holding Time Tracking NFTs, allowing for the tracking of the duration for which a token is held.

### Functions
- `get_holding_info(token_id: u256) -> (ContractAddress, u64)`: Returns the holder's address and the holding time for the specified token ID.
- `set_holding_time_whitelisted_address(account: ContractAddress, ignore_reset: bool)`: Sets an address as whitelisted for holding time tracking.

## Syntax Changes for Starknet's Cairo

### Interface Definition
```cairo
#[starknet::interface]
pub trait IERC721<TContractState> {
    fn get_holding_info(self: @TContractState, token_id: u256) -> (ContractAddress, u64);
    fn set_holding_time_whitelisted_address(ref self: TContractState, account: ContractAddress, ignore_reset: bool);
}
```

### Contract Implementation
```cairo
#[starknet::contract]
pub mod ERC721 {
    // Storage variables
    #[storage]
    struct Storage {
        holder: Map<u256, ContractAddress>,
        hold_start: Map<u256, u64>,
    }

    #[abi(embed_v0)]
    impl IERC721Impl of super::IERC721<ContractState> {
        fn get_holding_info(self: @ContractState, token_id: u256) -> (ContractAddress, u64) {
            let holder = self.holder.read(token_id);
            let hold_start = self.hold_start.read(token_id);
            let current_time = get_block_timestamp();
            let holding_time = current_time - hold_start;
            (holder, holding_time)
        }
    }
}
