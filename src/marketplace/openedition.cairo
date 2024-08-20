mod interfaces {
    mod IERC721;
    mod IFlexDrop;
    mod IFlexDropContractMetadata;
    mod INonFungibleFlexDropToken;
}

mod ERC721_open_edition;

mod ERC721_open_edition_multi_metadata;

mod FlexDrop;

mod erc721 {
    mod ERC721;
    mod ERC721MultiMetadata;
}

use erc721::ERC721;
use erc721::ERC721MultiMetadata;
use interfaces::IFlexDrop::IFlexDrop;
use interfaces::INonFungibleFlexDropToken::INonFungibleFlexDropToken;

