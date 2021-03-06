pragma solidity ^0.4.18;

import './safe-math.lib.sol';
import './ownable.sol';

interface Token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract CrowdSale is Ownable {
    using SafeMath for uint256;

    Token token;
    uint256 public constant RATE = 100;
    uint256 public constant CAP = 10;
    uint256 public constant START = 1516302000;
    uint256 public constant DAYS = 1;
    bool public initialized = false;
    uint256 public raisedAmount = 0;

    function CrowdSale (address _tokenAddress) public {
        assert(_tokenAddress != 0);
        token = Token(_tokenAddress);
    }

    function initialize(uint256 numTokens) public onlyOwner {
        require(initialized == false);

        token.transfer(this, CAP);

        require(tokensAvailable() == numTokens);
        initialized = true;
    }

    // fallback function, ether is send directly to contract's address
    function () public payable {
        buyTokens();
    }

    function buyTokens() public payable whenSaleIsActive {
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 tokensAmount = weiAmount.mul(RATE);

        BoughtTokens(msg.sender, tokensAmount);

        raisedAmount = raisedAmount.add(weiAmount);

        token.transfer(msg.sender, tokensAmount);

        owner.transfer(msg.value);
    }

    modifier whenSaleIsActive() {
        assert(isActive()); // TODO what's the diff between require(); ?

        _;
    }

    function isActive() internal view returns (bool) {
        return (
        initialized == true &&
        now >= START &&
        now <= START.add(DAYS * 1 days) &&
        goalReached() == false
        );
    }

    function goalReached() public constant returns (bool) {
        return (raisedAmount >= CAP * 1 ether); // TODO why do we multiply by a unit?
    }

    function tokensAvailable() public constant returns (uint256) {
        return token.balanceOf(this); // <-- "this" refers to Crowdsale contract address once it's been deployed;
    }

    // Terminate contract and refund to owner
    function destroy() public onlyOwner {
        uint256 balance = token.balanceOf(this);
        assert(balance > 0);
        token.transfer(owner, balance);

        // There should be no ether in the contract but just in case
        selfdestruct(owner);
    }

    event BoughtTokens(address indexed to, uint256 value);
}