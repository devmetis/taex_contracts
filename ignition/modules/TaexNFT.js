//npx hardhat ignition deploy ./ignition/modules/TaexNFT.js --network sepolia
//npx hardhat ignition deploy ./ignition/modules/TaexNFT.js --network sepolia --verify
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
require("dotenv").config();

const network = process.env.NETWORK;

const NftName = "TAEX NFT";
const NftSymbol = "TaexNFT";
const baseURI = "";
const primaryPrice = BigInt("100000000000000000"); // 0.1ETH
const primaryArtistFee = 85; // 85%
const secondaryArtistFee = 10; // 10%
const secondaryTaexFee = 10; // 10%
module.exports = buildModule("TaexNFT_Module", (m) => {
  const nft = m.contract("TaexNFT", [
    NftName,
    NftSymbol,
    baseURI,
    primaryPrice,
    primaryArtistFee,
    secondaryArtistFee,
    secondaryTaexFee,
  ]);
  return { nft };
});
