#[starknet::contract]
mod ERC5173 {
    use crate::interfaces::ierc721::{IERC721};
    use crate::interfaces::ierc20::{IERC20};
    use crate::interfaces::ierc5173::IERC5173;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map};  
    use std::collections::HashMap;
    use std::vec::Vec;

    #[storage]
    struct Storage {
        token_owners: Map<felt252, ContractAddress>,
        list_info: Map<felt252, ListInfo>,
        fr_info: Map<felt252, FRInfo>,
        reward_balances: Map<ContractAddress, felt252>,
        allotted_fr: Map<ContractAddress, felt252>,
        total_tokens: felt252,
        erc721_address: ContractAddress,
        erc20_address: ContractAddress,
    }

    #[derive(Default)]
    pub struct ERC5173 {
        pub token_owners: HashMap<u64, Address>,
        pub total_supply: u64,
    }

    struct FRInfo {
        numGenerations: felt252,
        percentOfProfit: felt252,
        successiveRatio: felt252,
        lastSoldPrice: felt252,
        ownerAmount: felt252,
        addressesInFR: Vec<ContractAddress>,
    }

    struct ListInfo {
        salePrice: felt252,
        lister: ContractAddress,
        isListed: bool,
    }

    #[constructor]
    pub fn constructor(ref self: ERC5173, erc721_address: ContractAddress, erc20_address: ContractAddress) {
        let storage = get_storage();
        storage.erc721_address = erc721_address;
        storage.erc20_address = erc20_address;
    }

    pub fn mint(ref self: ERC5173, to: ContractAddress, token_id: felt252) -> felt252 {
        let storage = get_storage();

        if storage.token_owners.contains_key(token_id) {
            return;
        }

        storage.token_owners.insert(token_id, to);
        emit Minted!(to, token_id);
    }

    pub fn transfer(ref self: ERC5173, from: ContractAddress, to: ContractAddress, tokenId: felt252, soldPrice: felt252) {
        let storage = get_storage();
        let caller = get_caller_address();
        assert_eq!(storage.token_owners.get(tokenId).unwrap(), from, "Caller is not the owner or approved");
        // assert!(storage.token_owners.get(tokenId) == from, "Caller is not the owner or approved");

        let mut fr_info = storage.fr_info.get(tokenId).unwrap();
        let last_sold_price = fr_info.lastSoldPrice;
        let profit = soldPrice - last_sold_price;

        storage.token_owners.insert(tokenId, to);

        let erc721_dispatcher = IERC721Dispatcher { contract_address: storage.erc721_address };
        erc721_dispatcher.transfer_from(caller, to, tokenId).unwrap();

        if profit > 0 {
            let allocated_fr = _distributeFR(tokenId, soldPrice);
            let amount_to_previous_owner = soldPrice - allocated_fr;
            let previous_owner = storage.token_owners.get(tokenId).expect("Previous owner not found");
            // assert!(previous_owner.is_some(), "Previous owner not found");
            let previous_owner_address = previous_owner.unwrap();
            let erc20_address = storage.erc20_address;
            let erc20: IERC20 = IERC20 { contract_address: erc20_address };
            assert!(erc20.transfer(previous_owner_address, amount_to_previous_owner), "Transfer to previous owner failed");
        } else {
            fr_info.lastSoldPrice = soldPrice;
            fr_info.ownerAmount += 1;

            let lister_address = get_caller_address();            
            assert!(erc20.transfer(lister_address, soldPrice), "Transfer to lister failed");

            let previous_owner_address = storage.token_owners.get(tokenId).expect("Previous owner not found");  
            assert!(erc20.transfer(*previous_owner_address, soldPrice), "Transfer to previous owner failed"); 
            // let previous_owner = storage.token_owners.get(tokenId);
            // assert!(previous_owner.is_some(), "Previous owner not found");
            // let previous_owner_address = previous_owner.unwrap();
            
            // assert!(erc20.transfer(previous_owner_address, soldPrice), "Transfer to previous owner failed");
        }

        storage.list_info.remove(tokenId);
    }

    fn _distributeFR(tokenId: felt252, soldPrice: felt252) -> felt252 {
        let storage = get_storage();
        // let fr_info = storage.fr_info.get(tokenId);
        let fr_info = storage.fr_info.get(tokenId).expect("FR info not found");  
        let addresses_in_fr = fr_info.addressesInFR;

        let profit = soldPrice - fr_info.lastSoldPrice;
        let mut allocated_fr = 0;

        if profit > 0 && !address_in_fr.is_empty() {
            let distributions = _calculateFR(profit, fr_info.percentOfProfit, fr_info.successiveRatio, fr_info.ownerAmount, addresses_in_fr.len());
            for (i, address) in addresses_in_fr.iter().enumerate() {
                let reward = distributions[i];

                let erc20_address = storage.erc20_address;
                let erc20: IERC20 = IERC20 { contract_address: erc20_address };

                assert!(erc20.transfer(*address, reward), "Transfer to address failed");
                allocated_fr += reward;
            }
            emit FRDistributed{tokenId, soldPrice, allocated_fr};
        }

        allocated_fr;
    }

    fn _calculateFR(totalProfit: felt252, buyerReward: felt252, successiveRatio: felt252, ownerAmount: felt252, windowSize: usize) -> Vec<felt252> {
        let mut distributions = Vec::new();
        let totalReward = (totalProfit * buyerReward) / 1_000_000_000_000_000_000; // 1e18
        
        for i in 0..windowSize {
            let reward = totalReward / pow(successiveRatio, i);

            if reward > 0 {
                distributions.push(reward);
            } else {
                break;
            }
        }

        while distributions.len() < ownerAmount {
            distributions.push(0);
        }

        distributions;
    }

    pub fn releaseFR(ref self: Self, account: ContractAddress) {
        let storage = get_storage();
        
        let amount = storage.allotted_fr.get(account).unwrap_or(0);
        assert!(amount > 0, "No funds to release");

        let erc20_address = storage.erc20_address;
        let erc20: IERC20 = IERC20 { contract_address: erc20_address };

        assert!(erc20.transfer(account, amount), "Transfer failed");
        storage.allotted_fr.insert(account, 0);                                  
        emit FRClaimed {account, amount};
    }

    fn _shiftGenerations(tokenId: felt252) {
        let storage = get_storage();
    
        match storage.fr_info.get(tokenId) {
            Some(mut fr_info) => {
                let addresses_in_fr = fr_info.addressesInFR;

                if !addresses_in_fr.is_empty() {
                    addresses_in_fr.remove(0);
                }

                storage.fr_info.insert(tokenId, fr_info);
            },
            None => {
                panic!("No fr_info found for tokenId: {}", tokenId);
            }
        }
    }

}
