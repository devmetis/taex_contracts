//npx hardhat ignition deploy ./ignition/modules/TaexNFT1155.js --network sepolia
//npx hardhat ignition deploy ./ignition/modules/TaexNFT1155.js --network sepolia --verify
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { saleNFT } = require("../../constants");
require("dotenv").config();

const network = process.env.NETWORK;

const baseURI = "";
const primaryPrice = BigInt("100000000000000000"); // 0.1ETH

module.exports = buildModule("TaexNFT1155_Module", (m) => {
  const nft = m.contract("TaexNFT1155", [
    baseURI,
    primaryPrice,
    saleNFT[network]
  ]);
  return { nft };
});
