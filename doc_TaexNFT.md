
---

### **Contract: `TaexNFT`**

This contract is an ERC721 (NFT) token implementation with additional features like listing for sale, price adjustment, minting by a minter role (will be saleNFT contract), and secure functions with reentrancy protection. It also allows the contract owner to change the base URI and set a primary sale price for minting.

---

### **Constructor**
```solidity
constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _primaryPrice,
    address _minter
)
```
- **Purpose**: Initializes the contract with the token name, symbol, base URI, primary sale price and minter address.
- **Parameters**:
  - `_name`: Name of the NFT collection.
  - `_symbol`: Symbol for the NFTs (e.g., “1PX”).
  - `_uri`: The base URI used for metadata storage.
  - `_primaryPrice`: The initial price for primary NFT sales.
  - `_minter`: The address of the SaleNFT contract that will mint the NFTs.
- **Modifiers**: Uses `isNotZero` to ensure that `_primaryPrice` is not zero.

---

### **Functions**

1. **`ownerOfToken(uint256 _tokenId)`**
   ```solidity
   function ownerOfToken(uint256 _tokenId) external view returns (address)
   ```
   - **Purpose**: Returns the owner of a specific NFT by its token ID.
   - **Parameters**: 
     - `_tokenId`: The ID of the token you want to check.
   - **Returns**: The address of the owner of the specified token.

---

2. **`listForSale(uint256 _tokenId, uint256 _price)`**
   ```solidity
   function listForSale(uint256 _tokenId, uint256 _price) external
   ```
   - **Purpose**: Allows the owner of an NFT to list it for sale at a specified price.
   - **Parameters**: 
     - `_tokenId`: The ID of the token to list for sale.
     - `_price`: The listing price of the token.
   - **Event**: Emits `TokenListedForSale` when a token is successfully listed.

---

3. **`unlistFromSale(uint256 _tokenId)`**
   ```solidity
   function unlistFromSale(uint256 _tokenId) external
   ```
   - **Purpose**: Allows the owner of an NFT to remove it from being listed for sale.
   - **Parameters**: 
     - `_tokenId`: The ID of the token to unlist.
   - **Event**: Emits `TokenUnListedForSale` when a token is successfully unlisted.

---

4. **`adjustPrice(uint256 _tokenId, uint256 _price)`**
   ```solidity
   function adjustPrice(uint256 _tokenId, uint256 _price) external
   ```
   - **Purpose**: Allows the owner to adjust the price of a listed NFT.
   - **Parameters**: 
     - `_tokenId`: The ID of the token whose price is being adjusted.
     - `_price`: The new price for the token.
   - **Event**: Emits `TokenPriceAdjusted` when the price is successfully changed.

---

5. **`setBaseURI(string calldata newBaseUri)`**
   ```solidity
   function setBaseURI(string calldata newBaseUri) external onlyOwner
   ```
   - **Purpose**: Allows the owner of the contract to set a new base URI for all tokens' metadata.
   - **Parameters**: 
     - `newBaseUri`: The new URI that will be used as the base for all token metadata.

---

6. **`setPrimaryPrice(uint256 _price)`**
   ```solidity
   function setPrimaryPrice(uint256 _price) external isNotZero(_price) onlyOwner
   ```
   - **Purpose**: Allows the contract owner to set a new primary price for minting new tokens.
   - **Parameters**: 
     - `_price`: The new primary sale price.
   - **Modifiers**: Uses `isNotZero` to ensure that the price is greater than zero.

---

7. **`mint(address to)`**
   ```solidity
   function mint(address to) external onlyMinter nonReentrant isNotZeroAddress(to) returns (uint256)
   ```
   - **Purpose**: Mints a new token and assigns it to the specified address.
   - **Parameters**: 
     - `to`: The address of the new token owner.
   - **Returns**: The ID of the newly minted token.
   - **Modifiers**:
     - `onlyMinter`: Ensures that only the designated minter can call this function, that will be SaleNFT contract.
     - `nonReentrant`: Prevents reentrancy attacks.
   - **Event**: Emits `TokenMinted` upon successful minting.

---

8. **`isMinter(address account)`**
   ```solidity
   function isMinter(address account) public view isNotZeroAddress(minter) returns (bool)
   ```
   - **Purpose**: Checks if the given address is the current minter.
   - **Parameters**: 
     - `account`: The address to check.
   - **Returns**: A boolean value indicating whether the address is the current minter.

---

9. **`setMinter(address account)`**
   ```solidity
   function setMinter(address account) external onlyOwner isNotZeroAddress(account)
   ```
   - **Purpose**: Allows the contract owner to change the minter role to a new address.
   - **Parameters**: 
     - `account`: The new address to set as the minter.
   - **Modifiers**: Ensures the new minter address is not the zero address.



### **Modifiers**

1. **`isNotZeroAddress(address _address)`**
   ```solidity
   modifier isNotZeroAddress(address _address)
   ```
   - **Purpose**: Prevents function execution if the provided address is the zero address.

---

2. **`isNotZero(uint256 amount)`**
   ```solidity
   modifier isNotZero(uint256 amount)
   ```
   - **Purpose**: Prevents function execution if the provided amount is zero.

---

3. **`onlyMinter()`**
   ```solidity
   modifier onlyMinter()
   ```
   - **Purpose**: Restricts function execution to the minter address.

---

### **Events**
- **`TokenListedForSale(uint256 tokenId, uint256 price)`**: Emitted when a token is listed for sale.
- **`TokenUnListedForSale(uint256 tokenId)`**: Emitted when a token is unlisted from sale.
- **`TokenPriceAdjusted(uint256 tokenId, uint256 price)`**: Emitted when the price of a token is adjusted.
- **`TokenMinted(address indexed to, uint256 tokenId)`**: Emitted when a new token is minted.

---
