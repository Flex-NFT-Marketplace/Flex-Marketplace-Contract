use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::interface]
trait IERC721<TContractState> {
    fn ownerOf(self: @TContractState, token_id: u256) -> ContractAddress;
    fn getApproved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn isApprovedForAll(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn transferFrom(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
}

#[starknet::interface]
trait INFTHolderAirdrop<TContractState> {
    fn get_rewards_per_nft(self: @TContractState) -> u256;
    fn initialize(
        ref self: TContractState,
        _owner: ContractAddress,
        _reward_token: ContractAddress,
        _eligible_nft: ContractAddress,
        _rewards_per_nft: u256
    );
    fn withdraw_reward_tokens(ref self: TContractState, _amount: u256);
    fn set_reward_per_nft(ref self: TContractState, _rewards_per_nft: u256);
    fn claim_rewards(ref self: TContractState, _token_id: u256);
}

#[starknet::contract]
mod NFTHolderAirdrop {
    use core::clone::Clone;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use super::IERC721Dispatcher;
    use super::IERC721DispatcherTrait;

    use core::traits::Into;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::get_contract_address;
    use starknet::get_caller_address;

    use openzeppelin::security::ReentrancyGuardComponent;

    component!(path: ReentrancyGuardComponent, storage: reentrancy, event: ReentrancyEvent);

    impl ReentrancyInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        initialized: bool,
        owner: ContractAddress,
        reward_token: ContractAddress,
        eligible_nft: ContractAddress,
        rewards_per_nft: u256,
        claimed_nfts: LegacyMap::<u256, bool>,
        #[substorage(v0)]
        reentrancy: ReentrancyGuardComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RewardTokensDepositedByAdmin: RewardTokensDepositedByAdmin,
        RewardTokensWithdrawnByAdmin: RewardTokensWithdrawnByAdmin,
        UpdatedRewardsPerNft: UpdatedRewardsPerNft,
        RewardsClaimed: RewardsClaimed,
        #[flat]
        ReentrancyEvent: ReentrancyGuardComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardTokensDepositedByAdmin {
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardTokensWithdrawnByAdmin {
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UpdatedRewardsPerNft {
        oldRewardsPerNft: u256,
        newRewardsPerNft: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardsClaimed {
        #[key]
        tokenId: u256,
        recipient: ContractAddress,
        rewardAmount: u256,
    }

    #[abi(embed_v0)]
    impl INFTHolderAirdropImpl of super::INFTHolderAirdrop<ContractState> {
        fn initialize(
            ref self: ContractState,
            _owner: ContractAddress,
            _reward_token: ContractAddress,
            _eligible_nft: ContractAddress,
            _rewards_per_nft: u256,
        ) {
            assert(!self.initialized.read(), 'Already initialized');
            self.initialized.write(true);
            self.owner.write(_owner);
            self.reward_token.write(_reward_token);
            self.eligible_nft.write(_eligible_nft);
            self.rewards_per_nft.write(_rewards_per_nft);
        }

        fn withdraw_reward_tokens(ref self: ContractState, _amount: u256) {
            self.reentrancy.start();
            assert(self.owner.read() == get_caller_address(), 'Only owner');
            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer(get_caller_address(), _amount);

            self
                .emit(
                    Event::RewardTokensWithdrawnByAdmin(
                        RewardTokensWithdrawnByAdmin { amount: _amount }
                    )
                );

            self.reentrancy.end();
        }

        fn set_reward_per_nft(ref self: ContractState, _rewards_per_nft: u256) {
            self.reentrancy.start();
            assert(self.owner.read() == get_caller_address(), 'Only owner');
            let old_rewards_per_nft = self.rewards_per_nft.read();
            self.rewards_per_nft.write(_rewards_per_nft);
            self
                .emit(
                    Event::UpdatedRewardsPerNft(
                        UpdatedRewardsPerNft {
                            oldRewardsPerNft: old_rewards_per_nft,
                            newRewardsPerNft: _rewards_per_nft
                        }
                    )
                );
            self.reentrancy.end();
        }

        fn claim_rewards(ref self: ContractState, _token_id: u256) {
            self.reentrancy.start();
            self._claim_rewards(_token_id);
            self.reentrancy.end();
        }

        fn get_rewards_per_nft(self: @ContractState) -> u256 {
            self.rewards_per_nft.read()
        }
    }

    #[generate_trait]
    impl StorageImpl of StorageTrait {
        fn _claim_rewards(ref self: ContractState, _token_id: u256) {
            let nft_contract = IERC721Dispatcher { contract_address: self.eligible_nft.read() };
            let nftOwner = nft_contract.ownerOf(_token_id);
            assert(nftOwner == get_caller_address(), 'Caller not the owner of the NFT');

            assert(!self.claimed_nfts.read(_token_id), 'Already claimed');
            self.claimed_nfts.write(_token_id, true);

            let rewards = self.get_rewards_per_nft();
            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer(nftOwner, rewards);
            self
                .emit(
                    Event::RewardsClaimed(
                        RewardsClaimed {
                            tokenId: _token_id, recipient: nftOwner, rewardAmount: rewards
                        }
                    )
                );
        }
    }
}
