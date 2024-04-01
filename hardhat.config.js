require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  defaultNetwork: "base",
  networks: {
    hardhat: {
    },
    base: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  solidity: "0.8.24",
  etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
