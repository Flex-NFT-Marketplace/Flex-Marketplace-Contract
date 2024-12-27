#[starknet::contract]
mod FlexHausFactory {
    use starknet::storage::MutableVecTrait;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, deploy_syscall, get_contract_address,
        get_block_timestamp, get_tx_info
    };
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Vec, VecTrait,
        MutableTrait
    };
    use flexhaus::interface::IFlexHausFactory::{IFlexHausFactory, DropDetail};
    use flexhaus::interface::IFlexHausCollectible::{
        IFlexHausCollectibleMixinDispatcher, IFlexHausCollectibleMixinDispatcherTrait
    };
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use openzeppelin::access::ownable::{
        OwnableComponent, interface::{IOwnableDispatcher, IOwnableDispatcherTrait}
    };
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::account::interface::{AccountABIDispatcher, AccountABIDispatcherTrait};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use array::ArrayTrait;
    use hash::{HashStateTrait, HashStateExTrait};
    use pedersen::PedersenTrait;

    const STARKNET_DOMAIN_TYPE_HASH: felt252 =
        selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

    const CLAIMABLE_STRUCT_TYPE_HASH: felt252 =
        selector!("ClaimableStruct(collectible:ContractAddress,recipient:ContractAddress)");

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        protocol_fee: u256,
        protocol_currency: ContractAddress,
        fee_recipient: ContractAddress,
        flex_haus_collectible_class: ClassHash,
        collectible_salt: u256,
        all_collectibles: Vec<ContractAddress>,
        // mapping collectible by owner
        mapping_collectible: Map<ContractAddress, Vec<ContractAddress>>,
        is_flex_haus_collectible: Map<ContractAddress, bool>,
        mapping_drop: Map<ContractAddress, DropDetail>,
        signer: ContractAddress,
        used_keys: Map<felt252, bool>,
        // min duration time before start time for update drop detail
        min_duration_time_for_update: u64,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        UpdateCollectible: UpdateCollectible,
        UpdateDrop: UpdateDrop,
        ClaimCollectible: ClaimCollectible,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event
    }

    #[derive(Drop, Copy, starknet::Event)]
    pub struct UpdateCollectible {
        #[key]
        creator: ContractAddress,
        collectible: ContractAddress,
    }

    #[derive(Drop, Copy, starknet::Event)]
    struct UpdateDrop {
        #[key]
        collectible: ContractAddress,
        drop_type: u8,
        secure_amount: u256,
        top_supporters: u64,
        start_time: u64,
    }

    #[derive(Drop, Copy, starknet::Event)]
    struct ClaimCollectible {
        #[key]
        collectible: ContractAddress,
        recipient: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        protocol_fee: u256,
        protocol_currency: ContractAddress,
        fee_recipient: ContractAddress,
        signer: ContractAddress,
        flex_haus_collectible_class: ClassHash,
    ) {
        self.ownable.initializer(owner);
        self.protocol_fee.write(protocol_fee);
        self.protocol_currency.write(protocol_currency);
        self.fee_recipient.write(fee_recipient);
        self.signer.write(signer);
        self.flex_haus_collectible_class.write(flex_haus_collectible_class);
        self.min_duration_time_for_update.write(3600);
    }

    #[derive(Drop, Copy, Serde, Hash)]
    struct ClaimableStruct {
        collectible: ContractAddress,
        recipient: ContractAddress,
    }

    #[derive(Drop, Copy, Serde, Hash)]
    struct StarknetDomain {
        name: felt252,
        version: felt252,
        chain_id: felt252,
    }

    #[abi(embed_v0)]
    impl FlexHausFactoyImpl of IFlexHausFactory<ContractState> {
        fn create_collectible(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            base_uri: ByteArray,
            total_supply: u256
        ) {
            self.reentrancyguard.start();
            self.pay_protocol_fee();
            let creator = get_caller_address();

            assert(total_supply > 0, 'Invalid total supply');

            let salt = self.collectible_salt.read();
            self.collectible_salt.write(salt + 1);

            let mut constructor_calldata = ArrayTrait::<felt252>::new();
            constructor_calldata.append(creator.into());
            constructor_calldata.append(name.data.len().into());
            for i in 0..name.data.len() {
                constructor_calldata.append((*name.data.at(i)).into());
            };
            constructor_calldata.append(name.pending_word);
            constructor_calldata.append(name.pending_word_len.into());
            constructor_calldata.append(symbol.data.len().into());
            for i in 0
                ..symbol.data.len() {
                    constructor_calldata.append((*symbol.data.at(i)).into());
                };
            constructor_calldata.append(symbol.pending_word);
            constructor_calldata.append(symbol.pending_word_len.into());
            constructor_calldata.append(base_uri.data.len().into());
            for i in 0
                ..base_uri
                    .data
                    .len() {
                        constructor_calldata.append((*base_uri.data.at(i)).into());
                    };
            constructor_calldata.append(base_uri.pending_word);
            constructor_calldata.append(base_uri.pending_word_len.into());
            constructor_calldata.append(total_supply.low.into());
            constructor_calldata.append(total_supply.high.into());
            constructor_calldata.append(get_contract_address().into());

            let (collectible, _) = deploy_syscall(
                self.get_flex_haus_collectible_class(),
                salt.try_into().unwrap(),
                constructor_calldata.span(),
                false
            )
                .ok()
                .unwrap();

            self.is_flex_haus_collectible.entry(collectible).write(true);
            self.all_collectibles.append().write(collectible);
            self.mapping_collectible.entry(creator).append().write(collectible);

            self.emit(UpdateCollectible { creator, collectible });
            self.reentrancyguard.end();
        }

        fn create_drop(
            ref self: ContractState,
            collectible: ContractAddress,
            drop_type: u8,
            secure_amount: u256,
            top_supporters: u64,
            start_time: u64,
        ) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_collectible(collectible);
            self.assert_only_creator_of_collectible(collectible);
            let drop_detail = self.mapping_drop.entry(collectible).read();
            assert(drop_detail.drop_type == 0, 'Drop already created');

            if top_supporters > 0 {
                self.assert_valid_total_supporters(collectible, top_supporters);
            }

            assert(start_time > 0, 'Wrong start time');
            self.assert_valid_drop_type(drop_type);

            let new_drop_detail = DropDetail {
                drop_type: drop_type.into(), secure_amount, top_supporters, start_time
            };

            self.mapping_drop.entry(collectible).write(new_drop_detail);

            self
                .emit(
                    UpdateDrop { collectible, drop_type, secure_amount, top_supporters, start_time }
                );

            self.reentrancyguard.end();
        }

        fn update_collectible_drop_phase(
            ref self: ContractState,
            collectible: ContractAddress,
            drop_type: u8,
            secure_amount: u256,
            top_supporters: u64,
            start_time: u64,
        ) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_collectible(collectible);
            self.assert_only_creator_of_collectible(collectible);

            let mut drop_detail = self.mapping_drop.entry(collectible).read();
            self.assert_not_exceeded_time(drop_detail);

            assert(start_time > 0, 'Wrong start time');

            if top_supporters > 0 {
                self.assert_valid_total_supporters(collectible, top_supporters);
            }
            self.assert_valid_drop_type(drop_type);

            drop_detail.drop_type = drop_type.into();
            drop_detail.secure_amount = secure_amount;
            drop_detail.top_supporters = top_supporters;
            drop_detail.start_time = start_time;

            self.mapping_drop.entry(collectible).write(drop_detail);

            self
                .emit(
                    UpdateDrop {
                        collectible, drop_type, secure_amount, top_supporters, start_time,
                    }
                );

            self.reentrancyguard.end();
        }

        fn update_collectible_detail(
            ref self: ContractState,
            collectible: ContractAddress,
            name: ByteArray,
            symbol: ByteArray,
            base_uri: ByteArray,
            total_supply: u256
        ) {
            self.reentrancyguard.start();
            self.assert_only_flex_haus_collectible(collectible);
            self.assert_only_creator_of_collectible(collectible);
            let collectible_drop = self.mapping_drop.entry(collectible).read();
            if collectible_drop.start_time != 0 {
                self.assert_not_exceeded_time(collectible_drop);
            }

            assert(total_supply > 0, 'Invalid total supply');
            assert(
                collectible_drop.top_supporters.into() <= total_supply, 'Supporters total supply'
            );

            let collectible_dis = IFlexHausCollectibleMixinDispatcher {
                contract_address: collectible
            };
            collectible_dis.set_total_supply(total_supply);
            collectible_dis.set_name(name);
            collectible_dis.set_symbol(symbol);
            collectible_dis.set_base_uri(base_uri);

            self.emit(UpdateCollectible { creator: get_caller_address(), collectible });
            self.reentrancyguard.end();
        }

        fn claim_collectible(
            ref self: ContractState, collectible: ContractAddress, keys: Array<felt252>
        ) {
            self.reentrancyguard.start();

            let collectible_drop = self.get_collectible_drop(collectible);
            assert(
                collectible_drop.drop_type != 0
                    && collectible_drop.start_time <= get_block_timestamp(),
                'Drop not started'
            );

            let caller = get_caller_address();
            let keys_hash = self.get_keys_hash(collectible, caller);
            assert(!self.used_keys.entry(keys_hash).read(), 'Key already used');

            let account: AccountABIDispatcher = AccountABIDispatcher {
                contract_address: self.get_signer()
            };

            assert(account.is_valid_signature(keys_hash, keys) == 'VALID', 'Invalid keys');
            self.used_keys.entry(keys_hash).write(true);

            let collectible_dis = IFlexHausCollectibleMixinDispatcher {
                contract_address: collectible
            };

            collectible_dis.mint_collectible(caller);
            self.emit(ClaimCollectible { collectible, recipient: caller });

            self.reentrancyguard.end();
        }

        fn set_protocol_fee(ref self: ContractState, new_fee: u256) {
            self.ownable.assert_only_owner();
            self.protocol_fee.write(new_fee);
        }

        fn set_protocol_currency(ref self: ContractState, new_currency: ContractAddress) {
            self.ownable.assert_only_owner();
            self.protocol_currency.write(new_currency);
        }

        fn set_flex_haus_collectible_class(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.flex_haus_collectible_class.write(new_class_hash);
        }

        fn set_fee_recipient(ref self: ContractState, new_recipient: ContractAddress) {
            self.ownable.assert_only_owner();
            self.fee_recipient.write(new_recipient);
        }

        fn set_min_duration_time_for_update(ref self: ContractState, new_duration: u64) {
            self.ownable.assert_only_owner();
            self.min_duration_time_for_update.write(new_duration);
        }

        fn set_signer(ref self: ContractState, new_signer: ContractAddress) {
            self.ownable.assert_only_owner();
            self.signer.write(new_signer);
        }

        fn get_signer(self: @ContractState) -> ContractAddress {
            self.signer.read()
        }

        fn get_fee_recipient(self: @ContractState) -> ContractAddress {
            self.fee_recipient.read()
        }

        fn get_collectible_drop(self: @ContractState, collectible: ContractAddress) -> DropDetail {
            self.mapping_drop.entry(collectible).read()
        }

        fn get_protocol_fee(self: @ContractState) -> u256 {
            self.protocol_fee.read()
        }

        fn get_protocol_currency(self: @ContractState) -> ContractAddress {
            self.protocol_currency.read()
        }

        fn get_flex_haus_collectible_class(self: @ContractState) -> ClassHash {
            self.flex_haus_collectible_class.read()
        }

        fn get_min_duration_time_for_update(self: @ContractState) -> u64 {
            self.min_duration_time_for_update.read()
        }

        fn get_all_collectibles_addresses(self: @ContractState) -> Array<ContractAddress> {
            let mut collectibles = ArrayTrait::new();
            for i in 0
                ..self
                    .all_collectibles
                    .len() {
                        collectibles.append(self.all_collectibles.at(i).read());
                    };
            collectibles
        }

        fn get_total_collectibles_count(self: @ContractState) -> u64 {
            self.all_collectibles.len()
        }

        fn get_collectibles_of_owner(
            self: @ContractState, owner: ContractAddress
        ) -> Array<ContractAddress> {
            let mut collectibles = ArrayTrait::new();
            let collectibles_of_owner = self.mapping_collectible.entry(owner);
            for i in 0
                ..collectibles_of_owner
                    .len() {
                        collectibles.append(collectibles_of_owner.at(i).read());
                    };
            collectibles
        }
    }

    trait IStructHash<T> {
        fn hash(self: @T) -> felt252;
    }

    impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
        fn hash(self: @StarknetDomain) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(STARKNET_DOMAIN_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(4);
            state.finalize()
        }
    }

    impl HashClaimableStruct of IStructHash<ClaimableStruct> {
        fn hash(self: @ClaimableStruct) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(CLAIMABLE_STRUCT_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(3);
            state.finalize()
        }
    }

    #[generate_trait]
    impl InternalImple of InternalImpleTrait {
        fn assert_only_flex_haus_collectible(self: @ContractState, collectible: ContractAddress) {
            let is_flex_haus_collectible = self.is_flex_haus_collectible.entry(collectible).read();
            assert(is_flex_haus_collectible, 'Only Flex Haus Collectible');
        }

        fn assert_only_creator_of_collectible(self: @ContractState, collectible: ContractAddress) {
            let creator = get_caller_address();
            let ownableCollectible = IOwnableDispatcher { contract_address: collectible };
            assert(ownableCollectible.owner() == creator, 'Only collectible creator');
        }

        fn assert_only_created_drop(self: @ContractState, drop_detail: DropDetail) {
            assert(drop_detail.start_time != 0, 'Drop not created');
        }

        fn assert_not_exceeded_time(self: @ContractState, drop_detail: DropDetail) {
            assert(
                get_block_timestamp()
                    + self.get_min_duration_time_for_update() <= drop_detail.start_time,
                'Exceeded allowed time'
            );
        }

        fn assert_valid_total_supporters(
            self: @ContractState, collectible: ContractAddress, total_supporters: u64
        ) {
            let collectible_dis = IFlexHausCollectibleMixinDispatcher {
                contract_address: collectible
            };
            let total_supply = collectible_dis.total_supply();
            assert(total_supporters.into() <= total_supply, 'Supporters exceeds total supply');
        }

        fn assert_valid_drop_type(self: @ContractState, drop_type: u8) {
            assert(drop_type == 1 || drop_type == 2, 'Invalid drop type');
        }

        fn pay_protocol_fee(ref self: ContractState) {
            let caller = get_caller_address();

            let currencyDispatcher = ERC20ABIDispatcher {
                contract_address: self.get_protocol_currency()
            };
            currencyDispatcher
                .transfer_from(caller, self.get_fee_recipient(), self.get_protocol_fee());
        }

        fn get_keys_hash(
            self: @ContractState, collectible: ContractAddress, recipient: ContractAddress,
        ) -> felt252 {
            let domain = StarknetDomain {
                name: 'FlexHaus', version: 1, chain_id: get_tx_info().unbox().chain_id
            };
            let mut state = PedersenTrait::new(0);
            state = state.update_with('StarkNet Message');
            state = state.update_with(domain.hash());
            state = state.update_with(self.get_signer());
            let winner = ClaimableStruct { collectible, recipient };
            state = state.update_with(winner.hash());
            state = state.update_with(4);
            state.finalize()
        }
    }
}
