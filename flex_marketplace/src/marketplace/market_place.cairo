use starknet::ContractAddress;

use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};

trait IMarketPlace<TState> {
    fn cancel_all_orders_for_sender(ref self: TState, min_nonce: u128);
    fn carcel_maker_order(ref self: TState, nonce: u128);
    fn match_ask_with_taker_bid(
        ref self: TState,
        taker_bid: TakerOrder,
        maker_ask: MakerOrder,
        maker_ask_signature: Span<felt252>,
        custom_non_fungible_token_recepient: ContractAddress
    );
    fn match_bid_with_taker_ask(
        ref self: TState,
        taker_ask: TakerOrder,
        maker_bid: MakerOrder,
        maker_bid_signature: Span<felt252>,
        extra_params: Span<felt252>
    );
    fn execute_auction_sale(
        ref self: TState,
        maker_ask: MakerOrder,
        maker_ask_signature: Span<felt252>,
        maker_bid: MakerOrder,
        maker_bid_signature: Span<felt252>
    );
    fn update_hash_domain(ref self: TState, hash: felt252);
    fn update_protocol_fee_recepient(ref self: TState, recepient: ContractAddress);
    fn update_currency_manager(ref self: TState, manager: ContractAddress);
    fn update_execution_manager(ref self: TState, manager: ContractAddress);
    fn update_royalty_fee_manager(ref self: TState, manager: ContractAddress);
    fn update_transfer_selector_NFT(ref self: TState, selector: felt252);
    fn update_signature_checker(ref self: TState, manager: ContractAddress);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn get_hash_domain(self: @TState) -> felt252;
    fn get_protocol_fee_recipient(self: @TState) -> ContractAddress;
    fn get_currency_manager(self: @TState) -> ContractAddress;
    fn get_execution_manager(self: @TState) -> ContractAddress;
    fn get_royalty_fee_manager(self: @TState) -> ContractAddress;
    fn get_transfer_selector_NFT(self: @TState) -> felt252;
    fn get_signature_checker(self: @TState) -> ContractAddress;
    fn get_user_min_order_nonce(self: @TState) -> u128;
    fn get_is_user_order_nonce_executed_or_cancelled(
        self: @TState, user: ContractAddress, nonce: u128
    ) -> bool;
}

#[starknet::contract]
mod MarketPlace {
    use starknet::{ContractAddress, contract_address_const};

    use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        hash_domain: felt252,
        protocol_fee_recipient: ContractAddress,
        currency_manager: ContractAddress,
        execution_manager: ContractAddress,
        royalty_fee_manager: ContractAddress,
        transfer_selector_NFT: felt252,
        signature_checker: ContractAddress,
        user_min_order_nonce: LegacyMap::<ContractAddress, u128>,
        is_user_order_nonce_executed_or_cancelled: LegacyMap::<(ContractAddress, u128), bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CancelAllOrders: CancelAllOrders,
        CancelOrder: CancelOrder,
        NewHashDomain: NewHashDomain,
        NewProtocolFeeRecipient: NewProtocolFeeRecipient,
        NewCurrencyManager: NewCurrencyManager,
        NewExecutionManager: NewExecutionManager,
        NewRoyaltyFeeManager: NewRoyaltyFeeManager,
        NewTransferSelectorNFT: NewTransferSelectorNFT,
        NewSignatureChecker: NewSignatureChecker,
        RoyaltyPayment: RoyaltyPayment,
        TakerAsk: TakerAsk,
        TakerBid: TakerBid,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CancelAllOrders {
        user: ContractAddress,
        new_min_nonce: u128,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct CancelOrder {
        user: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewHashDomain {
        hash: felt252,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewProtocolFeeRecipient {
        recipient: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewCurrencyManager {
        manager: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewExecutionManager {
        manager: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewRoyaltyFeeManager {
        manager: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewTransferSelectorNFT {
        selector: felt252,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct NewSignatureChecker {
        checker: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct RoyaltyPayment {
        collection: ContractAddress,
        tokenId: u256,
        royaltyRecipient: ContractAddress,
        currency: ContractAddress,
        amount: u128,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TakerAsk {
        orderHash: felt252,
        orderNonce: u128,
        taker: ContractAddress,
        maker: ContractAddress,
        strategy: felt252,
        currency: ContractAddress,
        collection: ContractAddress,
        tokenId: u256,
        amount: u128,
        price: u128,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TakerBid {
        orderHash: felt252,
        orderNonce: u128,
        taker: ContractAddress,
        maker: ContractAddress,
        strategy: felt252,
        currency: ContractAddress,
        collection: ContractAddress,
        tokenId: u256,
        amount: u128,
        price: u128,
        original_taker: ContractAddress,
        timestamp: u64,
    }

    #[external(v0)]
    impl MarketPlaceImpl of super::IMarketPlace<ContractState> {
        fn cancel_all_orders_for_sender(ref self: ContractState, min_nonce: u128) { // TODO
        }

        fn carcel_maker_order(ref self: ContractState, nonce: u128) { // TODO
        }

        fn match_ask_with_taker_bid(
            ref self: ContractState,
            taker_bid: TakerOrder,
            maker_ask: MakerOrder,
            maker_ask_signature: Span<felt252>,
            custom_non_fungible_token_recepient: ContractAddress
        ) { // TODO
        }

        fn match_bid_with_taker_ask(
            ref self: ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            maker_bid_signature: Span<felt252>,
            extra_params: Span<felt252>
        ) { // TODO
        }

        fn execute_auction_sale(
            ref self: ContractState,
            maker_ask: MakerOrder,
            maker_ask_signature: Span<felt252>,
            maker_bid: MakerOrder,
            maker_bid_signature: Span<felt252>
        ) { // TODO
        }

        fn update_hash_domain(ref self: ContractState, hash: felt252) { // TODO
        }

        fn update_protocol_fee_recepient(
            ref self: ContractState, recepient: ContractAddress
        ) { // TODO
        }

        fn update_currency_manager(ref self: ContractState, manager: ContractAddress) { // TODO
        }

        fn update_execution_manager(ref self: ContractState, manager: ContractAddress) { // TODO
        }

        fn update_royalty_fee_manager(ref self: ContractState, manager: ContractAddress) { // TODO
        }

        fn update_transfer_selector_NFT(ref self: ContractState, selector: felt252) { // TODO
        }

        fn update_signature_checker(ref self: ContractState, manager: ContractAddress) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_hash_domain(self: @ContractState) -> felt252 {
            // TODO
            0
        }

        fn get_protocol_fee_recipient(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_currency_manager(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_execution_manager(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_royalty_fee_manager(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_transfer_selector_NFT(self: @ContractState) -> felt252 {
            // TODO
            0
        }

        fn get_signature_checker(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_user_min_order_nonce(self: @ContractState) -> u128 {
            // TODO
            0
        }

        fn get_is_user_order_nonce_executed_or_cancelled(
            self: @ContractState, user: ContractAddress, nonce: u128
        ) -> bool {
            // TODO
            true
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn transfer_fees_and_funds(
            ref self: ContractState,
            strategy: felt252,
            collection: ContractAddress,
            token_id: u256,
            currency: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            amount: u128,
            minPercentageToAsk: u128,
        ) { // TODO
        }

        fn transfer_non_fungible_token(
            ref self: ContractState,
            collection: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            amount: u128
        ) { // TODO
        }

        fn calculate_protocol_fee(
            self: @ContractState, execution_strategy: felt252, amount: u128
        ) -> u128 { // TODO
        0
        }

        fn validate_order(
            self: @ContractState, order: MakerOrder, order_signature: Span<felt252>
        ) {// TODO
        }
    }
}
