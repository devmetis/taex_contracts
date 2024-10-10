### TaexNFT

**Overview**

The `TaexNFT` contract is an ERC-721 compliant smart contract that allows minting, managing, and trading NFTs on the Ethereum blockchain. It extends the functionality of OpenZeppelin's `ERC721`, `Ownable`, and `ReentrancyGuard` contracts, making use of standard practices for security and ownership. This contract includes functions for minting NFTs, listing and unlisting them for sale, and adjusting their prices, as well as managing artist and treasury fees for primary and secondary sales.

**Key Functionalities**

1. **Minting**
   - The contract owner can mint new NFTs to specified addresses.
   - When minting, the owner can specify primary and secondary sale fees (artist and Taex treasury fees).
   - The `mint` function automatically applies the standard primary price, while `mintWithSpecifiedFee` allows for custom artist and Taex fee configuration.

2. **Sale Management**
   - **Listing for Sale**: NFT owners can list their tokens for sale at a specified price using the `listForSale` function.
   - **Unlisting from Sale**: Owners can remove their NFTs from being listed for sale using `unlistFromSale`.
   - **Adjusting Price**: The price of listed tokens can be adjusted by the owner with the `adjustPrice` function.

3. **Base URI Management**
   - The contract owner can update the base URI used for token metadata using the `setBaseURI` function.

4. **Primary Price Setting**
   - The owner can set or modify the primary sale price for newly minted tokens.

**Modifiers**

- **isNotZeroAddress**: Prevents critical functions from being executed with a zero address parameter.
- **isNotZero**: Ensures numerical values (like prices) are greater than zero.

**Events**

- **TokenListedForSale**: Emitted when a token is listed for sale.
- **TokenUnListedForSale**: Emitted when a token is unlisted from sale.
- **TokenPriceAdjusted**: Emitted when the price of a listed token is adjusted.
- **TokenMinted**: Emitted when a new token is minted.

**Security Considerations**

- **Reentrancy Protection**: The `nonReentrant` modifier is used in minting functions to prevent reentrancy attacks.
- **Access Control**: Functions like `mint`, `setBaseURI`, and `setPrimaryPrice` are restricted to the owner, ensuring control over critical aspects of the contract.
- **Zero Address Checks**: The use of `isNotZeroAddress` ensures that tokens are not accidentally minted to the zero address, avoiding potential loss of NFTs.
