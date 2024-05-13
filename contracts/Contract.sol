// SPDX-License-Identifier: UNLICENSED dwadaa
pragma solidity ^0.8.9;

contract MyContract {
    // struct
    struct Campaign {
        address owner;
        address signer;
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
        uint256 amountSendToDonator;
        uint256 amountSendToNgo;
        ProofOfWork[] proofsOfWork;
        string image;
        // address[] donators;
        // uint256[] donations;
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

    // mapping

    mapping(address => Backer) public backers;
    mapping(uint256 => Campaign) public campaigns;

    // common var

    uint256 numberOfCampaigns = 0;
    uint256[] public campaignsID;

    // event

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
    event ReleaseFundForEndedCampaign(
        uint256 campaignId,
        uint256 amountNotYetSend,
        uint256 amountSendToDonator
    );

    event ProofOfWorkAdded(
        uint256 indexed campaignId,
        string dataType,
        string content,
        string description
    );

    // function

    // create

    function createCampaign(
        address _owner,
        address _signer,
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
        campaign.signer = _signer;
        campaign.emailAddress = _emailAddress;
        campaign.imgAddress = _imgAddress;
        campaign.title = _title;
        campaign.target = _target;
        campaign.videoAddress = _videoAddress;
        campaign.deadline = _deadline;
        campaign.description = _description;
        campaign.campaignId = numberOfCampaigns++;
        campaign.amountCollected = 0;
        campaign.amountNotYetSend = 0;
        campaign.amountSendToDonator = 0;
        campaign.amountSendToNgo = 0;
        campaignsID.push(campaign.campaignId);
        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function addProofOfWork(
        uint256 campaignId,
        string memory dataType,
        string memory content,
        string memory description
    ) public {
        // Require that the sender is the owner of the campaign
        require(
            msg.sender == campaigns[campaignId].signer,
            "Only campaign owner can add proofs of work"
        );

        // Create a new ProofOfWork
        ProofOfWork memory newProof = ProofOfWork({
            dataType: dataType,
            content: content,
            description: description
        });

        // Add the new ProofOfWork to the campaign
        campaigns[campaignId].proofsOfWork.push(newProof);

        // Emit the event
        emit ProofOfWorkAdded(campaignId, dataType, content, description);
    }

    // display

    function getCampaign(
        uint256 _id
    )
        public
        view
        returns (
            address owner,
            uint256 campaignId,
            address signer,
            string memory title,
            string memory description,
            uint256 target,
            uint256 deadline,
            uint256 amountCollected,
            uint256 amountNotYetSend,
            string memory image,
            string memory emailAddress,
            string memory imgAddress,
            string memory videoAddress,
            uint256 amountSendToDonator,
            uint256 amountSendToNgo
        )
    {
        require(_id < numberOfCampaigns, "Campaign does not exist.");
        Campaign storage campaign = campaigns[_id];
        return (
            campaign.owner,
            campaign.campaignId,
            campaign.signer,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.amountNotYetSend,
            campaign.image,
            campaign.emailAddress,
            campaign.imgAddress,
            campaign.videoAddress,
            campaign.amountSendToDonator,
            campaign.amountSendToNgo
        );
    }

    function getAllCampaigns() public view returns (uint256) {
        return numberOfCampaigns;
    }

    function getAllCampaignsId() public view returns (uint256[] memory) {
        return campaignsID;
    }

    // function displayBackerCampaigns(
    //     address _backerAddress
    // ) public view returns (uint256[] memory) {
    //     Backer storage backer = backers[_backerAddress];

    //     return backer.campaignsBacked;
    // }

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


    function getProofsOfWork(
        uint256 campaignId
    ) public view returns (ProofOfWork[] memory) {
        return campaigns[campaignId].proofsOfWork;
    }

    // fund

    function donateCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[msg.sender];
        uint256 amount = msg.value;
        require(_id < numberOfCampaigns, "Campaign does not exist.");
        require(
            block.timestamp < campaign.deadline,
            "The funding deadline has passed."
        );
        require(
            campaign.amountCollected <= campaign.target,
            "Campaign already reach its target"
        );
        require(
            campaign.amountCollected + amount <= campaign.target,
            "Donation cannot exceeds the campaign target."
        );
        require(amount > 0, "Donation amount must be greater than zero");

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

    function cancelFund(
        uint256 _id,
        address _backerAddress,
        address _ngoAddress
    ) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[_backerAddress];
        require(_id < numberOfCampaigns);
        require(block.timestamp < campaign.deadline);
        require(campaign.amountNotYetSend > 0, "current Id has no fund left");
        uint256 backerDonations = backer.donations[_id];
        if (backerDonations != 0) {
            (bool sent, ) = payable(_ngoAddress).call{value: backerDonations}(
                ""
            );
            require(sent, "Failed to send Ether");
            campaign.amountNotYetSend = campaign.amountNotYetSend - backer.donations[_id];
            campaign.amountSendToNgo = campaign.amountSendToNgo + backer.donations[_id];
            backer.donations[_id] = 0;
            emit CancelFund(
                _id,
                campaign.amountNotYetSend,
                campaign.amountSendToNgo
            );
        }
    }

    function releaseFund(uint256 _id, address _backerAddress) public payable {
        Campaign storage campaign = campaigns[_id];
        Backer storage backer = backers[_backerAddress];
        require(_id < numberOfCampaigns);
        require(block.timestamp < campaign.deadline);
        require(campaign.amountNotYetSend > 0, "current Id has no fund left");
        uint256 backerDonations = backer.donations[_id];
        if (backerDonations != 0) {
            (bool sent, ) = payable(campaign.owner).call{
                value: backerDonations
            }("");
            require(sent, "Failed to send Ether");
            campaign.amountNotYetSend =
                campaign.amountNotYetSend -
                backer.donations[_id];
            campaign.amountSendToDonator =
                campaign.amountSendToDonator +
                backer.donations[_id];
            backer.donations[_id] = 0;
            emit ReleaseFund(
                _id,
                campaign.amountNotYetSend,
                campaign.amountSendToDonator
            );
        }
    }

    function releaseFundForEndedCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(_id < numberOfCampaigns, "current Id is not exit");
        require(campaign.amountNotYetSend > 0, "current Id has no fund left");
        require(
            block.timestamp > campaign.deadline,
            "You can only use this function when campaign.dead is passed"
        );
        if (campaign.amountNotYetSend > 0) {
            (bool sent, ) = payable(campaign.owner).call{
                value: campaign.amountNotYetSend
            }("");
            require(sent, "Failed to send Ether");
            campaign.amountSendToDonator =
                campaign.amountSendToDonator +
                campaign.amountNotYetSend;
            campaign.amountNotYetSend = 0;
        }
    }
}
