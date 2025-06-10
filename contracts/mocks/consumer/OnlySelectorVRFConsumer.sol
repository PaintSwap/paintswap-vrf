// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../../interfaces/IPaintswapVRFConsumer.sol";

contract OnlySelectorVRFConsumer is IPaintswapVRFConsumer {
  function requestRandomness(
    address coordinator,
    uint256 callbackGasLimit,
    uint256 numWords
  ) external payable returns (uint256) {
    return
      IPaintswapVRFCoordinator(coordinator).requestRandomnessPayInNative{
        value: msg.value
      }(callbackGasLimit, numWords, msg.sender);
  }

  function rawFulfillRandomWords(
    uint256 /* requestId */,
    uint256[] memory /* randomWords */
  ) external pure override {
    // Return only the Error(string) selector with no additional data
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x08c379a000000000000000000000000000000000000000000000000000000000
      ) // Error(string) selector
      revert(ptr, 0x04) // Exactly 4 bytes
    }
  }
}
