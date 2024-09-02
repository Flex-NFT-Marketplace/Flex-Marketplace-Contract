use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder, BuyerBidOrder};

#[starknet::interface]
trait IStrategySaleAnyItemAtFixedPrice<TState> {
    // fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    //  fn set_item_sale(ref self: TState, token_id: u128);
    fn set_buy_back_price_for_item(
        ref self: TState, token_id: u128, price: u128, collection_address: ContractAddress
    );
    fn can_execute_buyer_bid(self: @TState, buyer_bid: BuyerBidOrder) -> (bool, u128, u128);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[feature("deprecated_legacy_map")]
#[starknet::contract]
mod StrategySaleAnyItemAtFixedPrice {
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use starknet::class_hash::ClassHash;
    use starknet::get_block_timestamp;

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{
        {UpgradeableComponent, interface::IUpgradeable},
        upgradeable::UpgradeableComponent::InternalTrait as UpgradeableInternalTrait
    };
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use marketplace::utils::order_types::{TakerOrder, MakerOrder, BuyerBidOrder};

    #[derive(Debug, Drop, Copy, Serde, starknet::Store)]
    pub struct Bids {
        pub token_id: u128,
        pub price: u128,
        pub collection_address: ContractAddress
    }

    #[storage]
    struct Storage {
        protocol_fee: u128,
        item_for_sale: LegacyMap::<
            u128, ContractAddress
        >, // token_id: u128, seller_address:ContractAddress
        buyer_bids: LegacyMap<
            ContractAddress, Bids
        >, // LegacyMap<buyer_addesss, (token_id, price)> LegacyMap<u128, u128>
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        ItemForSaleAdded: ItemForSaleAdded,
        SetBuyBackPriceForItem: SetBuyBackPriceForItem
    }

    #[derive(Drop, starknet::Event)]
    pub struct ItemForSaleAdded {
        #[key]
        pub token_id: u128,
        pub token_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SetBuyBackPriceForItem {
        #[key]
        pub token_id: u128,
        pub buyer_address: ContractAddress,
        pub price: u128,
        pub collection_address: ContractAddress
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, fee: u128) {
        assert(!owner.is_zero(), 'Owner cannot be a zero addr');
        self.ownable.initializer(owner);
        self.protocol_fee.write(fee);
    }

    #[abi(embed_v0)]
    impl StrategySaleAnyItemAtFixedPriceImpl of super::IStrategySaleAnyItemAtFixedPrice<
        ContractState
    > {
        fn update_protocol_fee(ref self: ContractState, fee: u128) {
            self.ownable.assert_only_owner();
            self.protocol_fee.write(fee);
        }
        fn protocol_fee(self: @ContractState) -> u128 {
            self.protocol_fee.read()
        }

        fn set_buy_back_price_for_item(
            ref self: ContractState,
            token_id: u128,
            price: u128,
            collection_address: ContractAddress
        ) {
            let owner = get_caller_address();

            let existing_buyer_bids = self.buyer_bids.read(owner);

            let buyer_token_price = existing_buyer_bids.price;
            assert(buyer_token_price != price, 'Buy Back Price Set Already');

            let new_buy_back_price = Bids {
                token_id: token_id, price: price, collection_address: collection_address
            };
            self.buyer_bids.write(owner, new_buy_back_price);
            // emit an event
            self
                .emit(
                    SetBuyBackPriceForItem {
                        token_id: token_id,
                        buyer_address: owner,
                        price: price,
                        collection_address: collection_address
                    }
                );
        }

        fn can_execute_buyer_bid(
            self: @ContractState, buyer_bid: BuyerBidOrder
        ) -> (bool, u128, u128) {
            let seller_item_listed_address = self.item_for_sale.read(buyer_bid.token_id);
            let seller_address = get_caller_address();
            // check if seller has listed the token to be sold at any price
            assert(seller_address == seller_item_listed_address, 'Not avaialable for sale');

            // get the buyer token from the bid
            let buyer_bids = self.buyer_bids.read(buyer_bid.buyer_adddress);
            let buyer_token_price = buyer_bids.price;
            if (buyer_token_price < 0) {
                return (false, buyer_bid.token_id, buyer_bid.price);
            }
            return (true, buyer_bid.token_id, buyer_bid.price);
        }
        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }
    }
}
