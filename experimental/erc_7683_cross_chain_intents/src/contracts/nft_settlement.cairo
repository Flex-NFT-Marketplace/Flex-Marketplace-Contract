#[starknet::contract]
mod NFTSettlementContract {
    use super::super::cross_chain_types::{
        CrossChainNFTOrder, ResolvedCrossChainNFTOrder, NFTInput, NFTOutput
    };
    use super::super::erc721::IERC721;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

    #[storage]
    struct Storage {
        initiated_orders: Map<(u256, u32), bool>, // nonce -> chain_id -> initiated
        fulfilled_orders: Map<(u256, u32), bool>, // nonce -> chain_id -> fulfilled
        supported_chains: Map<u32, bool>,
        bridge_contracts: Map<u32, ContractAddress>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OrderInitiated: OrderInitiated,
        OrderFulfilled: OrderFulfilled
    }

    #[derive(Drop, starknet::Event)]
    struct OrderInitiated {
        order: CrossChainNFTOrder,
        filler: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct OrderFulfilled {
        order: CrossChainNFTOrder,
        recipient: ContractAddress
    }


    #[constructor]
    fn constructor(ref self: ContractState, supported_chain_ids: Array<u32>) {
        let mut i = 0;
        loop {
            if i >= supported_chain_ids.len() {
                break;
            }
            self.supported_chains.write(supported_chain_ids[i], true);
            i += 1;
        }
    }

    #[abi(embed_v0)]
    impl NFTSettlement of super::INFTSettlement<ContractState> {
        fn initiate(
            ref self: ContractState,
            order: CrossChainNFTOrder,
            signature: Array<felt252>,
            filler_data: Array<felt252>
        ) {
            // Validate order hasn't expired
            assert(
                get_block_timestamp() <= order.initiate_deadline, 'Order initiation deadline passed'
            );

            // Validate chain ID
            assert(
                self.supported_chains.read(order.destination_chain_id),
                'Unsupported destination chain'
            );

            // Verify order signature
            // ... signature verification logic ...

            // Check order hasn't been initiated
            assert(
                !self.initiated_orders.read((order.nonce, order.origin_chain_id)),
                'Order already initiated'
            );

            // Transfer NFT to this contract
            let nft_dispatcher = IERC721Dispatcher { contract_address: order.nft_contract };
            nft_dispatcher.transfer_from(order.swapper, get_caller_address(), order.token_id);

            // Mark order as initiated
            self.initiated_orders.write((order.nonce, order.origin_chain_id), true);

            // Emit event
            self.emit(OrderInitiated { order: order, filler: get_caller_address() });
        }

        fn resolve(
            self: @ContractState, order: CrossChainNFTOrder, filler_data: Array<felt252>
        ) -> ResolvedCrossChainNFTOrder {
            ResolvedCrossChainNFTOrder {
                settlement_contract: order.settlement_contract,
                swapper: order.swapper,
                nonce: order.nonce,
                origin_chain_id: order.origin_chain_id,
                initiate_deadline: order.initiate_deadline,
                fill_deadline: order.fill_deadline,
                swapper_input: NFTInput {
                    nft_contract: order.nft_contract,
                    token_id: order.token_id,
                    chain_id: order.origin_chain_id
                },
                swapper_output: NFTOutput {
                    nft_contract: order.nft_contract,
                    token_id: order.token_id,
                    recipient: order.destination_address,
                    chain_id: order.destination_chain_id
                },
                filler_outputs: ArrayTrait::new()
            }
        }

        fn fulfill(
            ref self: ContractState, order: CrossChainNFTOrder, origin_chain_proof: Array<felt252>
        ) {
            // Validate order hasn't expired
            assert(
                get_block_timestamp() <= order.fill_deadline, 'Order fulfillment deadline passed'
            );

            // Validate hasn't been fulfilled
            assert(
                !self.fulfilled_orders.read((order.nonce, order.origin_chain_id)),
                'Order already fulfilled'
            );

            // Verify origin chain proof
            // ... proof verification logic ...

            // Mark as fulfilled
            self.fulfilled_orders.write((order.nonce, order.origin_chain_id), true);

            // Emit event
            self.emit(OrderFulfilled { order: order, recipient: order.destination_address });
        }
    }
}
