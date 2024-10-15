#[starknet::contract]
mod FlexHausCollectible {
    use flexhaus::erc721::ERC721::{ERC721Component, ERC721HooksEmptyImpl};
    use flexhaus::interface::IFlexHausCollectible::{
        IFlexHausCollectible, IFlexHausCollectibleCamelOnly, IFLEX_HAUS_COLLECTIBLE_ID
    };
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    };
    use starknet::{ContractAddress, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        totalSupply: u256,
        currentId: u256,
        flexHausFactories: Vec<ContractAddress>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        baseUri: ByteArray,
        totalSupply: u256,
        flexHausFactory: ContractAddress,
    ) {
        self.erc721.initializer(name, symbol, baseUri);
        self.ownable.initializer(owner);
        self.totalSupply.write(totalSupply);
        self.src5.register_interface(IFLEX_HAUS_COLLECTIBLE_ID);
        self.flexHausFactories.append().write(flexHausFactory);
    }


    #[abi(embed_v0)]
    impl FlexHausDropImpl of IFlexHausCollectible<ContractState> {
        fn get_base_uri(self: @ContractState) -> ByteArray {
            self.erc721._base_uri()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_factory();
            self.erc721._set_base_uri(base_uri);
            self.reentrancyguard.end();
        }

        fn set_total_supply(ref self: ContractState, total_supply: u256) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_factory();
            self.totalSupply.write(total_supply);
        }

        fn mint_collectible(ref self: ContractState, minter: ContractAddress) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_factory();
            let tokenId = self.totalSupply.read() + 1;
            assert(tokenId <= self.total_supply(), 'Max supply reached');

            self.currentId.write(tokenId);
            self.erc721.safe_mint(minter, tokenId, ArrayTrait::new().span());
            self.reentrancyguard.end();
        }
    }

    #[abi(embed_v0)]
    impl FlexHausDropCamelOnlyImpl of IFlexHausCollectibleCamelOnly<ContractState> {
        fn getBaseUri(self: @ContractState) -> ByteArray {
            self.get_base_uri()
        }

        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply()
        }
        fn setBaseUri(ref self: ContractState, baseUri: ByteArray) {
            self.set_base_uri(baseUri);
        }

        fn setTotalSupply(ref self: ContractState, totalSupply: u256) {
            self.set_total_supply(totalSupply);
        }

        fn mintCollectible(ref self: ContractState, minter: ContractAddress) {
            self.mint_collectible(minter);
        }
    }


    #[generate_trait]
    impl InternalImpl of InternalImplTrait {
        fn assert_only_flex_haus_factory(ref self: ContractState) {
            let flexHausFactory = get_caller_address();
            let mut is_allowed_factory = false;
            for i in 0
                ..self
                    .flexHausFactories
                    .len() {
                        let factory = self.flexHausFactories.at(i).read();
                        if factory == flexHausFactory {
                            is_allowed_factory = true;
                        }
                    };
            assert(is_allowed_factory, 'Only Flex Haus Factory');
        }
    }
}
