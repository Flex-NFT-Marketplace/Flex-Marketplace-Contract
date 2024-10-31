#[starknet::contract]
mod ERC5173FutureRewards {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry
    };
    use erc_5173_future_rewards::interfaces::{IERC5173FutureRewards};
    use erc_5173_future_rewards::structs::{
        FRInfo, ListInfo, AllottedRewards, RewardsClaimed, Listed, Unlisted, Bought
    };
    use erc_5173_future_rewards::errors;
    use alexandria_storage::list::List;
    use core::array::ArrayTrait;
    use alexandria_storage::list::ListTrait;
    use erc_5173_future_rewards::erc721::ERC721::ERC721Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721CamelImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721MetadataCamelImpl = ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;

    #[abi(embed_v0)]
    impl FlexDropContractMetadataImpl =
        ERC721Component::FlexDropContractMetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        default_fr_info: FRInfo,
        token_fr_info: Map::<u256, FRInfo>,
        addresses_in_fr: Map::<u256, List<ContractAddress>>,
        allotted_fr: Map::<ContractAddress, AllottedRewards>,
        token_list_info: Map::<u256, ListInfo>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Listed: Listed,
        Unlisted: Unlisted,
        Bought: Bought,
        RewardsClaimed: RewardsClaimed,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        num_generations: u256,
        profit_percentage: u256,
        successive_ratio: u256
    ) {
        self
            .default_fr_info
            .write(
                FRInfo {
                    profit_percentage,
                    successive_ratio,
                    owner_amount: 0,
                    last_sold_price: 0,
                    num_generations,
                    is_valid: true
                }
            );
        self.ownable.initializer(owner);
        let creator = get_caller_address();
        self.erc721.initializer(name, symbol, creator, base_uri);
    }


    // Helper function for generation shifting
    fn _shift_generations(ref self: ContractState, token_id: u256, new_owner: ContractAddress) {
        let mut addresses = self.addresses_in_fr.read(token_id);
        let fr_info = self.token_fr_info.read(token_id);

        // Remove oldest address if we've reached generation limit
        if addresses.len() >= fr_info.num_generations {
            addresses.pop_front();
        }

        // Add new owner
        addresses.append(new_owner);
        self.addresses_in_fr.write(token_id, addresses);
    }

    #[abi(embed_v0)]
    impl ERC5173FutureRewardsImpl of IERC5173FutureRewards<ContractState> {
        fn get_fr_info(
            self: @ContractState, token_id: u256
        ) -> (u8, u256, u256, u256, u256, Array<ContractAddress>) {
            let fr_info = self.token_fr_info.read(token_id);
            let addresses = self.addresses_in_fr.read(token_id);
            (
                fr_info.num_generations.try_into().unwrap(),
                fr_info.profit_percentage,
                fr_info.successive_ratio,
                fr_info.last_sold_price,
                fr_info.owner_amount.try_into().unwrap(),
                addresses
            )
        }

        fn get_allotted_rewards(self: @ContractState, account: ContractAddress) -> u256 {
            self.allotted_fr.read(account).allotted_rewards
        }

        fn get_list_info(self: @ContractState, token_id: u256) -> (u256, ContractAddress, bool) {
            let list_info = self.token_list_info.read(token_id);
            (list_info.sale_price, list_info.lister, list_info.is_listed)
        }
    }
}
