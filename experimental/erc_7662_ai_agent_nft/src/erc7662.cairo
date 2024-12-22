#[starknet::contract]
pub mod ERC7662 {
    use ERC721Component::InternalTrait;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::{ContractAddress};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    use erc_7662_ai_agent_nft::types::Agent;
    use erc_7662_ai_agent_nft::interfaces::IERC7662;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        token_ids: u256,
        // Map of token_id to Agent struct required for ERC7662
        agents: Map<u256, Agent>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        AgentCreated: AgentCreated,
        AgentUpdated: AgentUpdated,
    }


    // Event requierd for ERC7662 emitted when an Agent NFT is updated
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct AgentUpdated {
        pub token_id: u256,
    }


    // Event requierd for ERC7662 emitted when an Agent NFT is created
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct AgentCreated {
        pub name: ByteArray,
        pub description: ByteArray,
        pub model: ByteArray,
        pub recipient: ContractAddress,
        pub token_id: u256,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.erc721.initializer(name, symbol, base_uri);
        self.token_ids.write(1);
    }

    #[abi(embed_v0)]
    impl ERC7662Impl of IERC7662<ContractState> {
        // @dev Mint an Agent NFT and attach its data to the token id
        //
        // @param _recipient address to receive NFT
        // @param _name string Name of the Agent
        // @param _description string Description of the Agent
        // @param _model string AI Model of the Agent
        // @param _userPromptURI string URI of the Agent's User Prompt
        // @param _systemPromptURI string URI of the Agent's System Prompt
        // @param _imageURI string URI of the NFT image
        // @param _category string Category of Agent
        // @param _tokenURI string URI of the NFT
        //
        // Emits an AgentCreated event.
        fn mint_agent(
            ref self: ContractState,
            to: ContractAddress,
            name: ByteArray,
            description: ByteArray,
            model: ByteArray,
            user_prompt_uri: ByteArray,
            system_prompt_uri: ByteArray,
            image_uri: ByteArray,
            category: ByteArray
        ) -> u256 {
            let mut token_id = self.token_ids.read();
            self.erc721.mint(to, token_id);
            self.token_ids.write(token_id + 1);
            let agent = Agent {
                name: name.clone(),
                description: description.clone(),
                model: model.clone(),
                user_prompt_uri: user_prompt_uri.clone(),
                system_prompt_uri: system_prompt_uri.clone(),
                image_uri: image_uri.clone(),
                category: category.clone(),
                prompts_encrypted: false,
            };
            self.agents.write(token_id, agent.clone());
            self.emit(AgentCreated { name, description, model, recipient: to, token_id, });
            token_id
        }


        // @dev Update NFT with Encrypted Prompts as token id needed first for encryption params
        // @param _tokenID uint256 ID of the NFT
        // @param _encryptedUserPromptURI string Encrypted URI of the Agent's User Prompt
        // @param _encryptedSystemPromptURI string Encrypted URI of the Agent's System Prompt
        fn add_encrypted_prompts(
            ref self: ContractState,
            token_id: u256,
            encrypted_user_prompt_uri: ByteArray,
            encrypted_system_prompt_uri: ByteArray
        ) {
            let mut agent = self.get_agent(token_id);
            agent =
                Agent {
                    prompts_encrypted: true,
                    user_prompt_uri: encrypted_user_prompt_uri,
                    system_prompt_uri: encrypted_system_prompt_uri,
                    ..agent
                };
            self.agents.write(token_id, agent.clone());
            self.emit(AgentUpdated { token_id });
        }


        // @dev Get Agent NFT data
        // @param _tokenID uint256 ID of the NFT
        fn get_agent(self: @ContractState, token_id: u256) -> Agent {
            self.agents.read(token_id)
        }


        // @dev Return all token ids owned by address from ERC721_owners: Map<u256, ContractAddress>
        // @param address Address to check for
        fn get_collection_ids(self: @ContractState, address: ContractAddress) -> Array<u256> {
            let mut result: Array<u256> = ArrayTrait::new();
            let mut i: u256 = 1;
            let current_token_id = self.token_ids.read();

            while i < current_token_id {
                if self.erc721.ERC721_owners.read(i) == address {
                    result.append(i);
                }
                i += 1;
            };
            result
        }

        // @dev Return all Agent NFT data reuquired by standard erc-7662
        // @param _tokenID uint256 ID of the NFT
        fn get_agent_data(
            self: @ContractState, token_id: u256
        ) -> (ByteArray, ByteArray, ByteArray, ByteArray, ByteArray, bool) {
            let agent = self.get_agent(token_id);
            (
                agent.name,
                agent.description,
                agent.model,
                agent.user_prompt_uri,
                agent.system_prompt_uri,
                agent.prompts_encrypted,
            )
        }
    }


    /// An empty implementation of the ERC721 hooks.
    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
