#[starknet::interface]
pub trait IERC4907<TContractState> {
    fn renewSubscription(ref self: TContractState, token_id: u256, duration: u64);
    fn cancelSubscription(ref self: ContractState, token_id: u256);
    fn expiresAt(self: @ContractState, token_id: u256) -> u64;
    fn isRenewable(self: @ContractState, token_id: u256) -> bool;
}

#[starknet::contract]
mod erc721 {
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;

    use starknet::ContractAddress;
    use core::option::OptionTrait;
    use core::traits::Into;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use super::Expirations;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);


    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // ERC721 Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        expirations: LegacyMap<u256, u64>,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        base_uri: felt252,
        token_id: u256,
        recipient: ContractAddress
    ) {
        let owner = get_caller_address();

        self.erc721.initializer(name, symbol, base_uri);
        self.erc721.mint(recipient, token_id);
        self.ownable.initializer(owner);
    }
    #[abi(embed_v0)]
    impl IERC4907 of super::IERC4907<ContractState> {
        fn renewSubscription(ref self: ContractState, token_id: u256, duration: u64) {
            self.ownable.assert_only_owner();
            let current_expiration = self._expirations.read(token_id);
            let new_expiration = if current_expiration == 0 {
                get_block_timestamp().try_into().unwrap() + duration
            } else {
                current_expiration + duration
            };

            self._expirations.write(token_id, new_expiration);
        }
        fn cancelSubscription(ref self: ContractState, token_id: u256) {
            self.ownable.assert_only_owner();
            self._expirations.write(token_id, 0);
        }
        fn expiresAt(self: @ContractState, token_id: u256) -> u64 {
            self._expirations.read(token_id)
        }
        fn isRenewable(self: @ContractState, token_id: u256) -> bool {
            true
        }
    }
}
