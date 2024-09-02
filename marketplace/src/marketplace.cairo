use starknet::{ContractAddress, ClassHash};

use marketplace::utils::order_types::{MakerOrder, TakerOrder};

#[starknet::interface]
trait IMarketPlace<TState> {
    fn initializer(
        ref self: TState,
        hash: felt252,
        recepient: ContractAddress,
        currency: ContractAddress,
        execution: ContractAddress,
        fee_manager: ContractAddress,
        checker: ContractAddress,
        owner: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn upgrade(ref self: TState, new_class_hash: ClassHash);
    fn cancel_all_orders_for_sender(ref self: TState, min_nonce: u128);
    fn cancel_maker_order(ref self: TState, order_nonce: u128);
    fn match_ask_with_taker_bid(
        ref self: TState,
        taker_bid: TakerOrder,
        maker_ask: MakerOrder,
        maker_ask_signature: Array<felt252>,
        custom_non_fungible_token_recepient: ContractAddress
    );
    fn match_bid_with_taker_ask(
        ref self: TState,
        taker_ask: TakerOrder,
        maker_bid: MakerOrder,
        maker_bid_signature: Array<felt252>,
        extra_params: Array<felt252>
    );
    fn execute_auction_sale(
        ref self: TState,
        maker_ask: MakerOrder,
        maker_ask_signature: Array<felt252>,
        maker_bid: MakerOrder,
        maker_bid_signature: Array<felt252>
    );
    fn update_hash_domain(ref self: TState, hash: felt252);
    fn update_protocol_fee_recepient(ref self: TState, recipient: ContractAddress);
    fn update_currency_manager(ref self: TState, manager: ContractAddress);
    fn update_execution_manager(ref self: TState, manager: ContractAddress);
    fn update_royalty_fee_manager(ref self: TState, manager: ContractAddress);
    fn update_transfer_selector_NFT(ref self: TState, selector: ContractAddress);
    fn update_signature_checker(ref self: TState, checker: ContractAddress);
    fn whitelist_collection_for_zero_fees(
        ref self: TState, collection: ContractAddress, is_whitelisted: bool
    );
    fn whitelist_address_for_zero_fees(
        ref self: TState, address: ContractAddress, is_whitelisted: bool
    );
    fn get_hash_domain(self: @TState) -> felt252;
    fn get_protocol_fee_recipient(self: @TState) -> ContractAddress;
    fn get_currency_manager(self: @TState) -> ContractAddress;
    fn get_execution_manager(self: @TState) -> ContractAddress;
    fn get_royalty_fee_manager(self: @TState) -> ContractAddress;
    fn get_transfer_selector_NFT(self: @TState) -> ContractAddress;
    fn get_signature_checker(self: @TState) -> ContractAddress;
    fn get_user_min_order_nonce(self: @TState, user: ContractAddress) -> u128;
    fn get_is_user_order_nonce_executed_or_cancelled(
        self: @TState, user: ContractAddress, nonce: u128
    ) -> bool;
    fn is_address_whitelisted_for_zero_fees(self: @TState, address: ContractAddress) -> bool;
    fn is_collection_whitelisted_for_zero_fees(self: @TState, collection: ContractAddress) -> bool;
}

#[starknet::interface]
trait IExecutionStrategy<TState> {
    fn protocolFee(self: @TState) -> u128;
    fn canExecuteTakerAsk(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Array<felt252>
    ) -> (bool, u256, u128);
    fn canExecuteTakerBid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::interface]
trait IAuctionStrategy<TState> {
    fn auctionRelayer(self: @TState) -> ContractAddress;
    fn canExecuteAuctionSale(
        self: @TState, maker_ask: MakerOrder, maker_bid: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::contract]
mod MarketPlace {
    use super::{
        IExecutionStrategyDispatcher, IExecutionStrategyDispatcherTrait, IAuctionStrategyDispatcher,
        IAuctionStrategyDispatcherTrait, ContractAddress, ClassHash
    };
    use starknet::{contract_address_const, get_block_timestamp, get_caller_address};

