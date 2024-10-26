#[starknet::contract]
mod ERC5173FutureRewards {
    use starknet::{
        ContractAddress, get_caller_address, storage::Map
    };
    use erc_5173_future_rewards::interface::IERC5173FutureRewards;
    use erc_5173_future_rewards::structs::{
        FRInfo, ListInfo, AllottedRewards, 
        RewardsClaimed, Listed, Unlisted, Bought
    };
    use erc_5173_future_rewards::errors;

    #[storage]
    struct Storage {
        default_fr_info: FRInfo,
        token_fr_info: Map::<u256, FRInfo>,
        addresses_in_fr: Map::<u256, Array<ContractAddress>>,
        allotted_fr: Map::<ContractAddress, AllottedRewards>,
        token_list_info: Map::<u256, ListInfo>,    
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Listed: Listed,
        Unlisted: Unlisted,
        Bought: Bought,
        RewardsClaimed: RewardsClaimed
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        num_generations: u256,
        profit_percentage: u256,
        successive_ratio: u256
    ) {
        self.default_fr_info.write(FRInfo {
            profit_percentage,
            successive_ratio,
            owner_amount: 0,
            last_sold_price: 0,
            num_generations,
            is_valid: true
        });
    }

    #[abi(embed_v0)]
    impl ERC5173FutureRewardsImpl of IERC5173FutureRewards<ContractState> {
        fn get_fr_info(self: @ContractState, token_id: u256) -> (u8, u256, u256, u256, u256, Array<ContractAddress>) {
            let fr_info = self.token_fr_info.read(token_id);
            let addresses = self.addresses_in_fr.read(token_id);
            (
                fr_info.num_generations.try_into().unwrap(),
                fr_info.profit_percentage,
                fr_info.successive_ratio,
                fr_info.last_sold_price,
                fr_info.owner_amount.try_into().unwrap(),
                addresses
            )
        }

        fn get_allotted_rewards(self: @ContractState, account: ContractAddress) -> u256 {
            self.allotted_fr.read(account).allotted_rewards
        }

        fn get_list_info(self: @ContractState, token_id: u256) -> (u256, ContractAddress, bool) {
            let list_info = self.token_list_info.read(token_id);
            (list_info.sale_price, list_info.lister, list_info.is_listed)
        }
    }
}
