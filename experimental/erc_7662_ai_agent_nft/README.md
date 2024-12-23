## Experimental ERC-7662 AI Agent NFTs

A test implementation of the [ERC-7662](https://github.com/ethereum/ERCs/blob/ea6b5c5fb9bc3ab0f6183c84ab81c54b9b57e7ab/ERCS/erc-7662.md) to create AI Agent NFTs.
The AI Agents NFT standard introduces additional features and data to the standard ERC-721 protocol, aimed at addressing the practical requirements of using NFTs to store, trade and use AI Agents. It is designed to be fully backward-compatible with the original ERC-721 standard. 

### Key aspects

- Agent struct to store agent-related data
- Mapping between NFT Token ID and its Agent information in the smart-contract storage
- `mint_agent` function to mint a new Agent NFT
- `add_encrypted_prompts` function to add encrypted prompts to an Agent NFT (only callable by the owner)
- `get_agent` function to retrieve Agent data by token ID
- `get_collection_ids` function to retrieve all token IDs owned by an address
- `get_agent_data` function to retrieve all Agent NFT data required by the ERC-7662 standard
- Integration with OpenZeppelin's Ownable component to manage ownership


