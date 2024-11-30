#[starknet::contract]
mod FractionalNFT {
    use crate::interfaces::ifractional_nft::IFractionalNFT;
    use starknet::{ContractAddress, get_contract_address};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use crate::interfaces::ierc721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use crate::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[storage]
    struct Storage {
        owner: ContractAddress,
        nft_collection: ContractAddress,
        token_id: u256,
        is_initialized: bool,
        for_sale: bool,
        redeemable: bool,
        sale_price: u256,
        accepted_purchase_token: ContractAddress,
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.erc20.initializer("Flex NFT Fraction", "FNF");
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20MixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl FractionalNFTImpl of IFractionalNFT<ContractState> {
        fn initialized(ref self: ContractState, nft_collection: ContractAddress, accepted_purchase_token: ContractAddress, token_id: u256, amount: u256) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            assert(caller == self.owner.read(), 'not owner');
            assert(self.is_initialized.read() == false, 'already initialized');
            assert(amount > 0, 'zero not allowed');

            let nft = IERC721Dispatcher { contract_address: nft_collection };
            nft.transfer_from(caller, this_contract, token_id);

            self.nft_collection.write(nft_collection);
            self.accepted_purchase_token.write(accepted_purchase_token);
            self.token_id.write(token_id);
            self.is_initialized.write(true);

            self.erc20.mint(caller, amount);
        }

        fn put_for_sell(ref self: ContractState, price: u256) {
            self.sale_price.write(price);
            self.for_sale.write(true);
        }

        fn purchase(ref self: ContractState, amount: u256) {
            assert(self.for_sale.read(), 'not for sale');
            assert(amount >= self.sale_price.read(), 'not enough amount');

            let caller = get_caller_address();
            let this_contract = get_contract_address();
            let accepted_token = IERC20Dispatcher { contract_address: self.accepted_purchase_token.read() };

            assert(accepted_token.balance_of(caller) >= amount, 'insufficient funds');

            let purchase_tx = accepted_token.transfer_from(caller, this_contract, amount);
            assert(purchase_tx, 'purchase tx failed');

            IERC721Dispatcher { contract_address: self.nft_collection.read() }.transfer_from(this_contract, caller, self.token_id.read());

            self.for_sale.write(false);
            self.redeemable.write(true);
        }

        fn redeem(ref self: ContractState, amount: u256) {
            assert(self.redeemable.read(), 'not redeemable');

            let caller = get_caller_address();
            let this_contract = get_contract_address();

            let accepted_token = IERC20Dispatcher { contract_address: self.accepted_purchase_token.read() };

            let accepted_token_balance = accepted_token.balance_of(this_contract);
            let amount_to_redeem = (amount * accepted_token_balance) / self.erc20.total_supply();

            self.erc20.burn(caller, amount);

            let transfer = accepted_token.transfer(caller, amount_to_redeem);
            assert(transfer, 'redeem failed');
        }

        fn nft_collection(self: @ContractState) -> ContractAddress {
            self.nft_collection.read()
        }

        fn token_id(self: @ContractState) -> u256 {
            self.token_id.read()
        }

        fn is_initialized(self: @ContractState) -> bool {
            self.is_initialized.read()
        }

        fn for_sale(self: @ContractState) -> bool {
            self.for_sale.read()
        }

        fn redeemable(self: @ContractState) -> bool {
            self.redeemable.read()
        }

        fn sale_price(self: @ContractState) -> u256 {
            self.sale_price.read()
        }
    }
}