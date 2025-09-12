// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {PaintswapVRFConsumerUpgradeable} from "../PaintswapVRFConsumerUpgradeable.sol";
import {IPaintswapVRFCoordinator} from "../interfaces/IPaintswapVRFCoordinator.sol";

contract ExampleVRFConsumerUpgradeable is
  PaintswapVRFConsumerUpgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable
{
  // Expose initializer wrapper for tests.
  // Avoid calling the OZ initializer helpers (which require the contract to be in
  // an initializing state). The implementation constructor disables initializers
  // so tests that deploy the implementation directly would revert. Instead set
  // the needed state directly using internal functions.
  function initialize(
    address vrfCoordinator,
    address initialOwner
  ) public initializer {
    __PaintswapVRFConsumerUpgradeable_init(vrfCoordinator);
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    // Set owner directly (internal function from OwnableUpgradeable)
  }

  // Simple fulfill implementation
  function _fulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
  ) internal override {
    // no-op for tests
  }

  /**
   * Calculate the native request price for a given callback gas limit.
   * @param callbackGasLimit The gas limit for the callback function.
   */
  function calculateRequestPriceNative(
    uint256 callbackGasLimit
  ) external view returns (uint256) {
    return _calculateRequestPriceNative(callbackGasLimit);
  }

  /**
   * Request random words from the VRF coordinator.
   * @param numWords The number of random words to request.
   */
  function requestRandomWords(
    uint256 numWords
  ) external payable returns (uint256) {
    uint256 CALLBACK_GAS_LIMIT = 2_000_000;
    uint256 requestId = _requestRandomnessPayInNative(
      CALLBACK_GAS_LIMIT,
      numWords,
      msg.sender,
      msg.value
    );

    return requestId;
  }

  /**
   * @dev UUPS authorization
   * @param newImplementation The address of the new implementation contract.
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}
}
