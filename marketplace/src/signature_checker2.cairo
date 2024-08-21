use starknet::ContractAddress;

use marketplace::utils::order_types::MakerOrder;

#[derive(Drop, Copy, Serde)]
struct WhiteListParam {
    phase_id: u64,
    nft_address: ContractAddress,
    minter: ContractAddress,
}

const STARKNET_MESSAGE: felt252 = 110930206544689809660069706067448260453;

const HASH_MESSAGE_SELECTOR: felt252 =
    563771258078353655219004671487831885088158240957819730493696170021701903504;

const STARKNET_MAKER_ORDER_TYPE_HASH: felt252 =
    selector!(
        "MakerOrder(is_order_ask:u8,signer:felt,collection:felt,price:u128,seller:felt,token_id:u256,amount:u128,strategy:felt,currency:felt,salt_nonce:u128,start_time:u64,end_time:u64,min_percentage_to_ask:u128,params:felt)u256(low:felt,high:felt)"
    );

const STARKNET_WHITELIST_TYPE_HASH: felt252 =
    selector!("WhiteListParam(phase_id:u64,nft_address:felt,minter:felt)");

const U256_TYPE_HASH: felt252 = selector!("u256(low:felt,high:felt)");

#[starknet::interface]
trait ISignatureChecker2<TState> {
    fn compute_maker_order_hash(self: @TState, hash_domain: felt252, order: MakerOrder) -> felt252;
    fn verify_maker_order_signature(
        self: @TState, hash_domain: felt252, order: MakerOrder, order_signature: Array<felt252>
    );
    fn compute_message_hash(self: @TState, domain_hash: felt252, order: MakerOrder) -> felt252;
    fn verify_maker_order_signature_v2(
        self: @TState, domain_hash: felt252, order: MakerOrder, order_signature: Array<felt252>
    );

    fn compute_whitelist_mint_message_hash(
        self: @TState, domain_hash: felt252, signer: ContractAddress, whitelist_data: WhiteListParam
    ) -> felt252;
    fn verify_whitelist_mint_proof(
        self: @TState,
        domain_hash: felt252,
        signer: ContractAddress,
        whitelist_data: WhiteListParam,
        proof: Array<felt252>
    );
}

#[starknet::contract]
mod SignatureChecker2 {
    use openzeppelin::account::interface::AccountABIDispatcherTrait;
    use core::option::OptionTrait;
    use core::traits::Into;
    use core::traits::TryInto;
    use core::box::BoxTrait;
    use marketplace::signature_checker2::ISignatureChecker2;
    use starknet::{ContractAddress, get_tx_info, contract_address_to_felt252};
    use poseidon::poseidon_hash_span;
    use pedersen::PedersenTrait;
    use hash::{HashStateTrait, HashStateExTrait};
    use openzeppelin::account::interface::AccountABIDispatcher;
    use openzeppelin::account::interface::{ISRC6CamelOnlyDispatcher, ISRC6CamelOnlyDispatcherTrait};
    use openzeppelin::account::interface::{ISRC6Dispatcher, ISRC6DispatcherTrait};
    use super::{MakerOrder, WhiteListParam};

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[derive(Drop, Copy, Serde, Hash)]
    struct StarknetDomain {
        name: felt252,
        version: felt252,
        chain_id: felt252,
    }

    #[abi(embed_v0)]
    impl SignatureChecker2Impl of super::ISignatureChecker2<ContractState> {
        fn compute_message_hash(
            self: @ContractState, domain_hash: felt252, order: MakerOrder
        ) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with('StarkNet Message');
            state = state.update_with(domain_hash);
            state = state.update_with(order.signer);
            state = state.update_with(order.hash_struct());
            state = state.update_with(4);
            state.finalize()
        }

        fn compute_maker_order_hash(
            self: @ContractState, hash_domain: felt252, order: MakerOrder
        ) -> felt252 {
            let hash_message_params = array![
                super::HASH_MESSAGE_SELECTOR,
                order.is_order_ask.into(),
                order.signer.into(),
                order.collection.into(),
                order.price.into(),
                order.token_id.try_into().unwrap(),
                order.amount.into(),
                order.strategy.into(),
                order.currency.into(),
                order.salt_nonce.into(),
                order.start_time.into(),
                order.end_time.into(),
                order.min_percentage_to_ask.into(),
                order.params,
                14
            ];
            let hash_message = poseidon_hash_span(hash_message_params.span());

            let hash_params = array![
                super::STARKNET_MESSAGE, hash_domain, order.signer.into(), hash_message, 4
            ];
            poseidon_hash_span(hash_params.span())
        }