    use marketplace::{DisplayContractAddress};
    use marketplace::{
        currency_manager::{ICurrencyManagerDispatcher, ICurrencyManagerDispatcherTrait},
        execution_manager::{IExecutionManagerDispatcher, IExecutionManagerDispatcherTrait},
        royalty_fee_manager::{IRoyaltyFeeManagerDispatcher, IRoyaltyFeeManagerDispatcherTrait},
        signature_checker2::{ISignatureChecker2Dispatcher, ISignatureChecker2DispatcherTrait},
        transfer_selector_NFT::{
            ITransferSelectorNFTDispatcher, ITransferSelectorNFTDispatcherTrait
        },
        interfaces::nft_transfer_manager::{
            ITransferManagerNFTDispatcher, ITransferManagerNFTDispatcherTrait
        }
    };
    use marketplace::utils::order_types::{MakerOrder, TakerOrder};

    use array::{Array, ArrayTrait};
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;


    use snforge_std::PrintTrait;
    #[storage]
    struct Storage {
        hash_domain: felt252,
        protocol_fee_recipient: ContractAddress,
        currency_manager: ICurrencyManagerDispatcher,
        execution_manager: IExecutionManagerDispatcher,
        royalty_fee_manager: IRoyaltyFeeManagerDispatcher,
        transfer_selector_NFT: ITransferSelectorNFTDispatcher,
        signature_checker: ISignatureChecker2Dispatcher,
        user_min_order_nonce: LegacyMap::<ContractAddress, u128>,
        is_user_order_nonce_executed_or_cancelled: LegacyMap::<(ContractAddress, u128), bool>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
        // Mapping for whitelisted NFT collections
        whitelisted_collections_for_zero_fees: LegacyMap::<ContractAddress, bool>,
        // Mapping for whitelisted addresses
        whitelisted_addresses_for_zero_fees: LegacyMap::<ContractAddress, bool>,
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
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        CollectionWhitelistedForZeroFees: CollectionWhitelistedForZeroFees,
        AddressWhitelistedForZeroFees: AddressWhitelistedForZeroFees,
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
        order_nonce: u128,
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
        selector: ContractAddress,
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
        token_id: u256,
        royalty_recipient: ContractAddress,
        currency: ContractAddress,
        amount: u128,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TakerAsk {
        order_hash: felt252,
        order_nonce: u128,
        taker: ContractAddress,
        maker: ContractAddress,
        strategy: ContractAddress,
        currency: ContractAddress,
        collection: ContractAddress,
        token_id: u256,
        amount: u128,
        price: u128,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TakerBid {
        order_hash: felt252,
        order_nonce: u128,
        taker: ContractAddress,
        maker: ContractAddress,
        strategy: ContractAddress,
        currency: ContractAddress,
        collection: ContractAddress,
        token_id: u256,
        amount: u128,
        price: u128,
        original_taker: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct CollectionWhitelistedForZeroFees {
        #[key]
        collection: ContractAddress,
        is_whitelisted: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct AddressWhitelistedForZeroFees {
        #[key]
        address: ContractAddress,
        is_whitelisted: bool,
    }


    #[abi(embed_v0)]
    impl MarketPlaceImpl of super::IMarketPlace<ContractState> {
        fn initializer(
            ref self: ContractState,
            hash: felt252,
            recepient: ContractAddress,
            currency: ContractAddress,
            execution: ContractAddress,
            fee_manager: ContractAddress,
            checker: ContractAddress,
            owner: ContractAddress,
            proxy_admin: ContractAddress
        ) {
            self.ownable.initializer(owner);
            self.hash_domain.write(hash);
            self.protocol_fee_recipient.write(recepient);
            self.currency_manager.write(ICurrencyManagerDispatcher { contract_address: currency });
            self
                .execution_manager
                .write(IExecutionManagerDispatcher { contract_address: execution });
            self
                .royalty_fee_manager
                .write(IRoyaltyFeeManagerDispatcher { contract_address: fee_manager });
            self
                .signature_checker
                .write(ISignatureChecker2Dispatcher { contract_address: checker });
        }

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }

        fn cancel_all_orders_for_sender(ref self: ContractState, min_nonce: u128) {
            let caller = get_caller_address();
            let current_min_nonce = self.user_min_order_nonce.read(caller);
            assert!(
                current_min_nonce < min_nonce,
                "MarketPlace: current min nonce {} is not < than {}",
                current_min_nonce,
                min_nonce
            );
            self.user_min_order_nonce.write(caller, min_nonce);
            self
                .emit(
                    CancelAllOrders {
                        user: caller, new_min_nonce: min_nonce, timestamp: get_block_timestamp()
                    }
                );
        }

        fn cancel_maker_order(ref self: ContractState, order_nonce: u128) {
            let caller = get_caller_address();
            let current_min_nonce = self.user_min_order_nonce.read(caller);
            assert!(
                current_min_nonce < order_nonce,
                "MarketPlace: current min nonce {} is not < than {}",
                current_min_nonce,
                order_nonce
            );
            self.is_user_order_nonce_executed_or_cancelled.write((caller, order_nonce), true);
            self.emit(CancelOrder { user: caller, order_nonce, timestamp: get_block_timestamp() });
        }

        fn match_ask_with_taker_bid(
            ref self: ContractState,
            taker_bid: TakerOrder,
            maker_ask: MakerOrder,
            maker_ask_signature: Array<felt252>,
            custom_non_fungible_token_recepient: ContractAddress
        ) {
            self.reentrancyguard.start();
            let caller = get_caller_address();
            assert!(!caller.is_zero(), "MarketPlace: invalid caller address {:?}", caller);
            assert!(maker_ask.is_order_ask, "MarketPlace: maker ask is not an ask order");
            assert!(!taker_bid.is_order_ask, "MarketPlace: taker bid is an ask order");
            self.validate_order(@maker_ask, maker_ask_signature);
            let (can_execute, token_id, amount) = IExecutionStrategyDispatcher {
                contract_address: maker_ask.strategy
            }
                .canExecuteTakerBid(taker_bid, maker_ask);

            assert!(can_execute, "Marketplace: order cannot be executed");

            self
                .is_user_order_nonce_executed_or_cancelled
                .write((maker_ask.signer, maker_ask.salt_nonce), true);

            self
                .transfer_fees_and_funds(
                    maker_ask.strategy,
                    maker_ask.collection,
                    token_id,
                    maker_ask.currency,
                    taker_bid.taker,
                    maker_ask.signer,
                    taker_bid.price,
                    maker_ask.min_percentage_to_ask
                );
            let mut non_fungible_token_recipient = contract_address_const::<0>();
            if custom_non_fungible_token_recepient.is_zero() {
                non_fungible_token_recipient = taker_bid.taker;
            } else {
                non_fungible_token_recipient = custom_non_fungible_token_recepient;
            };
            self
                .transfer_non_fungible_token(
                    maker_ask.collection,
                    maker_ask.signer,
                    non_fungible_token_recipient,
                    token_id,
                    amount
                );
            let order_hash = self
                .signature_checker
                .read()
                .compute_maker_order_hash(self.hash_domain.read(), maker_ask);

            self
                .emit(
                    TakerBid {
                        order_hash,
                        order_nonce: maker_ask.salt_nonce,
                        taker: non_fungible_token_recipient,
                        maker: maker_ask.signer,
                        strategy: maker_ask.strategy,
                        currency: maker_ask.currency,
                        collection: maker_ask.collection,
                        token_id,
                        amount,
                        price: taker_bid.price,
                        original_taker: taker_bid.taker,
                        timestamp: get_block_timestamp()
                    }
                );

            self.reentrancyguard.end();
        }

        fn match_bid_with_taker_ask(
            ref self: ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            maker_bid_signature: Array<felt252>,
            extra_params: Array<felt252>
        ) {
            self.reentrancyguard.start();

            let caller = get_caller_address();
            assert!(!caller.is_zero(), "MarketPlace: invalid caller address {}", caller);
            assert!(!maker_bid.is_order_ask, "MarketPlace: maker bid is an ask order");
            assert!(taker_ask.is_order_ask, "MarketPlace: taker ask is not an ask order");
            assert!(
                caller == taker_ask.taker,
                "MarketPlace: caller {} is not taker {}",
                caller,
                taker_ask.taker
            );

            self.validate_order(@maker_bid, maker_bid_signature);

            let (can_execute, token_id, amount) = IExecutionStrategyDispatcher {
                contract_address: maker_bid.strategy
            }
                .canExecuteTakerAsk(taker_ask, maker_bid, extra_params);

            assert!(can_execute, "Marketplace: taker ask cannot be executed");

            self
                .is_user_order_nonce_executed_or_cancelled
                .write((maker_bid.signer, maker_bid.salt_nonce), true);
            self
                .transfer_non_fungible_token(
                    maker_bid.collection, taker_ask.taker, maker_bid.signer, token_id, amount
                );
            self
                .transfer_fees_and_funds(
                    maker_bid.strategy,
                    maker_bid.collection,
                    token_id,
                    maker_bid.currency,
                    maker_bid.signer,
                    taker_ask.taker,
                    taker_ask.price,
                    taker_ask.min_percentage_to_ask
                );
            let order_hash = self
                .signature_checker
                .read()
                .compute_maker_order_hash(self.hash_domain.read(), maker_bid);

            self
                .emit(
                    TakerAsk {
                        order_hash,
                        order_nonce: maker_bid.salt_nonce,
                        taker: taker_ask.taker,
                        maker: maker_bid.signer,
                        strategy: maker_bid.strategy,
                        currency: maker_bid.currency,
                        collection: maker_bid.collection,
                        token_id,
                        amount,
                        price: taker_ask.price,
                        timestamp: get_block_timestamp()
                    }
                );

            self.reentrancyguard.end();
        }

        fn execute_auction_sale(
            ref self: ContractState,
            maker_ask: MakerOrder,
            maker_ask_signature: Array<felt252>,
            maker_bid: MakerOrder,
            maker_bid_signature: Array<felt252>
        ) {
            self.reentrancyguard.start();

            let caller = get_caller_address();
            assert!(!caller.is_zero(), "MarketPlace: invalid caller address {}", caller);
            assert!(maker_ask.is_order_ask, "MarketPlace: maker ask is not an ask order");
            assert!(!maker_bid.is_order_ask, "MarketPlace: maker bid is an ask order");

            let auction_strategy = super::IAuctionStrategyDispatcher {
                contract_address: maker_ask.strategy
            };
            let relayer = auction_strategy.auctionRelayer();
            assert!(caller == relayer, "MarketPlace: caller is not relayer");

            self.validate_order(@maker_ask, maker_ask_signature);
            self.validate_order(@maker_bid, maker_bid_signature);

            let (can_execute, token_id, amount) = auction_strategy
                .canExecuteAuctionSale(maker_ask, maker_bid);
            assert!(can_execute, "MakerOrder: auction strategy can not be executed");

            self
                .is_user_order_nonce_executed_or_cancelled
                .write((maker_ask.signer, maker_ask.salt_nonce), true);
            self
                .is_user_order_nonce_executed_or_cancelled
                .write((maker_bid.signer, maker_bid.salt_nonce), true);

            self
                .transfer_fees_and_funds(
                    maker_ask.strategy,
                    maker_ask.collection,
                    token_id,
                    maker_ask.currency,
                    maker_bid.signer,
                    maker_ask.signer,
                    maker_bid.price,
                    maker_ask.min_percentage_to_ask
                );
            self
                .transfer_non_fungible_token(
                    maker_ask.collection, maker_ask.signer, maker_bid.signer, token_id, amount
                );

            let order_hash = self
                .signature_checker
                .read()
                .compute_maker_order_hash(self.hash_domain.read(), maker_ask);

            self
                .emit(
                    TakerBid {
                        order_hash,
                        order_nonce: maker_ask.salt_nonce,
                        taker: maker_bid.signer,
                        maker: maker_ask.signer,
                        strategy: maker_ask.strategy,
                        currency: maker_ask.currency,
                        collection: maker_ask.collection,
                        token_id,
                        amount,
                        price: maker_bid.price,
                        original_taker: maker_bid.signer,
                        timestamp: get_block_timestamp()
                    }
                );

            self.reentrancyguard.end();
        }

        fn update_hash_domain(ref self: ContractState, hash: felt252) {
            self.ownable.assert_only_owner();
            self.hash_domain.write(hash);
            self.emit(NewHashDomain { hash, timestamp: get_block_timestamp() });
        }

        fn update_protocol_fee_recepient(ref self: ContractState, recipient: ContractAddress) {
            self.ownable.assert_only_owner();
            self.protocol_fee_recipient.write(recipient);
            self.emit(NewProtocolFeeRecipient { recipient, timestamp: get_block_timestamp() });
        }

        fn update_currency_manager(ref self: ContractState, manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self.currency_manager.write(ICurrencyManagerDispatcher { contract_address: manager });
            self.emit(NewCurrencyManager { manager, timestamp: get_block_timestamp() });
        }

        fn update_execution_manager(ref self: ContractState, manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self.execution_manager.write(IExecutionManagerDispatcher { contract_address: manager });
            self.emit(NewExecutionManager { manager, timestamp: get_block_timestamp() });
        }

        fn update_royalty_fee_manager(ref self: ContractState, manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self
                .royalty_fee_manager
                .write(IRoyaltyFeeManagerDispatcher { contract_address: manager });
            self.emit(NewRoyaltyFeeManager { manager, timestamp: get_block_timestamp() });
        }

        fn update_transfer_selector_NFT(ref self: ContractState, selector: ContractAddress) {
            self.ownable.assert_only_owner();
            self
                .transfer_selector_NFT
                .write(ITransferSelectorNFTDispatcher { contract_address: selector });
            self.emit(NewTransferSelectorNFT { selector, timestamp: get_block_timestamp() });
        }

        fn update_signature_checker(ref self: ContractState, checker: ContractAddress) {
            self.ownable.assert_only_owner();
            self
                .signature_checker
                .write(ISignatureChecker2Dispatcher { contract_address: checker });
            self.emit(NewSignatureChecker { checker, timestamp: get_block_timestamp() });
        }

        fn get_hash_domain(self: @ContractState) -> felt252 {
            self.hash_domain.read()
        }

        fn get_protocol_fee_recipient(self: @ContractState) -> ContractAddress {
            self.protocol_fee_recipient.read()
        }

        fn get_currency_manager(self: @ContractState) -> ContractAddress {
            self.currency_manager.read().contract_address
        }

        fn get_execution_manager(self: @ContractState) -> ContractAddress {
            self.execution_manager.read().contract_address
        }

        fn get_royalty_fee_manager(self: @ContractState) -> ContractAddress {
            self.royalty_fee_manager.read().contract_address
        }

        fn get_transfer_selector_NFT(self: @ContractState) -> ContractAddress {
            self.transfer_selector_NFT.read().contract_address
        }

        fn get_signature_checker(self: @ContractState) -> ContractAddress {
            self.signature_checker.read().contract_address
        }

        fn get_user_min_order_nonce(self: @ContractState, user: ContractAddress) -> u128 {
            self.user_min_order_nonce.read(user)
        }

        fn get_is_user_order_nonce_executed_or_cancelled(
            self: @ContractState, user: ContractAddress, nonce: u128
        ) -> bool {
            self.is_user_order_nonce_executed_or_cancelled.read((user, nonce))
        }

        //util to whitelist collection
        fn whitelist_collection_for_zero_fees(
            ref self: ContractState, collection: ContractAddress, is_whitelisted: bool
        ) {
            self.ownable.assert_only_owner();
            self.whitelisted_collections_for_zero_fees.write(collection, is_whitelisted);
            self.emit(CollectionWhitelistedForZeroFees { collection, is_whitelisted });
        }

        //util to whitelist address
        fn whitelist_address_for_zero_fees(
            ref self: ContractState, address: ContractAddress, is_whitelisted: bool
        ) {
            self.ownable.assert_only_owner();
            self.whitelisted_addresses_for_zero_fees.write(address, is_whitelisted);
            self.emit(AddressWhitelistedForZeroFees { address, is_whitelisted });
        }

        //util to check whitelisted collection
        fn is_collection_whitelisted_for_zero_fees(
            self: @ContractState, collection: ContractAddress
        ) -> bool {
            self.whitelisted_collections_for_zero_fees.read(collection)
        }

        //util to check whitelisted address
        fn is_address_whitelisted_for_zero_fees(
            self: @ContractState, address: ContractAddress
        ) -> bool {
            self.whitelisted_addresses_for_zero_fees.read(address)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn transfer_fees_and_funds(
            ref self: ContractState,
            strategy: ContractAddress,
            collection: ContractAddress,
            token_id: u256,
            currency: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            amount: u128,
            minPercentageToAsk: u128,
        ) {
            assert!(!amount.is_zero(), "MarketPlace: amount is zero");

            let protocol_fee_amount = self
                .calculate_protocol_fee(strategy, amount, collection, from);
            let recipient = self.get_protocol_fee_recipient();
            let currency_erc20 = IERC20CamelDispatcher { contract_address: currency };
            if !protocol_fee_amount.is_zero() && !recipient.is_zero() {
                currency_erc20.transferFrom(from, recipient, protocol_fee_amount.into());
            }
            let (recipient, royalty_amount) = self
                .royalty_fee_manager
                .read()
                .calculate_royalty_fee_and_get_recipient(collection, token_id, amount);
            if !royalty_amount.is_zero() && !recipient.is_zero() {
                currency_erc20.transferFrom(from, recipient, royalty_amount.into());
                self
                    .emit(
                        RoyaltyPayment {
                            collection,
                            token_id,
                            royalty_recipient: recipient,
                            currency,
                            amount: royalty_amount,
                            timestamp: get_block_timestamp()
                        }
                    );
            }

            currency_erc20
                .transferFrom(from, to, (amount - protocol_fee_amount - royalty_amount).into());
        }

        fn transfer_non_fungible_token(
            ref self: ContractState,
            collection: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            amount: u128
        ) {
            assert!(!amount.is_zero(), "MarketPlace: invalid amount {}", amount);

            let manager = self
                .transfer_selector_NFT
                .read()
                .check_transfer_manager_for_token(collection);
            assert!(!manager.is_zero(), "MarketPlace: invalid tranfer manager {}", manager);
            ITransferManagerNFTDispatcher { contract_address: manager }
                .transfer_non_fungible_token(
                    collection, from, to, token_id, amount, ArrayTrait::<felt252>::new().span()
                );
        }

        fn calculate_protocol_fee(
            self: @ContractState,
            execution_strategy: ContractAddress,
            amount: u128,
            collection: ContractAddress,
            user: ContractAddress
        ) -> u128 {
            // Check if the collection or address is whitelisted
            if self.whitelisted_collections_for_zero_fees.read(collection)
                || self.whitelisted_addresses_for_zero_fees.read(user) {
                return 0;
            }

            let fee = IExecutionStrategyDispatcher { contract_address: execution_strategy }
                .protocolFee();
            amount * fee / 10_000
        }

        fn validate_order(
            self: @ContractState, order: @MakerOrder, order_signature: Array<felt252>
        ) {
            let executed_order_cancelled = self
                .get_is_user_order_nonce_executed_or_cancelled(*order.signer, *order.salt_nonce);
            let min_nonce = self.get_user_min_order_nonce(*order.signer);
            assert!(!executed_order_cancelled, "MarketPlace: executed order is cancelled");
            assert!(
                min_nonce <= *order.salt_nonce,
                "MarketPlace: min_nonce {} is higher than order nonce {}",
                min_nonce,
                *order.salt_nonce
            );
            assert!(
                !(*order.signer).is_zero(), "MarketPlace: invalid order signer {}", *order.signer
            );
            assert!(
                !(*order.amount).is_zero(), "MarketPlace: invalid order amount {}", *order.amount
            );
            self
                .signature_checker
                .read()
                .verify_maker_order_signature(self.get_hash_domain(), *order, order_signature);
            let currency_whitelisted = self
                .currency_manager
                .read()
                .is_currency_whitelisted(*order.currency);
            assert!(
                currency_whitelisted, "MarketPlace: currency {} is not whitelisted", *order.currency
            );
            let strategy_whitelisted = self
                .execution_manager
                .read()
                .is_strategy_whitelisted(*order.strategy);
            assert!(
                strategy_whitelisted,
                "MarketPlace: strategy {} is not whitelisted",
                (*order.strategy)
            );
        }
    }
}
