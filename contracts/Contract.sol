// SPDX-License-Identifier: UNLICENSED dwadaa
pragma solidity ^0.8.9;

// struct
contract MyContract {
    struct Campaign {
        address owner;
        uint256 campaignId;
        string emailAddress;
        string imgAddress;
        string title;
        uint256 target;
        string videoAddress;
        uint256 deadline;
        string description;
        uint256 amountCollected;
        uint256 amountNotYetSend;
        ProofOfWork [] proofsOfWork;
        string image;
        address[] donators;
        uint256[] donations;
        bool[] donationReleased;
        uint256 amountSendToDonator;
        uint256 amountSendToNgo;
    }

    struct Backer {
        address owner;
        uint256[] campaignsBacked;
        mapping(uint256 => uint256) donations;
    }

        struct ProofOfWork {
        string dataType;
        string content;
        string description;
    }

    mapping(address => Backer) public backers;
    mapping(uint256 => Campaign) public campaigns;

    uint256 numberOfCampaigns = 0;

    event AmountCollectedUpdated(uint256 campaignId, uint256 amountCollected);
    event ReleaseFund(
        uint256 campaignId,
        uint256 amountNotYetSend,
        uint256 amountSendToDonator
    );
    event CancelFund(
        uint256 campaignId,
        uint256 amountNotYetSend,
        uint256 amountSendToNgo
    );

    function createCampaign(
        address _owner,
        string memory _emailAddress,
        string memory _imgAddress,
        string memory _title,
        uint256 _target,
        string memory _videoAddress,
        uint256 _deadline,
        string memory _description
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = _owner;
        campaign.emailAddress = _emailAddress;
        campaign.imgAddress = _imgAddress;
        campaign.title = _title;
        campaign.target = _target;
        campaign.videoAddress = _videoAddress;
        campaign.deadline = _deadline;
        campaign.description = _description;
        campaign.campaignId = numberOfCampaigns++;

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
        require(campaign.amountCollected <= campaign.target,"Campaign already reach its target");
        require(campaign.amountCollected + amount <= campaign.target,"Donation cannot exceeds the campaign target.");
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

        emit AmountCollectedUpdated(_id, msg.value);
    }

    function getCampaign(
        uint256 _id
    )
        public
        view
        returns (
            address owner,
            uint256 campaignId,
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
            campaign.campaignId,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.amountNotYetSend,
            campaign.image
        );
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
            backer.donations[_id] = 0;
            campaign.amountNotYetSend -= backer.donations[_id];
            campaign.amountSendToDonator += backer.donations[_id];
            emit ReleaseFund(
                _id,
                campaign.amountNotYetSend,
                campaign.amountSendToDonator
            );
        }
    }

    function cancelFund(
        uint256 _id,
        address _backerAddress,
        address _ngoAddress
    ) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[_backerAddress];
        require(_id < numberOfCampaigns);
        require(block.timestamp < campaign.deadline);
        uint256 backerDonations = backer.donations[_id];
        if (backerDonations != 0) {
            (bool sent, ) = payable(_ngoAddress).call{value: backerDonations}(
                ""
            );
            require(sent, "Failed to send Ether");
            backer.donations[_id] = 0;
            campaign.amountNotYetSend -= backer.donations[_id];
            campaign.amountSendToNgo += backer.donations[_id];
            emit CancelFund(
                _id,
                campaign.amountNotYetSend,
                campaign.amountSendToNgo
            );
        }
    }

    function releaseFundsForEndedCampaigns() public payable {
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];

            (bool sent, ) = payable(campaign.owner).call{
                value: campaign.amountNotYetSend
            }("");
            require(sent, "Failed to send Ether");
            campaign.amountNotYetSend = 0;
        }
    }

    function displayFund(
        uint256 _id,
        address _backerAddress
    ) public view returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[_backerAddress];
        require(_id < numberOfCampaigns);
        require(block.timestamp < campaign.deadline);
        uint256 backerDonations = backer.donations[_id];
        return backerDonations;
    }

    function addProofOfWork(
        uint256 _campaignId,
        string memory _dataType,
        string memory _content,
        string memory _description
    ) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(
            msg.sender == campaign.owner,
            "Only the campaign owner can add proof of work"
        );
        ProofOfWork memory newProofOfWork = ProofOfWork({
            dataType: _dataType,
            content: _content,
            description: _description
        });
        campaign.proofsOfWork.push(newProofOfWork);
    }

    function getProofsOfWork(
        uint256 _campaignId
    ) public view returns (ProofOfWork[] memory) {
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

    function getActiveCampaignList() public view returns (Campaign[] memory) {
        uint256 activeCount = 0;

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].deadline > block.timestamp) {
                activeCount++;
            }
        }

        Campaign[] memory activeCampaigns = new Campaign[](activeCount);

        uint256 j = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].deadline > block.timestamp) {
                Campaign storage c = campaigns[i];
                activeCampaigns[j] = Campaign({
                    campaignId: c.campaignId,
                    owner: c.owner,
                    emailAddress: c.emailAddress,
                    imgAddress: c.imgAddress,
                    title: c.title,
                    target: c.target,
                    videoAddress: c.videoAddress,
                    deadline: c.deadline,
                    description: c.description,
                    amountCollected: c.amountCollected,
                    amountNotYetSend: c.amountNotYetSend,
                    proofsOfWork: c.proofsOfWork,
                    image: c.image,
                    donators: c.donators,
                    donations: c.donations,
                    donationReleased: c.donationReleased,
                    amountSendToDonator: c.amountSendToDonator,
                    amountSendToNgo: c.amountSendToNgo
                });
                j++;
            }
        }

        return activeCampaigns;
    }
}
