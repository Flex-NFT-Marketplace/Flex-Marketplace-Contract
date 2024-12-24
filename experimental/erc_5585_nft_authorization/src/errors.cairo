pub mod Errors {
    pub const INVALID_TOKEN_ID: felt252 = 'Invalid token ID';
    pub const UNAUTHORIZED: felt252 = 'Not authorized';
    pub const ALREADY_MINTED: felt252 = 'Already minted';
    pub const WRONG_OWNER: felt252 = 'Wrong owner';
    pub const INVALID_APPROVAL: felt252 = 'Invalid approval';
    pub const INVALID_OPERATOR: felt252 = 'Invalid operator';
    pub const ZERO_ADDRESS: felt252 = 'Zero address';

    // Authorization specific errors
    pub const INVALID_RIGHTS: felt252 = 'Invalid rights';
    pub const EXPIRED_AUTH: felt252 = 'Auth expired';
    pub const INVALID_USER: felt252 = 'Invalid user';
    pub const USER_LIMIT: felt252 = 'User limit exceeded';
    pub const RESET_DISABLED: felt252 = 'Reset disabled';
}
