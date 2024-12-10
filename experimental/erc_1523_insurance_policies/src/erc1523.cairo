#[starknet::contract]
pub mod ERC1523 {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, StoragePathEntry, Vec, VecTrait, MutableVecTrait
    };
    use erc_1523_insurance_policies::types::{InsurancePolicy, PolicyStatus};
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
        token_count: u256,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        policies: Map<u256, InsurancePolicy>,
        user_policies: Map<ContractAddress, Vec<u256>>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray, base_uri: ByteArray
    ) {
        self.erc721.initializer(name, symbol, base_uri);
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
    pub struct PolicyCreated {
        pub token_id: u256,
        pub policy_holder: ContractAddress,
        pub coverage_period_start: u256,
        pub coverage_period_end: u256,
        pub risk: ByteArray,
        pub underwriter: ContractAddress,
        pub metadataURI: ByteArray,
    }

    #[abi(embed_v0)]
    impl ERC1523Impl of IERC1523<ContractState> {
        fn create_policy(ref self: ContractState, policy: InsurancePolicy) -> u256 {
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

        fn update_policy(ref self: ContractState, token_id: u256, state: PolicyStatus) {
            let mut policy = self.get_policy(token_id);

            policy.state = state;

            self.policies.write(token_id, policy);
        }

        fn transfer_policy(ref self: ContractState, token_id: u256, to: ContractAddress) {
            let owner = self.get_policy(token_id).policy_holder;
            let caller = get_caller_address();
            assert(caller == owner, 'Wrong policy holder');

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

        fn get_policy(self: @ContractState, token_id: u256) -> InsurancePolicy {
            self.policies.read(token_id)
        }

        fn get_policies_by_owner(
            self: @ContractState, owner: ContractAddress
        ) -> Array<InsurancePolicy> {
            let user_policy_id_len = self.get_user_policy_amount(owner);
            let mut user_policy_ids = array![];
            let mut user_policies = array![];

            for index in 0
                ..user_policy_id_len {
                    user_policy_ids.append(self.user_policies.entry(owner).at(index).read());
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

        fn activate_policy(ref self: ContractState, token_id: u256) {
            let mut policy = self.get_policy(token_id);

            let caller = get_caller_address();
            assert(caller == policy.policy_holder, 'Only policy holder can activate');
            assert(policy.state != PolicyStatus::Active, 'Policy already active');

            policy.state = PolicyStatus::Active;
            self.policies.write(token_id, policy);
        }

        fn expire_policy(ref self: ContractState, token_id: u256) {
            let mut policy = self.get_policy(token_id);

            let caller = get_caller_address();
            assert(caller == policy.policy_holder, 'Only policy holder can expire');
            assert(policy.state != PolicyStatus::Expired, 'Policy already expired');

            policy.state = PolicyStatus::Expired;
            self.policies.write(token_id, policy);
        }

        fn cancel_policy(ref self: ContractState, token_id: u256) {
            let mut policy = self.get_policy(token_id);

            let caller = get_caller_address();
            assert(caller == policy.policy_holder, 'Only policy holder can cancel');
            assert(policy.state != PolicyStatus::Cancelled, 'Policy already cancelled');

            policy.state = PolicyStatus::Cancelled;
            self.policies.write(token_id, policy);
        }

        fn claim_policy(ref self: ContractState, token_id: u256) {
            let mut policy = self.get_policy(token_id);

            let caller = get_caller_address();
            assert(caller == policy.policy_holder, 'Only policy holder can claim');
            assert(policy.state == PolicyStatus::Active, 'Policy must be active to claim');

            policy.state = PolicyStatus::Claimed;
            self.policies.write(token_id, policy);
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721.mint(to, token_id);
        }
    }

    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
