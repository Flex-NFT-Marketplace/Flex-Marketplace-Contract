MAX_LEN_FELT = 31

def str_to_felt(text):
    if len(text) > MAX_LEN_FELT:
        raise Exception("Text length too long to convert to felt.")
    return int.from_bytes(text.encode(), "big")

def felt_to_str(felt):
    print(felt + ":")
    length = (felt.bit_length() + 7) // 8
    return felt.to_bytes(length, byteorder="big").decode("utf-8")

def str_to_felt_array(text):
    print(text + ":")
    return [str_to_felt(text[i:i+MAX_LEN_FELT]) for i in range(0, len(text), MAX_LEN_FELT)]

def uint256_to_int(uint256):
    print(uint256 + ":")
    return uint256[0] + uint256[1]*2**128

def uint256(val):
    print(val)
    return (val & 2**128-1, (val & (2**256-2**128)) >> 128)

def hex_to_felt(val):
    print(val + ":")
    return int(val, 16)

def felt_to_hex(val):
    print(val + ":")
    return hex(val)


# print(str_to_felt_array('https://gateway.pinata.cloud/ipfs/QmSzDqZGkjMVGuTyxhKC49JX2CJjn82KrkUDMPWqj37zzJ/'))
print(str_to_felt_array('https://ipfs.io/ipfs/QmUiDKEX2owkZUHHUadomuVnjbW3EFfuowjfQndFuJDm77'))
# print(str_to_felt('FP'))