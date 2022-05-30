//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

library AdUtil {
    function compareStrHash(string memory a, string memory b) public pure returns (bool) {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
