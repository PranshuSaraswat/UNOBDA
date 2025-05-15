module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,  // Default Ganache GUI port (use 8545 if using Ganache CLI)
      network_id: "*"
    }
  },
  compilers: {
    solc: {
      version: "0.8.17",    // Use a specific 0.8.x version
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};