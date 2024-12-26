use starknet::ContractAddress;
use erc5006_cairo::types::UserRecord;

#[starknet::interface]
pub trait IERC5006Mixin<TState> {
    fn usable_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256;

    fn frozen_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256;

    fn user_record_of(self: @TState, record_id: u256) -> UserRecord;

    fn create_user_record(
        ref self: TState,
        owner: ContractAddress,
        user: ContractAddress,
        token_id: u256,
        amount: u64,
        expiry: u64
    ) -> u256;

    fn delete_user_record(ref self: TState, record_id: u256);

    fn balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256;
    fn balance_of_batch(
        self: @TState, accounts: Span<ContractAddress>, token_ids: Span<u256>,
    ) -> Span<u256>;
    fn safe_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        value: u256,
        data: Span<felt252>,
    );
    fn safe_batch_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_ids: Span<u256>,
        values: Span<u256>,
        data: Span<felt252>,
    );
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress,
    ) -> bool;
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
}

#[starknet::contract]
pub mod ERC5006RentalNft {
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc1155::{ERC1155Component, ERC1155HooksEmptyImpl};
    use erc5006_cairo::erc5006::ERC5006Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: ERC5006Component, storage: erc5006, event: ERC5006Event);

    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;

    // ERC5006
    #[abi(embed_v0)]
    impl ERC5006Impl = ERC5006Component::ERC5006Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        erc5006: ERC5006Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        ERC5006Event: ERC5006Component::Event,
    }
}
