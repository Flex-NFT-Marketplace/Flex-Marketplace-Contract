use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress);
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}


#[starknet::contract]
mod ERC721 {
    use openzeppelin::token::erc721::interface::IERC721;
    use openzeppelin::token::erc721::erc721::ERC721Component::InternalTrait;
    use starknet::ContractAddress;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

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
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // src5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name: ByteArray = "FLEX TOKEN";
        let symbol: ByteArray = "FLX";
        let base_uri: ByteArray = "";
        self.erc721.initializer(name, symbol, base_uri);
    }

    #[abi(embed_v0)]
    impl ERC721 of super::IERC721<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress) {
            self._mint_with_uri(recipient);
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721._approve(to, token_id);
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _mint_with_uri(ref self: ContractState, recipient: ContractAddress) {
            let token_id = self.id.read() + 1;
            self.id.write(token_id);

            self.erc721._mint(recipient, token_id);
        }
    }
}
