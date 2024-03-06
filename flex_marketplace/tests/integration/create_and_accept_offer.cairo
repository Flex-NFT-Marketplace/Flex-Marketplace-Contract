use flex::mocks::{
    erc721::{IERC721Dispatcher, IERC721DispatcherTrait},
    erc20::{IERC20Dispatcher, IERC20DispatcherTrait}
};
use tests::{
    utils::{setup, E18, Dispatchers, OWNER},
    integration::utils::{Mocks, initialize_test, deploy_mock_accounts}
};
use flex::marketplace::{
    signature_checker2::{ISignatureChecker2Dispatcher, ISignatureChecker2DispatcherTrait},
    marketplace::{IMarketPlaceDispatcher, IMarketPlaceDispatcherTrait},
    utils::order_types::{MakerOrder, TakerOrder}
};
use snforge_std::{start_prank, stop_prank, CheatTarget};
use starknet::{get_block_timestamp, ContractAddress, contract_address_const, contract_address_to_felt252};
use snforge_std::signature::KeyPairTrait;
use snforge_std::signature::stark_curve::{
    StarkCurveKeyPairImpl, StarkCurveSignerImpl, StarkCurveVerifierImpl
};

fn create_maker_bid_offer(mocks: Mocks, approvee: ContractAddress, dsp: Dispatchers) -> (MakerOrder, felt252, felt252, ContractAddress, ContractAddress) {
    let key_pair1 = KeyPairTrait::<felt252, felt252>::generate();
    let key_pair2 = KeyPairTrait::<felt252, felt252>::generate();

    let pub_keys = array![key_pair1.public_key, key_pair2.public_key];

    let accounts = deploy_mock_accounts(pub_keys);
    let buyer = *accounts.at(0);
    let seller = *accounts.at(1);
    let nft = IERC721Dispatcher { contract_address: mocks.erc721 };

    start_prank(CheatTarget::One(mocks.erc721), seller);
    nft.mint(seller);
    nft.approve(approvee, 1);
    stop_prank(CheatTarget::One(mocks.erc721));

    let mut maker_bid: MakerOrder = Default::default();

    maker_bid.signer = buyer;
    maker_bid.collection = mocks.erc721;
    maker_bid.price = E18;
    maker_bid.token_id = 1;
    maker_bid.amount = 1;
    maker_bid.strategy = mocks.strategy;
    maker_bid.currency = mocks.erc20;

    let maker_bid_hash = dsp
        .signature_checker
        .compute_maker_order_hash(dsp.marketplace.get_hash_domain(), maker_bid);

    let (r, s): (felt252, felt252) = key_pair1.sign(maker_bid_hash);

    return (maker_bid, r, s, buyer, seller);
}

fn create_maker_ask_offer(mocks: Mocks, approvee: ContractAddress, dsp: Dispatchers) -> (MakerOrder, felt252, felt252, ContractAddress, ContractAddress) {
    let key_pair1 = KeyPairTrait::<felt252, felt252>::generate();
    let key_pair2 = KeyPairTrait::<felt252, felt252>::generate();

    let pub_keys = array![key_pair1.public_key, key_pair2.public_key];

    let accounts = deploy_mock_accounts(pub_keys);
    let buyer = *accounts.at(0);
    let seller = *accounts.at(1);
    let nft = IERC721Dispatcher { contract_address: mocks.erc721 };

    start_prank(CheatTarget::One(mocks.erc721), seller);
    nft.mint(seller);
    nft.approve(approvee, 1);
    stop_prank(CheatTarget::One(mocks.erc721));

    let mut maker_ask: MakerOrder = Default::default();
    maker_ask.is_order_ask = true;
    maker_ask.signer = seller;
    maker_ask.collection = mocks.erc721;
    maker_ask.price = E18;
    maker_ask.token_id = 1;
    maker_ask.amount = 1;
    maker_ask.strategy = mocks.strategy;
    maker_ask.currency = mocks.erc20;

    let maker_ask_hash = dsp
        .signature_checker
        .compute_maker_order_hash(dsp.marketplace.get_hash_domain(), maker_ask);

    let (r, s): (felt252, felt252) = key_pair2.sign(maker_ask_hash);

    return (maker_ask, r, s, buyer, seller);
}

