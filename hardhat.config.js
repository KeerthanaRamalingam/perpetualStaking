require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require("dotenv").config()
require("@nomiclabs/hardhat-etherscan");


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const MAINNET_RPC_URL = "https://matic-mainnet.chainstacklabs.com"
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;

const MUMBAI_RPC_URL = "https://matic-mumbai.chainstacklabs.com";
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY;

const BSCTESTNET_RPC_URL = "https://data-seed-prebsc-2-s1.binance.org:8545";
const BSCTESTNET_PRIVATE_KEY = process.env.BSCTESTNET_PRIVATE_KEY;


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        },
      },
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        },
      }
    ]
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://polygon-mumbai.g.alchemy.com/v2/nnwB44ZrYOrWD_d1DApJk68k20i6Rakh`,
      }
    },
    local: {
      url: 'http://127.0.0.1:8545/'
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: [MAINNET_PRIVATE_KEY],
      saveDeployments: true,
    },
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [MUMBAI_PRIVATE_KEY],
      gasPrice: 35000000000,
      saveDeployments: true,
    },
    bsctestnet: {
      url: BSCTESTNET_RPC_URL,
      // chainId: 97,
      gasPrice: 35000000000,
      accounts: [BSCTESTNET_PRIVATE_KEY],
      saveDeployments: true,

    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: "2JTDAGM8YJJ7J89IQQ29BFFCG49PV6FXA9"
  },
};
