use starknet::ContractAddress;
use flex::marketplace::utils::openedition::PublicDrop;

#[starknet::interface]
trait IFlexDrop<TContractState> {
    fn mint_public(
        ref self: TContractState,
        nft_address: ContractAddress,
        fee_recipient: ContractAddress,
        minter_if_not_payer: ContractAddress,
        quantity: u64,
        currency: ContractAddress,
    );
    fn update_public_drop(ref self: TContractState, public_drop: PublicDrop);
    fn update_creator_payout_address(ref self: TContractState, new_payout_address: ContractAddress);
    fn update_allowed_fee_recipient(
        ref self: TContractState, fee_recipient: ContractAddress, allowed: bool
    );
    fn update_payer(ref self: TContractState, payer: ContractAddress, allowed: bool);
}

