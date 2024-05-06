use starknet::ContractAddress;

#[starknet::interface]
trait IFlexDropContractMetadata<TContractState> {
    fn set_base_uri(ref self: TContractState, new_token_uri: ByteArray);
    fn set_contract_uri(ref self: TContractState, new_contract_uri: ByteArray);
    fn set_max_supply(ref self: TContractState, new_max_supply: u64);
    fn get_base_uri(self: @TContractState) -> ByteArray;
    fn get_contract_uri(self: @TContractState) -> ByteArray;
    fn get_max_supply(self: @TContractState) -> u64;
}

