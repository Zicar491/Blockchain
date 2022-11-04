// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.15;

import "./CrowdFunding.sol";
import "./DistributeFunding.sol";

contract SponsorFunding{
    CrowdFunding public crowd_addr;
    address public owner;
    uint public sponsor_percent;
    bool public can_sponsor = false;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only the owner can call this function!");
        _;
    }

    function getNeeded() public view returns (uint){
        return (address(crowd_addr).balance * sponsor_percent) / 100;
    }

    constructor(address _crowd_addr){
        crowd_addr = CrowdFunding(payable(_crowd_addr));
        sponsor_percent = 10;
        owner = msg.sender;
    }

    receive() external payable onlyOwner{}

    function changeSponsorPercent(uint _sponsor_percent) external onlyOwner{
        sponsor_percent = _sponsor_percent;
    }

    function announcePrefounded() external{
        require(!can_sponsor, "Sponsor state already set!");
        require(msg.sender == CrowdFunding(payable(crowd_addr)).owner(), "You need to be the owner of CrowdFunding!");
        require(CrowdFunding(payable(crowd_addr)).goal_has_been_reached(), "The contract wasn't financed yet!");
        can_sponsor = true;
    }

    function sponsor() external onlyOwner{
        require(can_sponsor, "The contract wasn't financed yet!");
        uint needed = getNeeded();
        require(address(this).balance >= needed, "Not enough!");
        uint reminder = address(this).balance - needed;
        payable(owner).transfer(reminder);
        (bool sent, ) = payable(crowd_addr).call{value:needed}("");
        require(sent, "Error when sending the sponsorship to crowdfunding");
    }
}