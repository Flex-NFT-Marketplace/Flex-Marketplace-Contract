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

mod marketplace {
    mod launchpad {
        mod ERC721_launchpad_migrated;
        mod ERC721_launchpad;
        mod minter;
    }

    mod swap {
        mod exponential_curve;
        mod pair_factory;
        mod pair;
    }

    mod utils {
        mod merkle;
        mod order_types;
        mod reentrancy_guard;
    }

    mod interfaces {
        mod nft_transfer_manager;
    }

    mod contract_deployer;
    mod currency_manager;
    mod ERC721_flex;
    mod execution_manager;
    mod marketplace;
    mod royalty_fee_manager;
    mod royalty_fee_registry;
    mod signature_checker;
    mod signature_checker2;
    mod strategy_any_item_from_collection_for_fixed_price;
    mod strategy_highest_bidder_auction_sale;
    mod strategy_private_sale;
    mod strategy_standard_sale_for_fixed_price;
    mod transfer_manager_ERC721;
    mod transfer_manager_ERC1155;
    mod transfer_selector_NFT;
}

mod mocks {
    mod account;
    mod erc20;
    mod erc1155;
    mod erc721;
    mod strategy;
}
