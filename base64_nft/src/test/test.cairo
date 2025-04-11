use base64_nft::common::{base64_encode, byte_arr_to_arr_u8};

#[test]
fn test_base64_encode() {
    let mut i: u256 = 0;
    let mut count: u256 = 0;
    while i < 3_000_00 {
        count += 1;
        i += 1;
    };
    println!("base64: {}", count);
}
