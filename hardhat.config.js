require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true
    },
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545'
    },
    hardhat: {
      // Configuration specific to the Hardhat network, if necessary.
    },
  },
  paths: {
    sources: "./contracts",  
    cache: "./cache",
    artifacts: "./artifacts"
  },
};