// SPDX-License-Identifier: Apache 2.0
// Immutable Cairo Contracts v0.3.0 (access/IAccessControl.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccessControl {
    func hasRole(role: felt, account: felt) -> (res: felt) {
    }

    func getRoleAdmin(role: felt) -> (role_admin: felt) {
    }

    func grantRole(role: felt, account: felt) {
    }

    func revokeRole(role: felt, account: felt) {
    }

    func renounceRole(role: felt, account: felt) {
    }
}
