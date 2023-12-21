mod marketplace {
    mod ERC721_flex;

    mod contract_deployer;
    mod currency_manager;
    mod execution_manager;
    mod market_place;
    mod proxy;
    mod royalty_fee_manager;
    mod royalty_fee_registry;
    mod signature_checker;
    mod signature_checker2;
    mod strategy_any_item_from_collection_for_fixed_price;
    mod strategy_highest_bidder_auction_sale;
    mod strategy_private_sale;
    mod strategy_standard_sale_for_fixed_price;
    mod transfer_manager_ERC1155;
    mod transfer_manager_ERC721;
    mod transfer_selector_NFT;
    mod launchpad {
        mod ERC721_Launchpad;
        mod ERC721_launchpad_migrated;
        mod minter;
    }

    mod swap {
        mod exponential_curve;
        mod pair;
        mod pair_factory;
    }

    mod utils {
        mod merkle;
        mod order_types;
        mod reentrancy_guard;
    }
}
