/* Main Object to manage Contract interactions */
var App = {
  contracts: {},
  // address in Ropsten Testnet:
  CryptoPlanetsAddress: '0x98bEC182520835C6c148354e4EEFf4A0b62c5C77',

  init() {
    return App.initWeb3();
  },
  
  initWeb3() {
    if (typeof web3 !== 'undefined') {
      web3 = new Web3(web3.currentProvider);
    } else {
      web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
    }
    return App.initContract();
  },

  initContract() {
    $.getJSON('CryptoPlanets.json', (data) => {
      const CryptoPlanetsArtifacts = data;
      App.contracts.CryptoPlanets = TruffleContract(CryptoPlanetsArtifacts);
      App.contracts.CryptoPlanets.setProvider(web3.currentProvider);
      return App.loadPlanets();
    });
    return App.bindEvents();
  },

  loadPlanets () {
    web3.eth.getAccounts(function(err, accounts) {
      if (err) {
        console.error(err);
      } else if (accounts.length == 0) {
        console.log('User is not logged into Metamask!');
      } else {
        $('#card-row').children().remove();
      }
    });

    let address = web3.eth.defaultAccount;
    let contractInstance = App.contracts.CryptoPlanets.at(App.CryptoPlanetsAddress);
    return totalSupply = contractInstance.totalSupply().then((supply) => {
      for (var i = 0; i < supply; i++) {
        App.getPlanetDetails(i, address);
      }
    }).catch((err) => {
      console.error(err.message);
    })
  },

  getPlanetDetails(planetId, localAddress) {
    let contractInstance = App.contracts.CryptoPlanets.at(App.CryptoPlanetsAddress);
    return contractInstance.getToken(planetId).then((planet) => {
      let planetJson = {
        'planetId'    : planetId,
        'planetName'  : planet[0],
        'planetAge'   : planet[1],
        'Habitable'   : planet[2],
        'StellarSystem'   : planet[3],
        'planetColor'     : planet[4],
        'planetPrice'     : web3.fromWei(planet[5]).toNumber(),
        'planetNextPrice' : web3.fromWei(planet[6]).toNumber(),
        'planetOwnerAddr' : planet[7]
      };
      if (planetJson.planetOwnerAddr !== localAddress) {
        loadPlanet(
          planetJson.planetId,
          planetJson.planetName,
          planetJson.planetAge,
          planetJson.Habitable,
          planetJson.StellarSystem,
          planetJson.planetColor,
          planetJson.planetPrice,
          planetJson.planetNextPrice,
          planetJson.planetOwnerAddr,
          false
        );
      } else {
        loadPlanet(
          planetJson.planetId,
          planetJson.planetName,
          planetJson.planetAge,
          planetJson.Habitable,
          planetJson.StellarSystem,
          planetJson.planetColor,
          planetJson.planetPrice,
          planetJson.planetNextPrice,
          planetJson.planetOwnerAddr,
          true
        );
      }
    }).catch((err) => {
      console.error(err.message);
    });
  },

  handlePurchase(event) {
    event.preventDefault();

    var planetId = parseInt($(event.target.elements).closest('.btn-buy').data('id'));

    web3.eth.getAccounts((error, accounts) => {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      let contractInstance = App.contracts.CryptoPlanets.at(App.CryptoPlanetsAddress);
      contractInstance.priceOf(planetId).then((price) => {
        return contractInstance.purchase(planetId, {
          from: account,
          value: price
        }).then(result => App.loadPlanets()).catch((err) => {
          console.log(err.message);
        });
      });
    });
  },

  bindEvents() {
    $(document).on('submit', 'form.planet-purchase', App.handlePurchase);
  }

};


/* Load Planets based on input data */
function loadPlanet(planetId, name, age, habitable, stellarSystem, color, price, nextPrice, owner, locallyOwned) {
  var cardRow = $('#card-row');
  var cardTemplate = $('#card-template');
  
  var habitable = habitable ? "yes" : "no"

  if (locallyOwned) {
    cardTemplate.find('btn-buy').attr('disabled', true);
  } else {
    cardTemplate.find('btn-buy').removeAttr('disabled');
  }

  cardTemplate.find('.planet-name').text(name);
  cardTemplate.find('.planet-image').css("background-color", color);
  cardTemplate.find('.planet-age').text(age + ' BLN years');
  cardTemplate.find('.planet-habitability').text(habitable);
  cardTemplate.find('.planet-stellar-system').text(stellarSystem);
  cardTemplate.find('.planet-color').text(color);
  cardTemplate.find('.planet-owner').text(owner);
  cardTemplate.find('.planet-owner').attr('href', 'https://etherscan.io/address/' + owner);
  cardTemplate.find('.btn-buy').attr('data-id', planetId);
  cardTemplate.find('.planet-price').text(parseFloat(price.toFixed(4)));
  cardTemplate.find('.planet-next-price').text(parseFloat(nextPrice.toFixed(4)));

  cardRow.append(cardTemplate.html());
}

/* Called When Document has loaded */
jQuery(document).ready(
  function ($) {
    App.init();
    // NEXT LINE IS FOR THE TEST PURPOSE. COMMENT OUT WHEN DEPLOYED TO NETWORK
    //loadPlanet(0, 1, true, 'Mars', 'Gamma Indus', 'FireBrick', 0.100, 0.200, '0x8af...', false)
  }
);
