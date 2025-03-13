#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::byte_array::ByteArray;
    use flexhaus::factory::FlexHausFactory;
    use flexhaus::collectible::FlexHausCollectible;
    use core::starknet::{
        ContractAddress, contract_address_const, ClassHash, get_caller_address, deploy_syscall,
        get_contract_address, get_block_timestamp, get_tx_info
    };
    use openzeppelin::utils::serde::SerializedAppend;
    use flexhaus::interface::IFlexHausFactory::{
        IFlexHausFactory, IFlexHausFactoryDispatcher, IFlexHausFactoryDispatcherTrait,
        CollectibleRarity, DropDetail
    };
    use flexhaus::interface::IFlexHausCollectible::{
        IFlexHausCollectibleMixinDispatcher, IFlexHausCollectibleMixinDispatcherTrait
    };
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, MutableVecTrait, Map, Vec, VecTrait,
        MutableTrait
    };
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use snforge_std::{
        declare, ContractClass, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
        stop_cheat_caller_address, EventSpyAssertionsTrait, spy_events, load, test_address, start_cheat_caller_address_global, stop_cheat_caller_address_global
    };
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use hash::{HashStateTrait, HashStateExTrait};
    use pedersen::PedersenTrait;
    use core::{traits::Into, debug::PrintTrait};

    // Helper functions
    fn owner() -> ContractAddress {
        contract_address_const::<'owner'>()
    }

    fn addr1() -> ContractAddress {
        contract_address_const::<'addr1'>()
    }

    fn protocol_fee() -> u256 {
        1000
    }
    fn protocol_currency() -> ContractAddress {
        // contract_address_const::<'protocol_currency'>()
        deploy_erc20()
    }


    fn fee_recipient() -> ContractAddress {
        contract_address_const::<'fee_recipient'>()
    }

    fn signer() -> ContractAddress {
        contract_address_const::<'signer'>()
    }

    fn flex_haus_collectible_class() -> ClassHash {
        let collectible_contract = declare("FlexHausCollectible").unwrap().contract_class();
        *collectible_contract.class_hash
    }

    fn attacker() -> ContractAddress {
        contract_address_const::<'attacker'>()
    }

    // Deployments
    fn deploy_erc20() -> ContractAddress {
        let erc20_class = declare("erc20").unwrap().contract_class();

        let name = ByteArray {
            data: array![], pending_word: 'ProtocolToken', pending_word_len: 13
        };
        let symbol = ByteArray { data: array![], pending_word: 'PPT', pending_word_len: 3 };

        let mut constructor_calldata = ArrayTrait::<felt252>::new();
        constructor_calldata.append_serde(name);
        constructor_calldata.append_serde(symbol);

        let (erc20_address, _) = erc20_class.deploy(@constructor_calldata).unwrap();

        let _currencyDispatcher = ERC20ABIDispatcher { contract_address: erc20_address };

        erc20_address
    }

    fn deploy_flex_haus_factory() -> (IFlexHausFactoryDispatcher, ContractAddress) {
        let contract = declare("FlexHausFactory").unwrap().contract_class();

        let mut calldata: Array<felt252> = array![];
        calldata.append_serde(owner());
        calldata.append_serde(protocol_fee().into());
        calldata.append_serde(protocol_currency());
        calldata.append_serde(fee_recipient());
        calldata.append_serde(signer());
        calldata.append_serde(flex_haus_collectible_class());

        let (contract_address, _) = contract.deploy(@calldata).unwrap();

        let dispatcher = IFlexHausFactoryDispatcher { contract_address };

        (dispatcher, contract_address)
    }

    #[test]
    fn test_constructor() {
        let (factory, _) = deploy_flex_haus_factory();

        assert_eq!(factory.get_protocol_fee(), protocol_fee());
        assert_eq!(factory.get_protocol_currency(), protocol_currency());
        assert_eq!(factory.get_fee_recipient(), fee_recipient());
    }


    #[test]
    fn test_initial_state() {
        let (factory, _) = deploy_flex_haus_factory();

        assert_eq!(
            factory.get_signer(),
            signer(),
            "{:?},{:?} should be equal",
            factory.get_signer(),
            signer()
        );
        assert_eq!(
            factory.get_flex_haus_collectible_class(),
            flex_haus_collectible_class(),
            "{:?},{:?} Wrong collectible class",
            factory.get_flex_haus_collectible_class(),
            flex_haus_collectible_class()
        );
        assert_eq!(
            factory.get_min_duration_time_for_update(),
            3600,
            "{:?} {:?} Wrong duration time",
            factory.get_min_duration_time_for_update(),
            3600
        );
        assert_eq!(
            factory.get_total_collectibles_count(),
            0,
            "{:?} {:?} Factory should start with 0 collectibles",
            factory.get_total_collectibles_count(),
            0
        );
    }

    #[test]
    fn test_create_collectible() {
        let (mut factory, contract_address) = deploy_flex_haus_factory();
        let mut _events_spy = spy_events();

        let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5, };

        let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3, };

        let base_uri = ByteArray {
            data: array![], pending_word: 'ipfs://', pending_word_len: 15,
        };

        start_cheat_caller_address(contract_address, owner());
        factory.create_collectible(name, symbol, base_uri, 1000.into(), 'common');
        stop_cheat_caller_address(contract_address);

        let collectibles = factory.get_all_collectibles_addresses();
        assert_eq!(collectibles.len(), 1, "Should create 1 collectible");
    }

    #[test]
    fn test_create_drop() {
        let (factory, contract_address) = deploy_flex_haus_factory();
        let mut _events_spy = spy_events();

        // Create a collectible first
        let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5, };
        let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3, };
        let base_uri = ByteArray {
            data: array![], pending_word: 'ipfs://', pending_word_len: 15,
        };

        start_cheat_caller_address(contract_address, owner());
        factory.create_collectible(name, symbol, base_uri, 1000.into(), 'common');
        stop_cheat_caller_address(contract_address);

        let collectibles = factory.get_all_collectibles_addresses();
        let collectible_address = collectibles.at(0);

        // Create a drop
        start_cheat_caller_address(contract_address, owner());
        factory
            .create_drop(
                *collectible_address,
                1, // drop_type
                500.into(), // secure_amount
                true, // is_random_to_subscribers
                1, // from_top_supporter
                10, // to_top_supporter
                get_block_timestamp() + 3600, // start_time
                get_block_timestamp() + 7200 // expire_time
            );
        stop_cheat_caller_address(contract_address);

        // Verify the drop details
        let drop_detail = factory.get_collectible_drop(*collectible_address);
        assert_eq!(drop_detail.drop_type, 1, "Drop type should be 1");
        assert_eq!(drop_detail.secure_amount, 500.into(), "Secure amount should be 500");
    }

    #[test]
    fn test_claim_collectible() {
        let (factory, _) = deploy_flex_haus_factory();

        // Create a collectible first
        let name = ByteArray { data: array![], pending_word: 'MyNFT', pending_word_len: 5, };
        let symbol = ByteArray { data: array![], pending_word: 'MFT', pending_word_len: 3, };
        let base_uri = ByteArray {
            data: array![], pending_word: 'ipfs://', pending_word_len: 15,
        };
        let total_supply: u256 = 1000.into();
        let rarity: felt252 = 'common';

        start_cheat_caller_address_global(owner());
        factory.create_collectible(name, symbol, base_uri, total_supply, rarity);

        let collectibles = factory.get_all_collectibles_addresses();
        let collectible_address = collectibles.at(0);

        let drop_type: u8 = 1;
        let secure_amount: u256 = 500;
        let is_random_to_subscribers: bool = true;
        let from_top_supporter: u64 = 1;
        let to_top_supporter: u64 = 10;
        let start_time: u64 = get_block_timestamp() + 3600;
        let expire_time: u64 = start_time + 3600;

        factory
            .create_drop(
                *collectible_address,
                drop_type,
                secure_amount,
                is_random_to_subscribers,
                from_top_supporter,
                to_top_supporter,
                start_time,
                expire_time
            );

        let _recipient: ContractAddress = contract_address_const::<'recipient'>();
        let mut keys = ArrayTrait::<felt252>::new();
        keys.append(0x123);
        keys.append(0x456);

        factory.claim_collectible(*collectible_address, keys);

        let collectible_dis = IFlexHausCollectibleMixinDispatcher {
            contract_address: *collectible_address
        };
        
        collectible_dis.mint_collectible(_recipient);


        // assert(balance == 1, 'Collectible not claimed');
    }

}
