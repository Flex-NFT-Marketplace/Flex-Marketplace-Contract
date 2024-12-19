use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC6105<TState> {
    /// @notice Create or update a listing for `tokenId`
    /// @dev `salePrice` MUST NOT be set to zero
    /// @param tokenId - identifier of the token being listed
    /// @param salePrice - the price the token is being sold for
    /// @param expires - UNIX timestamp, the buyer could buy the token before expires
    /// @param supportedToken - contract addresses of supported token or zero address
    ///                         The zero address indicates that the supported token is ETH
    ///                         Buyer needs to purchase item with supported token
    /// Requirements:
    /// - `tokenId` must exist
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - `salePrice` must not be zero
    /// - `expires` must be valid
    /// - Must emit an {UpdateListing} event.
    fn list_item(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress
    );

    /// @notice Create or update a listing for `tokenId` with `benchmarkPrice`
    /// @dev `salePrice` MUST NOT be set to zero
    /// @param tokenId - identifier of the token being listed
    /// @param salePrice - the price the token is being sold for
    /// @param expires - UNIX timestamp, the buyer could buy the token before expires
    /// @param supportedToken - contract addresses of supported token or zero address
    ///                         The zero address indicates that the supported token is ETH
    ///                         Buyer needs to purchase item with supported token
    /// @param benchmarkPrice - Additional price parameter, may be used when calculating royalties
    /// Requirements:
    /// - `tokenId` must exist
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - `salePrice` must not be zero
    /// - `expires` must be valid
    /// - Must emit an {UpdateListing} event.
    fn list_item_with_benchmark(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress,
        benchmark_price: u256
    );

    /// @notice Remove the listing for `tokenId`
    /// @param tokenId - identifier of the token being delisted
    /// Requirements:
    /// - `tokenId` must exist and be listed for sale
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - Must emit an {UpdateListing} event
    fn delist_item(ref self: TState, token_id: u256);

    /// @notice Buy a token and transfer it to the caller
    /// @dev `salePrice` and `supportedToken` must match the expected purchase price and token to
    /// prevent front-running attacks @param tokenId - identifier of the token being purchased
    /// @param salePrice - the price the token is being sold for
    /// @param supportedToken - contract addresses of supported token or zero address
    /// Requirements:
    /// - `tokenId` must exist and be listed for sale
    /// - `salePrice` must matches the expected purchase price to prevent front-running attacks
    /// - `supportedToken` must matches the expected purchase token to prevent front-running attacks
    /// - Caller must be able to pay the listed price for `tokenId`
    /// - Must emit a {Purchased} event
    fn buy_item(
        ref self: TState, token_id: u256, sale_price: u256, supported_token: ContractAddress
    );

    /// @notice Return the listing for `tokenId`
    /// @dev The zero sale price indicates that the token is not for sale
    ///      The zero expires indicates that the token is not for sale
    ///      The zero supported token address indicates that the supported token is ETH
    /// @param tokenId identifier of the token being queried
    /// @return the specified listing (sale price, expires, supported token, benchmark price)
    fn get_listing(self: @TState, token_id: u256) -> (u256, u64, ContractAddress, u256);
}
