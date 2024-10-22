use starknet::ContractAddress;

const IFLEX_HAUS_COLLECTIBLE_ID: felt252 =
    0xd553e6f52882a90db884cfd1e898d0588b71db449f0f360404b6bb22e641c4;

#[starknet::interface]
trait IFlexHausCollectible<TContractState> {
    fn get_base_uri(self: @TContractState) -> ByteArray;
    fn total_supply(self: @TContractState) -> u256;
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
    fn set_total_supply(ref self: TContractState, total_supply: u256);
    fn set_name(ref self: TContractState, name: ByteArray);
    fn set_symbol(ref self: TContractState, symbol: ByteArray);
    fn add_factory(ref self: TContractState, factory: ContractAddress);
    fn remove_factory(ref self: TContractState, factory: ContractAddress);
    fn mint_collectible(ref self: TContractState, minter: ContractAddress);
}

#[starknet::interface]
trait IFlexHausCollectibleCamelOnly<TContractState> {
    fn getBaseUri(self: @TContractState) -> ByteArray;
    fn totalSupply(self: @TContractState) -> u256;
    fn setBaseUri(ref self: TContractState, baseUri: ByteArray);
    fn setTotalSupply(ref self: TContractState, totalSupply: u256);
    fn setName(ref self: TContractState, name: ByteArray);
    fn setSymbol(ref self: TContractState, symbol: ByteArray);
    fn addFactory(ref self: TContractState, factory: ContractAddress);
    fn removeFactory(ref self: TContractState, factory: ContractAddress);
    fn mintCollectible(ref self: TContractState, minter: ContractAddress);
}

#[starknet::interface]
trait IFlexHausCollectibleMixin<TContractState> {
    fn get_base_uri(self: @TContractState) -> ByteArray;
    fn total_supply(self: @TContractState) -> u256;
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
    fn set_total_supply(ref self: TContractState, total_supply: u256);
    fn set_name(ref self: TContractState, name: ByteArray);
    fn set_symbol(ref self: TContractState, symbol: ByteArray);
    fn mint_collectible(ref self: TContractState, minter: ContractAddress);
    fn add_factory(ref self: TContractState, factory: ContractAddress);
    fn remove_factory(ref self: TContractState, factory: ContractAddress);
    fn getBaseUri(self: @TContractState) -> ByteArray;
    fn totalSupply(self: @TContractState) -> u256;
    fn setBaseUri(ref self: TContractState, baseUri: ByteArray);
    fn setTotalSupply(ref self: TContractState, totalSupply: u256);
    fn setName(ref self: TContractState, name: ByteArray);
    fn setSymbol(ref self: TContractState, symbol: ByteArray);
    fn addFactory(ref self: TContractState, factory: ContractAddress);
    fn removeFactory(ref self: TContractState, factory: ContractAddress);
    fn mintCollectible(ref self: TContractState, minter: ContractAddress);
}
