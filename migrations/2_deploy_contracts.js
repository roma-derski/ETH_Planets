var CryptoPlanets = artifacts.require('CryptoPlanets.sol');

module.exports = function(deployer) {
    deployer.deploy(CryptoPlanets);
};