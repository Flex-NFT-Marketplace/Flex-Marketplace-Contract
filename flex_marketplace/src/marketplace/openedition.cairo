mod interfaces {
    mod IERC721;
    mod IFlexDrop;
    mod IFlexDropContractMetadata;
    mod INonFungibleFlexDropToken;
}

mod ERC721_open_edition;

mod FlexDrop;

mod erc721 {
    mod ERC721;
}

use erc721::ERC721;
use interfaces::IFlexDrop::IFlexDrop;
use interfaces::INonFungibleFlexDropToken::INonFungibleFlexDropToken;

