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

    mapping(uint256 => Campaign) public campaigns;

    uint256 numberOfCampaigns = 0;

    event CampaignCreated(
        uint256 indexed campaignId,
        address owner,
        string title,
        uint256 target,
        uint deadline
    );

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");

        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;

        emit CampaignCreated(
            numberOfCampaigns,
            msg.sender,
            _title,
            _target,
            _deadline
        );

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function addProofOfWork(
        uint256 _campaignId,
        string memory _newProofOfWork
    ) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(
            msg.sender == campaign.owner,
            "Only the campaign owner can add proof of work"
        );

        campaign.proofsOfWork.push(_newProofOfWork);
    }

    function getProofsOfWork(
        uint256 _campaignId
    ) public view returns (string[] memory) {
        return campaigns[_campaignId].proofsOfWork;
    }
}
