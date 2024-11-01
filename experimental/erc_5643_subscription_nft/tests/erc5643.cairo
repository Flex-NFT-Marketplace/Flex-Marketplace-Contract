use core::panic_with_felt252;
use snforge_std::{
    start_cheat_caller_address, start_cheat_block_timestamp, spy_events, EventSpyAssertionsTrait
};
use openzeppelin_testing::constants::{OWNER, TOKEN_ID, FAILURE};
use openzeppelin_token::erc721::ERC721Component;
use erc_5643_subscription_nft::erc5643::interface::IERC5643_ID;
use erc_5643_subscription_nft::erc5643::erc5643::ERC5643Component;
use erc_5643_subscription_nft::presets::erc5643_subscription_nft::{
    IERC5643SubscriptionNftMixinDispatcherTrait, IERC5643SubscriptionNftMixinSafeDispatcherTrait
};
use super::utils::ERC5643TestTrait;

#[test]
fn test_supports_interface_id() {
    let erc5643_test = ERC5643TestTrait::setup();
    assert_eq!(erc5643_test.erc5643_subscription_nft.supports_interface(IERC5643_ID), true);
}

#[test]
fn test_renewal_valid() {
    let erc5643_test = ERC5643TestTrait::setup();
    start_cheat_block_timestamp(erc5643_test.erc5643_subscription_nft_address, 1000);
    start_cheat_caller_address(erc5643_test.erc5643_subscription_nft_address, OWNER());
    let mut spy = spy_events();
    erc5643_test.erc5643_subscription_nft.renew_subscription(TOKEN_ID, 2000);
    spy
        .assert_emitted(
            @array![
                (
                    erc5643_test.erc5643_subscription_nft_address,
                    ERC5643Component::Event::SubscriptionUpdate(
                        ERC5643Component::SubscriptionUpdate {
                            token_id: TOKEN_ID, expiration: 3000,
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_renewal_not_owner() {
    let erc5643_test = ERC5643TestTrait::setup();
    match erc5643_test.erc5643_subscription_nft_safe.renew_subscription(TOKEN_ID, 2000) {
        Result::Ok(_) => panic_with_felt252(FAILURE),
        Result::Err(panic_data) => {
            assert_eq!(*panic_data.at(0), ERC721Component::Errors::UNAUTHORIZED);
        }
    }
}

#[test]
fn test_cancel_valid() {
    let erc5643_test = ERC5643TestTrait::setup();
    start_cheat_caller_address(erc5643_test.erc5643_subscription_nft_address, OWNER());
    let mut spy = spy_events();
    erc5643_test.erc5643_subscription_nft.cancel_subscription(TOKEN_ID);
    spy
        .assert_emitted(
            @array![
                (
                    erc5643_test.erc5643_subscription_nft_address,
                    ERC5643Component::Event::SubscriptionUpdate(
                        ERC5643Component::SubscriptionUpdate { token_id: TOKEN_ID, expiration: 0, }
                    )
                )
            ]
        );
}

#[test]
fn test_cancel_not_owner() {
    let erc5643_test = ERC5643TestTrait::setup();
    match erc5643_test.erc5643_subscription_nft_safe.cancel_subscription(TOKEN_ID) {
        Result::Ok(_) => panic_with_felt252(FAILURE),
        Result::Err(panic_data) => {
            assert_eq!(*panic_data.at(0), ERC721Component::Errors::UNAUTHORIZED);
        }
    }
}

#[test]
fn test_expires_at() {
    let erc5643_test = ERC5643TestTrait::setup();
    start_cheat_block_timestamp(erc5643_test.erc5643_subscription_nft_address, 1000);
    assert_eq!(erc5643_test.erc5643_subscription_nft.expires_at(TOKEN_ID), 0);
    start_cheat_caller_address(erc5643_test.erc5643_subscription_nft_address, OWNER());
    erc5643_test.erc5643_subscription_nft.renew_subscription(TOKEN_ID, 2000);
    assert_eq!(erc5643_test.erc5643_subscription_nft.expires_at(TOKEN_ID), 3000);
    erc5643_test.erc5643_subscription_nft.cancel_subscription(TOKEN_ID);
    assert_eq!(erc5643_test.erc5643_subscription_nft.expires_at(TOKEN_ID), 0);
}
