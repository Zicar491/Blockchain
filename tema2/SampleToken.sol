// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleToken {
    
    string public name = "Sample Token";
    string public symbol = "TOK";
    uint8 public decimals = 1;

    uint256 public totalSupply;
    uint256 public transfered;

    address public owner;
    address public seller;
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) {
        // effects:
        owner = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        // interactions:
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function allowanceFromOwner() public view returns (uint256){
        return allowance[owner][msg.sender];
    }

    function authorizeSeller(address _seller, uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(seller == address(0));

        seller = _seller;
        return approve(_seller, _value);
    }

    function mint() private {
        if(transfered >= 10000){
            uint256 newlyMinted = transfered / 10000;
            balanceOf[owner] += newlyMinted;
            totalSupply += newlyMinted;
            transfered -= newlyMinted * 10000;
            allowance[owner][seller] += newlyMinted;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // checks:
        require(balanceOf[msg.sender] >= _value);

        // effects:
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        transfered += _value;

        // interactions:
        mint();
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        // effects:
        allowance[msg.sender][_spender] = _value;

        // interactions:
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        // checks:
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        // effects:
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        transfered += _value;

        // interactions:
        mint();
        emit Transfer(_from, _to, _value);

        return true;
    }
}

contract SampleTokenSale {
    
    SampleToken public tokenContract;
    uint256 public tokenPrice;
    address public owner;

    uint256 public tokensSold;

    event Sell(address indexed _buyer, uint256 indexed _amount);

    constructor(SampleToken _tokenContract, uint256 _tokenPrice) {
        // effects:
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function updateTokenPrice(uint256 newPrice) public {
        require(msg.sender == owner);
        tokenPrice = newPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        uint256 ethValue = _numberOfTokens * tokenPrice;
        uint256 returnValue = msg.value - ethValue;
        // checks:
        require(ethValue >= _numberOfTokens);
        require(ethValue >= tokenPrice);
        require(returnValue >= 0);
        require(tokenContract.allowanceFromOwner() >= _numberOfTokens);

        // effects:
        tokensSold += _numberOfTokens;

        // interactions:
        require(tokenContract.transferFrom(tokenContract.owner(), msg.sender, _numberOfTokens));
        emit Sell(msg.sender, _numberOfTokens);
        if(returnValue > 0){
            payable(msg.sender).transfer(returnValue);
        }
    }

    function endSale() public {
        // checks:
        require(msg.sender == owner);

        // interactions:
        payable(msg.sender).transfer(address(this).balance);
    }
}