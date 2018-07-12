var CryptoPlanets = artifacts.require('CryptoPlanets.sol');

contract('CryptoPlanets', function(accounts) {
  var helpfulFunctions = require('./CryptoPlanetsUtils')(CryptoPlanets, accounts);
  var hfn = Object.keys(helpfulFunctions);
  for (var i = 0; i < hfn.length; i++) {
    global[hfn[i]] = helpfulFunctions[hfn[i]];
  }

  checkTotalSupply(0);

  for (x = 0; x < 10; x++) {
    checkPlanetCreation('Planet-' + x);
  }

  checkTotalSupply(10);
})