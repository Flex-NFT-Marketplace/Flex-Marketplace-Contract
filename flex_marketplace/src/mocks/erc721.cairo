use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress);
}


#[starknet::contract]
mod ERC721 {
    use starknet::ContractAddress;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    const NAME: felt252 = 'FLEX TOKEN';
    const SYMBOL: felt252 = 'FLX';
    const TOKEN_URI: felt252 = '';

    #[storage]
    struct Storage {
        id: u256,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event
    }

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // src5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc721.initializer(NAME, SYMBOL);
    }

    #[abi(embed_v0)]
    impl ERC721 of super::IERC721<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress) {
            self._mint_with_uri(recipient);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _mint_with_uri(ref self: ContractState, recipient: ContractAddress) {
            let token_id = self.id.read() + 1;
            self.id.write(token_id);

            self.erc721._set_token_uri(token_id, TOKEN_URI);
            self.erc721._mint(recipient, token_id);
        }
    }
}