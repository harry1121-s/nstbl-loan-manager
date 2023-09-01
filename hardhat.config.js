require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
// require("@nomicfoundation/hardhat-chai-matchers");
const CONFIG = require("./credentials.json");


module.exports = {
  solidity: "0.8.21",
  networks:{
    goerli: {
      url : CONFIG["GOERLI"]["URL"],
      accounts : [CONFIG["GOERLI"]["PKEY"]]
    },
    mainnet: {
        url : CONFIG["MAINNET"]["URL"],
        accounts : [CONFIG["MAINNET"]["PKEY"]]
      }
  },
  etherscan :{
    apiKey: "4VE2P5D5YUD5EFUIM6W8BN95PYFPUQBZ5Z"
  }
};
