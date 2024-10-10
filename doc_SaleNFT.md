### SaleNFT

**Overview**

The `SaleNFT` contract facilitates the primary and secondary sale of NFTs. It interacts with an NFT contract (ITaexNFT) to handle transactions for both initial sales and resales. This contract ensures that funds are distributed correctly among artist, Taex treasury, and the token seller. Key features include primary and secondary sales, secure fund transfers, and configurable treasury addresses.

**Key Functionalities**

1. **Primary Sale**
   - Facilitates the initial sale of an NFT.
   - Requires the buyer to pay at least the specified price.
   - The purchase price is split between the artist treasury and the Taex treasury based on a predetermined fee.
   - Once the transaction is complete, the NFT is transferred from the owner to the buyer.
   - If excess funds are sent, they are refunded to the buyer.

      For this transfer to work, the current owner must first **approve** the contract to transfer the NFT on their behalf. This is standard practice in ERC721 (NFT) contracts where the owner must explicitly approve another address (in this case, the `SaleNFT` contract) to manage or transfer their tokens.

2. **Secondary Sale**
   - Facilitates the resale of an NFT.
   - Checks if the NFT is listed for sale and verifies ownership.
   - The price is split among the artist treasury, Taex treasury, and the current owner of the NFT.
   - The NFT is transferred to the buyer, and any excess funds are refunded.

      In the `secondarySale` function, after ensuring that the token is listed for sale and the buyer has sent sufficient ETH, the contract calls `ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId)` to transfer the NFT from the current owner to the buyer.

      For this transfer to work, the current owner must first **approve** the contract to transfer the NFT on their behalf. This is standard practice in ERC721 (NFT) contracts where the owner must explicitly approve another address (in this case, the `SaleNFT` contract) to manage or transfer their tokens.

3. **Withdrawal of ETH**
   - The contract owner can withdraw any remaining ETH balance from the contract.
   - Prevents withdrawal to a zero address.

4. **Set Treasury Addresses**
   - Allows the owner to set or update the artist and Taex treasury addresses.

**Modifiers**

- **isNotZeroAddress**: Ensures that no functions receive a zero address.
- **isNotZero**: Ensures numerical values are greater than zero.

**Events**

- **PrimarySale**: Emitted when an NFT is successfully sold in a primary sale.
- **SecondarySale**: Emitted when an NFT is sold in a secondary sale.
- **ETHWithdrawn**: Emitted when the owner successfully withdraws ETH from the contract.

**Security Considerations**

- **Reentrancy Protection**: The `nonReentrant` modifier is used for primary and secondary sale functions to prevent reentrancy attacks.
- **Zero Address Checks**: Both the artist and Taex treasury addresses are validated to prevent transferring funds to an invalid address.
- **Payment Splitting**: Correct allocation of funds is enforced using the percentages specified by the NFT contract.


