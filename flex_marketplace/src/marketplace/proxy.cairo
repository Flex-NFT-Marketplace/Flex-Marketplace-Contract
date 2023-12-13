use starknet::{ContractAddress, class_hash::ClassHash};

#[starknet::interface]
trait IProxy<TState> {
    fn upgrade(ref self: TState, new_implementation: ClassHash);
    fn set_admin(ref self: TState, new_admin: ContractAddress);
    fn get_implementation(self: @TState) -> ClassHash;
    fn get_admin(self: @TState) -> ContractAddress;
    fn __default__(self: @TState, selector: felt252, calldata: Span<felt252>) -> Span<felt252>;
    fn __l1_default__(self: @TState, selector: felt252, calldata: Span<felt252>);
}

#[starknet::contract]
mod Proxy {
    use starknet::{ContractAddress, contract_address_const, class_hash::ClassHash};

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(
        ref self: ContractState,
        implementation_hash: ClassHash,
        selector: felt252,
        calldata: Span<felt252>
    ) { // TODO
    }

    #[external(v0)]
    impl Proxy of super::IProxy<ContractState> {
        fn upgrade(ref self: ContractState, new_implementation: ClassHash) { // TODO
        }

        fn set_admin(ref self: ContractState, new_admin: ContractAddress) { // TODO
        }

        fn get_implementation(self: @ContractState) -> ClassHash {
            // TODO
            Zeroable::zero()
        }

        fn get_admin(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }
        fn __default__(
            self: @ContractState, selector: felt252, calldata: Span<felt252>
        ) -> Span<felt252> {
            // TODO
            array![0].span()
        }
        fn __l1_default__(
            self: @ContractState, selector: felt252, calldata: Span<felt252>
        ) { // TODO
        }
    }
}
