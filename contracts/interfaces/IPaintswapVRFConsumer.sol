// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

interface IPaintswapVRFConsumer {
  /**
   * @notice rawFulfillRandomWords handles the VRF response and your contract must implement it!
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}
