#[starknet::contract]
pub mod ERC7662 {
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, StoragePathEntry, Vec, VecTrait, MutableVecTrait
    };

    use erc_7662_ai_agent_nft::types::Agent;
    use erc_7662_ai_agent_nft::interfaces::IERC7662;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        collections_ids: Map<ContractAddress, u256>,
        agents: Map<u256, Agent>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        AgentCreated: AgentCreated,
        AgentUpdated: AgentUpdated,
    }


    #[derive(Drop, starknet::Event)]
    struct AgentUpdated {
        token_id: u256,
    }


    #[derive(Drop, starknet::Event)]
    struct AgentCreated {
        name: ByteArray,
        description: ByteArray,
        model: ByteArray,
        recipient: ContractAddress,
        token_id: u256,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.erc721.initializer(name, symbol, base_uri);
    }

    #[abi(embed_v0)]
    impl ERC7662Impl of IERC7662<ContractState> {
        fn get_agent_data(self: @ContractState, token_id: u256) -> Agent {
            self.agents.read(token_id)
        }
    }


    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721.mint(to, token_id);
        }
    }

    /// An empty implementation of the ERC721 hooks.
    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
