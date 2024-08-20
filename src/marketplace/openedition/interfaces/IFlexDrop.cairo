use starknet::ContractAddress;
use flex::marketplace::utils::openedition::{PhaseDrop, WhiteListParam};

#[starknet::interface]
trait IFlexDrop<TContractState> {
    fn mint_public(
        ref self: TContractState,
        nft_address: ContractAddress,
        phase_id: u64,
        fee_recipient: ContractAddress,
        minter_if_not_payer: ContractAddress,
        quantity: u64,
        is_warpcast: bool,
    );
    fn whitelist_mint(
        ref self: TContractState,
        whitelist_data: WhiteListParam,
        fee_recipient: ContractAddress,
        proof: Array<felt252>
    );
    fn start_new_phase_drop(
        ref self: TContractState,
        phase_drop_id: u64,
        phase_drop: PhaseDrop,
        fee_recipient: ContractAddress,
    );
    fn update_phase_drop(ref self: TContractState, phase_drop_id: u64, phase_drop: PhaseDrop);
    fn update_creator_payout_address(ref self: TContractState, new_payout_address: ContractAddress);
    fn update_payer(ref self: TContractState, payer: ContractAddress, allowed: bool);
}

