// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.15;

import "./CrowdFunding.sol";
import "./SponsorFunding.sol";
import "./DistributeFunding.sol";

contract Testing {
    CrowdFunding public crowd;
    SponsorFunding public sponsor;
    DistributeFunding public dist;
    uint public size;
    address public owner;

    receive() external payable{}

    constructor(uint _size){
        size = _size;
        owner = msg.sender;
        crowd = new CrowdFunding(size);
        sponsor = new SponsorFunding(address(crowd));
        dist = new DistributeFunding(address(crowd));

        crowd.setDistributor(payable(address(dist)));
        crowd.setSponsor(payable(address(sponsor)));
    }

    function testCrowd1() external{
        uint initBalance = address(this).balance;
        
        (bool sent, ) = payable(address(crowd)).call{value:crowd.EthToWei(size)/2}("");
        require(sent, "Test 1 fails");
        require(!crowd.goal_has_been_reached(), "Test 2 fails");
        crowd.returnFinancing();
        require(initBalance == address(this).balance, "Test 3 fails");
    }

    function testCrowd2() external{
        (bool sent, ) = payable(address(crowd)).call{value:crowd.EthToWei(size)}("");
        require(sent, "Test 1 fails");
        require(crowd.goal_has_been_reached(), "Test 2 fails");
    }

    function testSponsor() external{
        (bool sent, ) = payable(address(sponsor)).call{value:sponsor.getNeeded()}("");
        require(sent, "Test 1 fails");
        sponsor.announcePrefounded();
        sponsor.sponsor();
        require(crowd.goal_has_been_reached(), "Test 2 fails");
        require(crowd.sponsor_funding_received(), "Test 3 fails");
    }

    function testDistribute() external{
        dist.addActionar(owner, 50);
        dist.addActionar(address(this), 50);
        crowd.sendFinancing();

        dist.takeShare();
        payable(owner).transfer(address(this).balance);
    }
}