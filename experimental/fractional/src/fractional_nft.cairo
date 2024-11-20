use starknet::ContractAddress;

#[starknet::interface]
pub trait IFractionalNFT<TContractState> {
    fn initialized(ref self: TContractState, nft_collection: ContractAddress, token_id: u256, amount: u256);
    fn put_for_sell(ref self: TContractState, price: u256);
    fn purchase(ref self: TContractState, amount: u256);
    fn redeem(ref self: TContractState, amount: u256);

    fn nft_collection(self: @TContractState) -> ContractAddress;
    fn token_id(self: @TContractState) -> u256;
    fn is_initialized(self: @TContractState) -> bool;
    fn for_sale(self: @TContractState) -> bool;
    fn redeemable(self: @TContractState) -> bool;
    fn sale_price(self: @TContractState) -> u256;
}

#[starknet::contract]
mod FractionalNFT {
    use starknet::ContractAddress;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};

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
    impl FractionalNFTImpl of super::IFractionalNFT<ContractState> {
        fn initialized(ref self: ContractState, nft_collection: ContractAddress, token_id: u256, amount: u256) {

        }

        fn put_for_sell(ref self: ContractState, price: u256) {

        }

        fn purchase(ref self: ContractState, amount: u256) {

        }

        fn redeem(ref self: ContractState, amount: u256) {

        }

        fn nft_collection(self: @ContractState) -> ContractAddress {

        }

        fn token_id(self: @ContractState) -> u256 {

        }

        fn is_initialized(self: @ContractState) -> bool {

        }

        fn for_sale(self: @ContractState) -> bool {

        }

        fn redeemable(self: @ContractState) -> bool {

        }

        fn sale_price(self: @ContractState) -> u256 {

        }
    }
}