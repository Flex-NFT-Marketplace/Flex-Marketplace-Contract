%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.openzeppelin.utils.ShortString import uint256_to_ss
from contracts.openzeppelin.utils.Array import concat_arr

//
// Storage
//

@storage_var
func ERC721_base_tokenURI(index: felt) -> (res: felt) {
}

@storage_var
func ERC721_base_tokenURI_len() -> (res: felt) {
}

func ERC721_tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;

    // Return tokenURI with an array of felts, `${base_tokenURI}/${token_id}`
    let (local base_tokenURI) = alloc();
    let (local base_tokenURI_len) = ERC721_base_tokenURI_len.read();
    _ERC721_baseTokenURI(base_tokenURI_len, base_tokenURI);
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id);
    let (tokenURI, tokenURI_len) = concat_arr(
        base_tokenURI_len, base_tokenURI, token_id_ss_len, token_id_ss
    );

    return (tokenURI_len=tokenURI_len, tokenURI=tokenURI);
}

func _ERC721_baseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    base_tokenURI_len: felt, base_tokenURI: felt*
) {
    if (base_tokenURI_len == 0) {
        return ();
    }
    let (base) = ERC721_base_tokenURI.read(base_tokenURI_len);
    assert [base_tokenURI] = base;
    _ERC721_baseTokenURI(base_tokenURI_len=base_tokenURI_len - 1, base_tokenURI=base_tokenURI + 1);
    return ();
}

func ERC721_setBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI_len: felt, tokenURI: felt*
) {
    _ERC721_setBaseTokenURI(tokenURI_len, tokenURI);
    ERC721_base_tokenURI_len.write(tokenURI_len);
    return ();
}

func _ERC721_setBaseTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenURI_len: felt, tokenURI: felt*
) {
    if (tokenURI_len == 0) {
        return ();
    }
    ERC721_base_tokenURI.write(index=tokenURI_len, value=[tokenURI]);
    _ERC721_setBaseTokenURI(tokenURI_len=tokenURI_len - 1, tokenURI=tokenURI + 1);
    return ();
}

func ERC721_baseURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    baseURI_len: felt, baseURI: felt*
) {
    alloc_locals;

    let (local baseURI) = alloc();
    let (local baseURI_len) = ERC721_base_tokenURI_len.read();
    _ERC721_baseTokenURI(baseURI_len, baseURI);

    return (baseURI_len=baseURI_len, baseURI=baseURI);
}
