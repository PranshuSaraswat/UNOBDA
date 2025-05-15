const BlockchainUNO = artifacts.require("UnoRewardGame");

module.exports = function(deployer) {
  deployer.deploy(BlockchainUNO);
};