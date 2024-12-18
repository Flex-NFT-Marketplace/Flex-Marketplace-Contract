use starknet::ContractAddress;

/// @dev A structure representing a listed token
///      The zero `salePrice` indicates that the token is not for sale
///      The zero `expires` indicates that the token is not for sale
/// @param salePrice - the price the token is being sold for
/// @param expires - UNIX timestamp, the buyer could buy the token before expires
/// @param supportedToken - contract addresses of supported ERC20 token or zero address
///                         The zero address indicates that the supported token is ETH
///                         Buyer needs to purchase item with supported token
/// @param historicalPrice - The price at which the seller last bought this token
#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct Listing {
    pub sale_price: u256,
    pub expires: u64,
    pub supported_token: ContractAddress,
    pub historical_price: u256
}
