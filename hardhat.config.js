require("@matterlabs/hardhat-zksync-solc");
require("@nomiclabs/hardhat-ethers");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  zksolc: {
    version: "1.3.9",
    compilerSource: "binary",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  networks: {
    hardhat:{
      
    },
    zksync_testnet: {
      url: "https://zksync2-testnet.zksync.dev",
      ethNetwork: "goerli",
      chainId: 280,
      zksync: true,
    },
    zksync_mainnet: {
      url: "https://zksync2-mainnet.zksync.io/",
      ethNetwork: "mainnet",
      chainId: 324,
      zksync: true,
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.17",
    defaultNetwork: 'sepolia',
    paths: {
      sources: "./contracts",  
      cache: "./cache-zk",
      artifacts: "./artifacts-zk"
    },
    networks: {
       hardhat: {},
       sepolia: {
         url: 'https://rpc.ankr.com/eth_sepolia',
         accounts: [`0x${process.env.PRIVATE_KEY}`]
       }
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
