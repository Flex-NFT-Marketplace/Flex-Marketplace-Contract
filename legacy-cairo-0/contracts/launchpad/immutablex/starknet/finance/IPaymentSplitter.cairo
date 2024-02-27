// SPDX-License-Identifier: Apache 2.0
// Immutable Cairo Contracts v0.3.0 (finance/IPaymentSplitter.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPaymentSplitter {
    func balance(token: felt) -> (balance: Uint256) {
    }

    func payee(index: felt) -> (payee: felt) {
    }

    func payeeCount() -> (payee_count: felt) {
    }

    func totalShares() -> (total_shares: felt) {
    }

    func shares(payee: felt) -> (shares: felt) {
    }

    func totalReleased(token: felt) -> (total_released: Uint256) {
    }

    func released(token: felt, payee: felt) -> (released: Uint256) {
    }

    func pendingPayment(token: felt, payee: felt) -> (payment: Uint256) {
    }

    func release(token: felt, payee: felt) {
    }
}
