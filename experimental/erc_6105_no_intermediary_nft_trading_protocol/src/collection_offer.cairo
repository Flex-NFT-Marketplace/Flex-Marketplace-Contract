/// The collection offer extension is OPTIONAL for ERC-6105 smart contracts. This allows smart
/// contract to support collection offer functionality.
#[starknet::component]
pub mod ERC6105CollectionOfferComponent {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin_token::common::erc2981::ERC2981Component::InternalImpl as ERC2981Internal;
    use openzeppelin_token::common::erc2981::ERC2981Component::ERC2981Impl;
    use openzeppelin_token::common::erc2981::ERC2981Component;

    use erc_6105_no_intermediary_nft_trading_protocol::interface::IERC6105CollectionOffer;
    use erc_6105_no_intermediary_nft_trading_protocol::types::CollectionOffer;

    #[storage]
    struct Storage {
        offers: Map<ContractAddress, CollectionOffer>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        UpdateCollectionOffer: UpdateCollectionOffer,
        CollectionPurchased: CollectionPurchased
    }

    /// @notice Emitted when the collection receives an offer or an offer is canceled
    /// @dev The zero `salePrice` indicates that the collection offer of the token is canceled
    ///      The zero `expires` indicates that the collection offer of the token is canceled
    /// @param from - address of who make collection offer
    /// @param amount - the amount the offerer wants to buy at `salePrice` per token
    /// @param salePrice - the price of each token is being offered for the collection
    /// @param expires - UNIX timestamp, the offer could be accepted before expires
    /// @param supportedToken - contract addresses of supported ERC20 token
    ///                          Buyer wants to purchase items with supported token
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct UpdateCollectionOffer {
        #[key]
        pub from: ContractAddress,
        pub amount: u256,
        pub sale_price: u256,
        pub expires: u64,
        pub supported_token: ContractAddress,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct CollectionPurchased {
        #[key]
        pub token_id: u256,
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub sale_price: u256,
        pub supported_token: ContractAddress,
        pub royalties: u256
    }

    pub mod Errors {
        pub const INVALID_PRICE: felt252 = 'ERC6105: invalid sale price';
        pub const INVALID_EXPIRES: felt252 = 'ERC6105: invalid expires';
        pub const INVALID_AMOUNT: felt252 = 'ERC6105: invalid amount';
        pub const INSUFFICIENT_ALLOWANCE: felt252 = 'ERC6105: insufficient allowance';
        pub const INSUFFICIENT_BALANCE: felt252 = 'ERC6105: insufficient balance';
        pub const INVALID_TOKEN: felt252 = 'ERC6105: invalid token';
        pub const INCORRECT_VALUE: felt252 = 'ERC6105: not enough tokens';
    }

    #[embeddable_as(ERC6105CollectionOfferImpl)]
    impl ERC6105CollectionOffer<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        +ERC2981Component::ImmutableConfig,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC6105CollectionOffer<ComponentState<TContractState>> {
        fn make_collection_offer(
            ref self: ComponentState<TContractState>,
            amount: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress
        ) {
            assert(sale_price > 0, Errors::INVALID_PRICE);
            assert(amount > 0, Errors::INVALID_AMOUNT);
            assert(expires > get_block_timestamp(), Errors::INVALID_EXPIRES);

            let address_zero: ContractAddress = 0.try_into().unwrap();
            let caller: ContractAddress = get_caller_address();

            if supported_token == address_zero {
                let ETH_address: ContractAddress =
                    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                    .try_into()
                    .unwrap();
                let supported_token_dispatcher = ERC20ABIDispatcher {
                    contract_address: ETH_address
                };
                assert(
                    supported_token_dispatcher.balance_of(caller) >= sale_price,
                    Errors::INSUFFICIENT_BALANCE
                );
                assert(
                    supported_token_dispatcher
                        .allowance(caller, get_contract_address()) >= sale_price,
                    Errors::INSUFFICIENT_ALLOWANCE
                );
            } else {
                let supported_token_dispatcher = ERC20ABIDispatcher {
                    contract_address: supported_token
                };
                assert(
                    supported_token_dispatcher.balance_of(caller) >= sale_price,
                    Errors::INSUFFICIENT_BALANCE
                );
                assert(
                    supported_token_dispatcher
                        .allowance(caller, get_contract_address()) >= sale_price,
                    Errors::INSUFFICIENT_ALLOWANCE
                );
            }

            let collection_offer = CollectionOffer {
                buyer: caller, amount, sale_price, expires, supported_token
            };
            self.offers.entry(caller).write(collection_offer);

            self
                .emit(
                    UpdateCollectionOffer {
                        from: caller, amount, sale_price, expires, supported_token
                    }
                )
        }

        fn accept_collection_offer(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            supported_token: ContractAddress,
            buyer: ContractAddress
        ) {
            self
                .accept_collection_offer_with_benchmark(
                    token_id, sale_price, supported_token, buyer, 0
                );
        }

        fn accept_collection_offer_with_benchmark(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            supported_token: ContractAddress,
            buyer: ContractAddress,
            benchmark_price: u256
        ) {
            assert(self.offers.entry(buyer).read().sale_price == sale_price, Errors::INVALID_PRICE);
            assert(
                self.offers.entry(buyer).read().supported_token == supported_token,
                Errors::INVALID_TOKEN
            );

            let mut erc721_component = get_dep_component_mut!(ref self, ERC721);
            let token_owner = erc721_component.owner_of(token_id);

            let (royalty_recipient, royalties): (ContractAddress, u256) = self
                ._calculate_royalties(token_id, sale_price, benchmark_price);

            let payment: u256 = sale_price - royalties;
            let address_zero: ContractAddress = 0.try_into().unwrap();

            if supported_token == address_zero {
                let ETH_address: ContractAddress =
                    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                    .try_into()
                    .unwrap();
                let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
                assert(
                    ETH_dispatcher.balance_of(get_contract_address()) == sale_price,
                    Errors::INCORRECT_VALUE
                );
                self
                    ._process_supported_token_payment(
                        royalties, buyer, royalty_recipient, address_zero
                    );
                self._process_supported_token_payment(payment, buyer, token_owner, address_zero);
            } else {
                let token_dispatcher = ERC20ABIDispatcher { contract_address: supported_token };
                let num: u256 = token_dispatcher.allowance(buyer, get_contract_address());
                assert(num >= sale_price, Errors::INSUFFICIENT_ALLOWANCE);
                self
                    ._process_supported_token_payment(
                        royalties, buyer, royalty_recipient, supported_token
                    );
                self._process_supported_token_payment(payment, buyer, token_owner, supported_token);
            }

            erc721_component.transfer_from(token_owner, buyer, token_id);
            let prev_offer = self.offers.entry(buyer).read();
            self
                .offers
                .entry(buyer)
                .write(
                    CollectionOffer {
                        buyer,
                        sale_price,
                        supported_token,
                        expires: prev_offer.expires,
                        amount: prev_offer.amount - 1,
                    }
                );

            self
                .emit(
                    CollectionPurchased {
                        token_id,
                        from: token_owner,
                        to: buyer,
                        sale_price,
                        supported_token,
                        royalties
                    }
                );
        }

        fn cancel_collection_offer(ref self: ComponentState<TContractState>) {
            let caller: ContractAddress = get_caller_address();
            let address_zero: ContractAddress = 0.try_into().unwrap();
            self
                .offers
                .entry(caller)
                .write(
                    CollectionOffer {
                        buyer: caller,
                        amount: 0,
                        sale_price: 0,
                        expires: 0,
                        supported_token: address_zero
                    }
                );

            self
                .emit(
                    UpdateCollectionOffer {
                        from: caller,
                        amount: 0,
                        sale_price: 0,
                        expires: 0,
                        supported_token: address_zero
                    }
                )
        }

        fn get_collection_offer(
            self: @ComponentState<TContractState>, buyer: ContractAddress
        ) -> (u256, u256, u64, ContractAddress) {
            let offer = self.offers.entry(buyer).read();
            (offer.amount, offer.sale_price, offer.expires, offer.supported_token)
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        +ERC2981Component::ImmutableConfig,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn _calculate_royalties(
            self: @ComponentState<TContractState>,
            token_id: u256,
            price: u256,
            historical_price: u256
        ) -> (ContractAddress, u256) {
            let mut taxable_price: u256 = 0;
            if price > historical_price {
                taxable_price = price - historical_price;
            }

            let erc2981_component = get_dep_component!(self, ERC2981);
            let (royalty_recipient, royalties): (ContractAddress, u256) = erc2981_component
                .royalty_info(token_id, taxable_price);
            return (royalty_recipient, royalties);
        }

        fn _process_supported_token_payment(
            ref self: ComponentState<TContractState>,
            amount: u256,
            from: ContractAddress,
            recipient: ContractAddress,
            supported_token: ContractAddress
        ) {
            let address_zero: ContractAddress = 0.try_into().unwrap();
            if supported_token == address_zero {
                let ETH_address: ContractAddress =
                    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                    .try_into()
                    .unwrap();
                let ETH_dispatcher = ERC20ABIDispatcher { contract_address: ETH_address };
                let res: bool = ETH_dispatcher.transfer(recipient, amount);
                assert(res, 'Ether Transfer Fail');
            } else {
                let token_dispatcher = ERC20ABIDispatcher { contract_address: supported_token };
                let res: bool = token_dispatcher.transfer_from(from, recipient, amount);
                assert(res, 'Supported Token Transfer Fail');
            }
        }
    }
}