        fn verify_maker_order_signature(
            self: @ContractState,
            hash_domain: felt252,
            order: MakerOrder,
            order_signature: Array<felt252>
        ) {
            let hash = self.compute_maker_order_hash(hash_domain, order);
            let result = ISRC6Dispatcher { contract_address: order.signer }
                .is_valid_signature(hash, order_signature);

            assert!(result == starknet::VALIDATED, "SignatureChecker: Invalid signature");
        }

        fn verify_maker_order_signature_v2(
            self: @ContractState,
            domain_hash: felt252,
            order: MakerOrder,
            order_signature: Array<felt252>
        ) {
            let hash = self.compute_message_hash(domain_hash, order);
            let account: AccountABIDispatcher = AccountABIDispatcher {
                contract_address: order.signer
            };
            let result = account.is_valid_signature(hash, order_signature);

            assert!(result == starknet::VALIDATED, "SignatureChecker: Invalid signature");
        }

        fn compute_whitelist_mint_message_hash(
            self: @ContractState,
            domain_hash: felt252,
            signer: ContractAddress,
            whitelist_data: WhiteListParam
        ) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with('StarkNet Message');
            state = state.update_with(domain_hash);
            state = state.update_with(signer);
            state = state.update_with(whitelist_data.hash_struct());
            state = state.update_with(4);
            state.finalize()
        }

        fn verify_whitelist_mint_proof(
            self: @ContractState,
            domain_hash: felt252,
            signer: ContractAddress,
            whitelist_data: WhiteListParam,
            proof: Array<felt252>
        ) {
            let hash = self
                .compute_whitelist_mint_message_hash(domain_hash, signer, whitelist_data);
            let account: AccountABIDispatcher = AccountABIDispatcher { contract_address: signer };
            let result = account.is_valid_signature(hash, proof);

            assert!(result == starknet::VALIDATED, "SignatureChecker: Invalid proof");
        }
    }

    trait IStructHash<T> {
        fn hash_struct(self: @T) -> felt252;
    }

    impl StructHashWhiteList of IStructHash<WhiteListParam> {
        fn hash_struct(self: @WhiteListParam) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(super::STARKNET_WHITELIST_TYPE_HASH);
            state = state.update_with(*self.phase_id);
            state = state.update_with(contract_address_to_felt252(*self.nft_address));
            state = state.update_with(contract_address_to_felt252(*self.minter));
            state = state.update_with(4);
            state.finalize()
        }
    }

    impl StructHashMarkerOrder of IStructHash<MakerOrder> {
        fn hash_struct(self: @MakerOrder) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(super::STARKNET_MAKER_ORDER_TYPE_HASH);
            let mut is_order_ask_u8: u8 = 1;
            if !(*self.is_order_ask) {
                is_order_ask_u8 = 0;
            }
            state = state.update_with(is_order_ask_u8);
            state = state.update_with(contract_address_to_felt252(*self.signer));
            state = state.update_with(contract_address_to_felt252(*self.collection));
            state = state.update_with(*self.price);
            state = state.update_with(contract_address_to_felt252(*self.seller));
            state = state.update_with(self.token_id.hash_struct());
            state = state.update_with(*self.amount);
            state = state.update_with(contract_address_to_felt252(*self.strategy));
            state = state.update_with(contract_address_to_felt252(*self.currency));
            state = state.update_with(*self.salt_nonce);
            state = state.update_with(*self.start_time);
            state = state.update_with(*self.end_time);
            state = state.update_with(*self.min_percentage_to_ask);
            state = state.update_with(*self.params);
            state = state.update_with(15);
            state.finalize()
        }
    }

    impl StructHashU256 of IStructHash<u256> {
        fn hash_struct(self: @u256) -> felt252 {
            let mut state = PedersenTrait::new(0);
            state = state.update_with(super::U256_TYPE_HASH);
            state = state.update_with(*self);
            state = state.update_with(3);
            state.finalize()
        }
    }
}
