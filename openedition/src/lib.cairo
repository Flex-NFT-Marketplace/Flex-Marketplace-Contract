use core::fmt::{Display, Error, Formatter, Debug};
use starknet::{contract_address_to_felt252, ContractAddress, contract_address_const};

impl DisplayContractAddress of Display<starknet::ContractAddress> {
    fn fmt(self: @starknet::ContractAddress, ref f: Formatter) -> Result<(), Error> {
        write!(f, "{}", contract_address_to_felt252(*self))
    }
}

impl DebugContractAddress of Debug<ContractAddress> {
    fn fmt(self: @starknet::ContractAddress, ref f: Formatter) -> Result<(), Error> {
        Display::fmt(self, ref f)
    }
}

impl DefaultContractAddress of Default<ContractAddress> {
    fn default() -> ContractAddress {
        contract_address_const::<0>()
    }
}

mod erc721 {
    mod ERC721;
    mod ERC721MultiMetadata;
}

mod interfaces {
    mod IERC721;
    mod IFlexDrop;
    mod IFlexDropContractMetadata;
    mod INonFungibleFlexDropToken;
    mod ICurrencyManager;
    mod ISignatureChecker2;
}

mod utils {
    mod openedition;
}

mod ERC721_open_edition_multi_metadata;

mod ERC721_open_edition;

mod FlexDrop;

use erc721::ERC721;
use erc721::ERC721MultiMetadata;
use interfaces::IFlexDrop::IFlexDrop;
use interfaces::INonFungibleFlexDropToken::INonFungibleFlexDropToken;
