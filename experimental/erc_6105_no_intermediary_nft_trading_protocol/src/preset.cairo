use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC6105Nft<TState> {
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
}

#[starknet::interface]
pub trait IERC6105Mixin<TState> {
    // Mint the NFT
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);

    // IERC6105 functions
    fn list_item(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress
    );
    fn list_item_with_benchmark(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress,
        benchmark_price: u256
    );
    fn delist_item(ref self: TState, token_id: u256);
    fn buy_item(
        ref self: TState, token_id: u256, sale_price: u256, supported_token: ContractAddress
    );
    fn get_listing(self: @TState, token_id: u256) -> (u256, u64, ContractAddress, u256);

    // IERC6105CollectionOffer extension functions
    fn make_collection_offer(
        ref self: TState,
        amount: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress
    );
    fn accept_collection_offer(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        supported_token: ContractAddress,
        buyer: ContractAddress
    );
    fn accept_collection_offer_with_benchmark(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        supported_token: ContractAddress,
        buyer: ContractAddress,
        benchmark_price: u256
    );
    fn cancel_collection_offer(ref self: TState);
    fn get_collection_offer(
        self: @TState, buyer: ContractAddress
    ) -> (u256, u256, u64, ContractAddress);

    // IERC721 functions
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

    // Ownable functions
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);

    // IERC2981 functions
    fn royalty_info(self: @TState, token_id: u256, sale_price: u256) -> (ContractAddress, u256);
}

#[starknet::contract]
pub mod ERC6105NoIntermediaryNftTradingProtocol {
    use openzeppelin_token::common::erc2981::ERC2981Component::InternalTrait;
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin_token::common::erc2981::{ERC2981Component, DefaultConfig};
    use erc_6105_no_intermediary_nft_trading_protocol::erc6105::ERC6105Component;
    use erc_6105_no_intermediary_nft_trading_protocol::collection_offer::ERC6105CollectionOfferComponent;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC6105Component, storage: erc6105, event: ERC6105Event);
    component!(path: ERC2981Component, storage: erc2981, event: ERC2981Event);
    component!(
        path: ERC6105CollectionOfferComponent,
        storage: collection_offer,
        event: ERC6105CollectionOfferEvent
    );

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // ERC6105
    #[abi(embed_v0)]
    impl ERC6105Impl = ERC6105Component::ERC6105Impl<ContractState>;
    impl ERC6105InternalImpl = ERC6105Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc6105: ERC6105Component::Storage,
        #[substorage(v0)]
        erc2981: ERC2981Component::Storage,
        #[substorage(v0)]
        collection_offer: ERC6105CollectionOfferComponent::Storage,
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
        ERC6105Event: ERC6105Component::Event,
        #[flat]
        ERC2981Event: ERC2981Component::Event,
        #[flat]
        ERC6105CollectionOfferEvent: ERC6105CollectionOfferComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        royalty_fraction: u128
    ) {
        self.ownable.initializer(get_caller_address());
        self.erc721.initializer(name, symbol, base_uri);
        self.erc2981.initializer(get_caller_address(), royalty_fraction);
    }

    #[abi(embed_v0)]
    impl ERC6105NftImpl of super::IERC6105Nft<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.ownable.assert_only_owner();
            self.erc721.mint(to, token_id);
        }
    }
}
