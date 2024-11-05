pub const IERC5643_ID: felt252 = 0x8c65f84d;

#[starknet::interface]
pub trait IERC5643<TState> {
    /// @notice Renews the subscription to an NFT
    /// Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to renew the subscription for
    /// @param duration The number of seconds to extend a subscription for
    fn renew_subscription(ref self: TState, token_id: u256, duration: u64);
    /// @notice Cancels the subscription of an NFT
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to cancel the subscription for
    fn cancel_subscription(ref self: TState, token_id: u256);
    /// @notice Gets the expiration date of a subscription
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the expiration date of
    /// @return The expiration date of the subscription
    fn expires_at(self: @TState, token_id: u256) -> u64;
    /// @notice Determines whether a subscription can be renewed
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to get the expiration date of
    /// @return The renewability of a the subscription
    fn is_renewable(self: @TState, token_id: u256) -> bool;
}
