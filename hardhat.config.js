require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.24",
  networks: {
    acc: {
      url: "http://localhost:8545",  // Local ACC fork RPC
      chainId: 2330,
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"]  // Hardhat test PK
    },
    hardhat: {
      chainId: 31337  // Local testing
    }
  }
};
