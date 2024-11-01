use starknet::ContractAddress;
use openzeppelin_utils::serde::SerializedAppend;
use openzeppelin_testing::constants::{NAME, SYMBOL, BASE_URI, OWNER, TOKEN_ID};
use openzeppelin_testing::deployment::declare_and_deploy;
use erc_5643_subscription_nft::presets::erc5643_subscription_nft::{
    IERC5643SubscriptionNftMixinDispatcher, IERC5643SubscriptionNftMixinDispatcherTrait,
    IERC5643SubscriptionNftMixinSafeDispatcher,
};

#[derive(Copy, Drop)]
pub struct ERC5643Test {
    pub erc5643_subscription_nft_address: ContractAddress,
    pub erc5643_subscription_nft: IERC5643SubscriptionNftMixinDispatcher,
    pub erc5643_subscription_nft_safe: IERC5643SubscriptionNftMixinSafeDispatcher,
}

#[generate_trait]
pub impl ERC5643TestImpl of ERC5643TestTrait {
    fn setup() -> ERC5643Test {
        let mut erc5643_subscription_nft_calldata = array![];
        erc5643_subscription_nft_calldata.append_serde(NAME());
        erc5643_subscription_nft_calldata.append_serde(SYMBOL());
        erc5643_subscription_nft_calldata.append_serde(BASE_URI());
        let erc5643_subscription_nft_address = declare_and_deploy(
            "ERC5643SubscriptionNft", erc5643_subscription_nft_calldata
        );
        let erc5643_subscription_nft = IERC5643SubscriptionNftMixinDispatcher {
            contract_address: erc5643_subscription_nft_address
        };
        let erc5643_subscription_nft_safe = IERC5643SubscriptionNftMixinSafeDispatcher {
            contract_address: erc5643_subscription_nft_address
        };
        erc5643_subscription_nft.mint(OWNER(), TOKEN_ID);
        ERC5643Test {
            erc5643_subscription_nft_address,
            erc5643_subscription_nft,
            erc5643_subscription_nft_safe,
        }
    }
}
