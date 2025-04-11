use starknet::ContractAddress;

#[starknet::interface]
trait NftTrait<TState> {
    fn mint(ref self: TState, recipient: ContractAddress);
}

#[starknet::contract]
mod Nft {
    use starknet::{ContractAddress, get_block_timestamp};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use base64_nft::nft::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::pedersen::PedersenTrait;
    use super::NftTrait;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: Erc721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        seed: u128,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        Erc721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, recipient: ContractAddress, render: ContractAddress) {
        let name = "MyNFT";
        let symbol = "NFT";

        let mut token_id_felt = PedersenTrait::new(0);
        token_id_felt = token_id_felt.update_with(0);
        token_id_felt = token_id_felt.update_with(get_block_timestamp());
        token_id_felt = token_id_felt.update_with(recipient);
        let token_id: u256 = token_id_felt.finalize().into();
        self.erc721.initializer(name, symbol, render);
        self.erc721.mint(recipient, token_id);
        self.seed.write(1);
    }

    #[abi(embed_v0)]
    impl NftImpl of NftTrait<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress) {
            let seed = self.seed.read();
            let mut token_id_felt = PedersenTrait::new(0);
            token_id_felt = token_id_felt.update_with(seed);
            token_id_felt = token_id_felt.update_with(get_block_timestamp());
            token_id_felt = token_id_felt.update_with(recipient);
            let token_id: u256 = token_id_felt.finalize().into();
            self.erc721.mint(recipient, token_id);

            self.seed.write(seed + 1);
        }
    }
}
