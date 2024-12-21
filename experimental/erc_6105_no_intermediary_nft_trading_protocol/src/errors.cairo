pub mod Errors {
    pub const INVALID_PRICE: felt252 = 'ERC6105: invalid sale price';
    pub const INVALID_AMOUNT: felt252 = 'ERC6105: invalid amount';
    pub const INSUFFICIENT_BALANCE: felt252 = 'ERC6105: insufficient balance';
    pub const INVALID_TOKEN: felt252 = 'ERC6105: invalid token';
    pub const SALE_PRICE_ZERO: felt252 = 'ERC6105: price MUST NOT be 0';
    pub const INVALID_EXPIRES: felt252 = 'ERC6105: invalid expires';
    pub const NOT_OWNER_OR_APPROVED: felt252 = 'ERC6105: not owner nor approved';
    pub const INVALID_LISTING: felt252 = 'ERC6105: invalid listing';
    pub const INCONSISTENT_PRICE: felt252 = 'ERC6105: inconsistent price';
    pub const INCONSISTENT_TOKENS: felt252 = 'ERC6105: inconsistent tokens';
    pub const INCORRECT_VALUE: felt252 = 'ERC6105: incorrect value';
    pub const INSUFFICIENT_ALLOWANCE: felt252 = 'ERC6105: insufficient allowance';
}
