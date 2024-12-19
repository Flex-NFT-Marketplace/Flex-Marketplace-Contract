use snforge_std::{
    start_cheat_caller_address, start_cheat_block_timestamp, spy_events, EventSpyAssertionsTrait,
};
use openzeppelin_testing::constants::{OWNER, OTHER, TOKEN_ID};
use erc_4907_rental_nft::erc4907::interface::IERC4907_ID;
use erc_4907_rental_nft::erc4907::erc4907::ERC4907Component;
use erc_4907_rental_nft::presets::erc4907_rental_nft::IERC4907RentalNftMixinDispatcherTrait;
use core::num::traits::Zero;
use starknet::contract_address_const;
use super::utils::ERC4907TestTrait;

#[test]
fn test_support_intefrace_id() {
    let erc4907_test = ERC4907TestTrait::setup();

    assert!(erc4907_test.erc4907_rental_nft.supports_interface(IERC4907_ID));
}

#[test]
fn test_set_user() {
    let erc4907_test = ERC4907TestTrait::setup();
    let mut spy = spy_events();
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    let alice = OTHER();
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, 2000);

    spy
        .assert_emitted(
            @array![
                (
                    erc4907_test.erc4907_rental_nft_address,
                    ERC4907Component::Event::UpdateUser(
                        ERC4907Component::UpdateUser {
                            tokenId: TOKEN_ID, user: alice, expires: 2000,
                        },
                    ),
                ),
            ],
        )
}

#[test]
fn test_user_of() {
    let erc4907_test = ERC4907TestTrait::setup();
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    let alice = OTHER();
    let expires = 2000;
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, expires);

    let actual_user = erc4907_test.erc4907_rental_nft.userOf(TOKEN_ID);

    assert_eq!(alice, actual_user);
}

#[test]
fn test_not_zero_address() {
    let erc4907_test = ERC4907TestTrait::setup();
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    let alice = OTHER();
    let expires = 2000;
    let invalid_user = Zero::zero();
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, expires);

    let actual_user = erc4907_test.erc4907_rental_nft.userOf(TOKEN_ID);

    assert_ne!(invalid_user, actual_user);
}

#[test]
fn test_invalid_user_of() {
    let erc4907_test = ERC4907TestTrait::setup();
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    let alice = OTHER();
    let invalid_user = contract_address_const::<'INVALID'>();
    let expires = 2000;
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, expires);

    let actual_user = erc4907_test.erc4907_rental_nft.userOf(TOKEN_ID);

    assert_ne!(invalid_user, actual_user);
}

#[test]
fn test_user_expires() {
    let erc4907_test = ERC4907TestTrait::setup();
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    let alice = OTHER();
    let expires = 2000;
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, expires);

    let actual_expires = erc4907_test.erc4907_rental_nft.userExpires(TOKEN_ID);

    assert_eq!(expires, actual_expires);
}

#[test]
fn test_invalid_user_expires() {
    let erc4907_test = ERC4907TestTrait::setup();
    start_cheat_block_timestamp(erc4907_test.erc4907_rental_nft_address, 1000);
    let alice = OTHER();
    let expires = 2000;
    start_cheat_caller_address(erc4907_test.erc4907_rental_nft_address, OWNER());
    erc4907_test.erc4907_rental_nft.setUser(TOKEN_ID, alice, expires);

    let actual_expires = erc4907_test.erc4907_rental_nft.userExpires(TOKEN_ID);

    assert_ne!(expires - 1, actual_expires);
}
