// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.15;

import "./SponsorFunding.sol";
import "./DistributeFunding.sol";

contract CrowdFunding {
    uint256 public fundingGoal;
    mapping (address => uint) public contributors;

    address public owner;
    SponsorFunding public sponsor;
    DistributeFunding public distributor;
    
    bool public goal_has_been_reached = false;
    bool public sponsor_funding_received = false;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only the owner can call this function!");
        _;
    }

    function setSponsor(address payable _sponsor) external onlyOwner{
        sponsor = SponsorFunding(_sponsor);
    }

    function setDistributor(address payable _distributor) external onlyOwner{
        distributor = DistributeFunding(_distributor);
    }

    function getState() public view returns (string memory){
        if(sponsor_funding_received){
            return "finantat";
        }

        if(goal_has_been_reached){
            return "prefinantat";
        }

        return "nefinantat";
    }
  
    function WeiToEth(uint _wei) public pure returns (uint){
        return _wei / 1000000000000000000;
    }

    function EthToWei(uint _eth) public pure returns (uint){
        return _eth * 1000000000000000000;
    }

    constructor(uint256 goal){
        fundingGoal = EthToWei(goal);
        owner = msg.sender;
    }

    receive() external payable{
        require(!sponsor_funding_received, "The contract has been financed already!");

        if(goal_has_been_reached){
            require(msg.sender == address(sponsor), "Only the sponsor can finance the contract now!");
            sponsor_funding_received = true;
        } else {
            contributors[msg.sender] += msg.value;
            if(address(this).balance >= fundingGoal){
                goal_has_been_reached = true;
            }
        }
    }

    function returnFinancing() public{
        require(!sponsor_funding_received, "The contract has been financed already!");
        require(!goal_has_been_reached, "The financing has ended!");

        uint funded = contributors[msg.sender];
        require(funded > 0, "Your balance is 0!");
        payable(msg.sender).transfer(funded);
        contributors[msg.sender] = 0;
    }

    function sendFinancing() external onlyOwner{
        require(sponsor_funding_received && (address(this).balance > 0), "The financing has ended!");
        (bool sent, ) = payable(distributor).call{value:address(this).balance}("");
        require(sent, "Error when sending the sponsorship to crowdfunding");
    }

}