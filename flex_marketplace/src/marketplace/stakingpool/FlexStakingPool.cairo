#[starknet::contract]
mod FlexStakingPool {
    use core::array::ArrayTrait;
    use flex::marketplace::interfaces::IFlexStakingPool::IFlexStakingPool;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
    use openzeppelin::security::ReentrancyGuardComponent;
    use alexandria_storage::list::{List, ListTrait};
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, get_block_timestamp,
        contract_address_const
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy, event: ReentrancyEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl ReentrancyIntenalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;
    #[storage]
    struct Storage {
        // mapping eligible collection
        isEligibleCollection: LegacyMap::<ContractAddress, bool>,
        // Item => Stake
        vault: LegacyMap::<Item, Stake>,
        // collection => total staked
        totalStaked: LegacyMap::<ContractAddress, u256>,
        // (user, nft collection, token id) => claimed points
        claimedPoint: LegacyMap::<(ContractAddress, ContractAddress, u256), u256>,
        // user => staked details
        stakerIndexer: LegacyMap::<ContractAddress, List<Item>>,
        // collection => timeUnit (second)
        timeUnit: LegacyMap::<ContractAddress, u64>,
        // collection => reward point per unit time
        rewardPerUnitTime: LegacyMap::<ContractAddress, u256>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancy: ReentrancyGuardComponent::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress,) {
        self.ownable.initializer(owner);
    }

    #[derive(Copy, Drop, Serde, Hash, PartialEq, starknet::Store)]
    struct Item {
        collection: ContractAddress,
        tokenId: u256
    }

