%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.registers import get_fp_and_pc

from contracts.marketplace.utils.OrderTypes import MakerOrder
from contracts.openzeppelin.upgrades.library import Proxy

@contract_interface
namespace IAccount {
    func is_valid_signature(hash: felt, signature_len: felt, signature: felt*) {
    }
}

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    return ();
}

// Computes a hash from a MakerOrder
// https://github.com/0xs34n/starknet.js/blob/e72b4488638ebd77c2de13d62bb112e3d4d16550/src/utils/typedData/index.ts#L170
// domain: { name: "Flex", chainId: networkId() === "mainnet-alpha" ? "SN_MAIN" : "SN_GOERLI", version: "2" }
// hashDomain = ... # SN_MAIN
// hashDomain = ... # SN_GOERLI
@view
func computeMakerOrderHash{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    hashDomain: felt, order: MakerOrder
) -> (hash: felt) {
    const starknetMessage = 110930206544689809660069706067448260453;  // StarkNet Message

    // https://github.com/0xs34n/starknet.js/blob/e72b4488638ebd77c2de13d62bb112e3d4d16550/src/utils/typedData/index.ts#L172
    const hashMessageSelector = 563771258078353655219004671487831885088158240957819730493696170021701903504;

    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=0, y=hashMessageSelector);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.isOrderAsk);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.signer);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.collection);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.price);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.tokenId.low);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.tokenId.high);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.amount);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.strategy);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.currency);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.nonce);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.startTime);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.endTime);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.minPercentageToAsk);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=order.params);
    let (hashMessage) = hash2{hash_ptr=pedersen_ptr}(x=hashMessage, y=15);  // length

    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=0, y=starknetMessage);
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=hash, y=hashDomain);
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=hash, y=order.signer);
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=hash, y=hashMessage);
    let (hash) = hash2{hash_ptr=pedersen_ptr}(x=hash, y=4);  // length
    return (hash,);
}

// Verifies a MakerOrder signature
@view
func verifyMakerOrderSignature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(hashDomain: felt, order: MakerOrder, orderSignature_len: felt, orderSignature: felt*) {
    alloc_locals;
    let (hash) = computeMakerOrderHash(hashDomain, order);
    local pedersen_ptr: HashBuiltin* = pedersen_ptr;
    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    IAccount.is_valid_signature(
        contract_address=order.signer, hash=hash, signature_len=orderSignature_len, signature=orderSignature
    );
    return ();
}
