use starknet::ContractAddress;
use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, start_cheat_caller_address_global,
    spy_events, EventSpyAssertionsTrait
};
use openzeppelin_testing::constants::OWNER;
use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use erc_6105_no_intermediary_nft_trading_protocol::erc6105::ERC6105Component;
use erc_6105_no_intermediary_nft_trading_protocol::preset::IERC6105MixinDispatcherTrait;
use super::utils::ERC6105TestTrait;

#[test]
fn test_list_item() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let token_id: u256 = 69420;
    let sale_price: u256 = 100;
    let expires: u64 = 3600000;

    let test = ERC6105TestTrait::setup();
    start_cheat_caller_address(test.erc6105_address, OWNER());
    let mut spy = spy_events();
    test.erc6105.list_item(token_id, sale_price, expires, zero_address);
    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::UpdateListing(
                        ERC6105Component::UpdateListing {
                            token_id,
                            from: OWNER(),
                            sale_price,
                            expires,
                            supported_token: zero_address,
                            benchmark_price: 0
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_list_item_with_benchmark() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let token_id: u256 = 69420;
    let sale_price: u256 = 100;
    let expires: u64 = 3600000;
    let benchmark_price: u256 = 200;

    let test = ERC6105TestTrait::setup();
    start_cheat_caller_address(test.erc6105_address, OWNER());
    let mut spy = spy_events();
    test
        .erc6105
        .list_item_with_benchmark(token_id, sale_price, expires, zero_address, benchmark_price);
    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::UpdateListing(
                        ERC6105Component::UpdateListing {
                            token_id,
                            from: OWNER(),
                            sale_price,
                            expires,
                            supported_token: zero_address,
                            benchmark_price
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_delist_item() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let token_id: u256 = 69420;
    let sale_price: u256 = 100;
    let expires: u64 = 3600000;
    let benchmark_price: u256 = 200;

    let test = ERC6105TestTrait::setup();
    start_cheat_caller_address(test.erc6105_address, OWNER());
    let mut spy = spy_events();
    test
        .erc6105
        .list_item_with_benchmark(token_id, sale_price, expires, zero_address, benchmark_price);
    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::UpdateListing(
                        ERC6105Component::UpdateListing {
                            token_id,
                            from: OWNER(),
                            sale_price,
                            expires,
                            supported_token: zero_address,
                            benchmark_price
                        }
                    )
                )
            ]
        );
    test.erc6105.delist_item(token_id);

    let (
        res_sale_price, res_expires, res_supported_token, res_historical_price
    ): (u256, u64, ContractAddress, u256) =
        test
        .erc6105
        .get_listing(token_id);
    assert(res_sale_price == 0, 'Listing not null (sale_price)');
    assert(res_expires == 0, 'Listing not null (expires)');
    assert(res_supported_token == zero_address, 'Listing not null (token)');
    assert(res_historical_price == 0, 'Listing not null (bp_price)');
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 400000)]
fn test_buy_item() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let ETH_address: ContractAddress =
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let eth_rich_address: ContractAddress =
        0x061fa009f87866652b6fcf4d8ea4b87a12f85e8cb682b912b0a79dafdbb7f362
        .try_into()
        .unwrap();
    let token_id: u256 = 69420;
    let sale_price: u256 = 1;
    let expires: u64 = 9999999999;

    let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };

    start_cheat_caller_address(ETH_address, eth_rich_address);
    ETH_dispatcher.transfer(OWNER(), 5);
    stop_cheat_caller_address(ETH_address);

    let test = ERC6105TestTrait::setup();
    start_cheat_caller_address_global(OWNER());
    let mut spy = spy_events();
    test.erc6105.list_item(token_id, sale_price, expires, zero_address);
    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::UpdateListing(
                        ERC6105Component::UpdateListing {
                            token_id,
                            from: OWNER(),
                            sale_price,
                            expires,
                            supported_token: zero_address,
                            benchmark_price: 0
                        }
                    )
                )
            ]
        );

    let tx_res = ETH_dispatcher.transfer(test.erc6105_address, sale_price);
    assert(tx_res == true, 'tx failed');

    test.erc6105.buy_item(token_id, sale_price, zero_address);

    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::Purchased(
                        ERC6105Component::Purchased {
                            token_id,
                            from: OWNER(),
                            to: OWNER(),
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
fn test_get_listing() {
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let token_id: u256 = 69420;
    let sale_price: u256 = 100;
    let expires: u64 = 3600000;
    let benchmark_price: u256 = 200;

    let test = ERC6105TestTrait::setup();
    start_cheat_caller_address(test.erc6105_address, OWNER());
    let mut spy = spy_events();
    test
        .erc6105
        .list_item_with_benchmark(token_id, sale_price, expires, zero_address, benchmark_price);
    spy
        .assert_emitted(
            @array![
                (
                    test.erc6105_address,
                    ERC6105Component::Event::UpdateListing(
                        ERC6105Component::UpdateListing {
                            token_id,
                            from: OWNER(),
                            sale_price,
                            expires,
                            supported_token: zero_address,
                            benchmark_price
                        }
                    )
                )
            ]
        );

    let (
        res_sale_price, res_expires, res_supported_token, res_historical_price
    ): (u256, u64, ContractAddress, u256) =
        test
        .erc6105
        .get_listing(token_id);
    assert(res_sale_price == sale_price, 'Listing not null (sale_price)');
    assert(res_expires == expires, 'Listing not null (expires)');
    assert(res_supported_token == zero_address, 'Listing not null (token)');
    assert(res_historical_price == benchmark_price, 'Listing not null (bp_price)');
}
