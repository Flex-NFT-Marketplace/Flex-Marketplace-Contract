use array::Array;
use starknet::ContractAddress;
use flex::marketplace::utils::openedition::{PhaseDrop, MultiConfigureStruct};

const I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID: felt252 =
    0x3e8437a5f69da6b8bd474c863221741d75466a9500cfe343ac93d0e38135c16;

#[starknet::interface]
trait INonFungibleFlexDropToken<TContractState> {
    // update FlexDrop contract addresses
    fn update_allowed_flex_drop(
        ref self: TContractState, allowed_flex_drop: Array::<ContractAddress>
    );
    // mint tokens, restricted to the FlexDrop contract
    fn mint_flex_drop(
        ref self: TContractState, minter: ContractAddress, phase_id: u64, quantity: u64
    );
    fn create_new_phase_drop(
        ref self: TContractState,
        flex_drop: ContractAddress,
        phase_detail: PhaseDrop,
        fee_recipient: ContractAddress,
    );
    fn update_phase_drop(
        ref self: TContractState, flex_drop: ContractAddress, phase_id: u64, phase_detail: PhaseDrop
    );
    fn update_creator_payout(
        ref self: TContractState, flex_drop: ContractAddress, payout_address: ContractAddress
    );
    // update payer address for paying gas fee of minting NFT
    fn update_payer(
        ref self: TContractState, flex_drop: ContractAddress, payer: ContractAddress, allowed: bool
    );
    fn multi_configure(ref self: TContractState, config: MultiConfigureStruct);
    // return (number minted, current total supply, max supply)
    fn get_mint_state(
        self: @TContractState, minter: ContractAddress, phase_id: u64
    ) -> (u64, u64, u64);
    fn get_current_token_id(self: @TContractState) -> u256;
    fn get_allowed_flex_drops(self: @TContractState) -> Span::<ContractAddress>;
}
