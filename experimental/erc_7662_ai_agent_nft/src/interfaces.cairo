use starknet::{ContractAddress};
use erc_7662_ai_agent_nft::types::Agent;

#[starknet::interface]
pub trait IERC7662<TState> {
    fn mint_agent(
        ref self: TState,
        to: ContractAddress,
        name: ByteArray,
        description: ByteArray,
        model: ByteArray,
        user_prompt_uri: ByteArray,
        system_prompt_uri: ByteArray,
        image_uri: ByteArray,
        category: ByteArray
    ) -> u256;
    fn add_encrypted_prompts(
        ref self: TState,
        token_id: u256,
        encrypted_user_prompt_uri: ByteArray,
        encrypted_system_prompt_uri: ByteArray
    );
    fn get_collection_ids(self: @TState, address: ContractAddress) -> Array<u256>;
    fn get_agent(self: @TState, token_id: u256) -> Agent;
    fn get_agent_data(
        self: @TState, token_id: u256
    ) -> (ByteArray, ByteArray, ByteArray, ByteArray, ByteArray, bool);
}

