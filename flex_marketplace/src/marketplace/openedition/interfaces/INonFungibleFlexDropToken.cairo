use array::Array;
use starknet::ContractAddress;
use flex::marketplace::utils::openedition::{PublicDrop, MultiConfigureStruct};

const I_NON_FUNGIBLE_FLEX_DROP_TOKEN_ID: felt252 =
    0x7345179e748058b5caaabedd83ec1cce0034f037610dbd70846917635ea85a;

#[starknet::interface]
trait INonFungibleFlexDropToken<TContractState> {
    // update FlexDrop contract addresses
    fn update_allowed_flex_drop(
        ref self: TContractState, allowed_flex_drop: Array::<ContractAddress>
    );
    // mint tokens, restricted to the FlexDrop contract
    fn mint_flex_drop(ref self: TContractState, minter: ContractAddress, quantity: u64);
    fn update_public_drop(
        ref self: TContractState, flex_drop: ContractAddress, public_drop: PublicDrop
    );
    fn update_creator_payout(
        ref self: TContractState, flex_drop: ContractAddress, payout_address: ContractAddress
    );
    fn update_fee_recipient(
        ref self: TContractState,
        flex_drop: ContractAddress,
        fee_recipient: ContractAddress,
        allowed: bool
    );
    // update payer address for paying gas fee of minting NFT
    fn update_payer(
        ref self: TContractState, flex_drop: ContractAddress, payer: ContractAddress, allowed: bool
    );
    fn multi_configure(ref self: TContractState, config: MultiConfigureStruct);
    // return (number minted, current total supply, max supply)
    fn get_mint_state(self: @TContractState, minter: ContractAddress) -> (u64, u64, u64);
    fn get_current_token_id(self: @TContractState) -> u256;
}