#[test]
fn initiate_taker_ask_offer() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (maker_bid, r, s, buyer, seller) = create_maker_bid_offer(mocks, dsp.transfer_manager_erc721.contract_address, dsp);
    let currency = IERC20Dispatcher{ contract_address: mocks.erc20 };
    let nft = IERC721Dispatcher { contract_address: mocks.erc721 };

    start_prank(CheatTarget::All(()), OWNER());
    currency.transfer(buyer, (1000 * E18).into());
    stop_prank(CheatTarget::All(()));

    // check balance before main offer transaction
    let bidder_before_bal = currency.balance_of(buyer);
    assert!(bidder_before_bal == (1000 * E18).into(), "Unexpected Bidder before Balance {}", bidder_before_bal);
    let taker_before_bal = currency.balance_of(seller);
    assert!(taker_before_bal.is_zero(), "Unexpected Taker after Balance {}", taker_before_bal);

    let nft_buyer_before_bal = nft.balance_of(buyer);
    assert!(nft_buyer_before_bal.is_zero(), "Unexpected Buyer NFT Balance {}", nft_buyer_before_bal);
    let nft_seller_before_bal = nft.balance_of(seller);
    assert!(nft_seller_before_bal == 1, "Unexpected Seller NFT Balance {}", nft_seller_before_bal);

    // buyer approves marketplace to spend token
    start_prank(CheatTarget::One(mocks.erc20), buyer);
    IERC20Dispatcher{ contract_address: mocks.erc20 }.approve(dsp.marketplace.contract_address, (E18).into());
    stop_prank(CheatTarget::One(mocks.erc20));

    // taker sell to maker buy at the desired price
    let mut taker_ask: TakerOrder = Default::default();
    taker_ask.is_order_ask = true;
    taker_ask.taker = seller;
    taker_ask.price = E18;
    taker_ask.token_id = 1;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), seller);
    dsp.marketplace.match_bid_with_taker_ask(taker_ask, maker_bid, array![r, s], array![]);

    let royalty_and_protocol_fee = 200_000_000_000_000_000;

    // check buyer and seller balance after creating and accepting offfer
    let bidder_after_bal = currency.balance_of(buyer);
    assert!(bidder_after_bal == (999 * E18).into(), "Unexpected Bidder after Balance {}", bidder_after_bal);
    let taker_after_bal = currency.balance_of(seller);
    assert!(taker_after_bal == (E18 - royalty_and_protocol_fee).into(), "Unexpected Taker after Balance {}", taker_after_bal);

    let nft_buyer_after_bal = nft.balance_of(buyer);
    assert!(nft_buyer_after_bal == 1, "Unexpected Buyer NFT Balance {}", nft_buyer_after_bal);
    let nft_seller_after_bal = nft.balance_of(seller);
    assert!(nft_seller_after_bal.is_zero(), "Unexpected Seller NFT Balance {}", nft_seller_after_bal);
}

#[test]
fn initiate_taker_bid_offer() {
    let dsp = setup();
    let mocks = initialize_test(dsp);
    let (maker_ask, r, s, buyer, seller) = create_maker_ask_offer(mocks, dsp.transfer_manager_erc721.contract_address, dsp);
    let currency = IERC20Dispatcher{ contract_address: mocks.erc20 };
    let nft = IERC721Dispatcher { contract_address: mocks.erc721 };

    let nft_buyer_before_bal = nft.balance_of(buyer);
    assert!(nft_buyer_before_bal.is_zero(), "Unexpected Buyer NFT Balance {}", nft_buyer_before_bal);
    let nft_seller_before_bal = nft.balance_of(seller);
    assert!(nft_seller_before_bal == 1, "Unexpected Seller NFT Balance {}", nft_seller_before_bal);

    start_prank(CheatTarget::All(()), OWNER());
    currency.transfer(buyer, (1000 * E18).into());
    stop_prank(CheatTarget::All(()));

    // check balance before main offer transaction
    let buyer_before_bal = currency.balance_of(buyer);
    assert!(buyer_before_bal == (1000 * E18).into(), "Unexpected Buyer before Balance {}", buyer_before_bal);
    let seller_before_bal = currency.balance_of(seller);
    assert!(seller_before_bal.is_zero(), "Unexpected Seller before Balance {}", seller_before_bal);

    // buyer approves marketplace to spend token
    start_prank(CheatTarget::One(mocks.erc20), buyer);
    IERC20Dispatcher{ contract_address: mocks.erc20 }.approve(dsp.marketplace.contract_address, (E18).into());
    stop_prank(CheatTarget::One(mocks.erc20));

    // taker sell to maker buy at the desired price
    let mut taker_bid: TakerOrder = Default::default();
    taker_bid.taker = buyer;
    taker_bid.price = E18;
    taker_bid.token_id = 1;

    start_prank(CheatTarget::One(dsp.marketplace.contract_address), buyer);
    dsp.marketplace.match_ask_with_taker_bid(taker_bid, maker_ask, array![r, s], contract_address_const::<0>());

    let royalty_and_protocol_fee = 200_000_000_000_000_000;
    // check buyer and seller balance after creating and accepting offfer
    let buyer_after_bal = currency.balance_of(buyer);
    assert!(buyer_after_bal == (999 * E18).into(), "Unexpected Bidder after Balance {}", buyer_after_bal);
    let seller_after_bal = currency.balance_of(seller);
    assert!(seller_after_bal == (E18 - royalty_and_protocol_fee).into(), "Unexpected Taker after Balance {}", seller_after_bal);

    let nft_buyer_after_bal = nft.balance_of(buyer);
    assert!(nft_buyer_after_bal == 1, "Unexpected Buyer NFT Balance {}", nft_buyer_after_bal);
    let nft_seller_after_bal = nft.balance_of(seller);
    assert!(nft_seller_after_bal.is_zero(), "Unexpected Seller NFT Balance {}", nft_seller_after_bal);
}