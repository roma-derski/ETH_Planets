module.exports = function(CryptoPlanets, accounts) {
    function checkTotalSupply(expectedValue) {
        it('totalSupply should be equal to ' + expectedValue, function(done) {
            CryptoPlanets.deployed().then(function(instance) {
                instance.totalSupply.call().then(function(totalSupply) {
                    assert.equal(totalSupply, expectedValue, 'totalSupply is not equal to ' + expectedValue);
                }).then(done).catch(done);
            });
        });
    };

    function checkPlanetCreation(name) {
        it('createToken should create a random planet named ' + name, function(done) {
            CryptoPlanets.deployed().then( async function(instance) {
                await instance.createToken(name, {
                    from: accounts[0] 
                }).then(function(result) {
                    assert.include(result.logs[0].event, 'TokenCreated', 'TokenCreated event was not triggered');
                });
            }).then(done).catch(done);
        });
    };

    return {
        checkTotalSupply: checkTotalSupply,
        checkPlanetCreation: checkPlanetCreation
    };
}