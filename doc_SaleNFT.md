
---

### **Contract: `SaleNFT`**
The `SaleNFT` contract allows the sale of NFTs through two mechanisms:
1. **Primary Sale**: New NFTs are minted and sold directly to buyers.
2. **Secondary Sale**: NFTs that are already owned can be sold to new buyers.

It supports a fee mechanism for secondary sales, where a percentage of the sale price is deducted as a platform fee.

---

### **Key Components**

#### **State Variables:**
1. **`feeSecondarySale` (uint256)**:
   - Represents the fee for secondary sales in percentage terms (multiplied by 100). For example, a 1.5% fee would be stored as `150`.

---

### **Modifiers:**
1. **`isNotZeroAddress(address _address)`**:
   - Ensures that the provided address is not a zero address (`0x0`). If a zero address is passed, the transaction will revert with an error message: `"SaleNFT: zero address"`.

2. **`isNotZero(uint256 amount)`**:
   - Ensures that the provided amount is greater than zero. If not, the transaction will revert with an error message: `"SaleNFT: zero amount"`.

---

### **Events:**
1. **`PrimarySale`**:
   - Emitted after a successful primary sale.
   - Parameters:
     - `nft`: The address of the NFT contract.
     - `tokenId`: The token ID of the NFT minted.
     - `to`: The address of the buyer.

2. **`PrimarySaleByAdmin`**:
   - Emitted when the owner mints and transfers an NFT on behalf of a user.
   - Parameters:
     - `nft`: The address of the NFT contract.
     - `tokenId`: The token ID of the NFT minted.
     - `to`: The address of the buyer.

3. **`SecondarySale`**:
   - Emitted after a successful secondary sale.
   - Parameters:
     - `nft`: The address of the NFT contract.
     - `tokenId`: The token ID of the NFT transferred.
     - `to`: The address of the buyer.

4. **`ETHWithdrawn`**:
   - Emitted when the contract owner withdraws ETH from the contract.
   - Parameters:
     - `to`: The address of the recipient.
     - `amount`: The amount of ETH withdrawn.

---

### **Constructor:**
```solidity
constructor(uint256 _feeSecondarySale)
```
- Initializes the contract and sets the `feeSecondarySale` variable.
- Requires `_feeSecondarySale` to be non-zero.

---

### **Functions:**

#### **1. `primarySale(address _taexNFT)`**
```solidity
function primarySale(address _taexNFT) external payable returns (uint256)
```
- Allows users to purchase a newly minted NFT.
- The price is determined by the `primaryPrice()` function of the `_taexNFT` contract.
- If the amount of ETH sent (`msg.value`) exceeds the price, the excess is refunded to the buyer.
- Emits the `PrimarySale` event.

##### **Key Logic**:
1. Calls `primaryPrice()` from the `_taexNFT` contract to get the primary price.
2. Mints the NFT using `mint()` from the `_taexNFT` contract.
3. Refunds any excess ETH to the buyer.
4. Emits the `PrimarySale` event.

---

#### **2. `primarySaleByAdmin(address _taexNFT, address to)`**
```solidity
function primarySaleByAdmin(address _taexNFT, address to) external onlyOwner returns (uint256)
```
- Allows the owner (admin) to mint and transfer a new NFT to a specified address.
- Regarding to your business, it will be called when a buyer purchase with Fiat(e.g., using Moonpay)
- Emits the `PrimarySaleByAdmin` event.

##### **Key Logic**:
1. Only callable by the owner.
2. Calls the `mint()` function from the `_taexNFT` contract.
3. Emits the `PrimarySaleByAdmin` event.

---

#### **3. `secondarySale(address _taexNFT, uint256 _tokenId)`**
```solidity
function secondarySale(address _taexNFT, uint256 _tokenId) external payable nonReentrant
```
- Facilitates the secondary sale of an NFT.
- The seller (current owner) receives the sale price minus the fee, which is deducted as per the `feeSecondarySale` rate.
- Uses the `transferFrom` method from the `_taexNFT` contract to transfer the NFT to the buyer.
- If the amount of ETH sent exceeds the sale price, the excess is refunded to the buyer.
- Emits the `SecondarySale` event.

##### **Key Logic**:
1. Verifies that the NFT is listed for sale and that the seller is the owner.
2. Ensures sufficient ETH is sent to cover the price.
3. Calculates the platform fee.
4. Transfers the net amount to the seller and deducts the fee.
5. Transfers the NFT from the seller to the buyer.
6. Emits the `SecondarySale` event.

In the `secondarySale` function, after ensuring that the token is listed for sale and the buyer has sent sufficient ETH, the contract calls `ITaexNFT(_taexNFT).transferFrom(owner, msg.sender, _tokenId)` to transfer the NFT from the current owner to the buyer.

For this transfer to work, the current owner must first **approve** the contract to transfer the NFT on their behalf. This is standard practice in ERC721 (NFT) contracts where the owner must explicitly approve another address (in this case, the `SaleNFT` contract) to manage or transfer their tokens.

### Required:
Before calling the `secondarySale` function, the current owner should execute the following:
```solidity
approve(address(SaleNFT), _tokenId)
```
This approves the `SaleNFT` contract to transfer the specified NFT (`_tokenId`) on behalf of the current owner.

Without this approval, the `transferFrom` call in the `secondarySale` function would fail with a revert, as the contract would not have the permission to transfer the token.


#### **4. `withdrawETH(address to)`**
```solidity
function withdrawETH(address to) external onlyOwner
```
- Allows the owner to withdraw all ETH held by the contract.
- Emits the `ETHWithdrawn` event.

##### **Key Logic**:
1. Only callable by the owner.
2. Requires the contract balance to be greater than zero.
3. Transfers the entire balance to the specified address.
4. Emits the `ETHWithdrawn` event.

---

#### **5. `setFeeSecondarySale(uint256 _feePercentage)`**
```solidity
function setFeeSecondarySale(uint256 _feePercentage) external onlyOwner
```
- Allows the owner to set the fee for secondary sales.
- The fee percentage must be greater than zero.

##### **Key Logic**:
1. Only callable by the owner.
2. Updates the `feeSecondarySale` variable.

---

### **Security Features:**
1. **Non-Reentrancy**: The contract uses the `nonReentrant` modifier from OpenZeppelin’s `ReentrancyGuard` to prevent reentrancy attacks during the secondary sale process.
2. **Ownership Control**: Functions that deal with sensitive actions such as setting fees and withdrawing funds are restricted to the contract owner.
3. **Input Validation**: Modifiers such as `isNotZeroAddress` and `isNotZero` ensure that important parameters are not zero, preventing common input errors.
