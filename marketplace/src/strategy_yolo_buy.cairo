use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};

const MAX_FELT252: u256 = 3618502788666131213697322783095070105623107215331596699973092056135872020480_u256;

#[starknet::interface]
trait IStrategyYoloBuy<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn can_execute_taker_bid(
        ref self: TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
    fn receive_random_words(
        ref self: TState,
        requestor_address: ContractAddress,
        request_id: u64,
        random_words: Span<felt252>,
        calldata: Array<felt252>
    );
    fn set_randomness_contract(ref self: TState, randomness_contract: ContractAddress);
    fn get_randomness_contract(self: @TState) -> ContractAddress;
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::contract]
mod StrategyYoloBuy {

    use starknet::{ContractAddress, contract_address_const};
    use starknet::class_hash::ClassHash;
    use starknet::get_block_timestamp;
    use starknet::info::{get_caller_address, get_contract_address};
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use marketplace::utils::order_types::{TakerOrder, MakerOrder};

    #[derive(Clone, Drop, Serde, starknet::Store)]
    struct PendingRequest {
        request_id: u64,
        ask_price: u128,
        bid_price: u128,
        taker: ContractAddress,
        collection: ContractAddress,
        token_id: u256,
        amount: u128,
        finished: bool,
        won: bool,
    }    

    #[storage]
    struct Storage {
        protocol_fee: u128,
        takers_by_request_id: LegacyMap<u64, ContractAddress>,
        requests_by_taker: LegacyMap<ContractAddress, Option<PendingRequest>>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        randomness_contract: IRandomnessDispatcher,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        NewYoloBuy: NewYoloBuy
    }

    #[derive(Drop, starknet::Event)]
    struct NewYoloBuy {
        token_id: u256,
        taker: ContractAddress
        timestamp: u64,
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

        fn create_bid(
            ref self: ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) {
            // Check if the bid is valid (token id matches, start and end times are valid),
            // then calculate the odds, save the bid in storage, request randomness from Pragma VRF,
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            if (token_id_match && start_time_valid && end_time_valid) {
                // Get order hash
                let order_hash = taker_bid.compute_order_hash();
                // Check if there is this order exists
                if !self.requests_by_taker.read(order_hash).is_some() {
                    // Call the YOLO buy processing function
                    self.process_yolo_buy(taker_bid, maker_ask);
                    let timestamp = get_block_timestamp();
                    self.emit(NewYoloBuy {token_id: taker_bid.token_id, taker: taker_bid.taker, timestamp: timestamp })
                }
            }
        }
 
        fn can_execute_taker_bid(
            ref self: ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            // Check if the bid is valid (token id matches, start and end times are valid),
            // then calculate the odds, save the bid in storage, request randomness from Pragma VRF,
            // and return "false" because the bid is not executed immediately
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            if (token_id_match && start_time_valid && end_time_valid) {
                // Try to find the order
                let order_hash = taker_bid.compute_order_hash();
                if let Option::Some(pending_request) = self.requests_by_taker.read(order_hash) {
                    if pending_request.finished {
                        // check if it matches
                        let pending_price_match: bool = pending_request.bid_price == taker_bid.price;
                        let pending_token_id_match: bool = pending_request.token_id == taker_bid.token_id;
                        let pending_amount_match: bool = pending_request.amount == taker_bid.amount;
                        if pending_price_match && pending_token_id_match && pending_amount_match {
                            return (pending_request.won, maker_ask.token_id, maker_ask.amount);
                        } else {
                            return (false, maker_ask.token_id, maker_ask.amount);
                        }
                    } else {
                        return (false, maker_ask.token_id, maker_ask.amount);
                    }
                }
            }
            (false, maker_ask.token_id, maker_ask.amount)
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(impl_hash);
        }

        fn receive_random_words(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>,
            calldata: Array<felt252>
        ) {
            // Verify caller is the Pragma Randomness contract
            assert(get_caller_address() == self.randomness_contract.read().contract_address, 'Invalid caller');

            // Retrieve market orders from the storage (by request id)
            let order_hash = self.takers_by_request_id.read(request_id);
            let request = self.requests_by_taker.read(order_hash);
            if request.is_none() {
                return;
            }
            let mut request2 = request.unwrap();

            // Use randomness to determine if the bid wins
            let random_number = *random_words.at(0);
            let wins = self.determine_win(random_number, request2.bid_price, request2.ask_price);

            // Change the status of the request and save it to the storage
            request2.finished = true;
            request2.won = wins;
            self.requests_by_taker.write(taker, Option::Some(request2));
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
    }
    // Internal methods
    #[generate_trait]
    impl YOLOBuyImpl of YOLOBuyTrait {
        fn process_yolo_buy(ref self: ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder) {
            // Request randomness from Pragma VRF
            let randomness_dispatcher = self.randomness_contract.read();

            // Request the randomness
            let seed: u64 = taker_bid.params.try_into().unwrap(); // Assuming params is used as seed
            let request_id = randomness_dispatcher
                .request_random(
                    seed,
                    get_contract_address(),
                    self.protocol_fee.read(),
                    1, // publish_delay
                    1, // num_words
                    ArrayTrait::new() // empty calldata
                );

            let order_hash = taker_bid.compute_order_hash();

            // Store the request_id and pending request
            self.takers_by_request_id.write(request_id, order_hash);

            self.requests_by_taker.write(order_hash, Option::Some(PendingRequest {
                request_id,
                ask_price: maker_ask.price,
                bid_price: taker_bid.price,
                taker: taker_bid.taker,
                collection: maker_ask.collection,
                token_id: maker_ask.token_id,
                amount: maker_ask.amount,
                finished: false,
                won: false,
            }));
        }

        fn calculate_odds(self: @ContractState, bid_amount: u128, full_price: u128) -> u128 {
            // Ensure bid_amount is not greater than full_price
            assert(bid_amount <= full_price, 'Bid exceeds full price');

            // Calculate the percentage of the full price that the bid represents
            // We multiply by 100 to get a percentage
            let odds = (bid_amount * 100_u128) / full_price;

            odds
        }

        fn determine_win(self: @ContractState, random_number: felt252, bid_amount: u128, full_price: u128) -> bool {
            let odds = self.calculate_odds(bid_amount, full_price);

            // Convert felt252 to u256 for easier comparison
            let random_u256: u256 = random_number.into();

            // Calculate the threshold for winning
            let threshold: u256 = (MAX_FELT252 / 100_u256) * odds.into();

            random_u256 < threshold
        }
    }
}


