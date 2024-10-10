### TaexNFT1155

**Overview**

The `TaexNFT1155` contract is an ERC-1155 compliant smart contract that allows minting, managing, and trading NFTs on the Ethereum blockchain. It extends OpenZeppelin's `ERC1155`, `Ownable`, and `ReentrancyGuard` contracts, adhering to established standards for token management and security. This contract includes features such as minting, listing for sale, unlisting, and price adjustments. It also includes support for primary and secondary sale fees, enabling artist and Taex treasury fee management.

**Key Functionalities**

1. **Minting**
   - The contract owner can mint new NFTs to specified addresses using the `mint` function, which sets the primary price and sale fees.
   - The `mintWithSpecifiedFee` function allows minting with custom artist and Taex fee configurations.
   - Ownership of tokens is tracked using the `_owners` mapping.

2. **Sale Management**
   - **Listing for Sale**: Token owners can list their tokens for sale at a specified price using the `listForSale` function.
   - **Unlisting from Sale**: Token owners can unlist their tokens from being for sale using the `unlistFromSale` function.
   - **Adjusting Price**: Token owners can change the sale price of listed tokens using the `adjustPrice` function.

3. **Base URI Management**
   - The contract owner can modify the base URI for token metadata using the `setBaseURI` function.

4. **Primary Price Setting**
   - The owner can set or modify the primary price for newly minted tokens using the `setPrimaryPrice` function.

5. **Token Transfers**
   - Token transfers can be performed using `transferFrom`, which facilitates safe transfers of tokens between users.

**Modifiers**

- **isNotZeroAddress**: Prevents functions from accepting a zero address parameter to avoid critical errors.
- **isNotZero**: Ensures numeric values such as prices are greater than zero.

**Events**

- **TokenListedForSale**: Emitted when a token is successfully listed for sale.
- **TokenUnListedForSale**: Emitted when a token is unlisted from sale.
- **TokenPriceAdjusted**: Emitted when the price of a token is updated.
- **TokenMinted**: Emitted when a new token is minted and assigned to a user.

**Security Considerations**

- **Reentrancy Protection**: The `nonReentrant` modifier is applied to mint functions to prevent reentrancy vulnerabilities.
- **Access Control**: Critical functions like `mint`, `setBaseURI`, and `setPrimaryPrice` are restricted to the contract owner, ensuring only authorized users have control over important contract aspects.
- **Zero Address Checks**: The use of `isNotZeroAddress` helps prevent unintended transfers or minting to the zero address, avoiding potential token loss.
- **Token Ownership**: The `_owners` mapping keeps track of token ownership, which is crucial for validating sale operations.
