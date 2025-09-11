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

  // Helper to call internal _calculateRequestPriceNative
  function calculateRequestPriceNative(
    uint256 callbackGasLimit
  ) external view returns (uint256) {
    return _calculateRequestPriceNative(callbackGasLimit);
  }

  // Public payable wrapper used by tests to request randomness. Accepts the
  // number of words and forwards the native payment to the coordinator.
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

  /// @dev UUPS auth
  function _authorizeUpgrade(address) internal override onlyOwner {}
}
