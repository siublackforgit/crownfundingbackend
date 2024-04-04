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
        uint256 amountNotYetSend;
        string[] proofsOfWork;
        string image;
        address[] donators;
        uint256[] donations;
        bool[] donationReleased;
    }

    struct Backer {
        address owner;
        uint256[] campaignsBacked;
        mapping(uint256 => uint256) donations;
    }

    struct Creator {
        address owner;
    }

    mapping(address => Backer) public backers;
    mapping(uint256 => Campaign) public campaigns;

    uint256 numberOfCampaigns = 0;

    event CampaignCreated(
        uint256 indexed campaignId,
        address owner,
        string title,
        uint256 target,
        uint deadline
    );

    event CampaignLog(
        uint256 campaignId,
        address owner,
        string title,
        string description,
        uint256 target,
        uint256 deadline,
        uint256 amountCollected,
        uint256 amountNotYetSend
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

    function donateCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[msg.sender];
        uint256 amount = msg.value;
        require(_id < numberOfCampaigns, "Campaign does not exist.");
        require(
            block.timestamp < campaign.deadline,
            "The funding deadline has passed."
        );
        require(campaign.amountCollected < campaign.target);
        require(amount > 0, "Donation amount must be greater than zero");

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        backer.owner = msg.sender;
        backer.donations[_id] += msg.value;
        bool hasAlreadyBacked = false;
        for (uint256 i = 0; i < backer.campaignsBacked.length; i++) {
            if (backer.campaignsBacked[i] == _id) {
                hasAlreadyBacked = true;
                break;
            }
        }

        if (!hasAlreadyBacked) {
            backer.campaignsBacked.push(_id);
        }
        campaign.amountCollected += amount;
        campaign.amountNotYetSend += amount;

        emit CampaignLog(
            _id,
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.amountNotYetSend
        );
    }

    function getCampaign(
        uint256 _id
    )
        public
        view
        returns (
            address owner,
            string memory title,
            string memory description,
            uint256 target,
            uint256 deadline,
            uint256 amountCollected,
            uint256 amountNotYetSend,
            string memory image
        )
    {
        require(_id < numberOfCampaigns, "Campaign does not exist.");

        Campaign storage campaign = campaigns[_id];
        return (
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.amountNotYetSend,
            campaign.image
        );
    }

    function releaseFundsForEndedCampaigns() public payable {
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            (bool sent, ) = payable(campaign.owner).call{
                value: campaign.amountNotYetSend
            }("");
            require(sent, "Failed to send Ether");
            campaign.amountNotYetSend = 0;
            emit CampaignLog(
                i,
                campaign.owner,
                campaign.title,
                campaign.description,
                campaign.target,
                campaign.deadline,
                campaign.amountCollected,
                campaign.amountNotYetSend
            );
        }
    }

    function displayBackerCampaigns(
        address _backerAddress
    ) public view returns (uint256[] memory) {
        Backer storage backer = backers[_backerAddress];

        return backer.campaignsBacked;
    }

    function releaseFund(uint256 _id, address _backerAddress) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[_backerAddress];
        require(_id < numberOfCampaigns);
        require(block.timestamp < campaign.deadline);
        uint256 backerDonations = backer.donations[_id];
        if (backerDonations != 0) {
            (bool sent, ) = payable(campaign.owner).call{
                value: backerDonations
            }("");
            require(sent, "Failed to send Ether");
            campaign.amountNotYetSend -= backerDonations;
            backer.donations[_id] = 0;
        }
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

    // display

    function getAllCampaigns() public view returns (uint256) {
        return numberOfCampaigns;
    }

    function getTotalFundsRaised() public view returns (uint256) {
        uint256 totalFundsRaised = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            totalFundsRaised += campaigns[i].amountCollected;
        }
        return totalFundsRaised;
    }

    function getActiveCampaignCount() public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].deadline > block.timestamp) {
                activeCount++;
            }
        }
        return activeCount;
    }
}
