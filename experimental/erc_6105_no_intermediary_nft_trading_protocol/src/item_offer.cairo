/// The item offer extension is OPTIONAL for ERC-6105 smart contracts. This allows smart contract to support item offer functionality.
#[starknet::component]
pub mod ERC6105ItemOfferComponent {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        StoragePathEntry, Map
    };

    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin_token::common::erc2981::ERC2981Component::InternalImpl as ERC2981Internal;
    use openzeppelin_token::common::erc2981::ERC2981Component::ERC2981Impl;
    use openzeppelin_token::common::erc2981::ERC2981Component;

    use erc_6105_no_intermediary_nft_trading_protocol::interface::IERC6105ItemOffer;
    use erc_6105_no_intermediary_nft_trading_protocol::types::ItemOffer;
    use erc_6105_no_intermediary_nft_trading_protocol::errors::Errors;

    #[storage]
    struct Storage {
        item_offers: Map<ContractAddress, Map<u256, ItemOffer>>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        UpdateItemOffer: UpdateItemOffer,
        ItemPurchased: ItemPurchased
    }

    /// @notice Emitted when a token receives an offer or an offer is canceled
    /// @dev The zero `salePrice` indicates that the offer of the token is canceled
    ///      The zero `expires` indicates that the offer of the token is canceled
    /// @param tokenId - identifier of the token being offered
    /// @param from - address of who wants to buy the token
    /// @param salePrice - the price the token is being offered for
    /// @param expires - UNIX timestamp, the offer could be accepted before expires
    /// @param supportedToken - contract addresses of supported token
    ///                          Buyer wants to purchase item with supported token
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct UpdateItemOffer {
        #[key]
        pub token_id: u256,
        pub from: ContractAddress,
        pub sale_price: u256,
        pub expires: u64,
        pub supported_token: ContractAddress,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct ItemPurchased {
        #[key]
        pub token_id: u256,
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub sale_price: u256,
        pub supported_token: ContractAddress,
        pub royalties: u256
    }

    #[embeddable_as(ERC6105ItemOfferImpl)]
    impl ERC6105ItemOffer<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        +ERC2981Component::ImmutableConfig,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC6105ItemOffer<ComponentState<TContractState>> {
        fn make_item_offer(ref self: ComponentState<TContractState>, token_id: u256, sale_price: u256, expires: u64, supported_token: ContractAddress) {
            assert(sale_price > 0, Errors::INVALID_PRICE);
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

            let offer = ItemOffer {
                token_id,
                buyer: caller,
                sale_price,
                expires,
                supported_token
            };

            self.item_offers.entry(caller).write(token_id, offer);

            self.emit(
                UpdateItemOffer {
                    token_id,
                    sale_price,
                    from: caller,
                    expires,
                    supported_token
                }
            );
        }

        fn cancel_item_offer(ref self: ComponentState<TContractState>, token_id: u256) {
            let caller = get_caller_address();
            let zero_address: ContractAddress = 0.try_into().unwrap();
            let empty_offer = ItemOffer {
                token_id: 0,
                buyer: zero_address,
                sale_price: 0,
                expires: 0,
                supported_token: zero_address
            };
            self.item_offers.entry(caller).write(token_id, empty_offer);

            self.emit(
                UpdateItemOffer {
                    from: zero_address,
                    token_id: 0,
                    sale_price: 0,
                    expires: 0,
                    supported_token: zero_address
                }
            )
        }

        fn accept_item_offer(ref self: ComponentState<TContractState>, token_id: u256, sale_price: u256, supported_token: ContractAddress, buyer: ContractAddress) {
            self.accept_item_offer_with_benchmark(token_id, sale_price, supported_token, buyer, 0);
        }

        fn accept_item_offer_with_benchmark(ref self: ComponentState<TContractState>, token_id: u256, sale_price: u256, supported_token: ContractAddress, buyer: ContractAddress, benchmark_price: u256) {
            let caller = get_caller_address();
            assert(self.item_offers.entry(buyer).read(token_id).sale_price == sale_price, Errors::INVALID_PRICE);
            assert(
                self.item_offers.entry(buyer).read(token_id).supported_token == supported_token,
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
        
        let empty_offer = ItemOffer {
            token_id: 0,
            buyer: address_zero,
            sale_price: 0,
            expires: 0,
            supported_token: address_zero
        };
        self.item_offers.entry(buyer).write(token_id, empty_offer);
        self.emit(
            ItemPurchased {
                token_id,
                from: caller,
                to: buyer,
                sale_price,
                supported_token,
                royalties
            }
        )
        }

        fn get_item_offer(self: @ComponentState<TContractState>, token_id: u256, buyer: ContractAddress) -> (u256, u64, ContractAddress) {
            let offer = self.item_offers.entry(buyer).read(token_id);
            (offer.sale_price, offer.expires, offer.supported_token)
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