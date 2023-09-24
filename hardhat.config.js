require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.4",
  networks: {
    arbitrum: {
      url: `https://arbitrum-goerli.infura.io/v3/f49ad06e883e443588485b03efd71ebb`,
      accounts: [`0x5e922d00c8b920a90531b856b3bf063381eab6971dc2c1e6263dcaab5d623c64`]
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/5848c53d43a346119abeb48f608c5b18`,
      accounts: [`0x5e922d00c8b920a90531b856b3bf063381eab6971dc2c1e6263dcaab5d623c64`]
    },
  },
};

  