use erc_7662_ai_agent_nft::types::Agent;

#[starknet::interface]
pub trait IERC7662<TState> {
    fn get_agent_data(self: @TState, token_id: u256) -> Agent;
}
