#[starknet::contract]
mod Starkamigos {
    use openzeppelin::introspection::interface::ISRC5;
    use openzeppelin::introspection::src5::{SRC5Component};
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        currentId: u256,
        totalSupply: u256,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        baseUri: ByteArray,
        totalSupply: u256
    ) {
        self.erc721.initializer(name, symbol, baseUri);
        self.currentId.write(0);
        self.totalSupply.write(totalSupply)
    }

    #[abi(per_item)]
    #[generate_trait]
    impl Starkamigos of StarkamigosTrait {
        #[external(v0)]
        fn mint(ref self: ContractState, amount: u256) {
            let currentId = self.getCurrentId();
            assert(currentId + amount <= self.getTotalSupply(), 'Reach maximum total supply.');
            let receiver = get_caller_address();

            let mut index = 0;
            loop {
                if index == amount {
                    break;
                }
                let tokenId = currentId + index + 1;
                self.erc721._mint(receiver, tokenId);

                index += 1;
            };

            self.currentId.write(currentId + amount);
        }

        #[external(v0)]
        fn getCurrentId(self: @ContractState) -> u256 {
            self.currentId.read()
        }

        #[external(v0)]
        fn getTotalSupply(self: @ContractState) -> u256 {
            self.totalSupply.read()
        }

        #[external(v0)]
        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            self.src5.supports_interface(interfaceId)
        }
    }
}