    #[derive(Copy, Drop, Serde, Hash, starknet::Store)]
    struct Stake {
        owner: ContractAddress,
        stakedAt: u64
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemStaked: ItemStaked,
        ItemUnstaked: ItemUnstaked,
        ClaimPoint: ClaimPoint,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyEvent: ReentrancyGuardComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemStaked {
        #[key]
        collection: ContractAddress,
        #[key]
        tokenId: u256,
        owner: ContractAddress,
        stakedAt: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ItemUnstaked {
        #[key]
        collection: ContractAddress,
        #[key]
        tokenId: u256,
        owner: ContractAddress,
        unstakedAt: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimPoint {
        #[key]
        user: ContractAddress,
        point: u256
    }

    #[abi(embed_v0)]
    impl FlexStakingPoolImpl of IFlexStakingPool<ContractState> {
        fn stakeNFT(ref self: ContractState, collection: ContractAddress, tokenId: u256) {
            self.reentrancy.start();
            self.assertAllowedCollection(collection);

            let caller = get_caller_address();
            self.assertOnlyOwnerOfItem(collection, tokenId, caller);

            let stake = self.vault.read(Item { collection, tokenId });
            assert(stake.owner.is_zero(), 'Item already staked');

            let thisContract = get_contract_address();
            let nftDispatcher = ERC721ABIDispatcher { contract_address: collection };
            nftDispatcher.transferFrom(caller, thisContract, tokenId);

            let stakedAt = get_block_timestamp();
            self.vault.write(Item { collection, tokenId }, Stake { owner: caller, stakedAt });
            self.totalStaked.write(collection, self.totalStaked.read(collection) + 1);

            let mut stakerItems = self.stakerIndexer.read(caller);
            stakerItems.append(Item { collection, tokenId });
            self.stakerIndexer.write(caller, stakerItems);

            self.emit(ItemStaked { collection, tokenId, owner: caller, stakedAt });
            self.reentrancy.end();
        }

        fn unstakeNFT(ref self: ContractState, collection: ContractAddress, tokenId: u256) {
            self.reentrancy.start();
            let caller = get_caller_address();
            let stake = self.vault.read(Item { collection, tokenId });
            assert(stake.owner == caller, 'Not Item Owner');

            let thisContract = get_contract_address();
            self.assertOnlyOwnerOfItem(collection, tokenId, thisContract);

            let nftDispatcher = ERC721ABIDispatcher { contract_address: collection };
            nftDispatcher.transferFrom(thisContract, caller, tokenId);

            self.totalStaked.write(collection, self.totalStaked.read(collection) - 1);
            let unclaimedPoints = self._calculateUnclaimedPoint(caller, collection, tokenId);
            if (unclaimedPoints > 0) {
                self
                    .claimedPoint
                    .write(
                        (caller, collection, tokenId),
                        self.claimedPoint.read((caller, collection, tokenId)) + unclaimedPoints
                    );

                self.emit(ClaimPoint { user: caller, point: unclaimedPoints });
            }
            self
                .vault
                .write(
                    Item { collection, tokenId },
                    Stake { owner: contract_address_const::<0>(), stakedAt: 0 }
                );

            self._removeItem(caller, collection, tokenId);

            self
                .emit(
                    ItemUnstaked {
                        collection, tokenId, owner: caller, unstakedAt: get_block_timestamp()
                    }
                );
            self.reentrancy.end();
        }

        fn getUserPoint(
            self: @ContractState,
            user: ContractAddress,
            nftCollection: ContractAddress,
            tokenId: u256
        ) -> u256 {
            self._calculateTotalReward(user, nftCollection, tokenId)
        }
    }

    #[abi(per_item)]
    #[generate_trait]
    impl AdditionalImpl of IAdditionalImpl {
        #[external(v0)]
        fn getStakedStatus(
            self: @ContractState, collection: ContractAddress, tokenId: u256
        ) -> Stake {
            self.vault.read(Item { collection, tokenId })
        }

        #[external(v0)]
        fn getItemStaked(self: @ContractState, user: ContractAddress) -> Array::<Item> {
            self.stakerIndexer.read(user).array()
        }

        #[external(v0)]
        fn setAllowedCollection(
            ref self: ContractState, collection: ContractAddress, allowed: bool
        ) {
            self.ownable.assert_only_owner();
            self.isEligibleCollection.write(collection, allowed);
        }

        #[external(v0)]
        fn setTimeUnit(ref self: ContractState, collection: ContractAddress, timeUnit: u64) {
            self.reentrancy.start();
            self.ownable.assert_only_owner();

            self.assertAllowedCollection(collection);

            self.timeUnit.write(collection, timeUnit);

            self.reentrancy.end();
        }

        #[external(v0)]
        fn setRewardPerUnitTime(
            ref self: ContractState, collection: ContractAddress, reward: u256
        ) {
            self.reentrancy.start();
            self.ownable.assert_only_owner();

            self.assertAllowedCollection(collection);

            self.rewardPerUnitTime.write(collection, reward);

            self.reentrancy.end();
        }

        #[external(v0)]
        fn isEligibleCollection(self: @ContractState, collection: ContractAddress) -> bool {
            self.isEligibleCollection.read(collection)
        }

        #[external(v0)]
        fn totalStaked(self: @ContractState, collection: ContractAddress) -> u256 {
            self.totalStaked.read(collection)
        }

        #[external(v0)]
        fn getTimeUnit(self: @ContractState, collection: ContractAddress) -> u64 {
            self.timeUnit.read(collection)
        }

        #[external(v0)]
        fn getRewardPerUnitTime(self: @ContractState, collection: ContractAddress) -> u256 {
            self.rewardPerUnitTime.read(collection)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalImplTrait {
        fn assertAllowedCollection(self: @ContractState, collection: ContractAddress) {
            assert(self.isEligibleCollection.read(collection), 'Only Allowed Collection');
        }

        fn assertOnlyOwnerOfItem(
            self: @ContractState,
            collection: ContractAddress,
            tokenId: u256,
            caller: ContractAddress
        ) {
            let nft = ERC721ABIDispatcher { contract_address: collection };
            let owner = nft.ownerOf(tokenId);
            assert(owner == caller, 'Caller Is Not Owner Of The Item');
        }

        fn _calculateUnclaimedPoint(
            self: @ContractState, user: ContractAddress, collection: ContractAddress, tokenId: u256
        ) -> u256 {
            let stakerItems = self.stakerIndexer.read(user).array();
            let mut index = 0;
            let mut point = 0;
            let blockTime = get_block_timestamp();

            // calculate unclaimed point
            loop {
                if index == stakerItems.len() {
                    break point;
                }

                let item = *stakerItems.at(index);
                if (item == Item { collection, tokenId }) {
                    let stakedDetail = self.getStakedStatus(item.collection, item.tokenId);
                    let timeUnit = self.getTimeUnit(item.collection);
                    let rewardPerUnitTime = self.getRewardPerUnitTime(item.collection);

                    if (timeUnit > 0 && rewardPerUnitTime > 0) {
                        let stakedPeriod = blockTime - stakedDetail.stakedAt;
                        point += (stakedPeriod.into() * rewardPerUnitTime) / timeUnit.into();
                    }

                    break point;
                }

                index += 1;
            }
        }

        fn _calculateTotalReward(
            self: @ContractState, user: ContractAddress, collection: ContractAddress, tokenId: u256
        ) -> u256 {
            let mut point = self.claimedPoint.read((user, collection, tokenId));
            point + self._calculateUnclaimedPoint(user, collection, tokenId)
        }

        fn _removeItem(
            ref self: ContractState,
            user: ContractAddress,
            collection: ContractAddress,
            tokenId: u256,
        ) {
            let mut stakedItems = self.stakerIndexer.read(user);
            let mut newStakedItems = ArrayTrait::<Item>::new();
            let mut cpStakedItems = stakedItems.array();

            let mut index = 0;
            loop {
                if (index == cpStakedItems.len()) {
                    break;
                }
                let item = *cpStakedItems.at(index);
                if (item != Item { collection, tokenId }) {
                    newStakedItems.append(item);
                }

                index += 1;
            };

            stakedItems.from_array(@newStakedItems);
            self.stakerIndexer.write(user, stakedItems)
        }
    }
}

