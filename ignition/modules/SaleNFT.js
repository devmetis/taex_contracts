//npx hardhat ignition deploy ./ignition/modules/SaleNFT.js --network sepolia
//npx hardhat ignition deploy ./ignition/modules/SaleNFT.js --network sepolia --verify
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { feeSecondarySale } = require("../../constants");
require("dotenv").config();

const network = process.env.NETWORK;

module.exports = buildModule("SaleNFT_Module", (m) => {
  const saleNFT = m.contract("SaleNFT", [feeSecondarySale[network]]);
  return { saleNFT };
});
