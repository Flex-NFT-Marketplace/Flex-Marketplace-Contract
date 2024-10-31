#[starknet::interface]
pub trait IFlexDropContractMetadata<TContractState> {
    fn set_base_uri(ref self: TContractState, new_token_uri: ByteArray);
    fn set_contract_uri(ref self: TContractState, new_contract_uri: ByteArray);
    fn get_base_uri(self: @TContractState) -> ByteArray;
    fn get_contract_uri(self: @TContractState) -> ByteArray;
}

