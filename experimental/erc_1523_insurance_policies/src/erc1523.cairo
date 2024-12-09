#[starknet::contract]
pub mod ERC1523 {
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, StoragePathEntry, Vec, VecTrait, MutableVecTrait
    };

    use erc_1523_insurance_policies::types::{Policy, State};
    use erc_1523_insurance_policies::interfaces::{IERC1523};

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
        PolicyCreated: PolicyCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct PolicyCreated {
        token_id: u256,
        policy_holder: ContractAddress,
        coverage_period_start: u256,
        coverage_period_end: u256,
        risk: ByteArray,
        underwriter: ContractAddress,
        metadataURI: ByteArray,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.erc721.initializer(name, symbol, base_uri);
    }

    #[abi(embed_v0)]
    impl ERC1523Impl of IERC1523<ContractState> {
        fn create_policy(ref self: ContractState, policy: Policy) -> u256 {
            let mut token_id = self.token_count.read();

            if token_id < 1 {
                token_id += 1;
            }

            self._mint(policy.policy_holder.clone(), token_id);
            self.token_count.write(token_id + 1);
            self.policies.write(token_id, policy.clone());
            self.user_policies.entry(policy.policy_holder.clone()).append().write(token_id);

            self
                .emit(
                    PolicyCreated {
                        token_id,
                        policy_holder: policy.policy_holder,
                        coverage_period_start: policy.coverage_period_start,
                        coverage_period_end: policy.coverage_period_end,
                        risk: policy.risk,
                        underwriter: policy.underwriter,
                        metadataURI: policy.metadataURI,
                    }
                );

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
            let user_policy_id_len = self.get_user_policy_amount(user);
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

        fn get_user_policy_amount(self: @ContractState, user: ContractAddress) -> u64 {
            self.user_policies.entry(user).len()
        }

        fn transfer_policy(ref self: ContractState, token_id: u256, to: ContractAddress) {
            let owner = self.get_policy(token_id).policy_holder;
            assert(get_caller_address() == owner, 'wrong policy holder');

            self.erc721.transfer_from(owner, to, token_id);

            let mut policy = self.policies.entry(token_id).read();
            policy.policy_holder = to;

            self.policies.entry(token_id).write(policy);

            let owner_policy_id_len = self.get_user_policy_amount(owner);

            for index in 0
                ..owner_policy_id_len {
                    let id = self.user_policies.entry(owner).at(index).read();

                    if id == token_id {
                        self.user_policies.entry(owner).at(index).write(0);
                    };
                };

            self.user_policies.entry(to).append().write(token_id);
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
