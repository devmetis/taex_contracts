require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;

module.exports = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
    mainnetETH: {
      url: MAINNET_RPC_URL,
      chainId: 1,
      gasPrice: 10000000000, // 10 Gwei
      accounts: [MAINNET_PRIVATE_KEY],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};