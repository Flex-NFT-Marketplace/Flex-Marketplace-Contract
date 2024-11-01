## Objective:

Explore and implement an experimental feature that enables NFT fractionalization, allowing multiple users to own fractions of a single NFT.

## Implementation Details:

- The design and implementation approach are at the discretion of the assignee.
- Consider various methods for fractionalization (e.g., ERC-20 token wrappers, smart contract adjustments, etc.).
- Ensure compatibility with existing NFT standards and platforms.

### What you need to know about Fractional NFTs:
- A fractionalized NFT is an NFT divided into multiple pieces. 
- It lowers the barrier of entry, as the NFT fractions cost less than the full token.
- An NFT owner can fractionalize a token even if they aren't the token's creator.
- The original NFT gets locked in a smart contract, which creates a predetermined number of fungible tokens, each representing a piece of the NFT.
- In some ways, fractionalized NFTs more closely resemble a cryptocurrency than an NFT.

Pros 
- Increased accessibility and affordability for investors
- Higher liquidity for NFT owners. 
- Potentially increases the NFT's value and exposure for creators.

Cons
- Malicious entities sometimes trick investors into thinking they are buying partial ownership of a popular NFT
- Reduces original owner’s decision-making power.
- Reselling the full NFT requires a buyback auction, where the original owner could lose the asset if outbid.

## Research Fractionalization Methods

### The process of NFT fractionalization in detail:

- To fractionalize an NFT, it must first be secured in a smart contract that breaks this ERC-721 or ERC-1155 token into several smaller parts, each representing an individual ERC-20 token.
- Each ERC-20 token represents partial ownership of the NFT. After the owner of the NFT sells it, holders of the ERC-20 tokens can redeem their tokens for their share of the money received from the sale.
- From deciding on the number of ERC-20 tokens to be created to fixing each token’s price, the owner of the NFT makes all major decisions regarding the fractionalization process.
- An open sale is then organized for the fractional shares at a fixed price for a set period or until they are sold out.


### Let's take a Look at Fractional.art

Fractional.art is a decentralized protocol that enables NFT holders to fractionalize tokens individually or on a pooled basis.

As the first step of the fractionalization process, an NFT owner needs to lock their token up in something called a “vault.” To create a vault, the user needs the following information: ERC721VaultFactory#mintname.

Vaults, powered by smart contracts, take custody of users’ NFTs and lock them up until further action is taken. You can lock a single token or a collection of tokens in your vault.

The next step involves setting the parameters of fractionalization for your token(s), such as deciding the number of fractional shares to be issued. Once done, you must transfer the custody of the NFT(s) to the vault, which, in turn, will give you 100% fractional shares of the locked-up NFT(s).


### Define Fractional Ownership Logic
1. **Token Supply**: Set the number of fungible tokens representing fractional ownership.
2. **Ownership Rights**: Define the rights of fractional owners, including voting rights on major decisions (e.g., sale of the NFT).
3. **Resale Mechanism**: Allow a buyback mechanism to resell the original NFT or facilitate buyouts by fractional owners.

### Implement a Fractional Ownership Contract
**Overview**

This Cairo contract enables the fractional ownership of an NFT by locking it in a contract and issuing fractions as tokens. Fraction holders can collectively decide on actions, such as selling the NFT.

**Key Components**
- **NFT Locking**: The contract holds custody of an NFT for fractional ownership.
- **Fractional Tokens**: Represent fractions of the NFT and can be transferred among users.
- **Buyout Mechanism**: Fraction holders can initiate a buyout and receive proceeds if a buyer pays the set price.

```
#[starknet::contract]
```


### Documentation and Compatibility Checks