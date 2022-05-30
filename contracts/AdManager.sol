//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Struct.sol";
import "./Campaign.sol";

contract AdManager is Initializable {


    mapping(address => address[]) private campaigns;
    mapping(address => string[]) private media;

    address owner;
    event mediaEvent(string _metadata, address _owner);
    event campaignEvent(address _owner, address _campaign, Reward _reward, Spend _spend, string _metadata, bool _active);
    //event campaignEvent(address _owner, address _campaign, string _metadata, bool _active);

    function initialize(address _owner) public initializer {
        owner = _owner;
    }

    function addMedia(string memory _metadata) public returns (string[] memory) {
        media[msg.sender].push(_metadata);
        emit mediaEvent(_metadata, msg.sender);
        return media[msg.sender];
    }
  
    function deleteMedia(uint _i) public returns (string[] memory) {
        media[msg.sender][_i] = media[msg.sender][media[msg.sender].length - 1];
        return media[msg.sender];
    }

    function setMedia(uint _i, string memory _metadata) public returns (string[] memory) {
        media[msg.sender][_i] = _metadata;
        emit mediaEvent(_metadata, msg.sender);
        return media[msg.sender];
    }

    function addCampaign(
          Reward memory _reward,
          Spend memory _spend,
          string memory _metadata,
          bool _active,
          bool _payImpressionRewards,
          bool _thirdPartyValidation,
          address _oracle,
          address _accounts,
          address _broker) public returns (address) {

        Campaign campaign = new Campaign();
        campaign.initialize(
          _reward,
          _spend,
          _metadata,
          _active,
          _payImpressionRewards,
          _thirdPartyValidation,
          _oracle,
          _accounts,
          _broker,
          msg.sender);
        campaigns[msg.sender].push(address(campaign));
        emit campaignEvent(msg.sender, campaigns[msg.sender][campaigns[msg.sender].length - 1], _reward, _spend, _metadata, _active);
        //emit campaignEvent(msg.sender, campaigns[msg.sender][campaigns[msg.sender].length - 1], _metadata, _active);

        // finally attempt to transfer initial balance.
        //require(engageToken.allowance(msg.sender, address(campaign)) >= _balance, "Insuficient Balance");
        //require(engageToken.transferFrom(msg.sender, address(campaign), _balance), "Initial Balance Transfer Failed");
        return address(campaign);
    }

    function deleteCampaign(address _contract) public returns (address[] memory) {
        for (uint i = 0; i < campaigns[msg.sender].length-1; i++) {
            if (campaigns[msg.sender][i] == _contract) {
                delete campaigns[msg.sender][i];
            }
        }
        return campaigns[msg.sender];
    }

    function setCampaign(
          address payable _address,
          Reward memory _reward,
          Spend memory _spend,
          string memory _metadata,
          bool _active,
          bool _payImpressionRewards,
          bool _thirdPartyValidation,
          address _oracle,
          address _accounts,
          address _broker) public {

        Campaign c = Campaign(_address);
        require(c.getOwner() == msg.sender, "Not Owner");

        c.setReward(_reward);
        c.setSpend(_spend);
        c.setMetadata(_metadata);
        c.setActive(_active);
        c.setPayImpressionRewards(_payImpressionRewards);
        c.setThirdPartyValidation(_thirdPartyValidation);
        c.setOracle(_oracle);
        c.setAccounts(_accounts);
        c.setBroker(_broker);
        emit campaignEvent(msg.sender, _address, _reward, _spend, _metadata, _active);
        //emit campaignEvent(msg.sender, _address, _metadata, _active);
    }

    function fetchMyCampaigns() public view returns (address[] memory) {
        return campaigns[msg.sender];
    }

    function fetchMyMedia() public view returns (string[] memory) {
        return media[msg.sender];
    }

}
