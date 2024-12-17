use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC5643SubscriptionNft<TState> {
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
}

#[starknet::interface]
pub trait IERC5643SubscriptionNftMixin<TState> {
    // IERC5643SubscriptionNft
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
    // IERC5643
    fn renew_subscription(ref self: TState, token_id: u256, duration: u64);
    fn cancel_subscription(ref self: TState, token_id: u256);
    fn expires_at(self: @TState, token_id: u256) -> u64;
    fn is_renewable(self: @TState, token_id: u256) -> bool;
    // IERC721
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    // Ownable
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);
    // ISRC5
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}

#[starknet::contract]
pub mod ERC5643SubscriptionNft {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use erc_5643_subscription_nft::erc5643::erc5643::ERC5643Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC5643Component, storage: erc5643, event: ERC5643Event);

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // ERC5643
    #[abi(embed_v0)]
    impl ERC5643Impl = ERC5643Component::ERC5643Impl<ContractState>;
    impl ERC5643InternalImpl = ERC5643Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc5643: ERC5643Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ERC5643Event: ERC5643Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.ownable.initializer(get_caller_address());
        self.erc721.initializer(name, symbol, base_uri);
        self.erc5643.initializer();
    }

    #[abi(embed_v0)]
    impl ERC5643SubscriptionNftImpl of super::IERC5643SubscriptionNft<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.ownable.assert_only_owner();
            self.erc721.mint(to, token_id);
        }
    }
}
