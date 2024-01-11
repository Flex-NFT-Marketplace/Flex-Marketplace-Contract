#[starknet::interface]
trait IER721CamelOnly<TState> {
    fn transferFrom(
        ref self: TState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        token_id: u256
    );
}

#[starknet::contract]
mod ERC721 {
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl IERC721CamelOnlyImpl of super::IER721CamelOnly<ContractState> {
        fn transferFrom(
            ref self: ContractState,
            from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            token_id: u256
        ) {}
    }
}
