use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct CrossChainNFTOrder {
    // Standard ERC-7683 fields
    settlement_contract: ContractAddress,
    swapper: ContractAddress,
    nonce: u256,
    origin_chain_id: u32,
    initiate_deadline: u32,
    fill_deadline: u32,
    // NFT-specific fields
    nft_contract: ContractAddress,
    token_id: u256,
    destination_chain_id: u32,
    destination_address: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
struct ResolvedCrossChainNFTOrder {
    // Standard ERC-7683 fields
    settlement_contract: ContractAddress,
    swapper: ContractAddress,
    nonce: u256,
    origin_chain_id: u32,
    initiate_deadline: u32,
    fill_deadline: u32,
    // Input (NFT being transferred)
    swapper_input: NFTInput,
    // Output (NFT on destination chain)
    swapper_output: NFTOutput,
    // Filler rewards (if any)
    filler_outputs: Array<Output>
}

#[derive(Copy, Drop, Serde)]
struct NFTInput {
    nft_contract: ContractAddress,
    token_id: u256,
    chain_id: u32
}

#[derive(Copy, Drop, Serde)]
struct NFTOutput {
    nft_contract: ContractAddress,
    token_id: u256,
    recipient: ContractAddress,
    chain_id: u32
}
