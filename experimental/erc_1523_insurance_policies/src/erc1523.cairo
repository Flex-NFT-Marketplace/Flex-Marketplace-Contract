use starknet::ContractAddress;

#[starknet::contract]
pub mod ERC1523 {
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::IERC721Metadata;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, StoragePathEntry, Vec, VecTrait, MutableVecTrait, StorageAsPath,
        StorageAsPointer, StoragePath, StoragePointer0Offset, Mutable
    };

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
        token_count: u256,
        policies: Map<u256, Policy>,
        user_policies: Map<ContractAddress, Vec<u256>>,
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
            self: @ContractState, tokenId: u256, propertyPathHash: ByteArray
        ) -> ByteArray { //TODO
            let byte: ByteArray = "ok";
            byte
        }
    }

    #[abi(embed_v0)]
    impl ERC1523Impl of IERC1523<ContractState> {
        fn create_policy(ref self: ContractState, policy: Policy) -> u256 {
            let mut token_id = self.token_count.read();

            if token_id < 1 {
                token_id += 1;
            }

            self.policies.write(token_id, policy);
            token_id
        }

        fn update_policy_state(ref self: ContractState, token_id: u256, state: State) {
            let mut policy = self.get_policy(token_id);

            policy.state = state;

            self.policies.write(token_id, policy);
        }

        fn get_policy(self: @ContractState, token_id: u256) -> Policy {
            self.policies.read(token_id)
        }

        fn get_all_user_policies(self: @ContractState, user: ContractAddress) -> Array<Policy> {
            // let user_policy_ids = self.user_policies.entry(user).read();
            let user_policy_id_len = self.user_policies.entry(user).len();
            let mut user_policy_ids = array![];
            let mut user_policies = array![];

            for index in 0
                ..user_policy_id_len {
                    user_policy_ids.append(self.user_policies.entry(user).at(index).read());
                };

            for id in user_policy_ids {
                let policy = self.get_policy(id);

                user_policies.append(policy);
            };

            user_policies
        }
    }

    /// An empty implementation of the ERC721 hooks.
    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
