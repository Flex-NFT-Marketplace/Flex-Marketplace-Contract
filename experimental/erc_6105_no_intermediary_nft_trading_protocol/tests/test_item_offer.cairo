use starknet::ContractAddress;
use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, start_cheat_caller_address_global, stop_cheat_caller_address_global,
    spy_events, EventSpyAssertionsTrait
};
use openzeppelin_testing::constants::OWNER;
use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use erc_6105_no_intermediary_nft_trading_protocol::item_offer::ERC6105ItemOfferComponent;
use erc_6105_no_intermediary_nft_trading_protocol::preset::IERC6105MixinDispatcherTrait;
use super::utils::ERC6105TestTrait;

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_make_item_offer() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;
    let token_id: u256 = 69420;

    start_cheat_caller_address_global(eth_rich_address);

    let test = ERC6105TestTrait::setup();
    ETH_dispatcher.approve(test.erc6105_address, 1);
    let mut spy = spy_events();
    test.erc6105.make_item_offer(token_id,
        sale_price,
        expires,
        zero_address
    );

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id, from: eth_rich_address, sale_price, expires, supported_token: zero_address
                    }
            )
            )
        ]
    );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_cancel_item_offer() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;
    let token_id: u256 = 69420;

    start_cheat_caller_address_global(eth_rich_address);

    let test = ERC6105TestTrait::setup();
    ETH_dispatcher.approve(test.erc6105_address, 1);
    let mut spy = spy_events();
    test.erc6105.make_item_offer(token_id,
        sale_price,
        expires,
        zero_address
    );

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id, from: eth_rich_address, sale_price, expires, supported_token: zero_address
                    }
            )
            )
        ]
    );

    test.erc6105.cancel_item_offer(token_id);
    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id: 0,
                        from: eth_rich_address,
                        sale_price: 0,
                        expires: 0,
                        supported_token: zero_address
                    }
                )
            )
        ]
    );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_accept_item_offer() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;
    let token_id: u256 = 69420;

    start_cheat_caller_address_global(eth_rich_address);

    let test = ERC6105TestTrait::setup();
    ETH_dispatcher.approve(test.erc6105_address, 1);
    ETH_dispatcher.transfer(test.erc6105_address, 1);
    let mut spy = spy_events();
    test.erc6105.make_item_offer(token_id,
        sale_price,
        expires,
        zero_address
    );

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id, from: eth_rich_address, sale_price, expires, supported_token: zero_address
                    }
            )
            )
        ]
    );
    stop_cheat_caller_address_global();

    start_cheat_caller_address(test.erc6105_address, OWNER());
    test.erc6105.accept_item_offer(token_id, sale_price, zero_address, eth_rich_address);

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::ItemPurchased(
                    ERC6105ItemOfferComponent::ItemPurchased {
                        token_id,
                        from: OWNER(),
                        to: eth_rich_address,
                        sale_price,
                        supported_token: zero_address,
                        royalties: 0
                    }
                )
            )
        ]
    );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_accept_item_offer_with_benchmark() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;
    let token_id: u256 = 69420;

    start_cheat_caller_address_global(eth_rich_address);

    let test = ERC6105TestTrait::setup();
    ETH_dispatcher.approve(test.erc6105_address, 1);
    ETH_dispatcher.transfer(test.erc6105_address, 1);
    let mut spy = spy_events();
    test.erc6105.make_item_offer(token_id,
        sale_price,
        expires,
        zero_address
    );

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id, from: eth_rich_address, sale_price, expires, supported_token: zero_address
                    }
            )
            )
        ]
    );
    stop_cheat_caller_address_global();

    start_cheat_caller_address(test.erc6105_address, OWNER());
    test.erc6105.accept_item_offer_with_benchmark(token_id, sale_price, zero_address, eth_rich_address, 0);

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::ItemPurchased(
                    ERC6105ItemOfferComponent::ItemPurchased {
                        token_id,
                        from: OWNER(),
                        to: eth_rich_address,
                        sale_price,
                        supported_token: zero_address,
                        royalties: 0
                    }
                )
            )
        ]
    );
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_get_item_offer() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;
    let token_id: u256 = 69420;

    start_cheat_caller_address_global(eth_rich_address);

    let test = ERC6105TestTrait::setup();
    ETH_dispatcher.approve(test.erc6105_address, 1);
    let mut spy = spy_events();
    test.erc6105.make_item_offer(token_id,
        sale_price,
        expires,
        zero_address
    );

    spy.assert_emitted(
        @array![
            (
                test.erc6105_address,
                ERC6105ItemOfferComponent::Event::UpdateItemOffer(
                    ERC6105ItemOfferComponent::UpdateItemOffer {
                        token_id, from: eth_rich_address, sale_price, expires, supported_token: zero_address
                    }
            )
            )
        ]
    );

    let (res_sale_price, res_expires, res_supported_token): (u256, u64, ContractAddress) = test.erc6105.get_item_offer(token_id, eth_rich_address);
    assert(res_sale_price == sale_price, 'wrong sale price');
    assert(res_expires == expires, 'wrong expires');
    assert(res_supported_token == zero_address, 'wrong supported token');
}