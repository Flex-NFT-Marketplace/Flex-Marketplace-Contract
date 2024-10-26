mod errors {
    const INVALID_TOKEN_ID: felt252 = 'FR: invalid token ID';
    const NOT_TOKEN_OWNER: felt252 = 'FR: caller not authorized';
    const TOKEN_NOT_LISTED: felt252 = 'FR: token not listed';
    const PRICE_MISMATCH: felt252 = 'FR: sale price-value mismatch';
    const NO_FR_PAYMENT_DUE: felt252 = 'FR: no FR payment due';
    const FAILED_TO_SEND: felt252 = 'FR: failed to send value';
    const INVALID_FR_DATA: felt252 = 'FR: invalid FR data passed';
    const NO_DEFAULT_FR_INFO: felt252 = 'FR: default FR info not set';
    const INVALID_TRANSFER: felt252 = 'FR: invalid transfer';
    const ZERO_ADDRESS: felt252 = 'FR: zero address';
    const ALREADY_LISTED: felt252 = 'FR: token already listed';
    const INSUFFICIENT_FUNDS: felt252 = 'FR: insufficient funds';
    const INVALID_GENERATIONS: felt252 = 'FR: generations must be > 0';
    const INVALID_PERCENT: felt252 = 'FR: percent must be > 0 <= 1e18';
    const INVALID_RATIO: felt252 = 'FR: ratio must be > 0';
    const UNAUTHORIZED_OPERATOR: felt252 = 'FR: unauthorized operator';
    const INVALID_ARRAY_LENGTH: felt252 = 'FR: invalid array length';
    const NOT_IMPLEMENTED: felt252 = 'FR: function not implemented';
    const INVALID_RECIPIENT: felt252 = 'FR: invalid recipient';
    const TOKEN_ALREADY_MINTED: felt252 = 'FR: token already minted';
    const CONTRACT_PAUSED: felt252 = 'FR: contract paused';

    const MATH_ERROR: felt252 = 'FR: math operation failed';
    const ARRAY_OOB: felt252 = 'FR: array out of bounds';
    const STORAGE_ERROR: felt252 = 'FR: storage operation failed';
}
