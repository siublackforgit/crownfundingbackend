// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string[] proofsOfWork;
        string image;
        address[] donators;
        uint256[] donations;
        bool[] donationReleased;
    }
 
    mapping (uint256 => Campaign) public campaigns;

    uint256 numberOfCampaigns = 0;

    function addProofOfWork(uint256 _campaignId, string memory _newProofOfWork)
    public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only the campaign owner can add proof of work");

        campaign.proofsOfWork.push(_newProofOfWork);
    }

    function getProofsOfWork(uint256 _campaignId) public view returns (string[] memory) {
        return campaigns[_campaignId].proofsOfWork;
    }

 
}