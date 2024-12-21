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


#[starknet::interface]
pub trait IERC6105CollectionOffer<TState> {
    /// @notice Create or update an offer for the collection
    /// @dev `salePrice` MUST NOT be set to zero
    /// @param amount - the amount the offerer wants to buy at `salePrice` per token
    /// @param salePrice - the price of each token is being offered for the collection
    /// @param expires - UNIX timestamp, the offer could be accepted before expires
    /// @param supportedToken - contract addresses of supported token
    ///                         Buyer wants to purchase items with supported token
    /// Requirements:
    /// - The caller must have enough supported tokens, and has approved the contract a sufficient
    /// amount - `salePrice` must not be zero
    /// - `amount` must not be zero
    /// - `expires` must be valid
    /// - Must emit an {UpdateCollectionOffer} event
    fn make_collection_offer(
        ref self: TState,
        amount: u256,
        sale_price: u256,
        expires: u64,
        supported_token: ContractAddress
    );

    /// @notice Accepts collection offer and transfers the token to the buyer
    /// @dev `salePrice` and `supportedToken` must match the expected purchase price and token to
    /// prevent front-running attacks
    ///      When the trading is completed, the `amount` of NFTs the buyer wants to purchase needs
    ///      to be reduced by 1
    /// @param tokenId - identifier of the token being offered
    /// @param salePrice - the price the token is being offered for
    /// @param supportedToken - contract addresses of supported token
    /// @param buyer - address of who wants to buy the token
    /// Requirements:
    /// - `tokenId` must exist and and be offered for
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - Must emit a {Purchased} event
    fn accept_collection_offer(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        supported_token: ContractAddress,
        buyer: ContractAddress
    );

    /// @notice Accepts collection offer and transfers the token to the buyer
    /// @dev `salePrice` and `supportedToken` must match the expected purchase price and token to
    /// prevent front-running attacks
    ///      When the trading is completed, the `amount` of NFTs the buyer wants to purchase needs
    ///      to be reduced by 1
    /// @param tokenId - identifier of the token being offered
    /// @param salePrice - the price the token is being offered for
    /// @param supportedToken - contract addresses of supported token
    /// @param buyer - address of who wants to buy the token
    /// @param benchmarkPrice - additional price parameter, may be used when calculating royalties
    /// Requirements:
    /// - `tokenId` must exist and and be offered for
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - Must emit a {Purchased} event
    fn accept_collection_offer_with_benchmark(
        ref self: TState,
        token_id: u256,
        sale_price: u256,
        supported_token: ContractAddress,
        buyer: ContractAddress,
        benchmark_price: u256
    );

    /// @notice Removes the offer for the collection
    /// Requirements:
    /// - Caller must be the offerer
    /// - Must emit an {UpdateCollectionOffer} event
    fn cancel_collection_offer(ref self: TState);

    /// @notice Returns the offer for `tokenId` maked by `buyer`
    /// @dev The zero amount indicates there is no offer
    ///      The zero sale price indicates there is no offer
    ///      The zero expires indicates that there is no offer
    /// @param buyer address of who wants to buy the token
    /// @return the specified offer (amount, sale price, expires, supported token)
    fn get_collection_offer(
        self: @TState, buyer: ContractAddress
    ) -> (u256, u256, u64, ContractAddress);
}

#[starknet::interface]
pub trait IERC6105ItemOffer<TState> {
    /// @notice Create or update an offer for `tokenId`
    /// @dev `salePrice` MUST NOT be set to zero
    /// @param tokenId - identifier of the token being offered
    /// @param salePrice - the price the token is being offered for
    /// @param expires - UNIX timestamp, the offer could be accepted before expires
    /// @param supportedToken - contract addresses of supported token
    ///                         Buyer wants to purchase item with supported token
    /// Requirements:
    /// - `tokenId` must exist
    /// - The caller must have enough supported tokens, and has approved the contract a sufficient amount
    /// - `salePrice` must not be zero
    /// - `expires` must be valid
    /// - Must emit an {UpdateItemOffer} event.
    fn make_item_offer(ref self: TState, token_id: u256, sale_price: u256, expires: u64, supported_token: ContractAddress);

    /// @notice Remove the offer for `tokenId`
    /// @param tokenId - identifier of the token being canceled offer
    /// Requirements:
    /// - `tokenId` must exist and be offered for
    /// - Caller must be the offerer
    /// - Must emit an {UpdateItemOffer} event
    fn cancel_item_offer(ref self: TState, token_id: u256);

    /// @notice Accept offer and transfer the token to the buyer
    /// @dev `salePrice` and `supportedToken` must match the expected purchase price and token to prevent front-running attacks
    ///      When the trading is completed, the offer infomation needs to be removed
    /// @param tokenId - identifier of the token being offered
    /// @param salePrice - the price the token is being offered for
    /// @param supportedToken - contract addresses of supported token
    /// @param buyer - address of who wants to buy the token
    /// Requirements:
    /// - `tokenId` must exist and be offered for
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - Must emit a {Purchased} event
    fn accept_item_offer(ref self: TState, token_id: u256, sale_price: u256, supported_token: ContractAddress, buyer: ContractAddress);

    /// @notice Accepts offer and transfers the token to the buyer
    /// @dev `salePrice` and `supportedToken` must match the expected purchase price and token to prevent front-running attacks
    ///      When the trading is completed, the offer infomation needs to be removed
    /// @param tokenId - identifier of the token being offered
    /// @param salePrice - the price the token is being offered for
    /// @param supportedToken - contract addresses of supported token
    /// @param buyer - address of who wants to buy the token
    /// @param benchmarkPrice - additional price parameter, may be used when calculating royalties
    /// Requirements:
    /// - `tokenId` must exist and be offered for
    /// - Caller must be owner, authorised operators or approved address of the token
    /// - Must emit a {Purchased} event
    fn accept_item_offer_with_benchmark(ref self: TState, token_id: u256, sale_price: u256, supported_token: ContractAddress, buyer: ContractAddress, benchmark_price: u256);

    /// @notice Return the offer for `tokenId` maked by `buyer`
    /// @dev The zero sale price indicates there is no offer
    ///      The zero expires indicates that there is no offer
    /// @param tokenId identifier of the token being queried
    /// @param buyer address of who wants to buy the token
    /// @return the specified offer (sale price, expires, supported token)
    fn get_item_offer(self: @TState, token_id: u256, buyer: ContractAddress) -> (u256, u64, ContractAddress);
}