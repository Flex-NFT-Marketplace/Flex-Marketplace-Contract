use starknet::ContractAddress;

pub const IERC4907_ID: felt252 = 0xad092b5c;

#[starknet::interface]
pub trait IERC4907<TState> {
    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    fn setUser(ref self: TState, token_id: u256, user: ContractAddress, expires: u64);

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    fn userOf(self: @TState, token_id: u256) -> ContractAddress;

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    fn userExpires(self: @TState, token_id: u256) -> u64;
}
