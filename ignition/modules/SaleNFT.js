//npx hardhat ignition deploy ./ignition/modules/SaleNFT.js --network sepolia
//npx hardhat ignition deploy ./ignition/modules/SaleNFT.js --network sepolia --verify
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
require("dotenv").config();

const network = process.env.NETWORK;
const artistTreasuryAddress = "0x400BE6d7211a00c5eF5734B8ddefeFC18c25F0d5";
const taexTreasuryAddress = "0xc6773ed52DAB833E8f5ac89572dF2672F5B8d4ad";

module.exports = buildModule("SaleNFT_Module", (m) => {
  const saleNFT = m.contract("SaleNFT", [
    artistTreasuryAddress,
    taexTreasuryAddress,
  ]);
  return { saleNFT };
});
