//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract Oracle is Initializable {

    address admin;

    // a map of trusted publishers
    mapping(address => bool) public publishers;


    function initialize(address _admin) public initializer {
        admin = _admin;
    }

    /*
     * Iterate all engagements and process payment for each address
     */
    function addPublisher(address _publisher) public {
        if (msg.sender == admin) {
            publishers[_publisher] = true;
        }
    }

    function deletePublisher(address _publisher) public {
        if (msg.sender == admin) {
            delete publishers[_publisher];
        }
    }

    function hasPublishers(address _publisher) public view returns (bool) {
        if (publishers[_publisher] == true) {
          return true;
        } else {
          return false;
        }
    }

}

