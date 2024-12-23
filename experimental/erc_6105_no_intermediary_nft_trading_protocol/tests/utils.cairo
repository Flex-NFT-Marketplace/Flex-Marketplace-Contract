use starknet::ContractAddress;
use openzeppelin_utils::serde::SerializedAppend;
use openzeppelin_testing::constants::{NAME, SYMBOL, BASE_URI, OWNER};
use erc_6105_no_intermediary_nft_trading_protocol::preset::{
    IERC6105MixinDispatcher, IERC6105MixinDispatcherTrait, IERC6105MixinSafeDispatcher
};
use openzeppelin_testing::deployment::declare_and_deploy;


#[derive(Copy, Drop)]
pub struct ERC6105Test {
    pub erc6105_address: ContractAddress,
    pub erc6105: IERC6105MixinDispatcher,
    pub erc6105_safe: IERC6105MixinSafeDispatcher,
}

#[generate_trait]
pub impl ERC6105TestImpl of ERC6105TestTrait {
    fn setup() -> ERC6105Test {
        let mut calldata = array![];
        calldata.append_serde(NAME());
        calldata.append_serde(SYMBOL());
        calldata.append_serde(BASE_URI());
        calldata.append_serde(1);
        let erc6105_address = declare_and_deploy(
            "ERC6105NoIntermediaryNftTradingProtocol", calldata
        );
        let erc6105 = IERC6105MixinDispatcher { contract_address: erc6105_address };
        let erc6105_safe = IERC6105MixinSafeDispatcher { contract_address: erc6105_address };
        erc6105.mint(OWNER(), 69420);
        ERC6105Test { erc6105_address, erc6105, erc6105_safe }
    }
}
