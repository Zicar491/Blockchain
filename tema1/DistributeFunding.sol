// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.15;

import "./CrowdFunding.sol";
import "./SponsorFunding.sol";

contract DistributeFunding{
    mapping (address => uint) public actionari;
    address public owner;
    CrowdFunding public crowd_addr;
    bool public received_funds = false;
    uint public funds = 0;
    uint public percentage_sum = 0;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only the owner can call this function!");
        _;
    }

    constructor(address _crowd_addr){
        owner = msg.sender;
        crowd_addr = CrowdFunding(payable(_crowd_addr));
        received_funds = false;
        funds = 0;
    }

    function addActionar(address addr, uint percentage) external onlyOwner{
        require(percentage <= 100, "Can't have a share more than 100%!");
        uint old_share = actionari[addr];
        require((percentage_sum - old_share + percentage) <= 100, "Cannot have the sum of all shares > 100%");
        actionari[addr] = percentage;
        percentage_sum = percentage_sum - old_share + percentage;
    }

    receive() external payable{
        require(msg.sender == address(crowd_addr), "Only the CrowdFunding contract cand send money to this contract!");
        require(!received_funds, "The funds were already received!");
        received_funds = true;
        funds = msg.value;
    }

    function takeShare() external{
        require(actionari[msg.sender] != 0, "You are not an associate of this contract or you've already taken your share!");
        require(received_funds, "Funds weren't received yet!");
        payable(msg.sender).transfer((funds * actionari[msg.sender]) / 100);
        actionari[msg.sender] = 0;
    }
}