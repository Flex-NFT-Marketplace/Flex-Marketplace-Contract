use starknet::ContractAddress;
use openzeppelin_utils::serde::SerializedAppend;
use openzeppelin_testing::constants::{NAME, SYMBOL, BASE_URI, OWNER, TOKEN_ID};
use openzeppelin_testing::deployment::declare_and_deploy;
use erc_4907_rental_nft::presets::erc4907_rental_nft::{
    IERC4907RentalNftMixinDispatcher, IERC4907RentalNftMixinDispatcherTrait,
    IERC4907RentalNftMixinSafeDispatcher,
};

#[derive(Copy, Drop)]
pub struct ERC4907Test {
    pub erc4907_rental_nft_address: ContractAddress,
    pub erc4907_rental_nft: IERC4907RentalNftMixinDispatcher,
    pub erc4907_rental_nft_safe: IERC4907RentalNftMixinSafeDispatcher,
}

#[generate_trait]
pub impl ERC4907TestImpl of ERC4907TestTrait {
    fn setup() -> ERC4907Test {
        let mut erc4907_rental_nft_calldata = array![];
        erc4907_rental_nft_calldata.append_serde(NAME());
        erc4907_rental_nft_calldata.append_serde(SYMBOL());
        erc4907_rental_nft_calldata.append_serde(BASE_URI());
        let erc4907_rental_nft_address = declare_and_deploy(
            "ERC4907RentalNft", erc4907_rental_nft_calldata,
        );
        let erc4907_rental_nft = IERC4907RentalNftMixinDispatcher {
            contract_address: erc4907_rental_nft_address,
        };
        let erc4907_rental_nft_safe = IERC4907RentalNftMixinSafeDispatcher {
            contract_address: erc4907_rental_nft_address,
        };
        erc4907_rental_nft.mint(OWNER(), TOKEN_ID);

        ERC4907Test { erc4907_rental_nft_address, erc4907_rental_nft, erc4907_rental_nft_safe }
    }
}
