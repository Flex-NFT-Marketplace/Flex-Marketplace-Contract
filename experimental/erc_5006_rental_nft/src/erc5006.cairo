#[starknet::component]
pub mod ERC5006Component {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc1155::ERC1155Component::InternalImpl as ERC1155InternalImpl;
    use openzeppelin_token::erc1155::ERC1155Component::ERC1155Impl;
    use openzeppelin_token::erc1155::ERC1155Component;
    use openzeppelin_token::ERC1155ReceiverComponent::InternalImpl as Erc1155ReceiverInternalImpl;
    use openzeppelin_token::ERC1155ReceiverComponent::ERC1155ReceiverImpl;
    use openzeppelin_token::ERC1155ReceiverComponent;

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

    #[embeddable_as(ERC5006Impl)]
    impl ERC5006<
        TContractState,
        +HasComponent<TcontractState>,
        impl ERC1155: ERC1155Component::HasComponent<TContractState>,
        +ERC1155Component::ERC1155HooksTrait<TContractState>,
        impl ERC1155Receiver: ERC1155ReceiverComponent::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC5006<ComponentState<TContractState>> {
        fn usable_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256 {
            let record_ids = self.user_record_ids.entry(token_id).read(account);

            let mut amount: u256 = 0;

            for index in 0..record_ids.size.read() {
                if (get_block_timestamp() <= self.records.entry(record_ids.values.entry(index).read()).read().expiry) {
                    amount = amount + self.records.entry(record_ids.values.entry(index).read()).read().amount;
                }
            }
            amount
        }

        fn frozen_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256 {
            self.frozens.entry(token_id).read(account)
        }

        fn user_record_of(self: @TState, record_id: u256) -> UserRecord {
            self.records.entry(record_id).read()
        }

        fn create_user_record(ref self: TState, owner: ContractAddress, user: ContractAddress, token_id: u256, amount: u64, expiry: u64) -> u256 {

        }

        fn delete_user_record(ref self: TState, record_id: u256) {}
    }
}