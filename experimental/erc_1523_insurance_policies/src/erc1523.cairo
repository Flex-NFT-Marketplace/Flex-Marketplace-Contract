use starknet::ContractAddress;

#[starknet::contract]
pub mod ERC1523 {
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::IERC721Metadata;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;

    use erc_1523_insurance_policies::types::{Policy, State};
    use erc_1523_insurance_policies::interfaces::{IERC1523PolicyMetadata, IERC1523};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        token: u256,
        policies: Map<token_id, Policy>,
        user_policies: Map<ContractAddress, Vec>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.erc721.initializer(name, symbol, base_uri);
    }

    #[abi(embed_v0)]
    impl ERC721Metadata of IERC721Metadata<ContractState> {
        /// Returns the NFT name.
        fn name(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_name.read()
        }

        /// Returns the NFT symbol.
        fn symbol(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_symbol.read()
        }

        /// Returns the Uniform Resource Identifier (URI) for the `token_id` token.
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.erc721._base_uri()
        }
    }

    #[abi(embed_v0)]
    impl ERC1523PolicyMetadataImpl of IERC1523PolicyMetadata<ContractState> {
        fn policyMetadata(
            self: @TState, tokenId: u256, propertyPathHash: ByteArray
        ) -> ByteArray { //TODO
        }
    }

    #[abi(embed_v0)]
    impl ERC1523Impl of IERC1523<ContractState> {
        fn create_policy(ref self: TState, policy: Policy) -> token_id {
            //TODO
            1_u256
        }

        fn update_policy_state(ref self: TState, state: State) { //TODO
        }

        fn get_policy(self: @TState, token_id: u256) -> Policy {
            //TODO

            let risk: ByteArray = "ok";
            let metadataURI: ByteArray = "ok";

            Policy {
                policyholder: '123'.try_into().unwrap(),
                premium: 1_u256,
                coveragePeriodStart: 1_u256,
                coveragePeriodEnd: 1_u256,
                risk,
                underwriter: '123'.try_into().unwrap(),
                metadataURI,
                state: State::Active,
            }
        }

        fn get_all_user_policies(self: @TState, user: ContractAddress) -> Span<Policy> {
            //TODO

            let policy = Policy {
                policyholder: '123'.try_into().unwrap(),
                premium: 1_u256,
                coveragePeriodStart: 1_u256,
                coveragePeriodEnd: 1_u256,
                risk,
                underwriter: '123'.try_into().unwrap(),
                metadataURI,
                state: State::Active,
            };

            array![policy].Span()
        }
    }

    /// An empty implementation of the ERC721 hooks.
    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
