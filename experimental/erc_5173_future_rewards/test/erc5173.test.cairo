#[cfg(test)]
mod tests {
    use super::*;
    use starknet::testing::contract::Contract;
    use starknet::testing::accounts::Account;
    use starknet::testing::setup;

    #[test]
    fn test_mint() {
        let mut contract = ERC5173::default();
        let account1 = Address::from_str("0x3dB43319576aF8EC93e64239517Db69a83FB5087").unwrap(); // Replace with a valid address
        let token_id = 1;

        let result = contract.mint(account1, token_id);
        assert!(result.is_ok());

        assert_eq!(contract.token_owners.get(&token_id), Some(&account1));
    }

    #[test]
    fn test_transfer_from() {
        let (mut contract, account1, account2) = setup();

        let erc721_address = account1.deploy_erc721();
        let erc20_address = account1.deploy_erc20();
        contract.new(erc721_address, erc20_address);

        let tokenId = 1;
        contract.mint(account1.address, tokenId);

        let sold_price = 1000;
        contract.transfer_from(account1.address, account2.address, tokenId, sold_price);

        assert_eq!(contract.token_owners.get(&tokenId), account2.address);

        let previous_owner_balance = contract.reward_balances.get(account1.address);
        assert_eq!(previous_owner_balance, sold_price);

        let fr_info = contract.fr_info.get(tokenId);
        assert_eq!(fr_info.lastSoldPrice, sold_price);
    }

    #[test]
    fn test_releaseFR() {
        let (mut contract, account1) = setup();

        let erc20_address = account1.deploy_erc20();
        contract.new(erc721_address, erc20_address);

        let account = account1.address;
        contract.allotted_fr.insert(account, 500);

        contract.releaseFR(account);

        let allotted_after_release = contract.allotted_fr.get(&account);
        assert_eq!(allotted_after_release, 0);
    }

    #[test]
    fn test_shiftGenerations() {
        let (mut contract, account1, account2) = setup();

        let erc20_address = account1.deploy_erc20();
        contract.new(erc721_address, erc20_address);

        // Add addresses to the FRInfo
        let tokenId = 1;
        contract.fr_info.insert(tokenId, FRInfo {
            numGenerations: 1,
            percentOfProfit: 100,
            successiveRatio: 2,
            lastSoldPrice: 0,
            ownerAmount: 1,
            addressesInFR: vec![account1.address, account2.address],
        });

        contract._shiftGenerations(tokenId);

        let fr_info = contract.fr_info.get(tokenId);
        assert_eq!(fr_info.addressesInFR, vec![account2.address]);
    }
}