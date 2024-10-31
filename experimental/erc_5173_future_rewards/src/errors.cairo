mod errors {
    pub const INVALID_TOKEN_ID: felt252 = 'FR: invalid token ID';
    pub const NOT_TOKEN_OWNER: felt252 = 'FR: caller not authorized';
    pub const TOKEN_NOT_LISTED: felt252 = 'FR: token not listed';
    pub const PRICE_MISMATCH: felt252 = 'FR: sale price-value mismatch';
    pub const NO_FR_PAYMENT_DUE: felt252 = 'FR: no FR payment due';
    pub const FAILED_TO_SEND: felt252 = 'FR: failed to send value';
    pub const INVALID_FR_DATA: felt252 = 'FR: invalid FR data passed';
    pub const NO_DEFAULT_FR_INFO: felt252 = 'FR: default FR info not set';
    pub const INVALID_TRANSFER: felt252 = 'FR: invalid transfer';
    pub const ZERO_ADDRESS: felt252 = 'FR: zero address';
    pub const ALREADY_LISTED: felt252 = 'FR: token already listed';
    pub const INSUFFICIENT_FUNDS: felt252 = 'FR: insufficient funds';
    pub const INVALID_GENERATIONS: felt252 = 'FR: generations must be > 0';
    pub const INVALID_PERCENT: felt252 = 'FR: percent must be > 0 <= 1e18';
    pub const INVALID_RATIO: felt252 = 'FR: ratio must be > 0';
    pub const UNAUTHORIZED_OPERATOR: felt252 = 'FR: unauthorized operator';
    pub const INVALID_ARRAY_LENGTH: felt252 = 'FR: invalid array length';
    pub const NOT_IMPLEMENTED: felt252 = 'FR: function not implemented';
    pub const INVALID_RECIPIENT: felt252 = 'FR: invalid recipient';
    pub const TOKEN_ALREADY_MINTED: felt252 = 'FR: token already minted';
    pub const CONTRACT_PAUSED: felt252 = 'FR: contract paused';

    pub const MATH_ERROR: felt252 = 'FR: math operation failed';
    pub const ARRAY_OOB: felt252 = 'FR: array out of bounds';
    pub const STORAGE_ERROR: felt252 = 'FR: storage operation failed';
}
