#[starknet::component]
pub mod ERC5006Component {
    use starknet::{ContractAddress, get_block_timestamp};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc1155::ERC1155Component::InternalImpl as ERC1155InternalImpl;
    use openzeppelin_token::erc1155::ERC1155Component::ERC1155Impl;
    use openzeppelin_token::erc1155::ERC1155Component;

    use erc5006_cairo::interface::IERC5006;
    use erc5006_cairo::uintset::UintSet::{UintSet, UintSetTrait};
    use erc5006_cairo::types::UserRecord;

    #[storage]
    pub struct Storage {
        frozens: Map<u256, Map<ContractAddress, u256>>,
        records: Map<u256, UserRecord>,
        user_record_ids: Map<u256, Map<ContractAddress, UintSet>>,
        cur_record_id: u256,
        record_limit: u256
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        CreateUserRecord: CreateUserRecord,
        DeleteUserRecord: DeleteUserRecord
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct CreateUserRecord {
        #[key]
        pub record_id: u256,
        pub token_id: u256,
        pub amount: u64,
        pub owner: ContractAddress,
        pub user: ContractAddress,
        pub expiry: u64
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct DeleteUserRecord {
        #[key]
        pub record_id: u256
    }

    #[embeddable_as(ERC5006Impl)]
    pub impl ERC5006<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC1155: ERC1155Component::HasComponent<TContractState>,
        +ERC1155Component::ERC1155HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC5006<ComponentState<TContractState>> {
        fn usable_balance_of(
            self: @ComponentState<TContractState>, account: ContractAddress, token_id: u256
        ) -> u256 {
            let record_ids = self.user_record_ids.entry(token_id).entry(account);

            let mut amount: u256 = 0;

            for index in 0
                ..record_ids
                    .size
                    .read() {
                        if (get_block_timestamp() <= self
                            .records
                            .entry(record_ids.values.entry(index).read())
                            .read()
                            .expiry) {
                            amount = amount
                                + self
                                    .records
                                    .entry(record_ids.values.entry(index).read())
                                    .read()
                                    .amount
                                    .into();
                        }
                    };
            amount
        }

        fn frozen_balance_of(
            self: @ComponentState<TContractState>, account: ContractAddress, token_id: u256
        ) -> u256 {
            self.frozens.entry(token_id).entry(account).read()
        }

        fn user_record_of(self: @ComponentState<TContractState>, record_id: u256) -> UserRecord {
            self.records.entry(record_id).read()
        }

        fn create_user_record(
            ref self: ComponentState<TContractState>,
            owner: ContractAddress,
            user: ContractAddress,
            token_id: u256,
            amount: u64,
            expiry: u64
        ) -> u256 {
            let zero: ContractAddress = 0.try_into().unwrap();
            assert(user != zero, 'User cannot be the zero address');
            assert(amount > 0, 'amount must be greater than 0');
            assert(expiry > get_block_timestamp(), 'expiry more than blocktimestamp');
            let prev_frozen = self.frozens.entry(token_id).entry(owner).read();
            self.frozens.entry(token_id).entry(owner).write(prev_frozen + amount.into());
            self.cur_record_id.write(self.cur_record_id.read() + 1);
            let record = UserRecord { token_id, owner, amount, user, expiry };
            self.records.entry(self.cur_record_id.read()).write(record);

            self
                .emit(
                    CreateUserRecord {
                        record_id: self.cur_record_id.read(), token_id, amount, owner, user, expiry
                    }
                );
            self.user_record_ids.entry(token_id).entry(user).add(self.cur_record_id.read());
            return self.cur_record_id.read();
        }

        fn delete_user_record(ref self: ComponentState<TContractState>, record_id: u256) {
            let record = self.records.entry(record_id).read();
            let prev_frozen = self.frozens.entry(record.token_id).entry(record.owner).read();
            let u256_amount: u256 = record.amount.into();
            self
                .frozens
                .entry(record.token_id)
                .entry(record.owner)
                .write(prev_frozen - u256_amount);
            self.user_record_ids.entry(record.token_id).entry(record.user).remove(record_id);
            let zero: ContractAddress = 0.try_into().unwrap();
            let empty = UserRecord { token_id: 0, owner: zero, amount: 0, user: zero, expiry: 0 };
            self.records.entry(record_id).write(empty);
            self.emit(DeleteUserRecord { record_id });
        }
    }
}
