#[starknet::interface]
trait IER721CamelOnly<TState> {
    fn transferFrom(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        token_id: u256
    );
}

#[starknet::interface]
trait IERC2981<TContractState> {
    fn royaltyInfo(
        ref self: TContractState, tokenId: u256, salePrice: u128
    ) -> (starknet::ContractAddress, u128);
}

const OLD_IERC721_ID: felt252 = 0x80ac58cd;

#[starknet::contract]
mod ERC721 {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::introspection::src5::SRC5Component;
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState,) {
        self.src5.register_interface(0x80ac58cd);
    }

    #[external(v0)]
    impl IERC721CamelOnlyImpl of super::IER721CamelOnly<ContractState> {
        fn transferFrom(
            ref self: ContractState,
            from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            token_id: u256
        ) {}
    }


    fn RECIPIENT() -> starknet::ContractAddress {
        starknet::contract_address_const::<'RECIPIENT'>()
    }

    #[external(v0)]
    impl IERC2981Impl of super::IERC2981<ContractState> {
        fn royaltyInfo(
            ref self: ContractState, tokenId: u256, salePrice: u128
        ) -> (starknet::ContractAddress, u128) {
            (RECIPIENT(), 5000)
        }
    }
}
