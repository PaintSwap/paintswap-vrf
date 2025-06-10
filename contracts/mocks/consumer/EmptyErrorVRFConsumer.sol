// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../../interfaces/IPaintswapVRFConsumer.sol";

contract EmptyErrorVRFConsumer is IPaintswapVRFConsumer {
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
    // Create Error(string) with empty message
    revert("");
  }
}
