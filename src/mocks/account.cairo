// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.7.0 (account/account.cairo)

trait PublicKeyTrait<TState> {
    fn set_public_key(ref self: TState, new_public_key: felt252);
    fn get_public_key(self: @TState) -> felt252;
}

trait PublicKeyCamelTrait<TState> {
    fn setPublicKey(ref self: TState, newPublicKey: felt252);
    fn getPublicKey(self: @TState) -> felt252;
}

#[starknet::contract]
mod Account {
    use ecdsa::check_ecdsa_signature;

    use openzeppelin::account::interface;
    use openzeppelin::introspection::interface::ISRC5;
    use openzeppelin::introspection::interface::ISRC5Camel;
    use openzeppelin::account::account::AccountComponent;
    use starknet::account::Call;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::get_tx_info;
    use openzeppelin::introspection::src5::SRC5Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    #[abi(embed_v0)]
    impl SRC6Impl = AccountComponent::SRC6Impl<ContractState>;
    #[abi(embed_v0)]
    impl DeployableImpl = AccountComponent::DeployableImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeclarerImpl = AccountComponent::DeclarerImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyImpl = AccountComponent::PublicKeyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC6CamelOnlyImpl = AccountComponent::SRC6CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyCamelImpl = AccountComponent::PublicKeyCamelImpl<ContractState>;
    impl InternalImpl = AccountComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        account: AccountComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccountEvent: AccountComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, _public_key: felt252) {
        self.account.initializer(_public_key);
    }
}

