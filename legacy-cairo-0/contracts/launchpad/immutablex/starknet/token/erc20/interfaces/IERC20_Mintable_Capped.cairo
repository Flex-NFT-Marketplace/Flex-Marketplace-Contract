// SPDX-License-Identifier: Apache 2.0
// Immutable Cairo Contracts v0.3.0 (token/erc20/interfaces/IERC20_Mintable_Capped.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC20_Mintable_Capped {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func owner() -> (owner: felt) {
    }

    func cap() -> (cap: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt) {
    }

    func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt) {
    }

    func transferOwnership(new_owner: felt) -> (success: felt) {
    }

    func mint(to: felt, amount: Uint256) -> (success: felt) {
    }
}
