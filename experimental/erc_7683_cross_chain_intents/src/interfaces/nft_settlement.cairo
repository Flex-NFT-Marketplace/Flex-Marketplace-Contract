#[starknet::interface]
trait INFTSettlement<TContractState> {
    fn initiate(
        ref self: TContractState,
        order: CrossChainNFTOrder,
        signature: Array<felt252>,
        filler_data: Array<felt252>
    );

    fn resolve(
        self: @TContractState, order: CrossChainNFTOrder, filler_data: Array<felt252>
    ) -> ResolvedCrossChainNFTOrder;

    fn fulfill(
        ref self: TContractState, order: CrossChainNFTOrder, origin_chain_proof: Array<felt252>
    );
}
