//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
import "./Struct.sol";
import "./AdUtil.sol";
import "./AccountsEscrow.sol";

/* 
 * bool false = impression
 * bool true = click
 * referrer = publisher
 * validator in case of impression = publisher
 * validator in case of click = advertiser
 */

interface OracleInterface {
    function hasPublisher(address _addr) external view returns (bool);
}

contract Campaign is Initializable {

    bytes32 name;

    // Is the ad active ? Inactive ads do not pay.
    bool active;

    // Pay users rewards for impressions.
    bool payImpressionRewards;    

    // Enable 3p validators
    bool thirdPartyValidation;

    // Owner
    address public owner;

    // Rewards
    Reward public reward;

    // Spend & Targeting
    Spend public spend;
    // Target public target;

    string public metadata;

    // Address for broker (default invoke)
    address broker;

    // Address for admanager
    address adManager;

    // Address for oracle contract
    address oracle;

    // Address for accounts contract
    AccountsEscrow accounts;

    // Address to relay ERC2771Context metaTx.
    // address public trustedForwarder;

    // Engagements mapping token for clicks and impressions.
    mapping(string => Engagement) public userEngagements;

    // Track all redeemable tokens
    string[] public tokens;

    // event for new engagement
    event engagementEvent(Engagement indexed _engagement, address _owner);

    // (Optional) Trusted third party validators that must verify each engagement, typically trusted publishers
    OracleInterface thirdPartyValidators;

    function initialize(Reward memory _reward, Spend memory _spend, string memory _metadata, bool _active, bool _payImpressionRewards, bool _thirdPartyValidation, address _oracle, address _accounts, address _broker, address _owner) public initializer {
        adManager = msg.sender;
        owner = _owner;
        reward = _reward;
        spend = _spend;
        metadata = _metadata;
        active = _active;
        payImpressionRewards = _payImpressionRewards;
        thirdPartyValidation = _thirdPartyValidation;
        oracle = _oracle;
        accounts = AccountsEscrow(_accounts);
        broker = _broker;
        thirdPartyValidators = OracleInterface(oracle);
    }

    /* 
     * Engagements track user impressions and clicks
     * 1) When an ad loads the user receives a token that get's added into the contact as an impression (non click) engagement
     * 2) When the user clicks an ad the same engagement is sent but this time flipping click true.
     */
    function setEngagement(string[] memory _token, Engagement[] memory _engagement) public {
        if ((msg.sender == owner || msg.sender == broker) && active == true) {
            for(uint i=0; i<_token.length; i++) {
                userEngagements[_token[i]] = _engagement[i];
                tokens.push(_token[i]);
                emit engagementEvent(userEngagements[_token[i]], msg.sender);
            }
        }
    }

    /*
     * Engagements can be validated say in the case of enabling trusted publishers, publisher side software can confirm the user interaction.
     */
    function validateEngagements(string[] memory _token, address[] memory _client) public returns (bool) {
        if (thirdPartyValidators.hasPublisher(msg.sender)) {
            for(uint i=0; i<_token.length; i++) {
                if (userEngagements[_token[i]].owner == _client[i] && userEngagements[_token[i]].referer == msg.sender) {
                    userEngagements[_token[i]].validated = true;
                    return true;
                }
            }
        }
        return false;
    }

    /*
     * @dev process the reward payments for tokens
     * @params tokens to process (read offchain from engagement emits)
     * finally reset the engagments (allows for repeat engagements)
     */
    function processEngagements(string[] memory _tokens) external {
        if ((msg.sender == owner || msg.sender == broker) && active == true) {
            // user/publisher click/impression rewards
            uint usrClkRwd = spend.CPC * reward.userReward;
            uint pubClkRwd = spend.CPC * reward.publisherReward;
            uint bkrClkRwd = spend.CPC * reward.brokerReward;
            uint usrImpRwd = spend.CPI * reward.userReward;
            uint pubImpRwd = spend.CPI * reward.publisherReward;
            uint bkrImpRwd = spend.CPI * reward.brokerReward;
            address[] memory parties = new address[](_tokens.length);
            uint256[] memory rewards = new uint256[](_tokens.length);
            for (uint i = 0; i < _tokens.length; i++) {
                if (thirdPartyValidation == true && userEngagements[_tokens[i]].validated != true) {
                    continue;
                }
                parties[i] = userEngagements[_tokens[i]].owner;
                parties[i] = userEngagements[_tokens[i]].referer;
                parties[i] = userEngagements[_tokens[i]].broker;
                if (userEngagements[_tokens[i]].click == true) {
                    rewards[i] = usrClkRwd;
                    rewards[i] = pubClkRwd;
                    rewards[i] = bkrClkRwd;
                } else if (payImpressionRewards == true) {
                    rewards[i] = usrImpRwd;
                    rewards[i] = pubImpRwd;
                    rewards[i] = bkrImpRwd;
                }
                delete userEngagements[_tokens[i]];
            }
            accounts.process(parties, rewards);
        }
    }

    // Getters

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMetadata() public view returns (string memory) {
        return metadata;
    }

    // Setters

    function setSpend(Spend memory _spend) public {
        if (msg.sender == adManager) {
          spend = _spend;
        }
    }

    function setReward(Reward memory _reward) public {
        if (msg.sender == adManager) {
          reward = _reward;
        }
    }

    function setMetadata(string memory _metadata) public {
        if (msg.sender == adManager) {
          metadata = _metadata;
        }
    }

    function setActive(bool _b) public {
        if (msg.sender == adManager) {
          active = _b;
        }
    }

    function setPayImpressionRewards(bool _b) public {
        if (msg.sender == adManager) {
          payImpressionRewards = _b;
        }
    }

    function setThirdPartyValidation(bool _b) public {
        if (msg.sender == adManager) {
            thirdPartyValidation = _b;
        }
    }

    function setOracle(address _address) public {
        if (msg.sender == broker) {
            oracle = _address;
        }
    }

    function setBroker(address _address) public {
        if (msg.sender == broker) {
            broker = _address;
        }
    }

    function setAccounts(address _address) public {
        if (msg.sender == broker) {
            accounts = AccountsEscrow(_address);
        }
    }

    receive() external payable {}

}
