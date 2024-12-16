#[starknet::component]
pub mod ERC6105Component {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePathEntry, StoragePointerWriteAccess, StoragePointerReadAccess};

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

    #[storage]
    struct Storage {}

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

    pub mod Errors {}

    #[embeddable_as(ERC6105Impl)]
    impl ERC6105<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        +ERC20Component::ERC20HooksTrait<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>,
        +ERC721Component::ERC721HooksTrait<TContractState>,
        impl ERC2981: ERC2981Component::HasComponent<TContractState>,
        +ERC2981Component::ERC2981HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IERC6105<ComponentState<TContractState>> {
        fn list_item(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress
        ) {}

        fn list_item_with_benchmark(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            expires: u64,
            supported_token: ContractAddress,
            benchmark_price: u256
        ) {}

        fn delist_item(ref self: ComponentState<TContractState>, token_id: u256) {}

        fn buy_item(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            sale_price: u256,
            supported_token: ContractAddress
        ) {}

        fn get_listing(
            self: @ComponentState<TContractState>, token_id: u256
        ) -> (u256, u64, ContractAddress, u256) {
            let address: ContractAddress = 0.try_into().unwrap();
            return (0, 0, address, 0);
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
        +ERC2981Component::ERC2981HooksTrait<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {}
}
