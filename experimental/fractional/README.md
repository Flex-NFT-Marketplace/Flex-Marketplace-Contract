# Fractional NFT
NFT fractionalization is an implementation that enables fractional ownership of an asset (NFT) where the cost of an asset is split between multiple individuals who also shares the ownership of the asset.

## How the Smart Contract Works
To achieve NFT fractionalization, we have to make use of an ERC20 token which will serve as the fractions for the NFT. Anyone that holds the ERC20 token that is attached to an NFT with a given id, automatically holds a fraction of the NFT, depending on how many ERC20 tokens they hold. <br />

With the ERC20 tokens, holders can claim a fraction of the value of the NFT after it has been sold.

### FractionalNFT Smart Contract: `src/fractional_nft.cairo`
- The `FractionalNFT` contract will take in the `id` of the NFT to be fractionalized and also the NFT will be transferred into the `FractionalNFT` contract when the `initialized()` function is called. <br />

### 

- The `initialized()` function takes in `nft_collection`, `accepted_purchase_token`, `token_id` and `amount` as arguments:<br />
- `nft_collection` : This is the address of the NFT smart contract to be fractionalize <br />
- `accepted_purchase_token`: The token to be accepted as payment for purchase of the NFT whose id was transferred to the smart contract.<br />
- `token_id`: This is the NFT token id of the NFT that will transferred into the contract and fractionalized.<br />
- `amount`: This is the amount of ERC20 token to be minted, which will be the fractions of the NFT whose id was passed in.<br />

### 

- The `put_for_sell()` puts the NFT in the `FractionalNFT` contract for sell passing in the `price` for the NFT.<br />

- The `purchase()` function is used to purchase the NFT from the `FractionalNFT` contract at a price that was set. <br />

- The `redeem()` function is used to redeem the value after the NFT has been sold. The redeemed value sends value to the redeemer based on the amount of the FractionalNFT ERC20 token that they hold. This ERC20 token is what is used as the shares, indication how much of a fraction on the NFT a user owns. The ERC20 tokens are burnt from the redeemer's account when they redeem their shared value/reward, to prevent them from redeeming more than once with the same ERC20 tokens.

### FlexNFT Smart Contract: `src/mocks/flex_nft.cairo`
The `FlexNFT` smart contract is a mock ERC721 contract implemented using Openzeppelin component. It is a representation of an NFT which will be used for testing the `FractionalNFT` contract.

### Summary
For an NFT to be fractionalized, an ERC20 token is needed, to serve as the fractions of a single NFT item whose ID is given to the `FractionalNFT` smart contract.