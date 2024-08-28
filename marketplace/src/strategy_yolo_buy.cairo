use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};


#[starknet::interface]
trait IStrategyYoloBuy<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn can_execute_taker_ask(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Span<felt252>
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
    // Methods that don't execute immediately: they call the callback method on the marketplace contract
    fn can_execute_taker_ask_async(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Span<felt252>
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid_async(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::contract]
mod StrategyYoloBuy {
    use starknet::{ContractAddress, contract_address_const};
    use starknet::class_hash::ClassHash;
    use starknet::get_block_timestamp;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use marketplace::utils::order_types::{TakerOrder, MakerOrder};

    #[storage]
    struct Storage {
        protocol_fee: u128,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradable: UpgradeableComponent::Storage,
        randomness_contract: IRandomnessDispatcher,
        marketplace_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[abi(embed_v0)]
    impl StrategyYoloBuyImpl of super::IStrategyYoloBuy<ContractState> {
        fn initializer(ref self: ContractState, fee: u128, owner: ContractAddress) {
            self.ownable.initializer(owner);
            self.protocol_fee.write(fee);
        }

        fn update_protocol_fee(ref self: ContractState, fee: u128) {
            self.ownable.assert_only_owner();
            self.protocol_fee.write(fee);
        }

        fn protocol_fee(self: @ContractState) -> u128 {
            self.protocol_fee.read()
        }

        fn can_execute_taker_ask(
            self: @ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            extra_params: Span<felt252>
        ) -> (bool, u256, u128) {
            // synchronous execution doesn't work for this strategy
            (false, maker_bid.token_id, maker_bid.amount)
        }
        fn can_execute_taker_bid(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            // synchronous execution doesn't work for this strategy
            (false, maker_ask.token_id, maker_ask.amount)
        }

        fn can_execute_taker_ask_async(
            self: @ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            extra_params: Span<felt252>
        ) -> (bool, u256, u128) {
            // TODO implement this
            (false, maker_bid.token_id, maker_bid.amount)
        }

        fn can_execute_taker_bid_async(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            let price_match: bool = maker_ask.price == taker_bid.price;
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            if (price_match && token_id_match && start_time_valid && end_time_valid) {
                // Call the YOLO buy processing function
                self.process_yolo_buy(taker_bid, maker_ask);
            }
            // Always return false for async execution
            (false, maker_ask.token_id, maker_ask.amount)
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }
    }
    #[generate_trait]
    impl YOLOBuyImpl of YOLOBuyTrait {
        fn process_yolo_buy(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) {
            // Calculate odds based on bid amount
            let odds = self.calculate_odds(taker_bid.price, maker_ask.price);

            // Request randomness from Pragma VRF
            let randomness_dispatcher = IRandomnessDispatcher {
                contract_address: self.randomness_contract.read()
            };

            // pack the taker bid and maker ask into a single felt252 array
            let mut vrf_calldata = array![];
            taker_bid.serialize(ref vrf_calldata);
            maker_ask.serialize(ref vrf_calldata);
            let request_id = randomness_dispatcher
                .request_random(vrf_calldata);
        }

        fn calculate_odds(
            bid_amount: u128, full_price: u128
        ) -> u128 { // Implement odds calculation logic
        // Return odds as a percentage (e.g., 25 for 25%)
        }

        fn receive_random_words(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>,
            calldata: Array<felt252>
        ) {
            // Verify caller is the Pragma Randomness contract
            assert(get_caller_address() == self.randomness_contract.read(), 'Invalid caller');

            // Retrieve pending bid
            let (bidder, bid_amount) = self.pending_bids.read(request_id);

            // Use randomness to determine if the bid wins
            let random_number = *random_words.at(0);
            let wins = self.determine_win(random_number, bid_amount);

            if wins { // Execute the YOLO Buy (transfer NFT, handle payments)
            // You might need to call back to the MarketPlace contract here
            } else { // Handle losing bid (e.g., refund fees, update stats)
            }

            // Call the callback method on the Marketplace contract
            let marketplace = IMarketplaceDispatcher {
                contract_address: self.marketplace_address.read()
            };
            marketplace.async_match_callback(taker_bid, maker_ask, get_contract_address());
            
        }

        fn determine_win(
            random_number: felt252, bid_amount: u128
        ) -> bool { // Implement win determination logic using the random number and bid amount
        }

        fn set_randomness_contract(ref self: ContractState, randomness_contract: ContractAddress) {
            self.ownable.assert_only_owner();
            let randomness_dispatcher = IRandomnessDispatcher {
                contract_address: randomness_contract,
            };
            self.randomness_contract.write(randomness_dispatcher);
        }

        fn get_randomness_contract(self: @ContractState) -> ContractAddress {
            self.randomness_contract.read().contract_address
        }

        fn set_marketplace_address(ref self: ContractState, marketplace_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.marketplace_address.write(marketplace_address);
        }

        fn get_marketplace_address(self: @ContractState) -> ContractAddress {
            self.marketplace_address.read()
        }
    }
}
// TODO:
// 1) special method for async execution: can_execute_taker_bid_async
// 3) do setup logic in this method: add market orders to the calldata
// 3) call callback method on the marketplace contract


