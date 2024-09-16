### Deployment Instructions for `SaleNFT` and `TaexNFT` Contracts

In this process, we will deploy the `SaleNFT` contract, and ensure that the `SaleNFT` contract becomes the designated minter for all instances of `TaexNFT` collections.

---

### Deploy on Testnet Ethereum Sepolia

- Make sure that `NETWORK` on env file is 'testnet' like following.

    `NETWORK="testnet"`


### Deploy on Ethereum Mainnet

- Make sure that `NETWORK` on env file is 'mainnet' like following.

    `NETWORK="mainnet"`

    You also make sure that all of configs is correct.
    ```
    MAINNET_RPC_URL=
    MAINNET_PRIVATE_KEY=
    ETHERSCAN_API_KEY=
    ```

### Step-by-Step Guide:

#### 1. **Deploy the `SaleNFT` Contract**
   - Deploy the `SaleNFT` contract first. When deploying, you need to set the secondary sale fee (`feeSecondarySale`) in basis points (e.g., 150 for 1.5%).
   - Example deployment:
     ``` Run
     npx hardhat ignition deploy ./ignition/modules/SaleNFT.js --network sepolia
     ```


#### 2. **Set `SaleNFT` as Minter for Each `TaexNFT` Collection**
   - For every instance of a `TaexNFT` collection, you need to configure the `SaleNFT` contract as the minter. This ensures that all new NFTs minted within the `TaexNFT` collections will go through the `SaleNFT` contract.
   
   - Please input saleNFT contract address in `constants.js` file:
     ```
     saleNFT: {
      testnet: "0x2B3774dd95b5DAd93905CC75Eb0B4426A8437B5F",
      mainnet: "", <- here
     },
     ```

   - Write the corresponding information for a collection in `./ignition/TeaxNFT.js` file:
     ```
      const NftName = "TAEX NFT";
      const NftSymbol = "TaexNFT";
      const baseURI = "";
      const primaryPrice = BigInt("100000000000000000"); // 0.1ETH

     ```


### Summary:
1. **Deploy the `SaleNFT` contract** with a specific secondary sale fee.
2. **Set the `SaleNFT` contract as the minter** for each `TaexNFT` collection.
3. **Ensure proper approval** for secondary sales by the current NFT owner.
