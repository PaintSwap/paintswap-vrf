// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../../interfaces/IPaintswapVRFConsumer.sol";

contract ShortRevertVRFConsumer is IPaintswapVRFConsumer {
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
    // Return less than 4 bytes of revert data
    assembly {
      let ptr := mload(0x40)
      mstore(
        ptr,
        0x123400000000000000000000000000000000000000000000000000000000000
      ) // Only 2 bytes of data
      revert(ptr, 0x02) // Less than 4 bytes
    }
  }
}
