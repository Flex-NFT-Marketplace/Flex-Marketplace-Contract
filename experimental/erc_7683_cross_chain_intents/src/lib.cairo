mod erc721;
mod cross_chain_types;

mod interfaces {
    mod nft_settlement;
}

mod contracts {
    mod nft_settlement;
}

use cross_chain_types::{CrossChainNFTOrder, ResolvedCrossChainNFTOrder, NFTInput, NFTOutput};
use interfaces::nft_settlement::INFTSettlement;
