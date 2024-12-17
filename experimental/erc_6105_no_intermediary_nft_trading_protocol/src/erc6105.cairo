#[starknet::component]
pub mod ERC6105Component {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_tx_info};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map};

    use openzeppelin_introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721Component::InternalImpl as ERC721InternalImpl;
    use openzeppelin_token::erc721::ERC721Component::ERC721Impl;
    use openzeppelin_token::erc721::ERC721Component;
    use openzeppelin_token::erc20::ERC20Component::InternalImpl as ERC20Internal;
    use openzeppelin_token::erc20::ERC20Component::ERC20Impl;
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_token::common::erc2981::ERC2981Component::InternalImpl as ERC2981Internal;
    use openzeppelin_token::common::erc2981::ERC2981Component::ERC2981Impl;
    use openzeppelin_token::common::erc2981::ERC2981Component;

    use erc_6105_no_intermediary_nft_trading_protocol::interfaces::erc6105::IERC6105;
    use erc_6105_no_intermediary_nft_trading_protocol::types::Listing;

    #[storage]
    struct Storage {
        listings: Map<u256, Listing>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        UpdateListing: UpdateListing,
        Purchased: Purchased
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct UpdateListing {
        #[key]
        pub token_id: u256,
        pub from: ContractAddress,
        pub sale_price: u256,
        pub expires: u64,
        pub supported_token: ContractAddress,
        pub benchmark_price: u256
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct Purchased {
        #[key]
        pub token_id: u256,
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub sale_price: u256,
        pub supported_token: ContractAddress,
        pub royalties: u256
    }

    pub mod Errors {
        pub const SALE_PRICE_ZERO: felt252 = 'ERC6105: price MUST NOT be 0';
        pub const INVALID_EXPIRES: felt252 = 'ERC6105: invalid expires';
        pub const NOT_OWNER_OR_APPROVED: felt252 = 'ERC6105: not owner nor approved';
        pub const INVALID_LISTING: felt252 = 'ERC6105: invalid listing';
        pub const INCONSISTENT_PRICE: felt252 = 'ERC6105: inconsistent price';
        pub const INCONSISTENT_TOKENS: felt252 = 'ERC6105: inconsistent tokens';
        pub const INCORRECT_VALUE: felt252 = 'ERC6105: incorrect value';
        pub const INSUFFICIENT_ALLOWANCE: felt252 = 'ERC6105: insufficient allowance';
    }

    #[embeddable_as(ERC6105Impl)]
    impl ERC6105<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        +ERC20Component::ERC20HooksTrait<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC6105<ComponentState<TContractState>> {
        fn list_item(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress
        ) {
            self.list_item_with_benchmark(token_id, sale_price, expires, supported_token, 0);
        }

        fn list_item_with_benchmark(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress,
            benchmark_price: u256
        ) {
            // let token_owner: ContractAddress = 
            let token_owner: ContractAddress = 0.try_into().unwrap();
            assert(sale_price > 0, Errors::SALE_PRICE_ZERO);
            assert(expires > get_block_timestamp(), Errors::INVALID_EXPIRES);
            assert(self._is_approved_or_owner(self._msg_sender(), token_id), Errors::NOT_OWNER_OR_APPROVED);

            let mut listing = Listing {
                sale_price: sale_price,
                expires: expires,
                supported_token: supported_token,
                historical_price: benchmark_price
            };

            self.listings.entry(token_id).write(listing);

            self.emit(UpdateListing {
                token_id, from: token_owner, sale_price, expires, supported_token, benchmark_price
            });
        }

        fn delist_item(ref self: ComponentState<TContractState>, token_id: u256) {
            assert(self._is_approved_or_owner(self._msg_sender(), token_id), Errors::NOT_OWNER_OR_APPROVED);
            assert(self._is_for_sale(token_id), Errors::INVALID_LISTING);

            self._remove_listing(token_id);
        }

        fn buy_item(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            supported_token: ContractAddress
        ) {
            // let token_owner: ContractAddress = 
            let token_owner: ContractAddress = 0.try_into().unwrap();
            let buyer: ContractAddress = get_caller_address();
            let historical_price: u256 = self.listings.entry(token_id).read().historical_price;

            assert(sale_price == self.listings.entry(token_id).read().sale_price, Errors::INCONSISTENT_PRICE);
            assert(supported_token == self.listings.entry(token_id).read().supported_token, Errors::INCONSISTENT_TOKENS);
            assert(self._is_for_sale(token_id), Errors::INVALID_LISTING);

            (royalty_recipient: ContractAddress, royalties: u256) = self._calculate_royalties(token_id, sale_price, historical_price);

            let payment: u256 = sale_price - royalties;
            let address_zero: ContractAddress = 0.try_into().unwrap();
            if supported_token == address_zero {
                // TODO: implement the balance function
                self._process_supported_token_payment(royalties, buyer, royalty_recipient, address_zero);
                self._process_supported_token_payment(payment, buyer, token_owner, address_zero);
            } else {
                // TODO: implement IERC20 dispatcher and check allowance
                self._process_supported_token_payment(royalties, buyer, royalty_recipient, supported_token);
                self._process_supported_token_payment(payment, buyer, token_owner, supported_token);
            }

            self._transfer(token_owner, buyer, token_id);
            self.emit(Purchased {
                token_id, from: token_owner, to: buyer, sale_price, supported_token, royalties
            });
        }

        fn get_listing(
            self: @ComponentState<TContractState>, token_id: u256
        ) -> (u256, u64, ContractAddress, u256) {
            if self.listings.entry(token_id).read().sale_price > 0 && self.listings.entry(token_id).read().expires >= get_block_timestamp() {
                let sale_price: u256 = self.listings.entry(token_id).read().sale_price;
                let expires: u64 = self.listings.entry(token_id).read().expires;
                let supported_token: ContractAddress = self.listings.entry(token_id).read().supported_token;
                let historical_price: u256 = self.listings.entry(token_id).read().historical_price;
                return (sale_price, expires, supported_token, historical_price);
            } else {
                let address_zero: ContractAddress = 0.try_into().unwrap();
                return (0, 0, address_zero, 0);
            }
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        +ERC20Component::ERC20HooksTrait<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn _remove_listing(ref self: ComponentState<TContractState>, token_id: u256) {
            let token_owner: ContractAddress = 0.try_into().unwrap();
            let address_zero: ContractAddress = 0.try_into().unwrap();
            let zero_listing = Listing {
                sale_price: 0,
                expires: 0,
                supported_token: address_zero,
                historical_price: 0
            };
            self.listings.entry(token_id).write(zero_listing);
        }

        fn _is_for_sale(self: @ComponentState<TContractState>, token_id: u256) -> bool {
            if self.listings.entry(token_id).read().sale_price > 0 && self.listings.entry(token_id).read().expires >= get_block_timestamp() {
                return true;
            } else {
                return false;
            }
        }

        fn _calculate_royalties(self: @ComponentState<TContractState>, token_id: u256, price: u256, historical_price: u256) -> (ContractAddress, u256) {
            let mut taxable_price: u256 = 0;
            if price > historical_price {
                taxable_price = price - historical_price;
            }

            (royalty_recipient: ContractAddress, royalties: u256) = royalty_info(token_id, taxable_price);
            return (royalty_recipient, royalties);
        }

        fn _process_supported_token_payment(ref self: ComponentState<TContractState>, amount: u256, from: ContractAddress, recipient: ContractAddress, supported_token: ContractAddress) {
            let address_zero: ContractAddress = 0.try_into().unwrap();
            if supported_token == address_zero {
                // TODO: ???
            } else {
                // TODO: setup ierc20 dispatcher and transfer tokens
            }
        }

        fn _before_token_transfer(ref self: ComponentState<TContractState>, from: ContractAddress, to: ContractAddress, token_id: u256, batch_size: u256) {
            
        }
    }
}
