pragma solidity ^0.4.18;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract DetailedERC721 is ERC721 {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
}

contract CryptoPlanets is AccessControl, DetailedERC721 {
    using SafeMath for uint;
    
    event TokenCreated(
        uint tokenId, 
        uint _age, 
        bool _habitable, 
        string _name, 
        string _stellarSystem, 
        string _color, 
        uint price, 
        address owner
    );
    
    event TokenSold(
        uint indexed tokenId, 
        uint _age, 
        bool _habitable, 
        string _name, 
        string _stellarSystem, 
        string _color, 
        uint sellingPrice, 
        uint newPrice,
        address indexed oldOwner,
        address indexed newOwner
    );

    mapping (uint => address) private tokenIdToOwner;
    mapping (uint => uint) private tokenIdToPrice;
    mapping (address => uint) private ownershipTokenCount;
    mapping (uint => address) private tokenIdToApproved;

    struct Planet {
        uint age;
        bool habitable;
        string name;
        string stellarSystem;
        string color;
    }

    Planet[] private planets;

    uint private startingPrice = 0.01 ether;
    bool private erc721Enabled = false;

    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    function createToken(string _name, address _owner, uint _price) public onlyCLevel {
        require(_owner != address(0));
        require(_price >= startingPrice);

        string memory _stellarSystem = _generateRandomSSystem();
        string memory _color = _generateRandomColor();
        uint _age = _generateRandomAge();
        bool _habitable = _generateRandomHabitability();
        _createToken(_age, _habitable, _name, _stellarSystem, _color, _owner, _price); 
    }

    function createToken(string _name) public onlyCLevel {
        string memory _stellarSystem = _generateRandomSSystem();
        string memory _color = _generateRandomColor();
        uint _age = _generateRandomAge();
        bool _habitable = _generateRandomHabitability();
        _createToken(_age, _habitable, _name, _stellarSystem, _color, address(this), startingPrice);
    }

    function _generateRandomSSystem() private view returns(string) {
        
        string[10] memory stellarSystems = [
            "Alpha Andromeda", 
            "Beta Boötes", 
            "Gamma Caelum",
            "Alpha Delphinus",
            "Beta Equuleus",
            "Gamma Fornax",
            "Alpha Gemini",
            "Beta Hercules",
            "Gamma Indus",
            "Delta Lacerta"
        ];

        return stellarSystems[uint(keccak256(now)) % 10];
    }

    function _generateRandomColor() private view returns(string) {
        string[10] memory colors = [
            "AliceBlue", 
            "Bisque", 
            "CadetBlue",
            "DarkBlue",
            "FireBrick",
            "Gainsboro",
            "HoneyDew",
            "IndianRed",
            "Khaki",
            "LightCyan"
        ];

        return colors[uint(keccak256(now)) % 10];
    }

    function _generateRandomAge() private view returns(uint) {
        return (uint(keccak256(now)) % 100);
    }
    
    function _generateRandomHabitability() private view returns(bool) {
        return uint(keccak256(now)) % 1 == 1;
    }


    function _createToken(uint _age, bool _habitable, string _name, string _stellarSystem, string _color, address _owner, uint _price) private {
        Planet memory _planet = Planet({
            age: _age,
            habitable: _habitable,
            name: _name,
            stellarSystem: _stellarSystem,
            color: _color
        });
        uint newTokenId = planets.push(_planet) - 1;
        tokenIdToPrice[newTokenId] = _price;

        TokenCreated(newTokenId, _age, _habitable, _name, _stellarSystem, _color, _price, _owner);

        _transfer(address(0), _owner, newTokenId);
    }

    function getToken(uint _tokenId) public view returns(
        string _tokenName,
        uint _age,
        bool _habitable,
        string _stellarSystem,
        string _color,
        uint _price,
        uint _nextPrice,
        address _owner
    ) {
        _tokenName = planets[_tokenId].name;
        _age = planets[_tokenId].age;
        _habitable = planets[_tokenId].habitable;
        _stellarSystem = planets[_tokenId].stellarSystem;
        _color = planets[_tokenId].color;
        _price = tokenIdToPrice[_tokenId];
        _nextPrice = nextPriceOf(_tokenId);
        _owner = tokenIdToOwner[_tokenId];
    }

    function getAllTokens() public view returns(uint[], uint[], address[]) {
        uint total = totalSupply();
        uint[] memory prices = new uint[](total);
        uint[] memory nextPrices = new uint[](total);
        address[] memory owners = new address[](total);

        for(uint i = 0; i < total; i++) {
            prices[i] = tokenIdToPrice[i];
            nextPrices[i] = nextPriceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return (prices, nextPrices, owners);
    }

    function tokensOf(address _owner) public view returns(uint[]) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint total = totalSupply();
            uint resultIndex = 0;
            
            for (uint i = 0; i < total; i++) {
                if (tokenIdToOwner[i] == _owner) {
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            
            return result;
        }
    }

    function withdrawBalance(address _to, uint _amount) public onlyCEO {
        require(_amount <= this.balance);

        if (_amount == 0) {
            _amount = this.balance;
        }

        if (_to == address(0)) {
            ceoAddress.transfer(_amount);
        } else {
            _to.transfer(_amount);
        }
    }

    function purchase(uint _tokenId) public payable whenNotPaused {
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint sellingPrice = priceOf(_tokenId);

        require(oldOwner != address(0));
        require(newOwner != address(0));
        require(oldOwner != newOwner);
        require(!_isContract(newOwner));
        require(sellingPrice > 0);
        require(msg.value >= sellingPrice);

        _transfer(oldOwner, newOwner, _tokenId);

        tokenIdToPrice[_tokenId] = nextPriceOf(_tokenId);
        uint newPrice = priceOf(_tokenId);

        TokenSold(
            _tokenId,
            planets[_tokenId].age,
            planets[_tokenId].habitable,
            planets[_tokenId].name,
            planets[_tokenId].stellarSystem,
            planets[_tokenId].color,  
            sellingPrice,
            newPrice,
            oldOwner,
            newOwner
        );

        uint excess = msg.value.sub(sellingPrice);
        uint contractCut = sellingPrice.mul(5).div(100); //5%

        if (oldOwner != address(this)) {
            oldOwner.transfer(sellingPrice.sub(contractCut));
        }

        if (excess > 0) {
            newOwner.transfer(excess);
        }
    }

    function priceOf(uint _tokenId) public view returns(uint _price) {
        return tokenIdToPrice[_tokenId];
    }

    uint private increaseLimit1 = 0.1 ether;
    uint private increaseLimit2 = 1 ether;
    uint private increaseLimit3 = 10 ether;

    function nextPriceOf(uint _tokenId) public view returns(uint _nextPrice) {
        uint _price = priceOf(_tokenId);
        if (_price < increaseLimit1) {
            return _price.mul(3).div(2);
        } else if (_price < increaseLimit2) {
            return _price.mul(5).div(4);
        } else if (_price < increaseLimit3) {
            return _price.mul(11).div(10);
        }
    }

    function enableERC721() public onlyCEO {
        erc721Enabled = true;
    }

    function totalSupply() public view returns (uint _totalSupply) {
        _totalSupply = planets.length;
    }

    function balanceOf(address _owner) public view returns (uint _balance) {
        _balance = ownershipTokenCount[_owner];
    }

    function ownerOf(uint _tokenId) public view returns (address _owner) {
        _owner = tokenIdToOwner[_tokenId];
    }

    function approve(address _to, uint _tokenId) public whenNotPaused onlyERC721 {
        require(_owns(msg.sender, _tokenId));
        tokenIdToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(_from, _tokenId));
        require(_approved(msg.sender, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function implementsERC721() public view whenNotPaused returns(bool) {
        return erc721Enabled;
    }

    function takeOwnership(uint _tokenId) public whenNotPaused onlyERC721 {
        require(_approved(msg.sender, _tokenId));
        _transfer(tokenIdToOwner[_tokenId], msg.sender, _tokenId);
    }

    function name() public view returns(string _name) {
        _name = "CryptoPlanets";
    }

    function symbol() public view returns(string _symbol) {
        _symbol = "CPLN";
    }

    function _owns(address _claimant, uint _tokenId) private view returns(bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

    function _approved(address _to, uint _tokenId) private view returns(bool) {
        return tokenIdToApproved[_tokenId] == _to;
    }

    function _transfer(address _from, address _to, uint _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIdToOwner[_tokenId] = _to;

        if(_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete tokenIdToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _isContract(address addr) private view returns(bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}