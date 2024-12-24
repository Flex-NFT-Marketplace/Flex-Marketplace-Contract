# ERC 5643 Subscription NFT

## Overview

ERC 5643 is a standard for subscription-based NFTs that allows users to subscribe to digital assets. This standard provides a framework for managing subscriptions, including renewal and cancellation processes.

## Features

### Core Functionality
- Subscription creation and management
- Token-based subscription tracking
- Automatic expiration handling
- Subscription renewal management
- Transfer capability between users

### Technical Integration
- Starknet-compatible implementation
- Cairo-specific optimizations
- Comprehensive test coverage

## Interface Definition

```cairo
pub trait IERC5643<TState> {
    fn renew_subscription(ref self: TState, token_id: u256, duration: u64);
    fn cancel_subscription(ref self: TState, token_id: u256);
    fn expires_at(self: @TState, token_id: u256) -> u64;
    fn is_renewable(self: @TState, token_id: u256) -> bool;
}
```



## Cairo Implementation Notes

### Syntax Adaptations
- Use of `felt` type for integer values
- Explicit return type declarations
- Clear modifier definitions for access control
- Integration with Starknet's storage model

### Development Requirements
- [scarb](https://docs.swmansion.com/scarb/)
- [starknet-foundry](https://github.com/foundry-rs/starknet-foundry)

### Build and Test
```bash
# Compile the project
scarb build

# Run tests
scarb test

# Format code
scarb fmt
```

## Warning

⚠️ This implementation is experimental and under active development. Use with caution in production environments.

## License

Released under the Apache License.