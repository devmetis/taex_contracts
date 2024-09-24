
---

# TaexNFT1155 - ERC1155 NFT Contract

## Overview
The `TaexNFT1155` contract functions similarly to the `TaexNFT` contract, with both offering essential NFT management functionalities. However, `TaexNFT1155` is built on the **ERC1155 standard**, allowing for more flexibility in managing token types, while still maintaining the core functionality of minting and managing unique NFTs. Each token minted through this contract is treated as an NFT (Non-Fungible Token) with a unique token ID and a supply of 1.

## Key Features
- **Minting**: Only a designated minter can mint NFTs (one per token ID), just like in the `TaexNFT` contract.
- **Token Listing**: Owners can list their tokens for sale with adjustable prices.
- **URI Management**: The contract owner can set or update the base URI for token metadata.
- **Primary Price**: Admin can configure the primary price that applies to all newly minted tokens.
- **Sale Control**: Owners can list, unlist, and adjust the price of their NFTs.

## Similarities with TaexNFT
This contract offers the same core functionality as `TaexNFT`, including:
- **Minting and Sale Mechanism**: Tokens can be minted by the designated minter and listed/unlisted for sale by the token owner.
- **Price Adjustments**: Token owners can adjust the price of their tokens.
- **Ownership and Transfer**: The contract ensures strict ownership rules, and token transfers follow the ERC1155 standard, allowing flexible transfers.
- **Reentrancy Protection**: Like `TaexNFT`, `TaexNFT1155` uses reentrancy protection for sensitive operations.


## Events
- `TokenMinted`: Triggered when a new token is minted.
- `TokenListedForSale`: Triggered when a token is listed for sale.
- `TokenUnListedForSale`: Triggered when a token is unlisted from sale.
- `TokenPriceAdjusted`: Triggered when the price of a token is adjusted.

---