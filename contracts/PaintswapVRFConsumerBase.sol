// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "./interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "./interfaces/IPaintswapVRFConsumer.sol";

/**
 * @title PaintswapVRFConsumerBase
 * @notice Shared logic for VRF consumer contracts (both upgradeable and non-upgradeable).
 * @dev Children must implement `_getVRFCoordinator()` to supply the coordinator reference
 *      and `_fulfillRandomWords()` to process received randomness.
 */
abstract contract PaintswapVRFConsumerBase is IPaintswapVRFConsumer {
  /**
   * @dev Error thrown when a function restricted to the VRF coordinator is called by another address
   * @param sender The address that attempted to call the function
   * @param coordinator The address of the authorized VRF coordinator
   */
  error OnlyVRFCoordinator(address sender, address coordinator);

  /**
   * @dev Error thrown when a zero address is provided where it is not allowed
   */
  error ZeroAddress();

  event VRFCoordinatorSet(address indexed coordinator);

  /**
   * @dev Restricts function access to only the VRF coordinator
   * @notice Functions with this modifier can only be called by the VRF coordinator contract
   */
  modifier onlyCoordinator() {
    IPaintswapVRFCoordinator coord = _getVRFCoordinator();
    if (msg.sender != address(coord)) {
      revert OnlyVRFCoordinator(msg.sender, address(coord));
    }
    _;
  }

  /**
   * @dev Must return the active VRF coordinator reference.
   * @dev Implemented differently by non-upgradeable vs upgradeable variants.
   */
  function _getVRFCoordinator()
    internal
    view
    virtual
    returns (IPaintswapVRFCoordinator);

  /**
   * @dev Calculates the price in native currency for a randomness request
   * @param callbackGasLimit Maximum gas allowed for the fulfillment callback
   * @return requestPrice The price in native currency for the request
   * @notice The price depends on the current gas price and the callback gas limit
   */
  function _calculateRequestPriceNative(
    uint256 callbackGasLimit
  ) internal view returns (uint256 requestPrice) {
    requestPrice = _getVRFCoordinator().calculateRequestPriceNative(
      callbackGasLimit
    );
  }

  /**
   * @dev Requests random words from the VRF coordinator, paying with native currency, specifying a refundee
   * @param callbackGasLimit Maximum gas allowed for the fulfillment callback
   * @param numWords Number of random words to request
   * @param refundee Address to receive any unused gas refund
   * @param gasPayment Amount of native currency to pay for the request
   * @return requestId Unique identifier for this randomness request
   * @notice The contract must have sufficient balance to cover the value parameter
   */
  function _requestRandomnessPayInNative(
    uint256 callbackGasLimit,
    uint256 numWords,
    address refundee,
    uint256 gasPayment
  ) internal returns (uint256 requestId) {
    return
      _getVRFCoordinator().requestRandomnessPayInNative{value: gasPayment}(
        callbackGasLimit,
        numWords,
        refundee
      );
  }

  /**
   * @dev Processes the received random words
   * @param requestId The ID of the request that corresponds to these random words
   * @param randomWords The array of random words received from the VRF coordinator
   * @notice This function must be implemented by the inheriting contract
   */
  function _fulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
  ) internal virtual;

  /**
   * @dev Callback function called by the VRF coordinator to deliver random words
   * @dev Special care should be taken when overriding this function. Use `_fulfillRandomWords()` instead.
   * @param requestId The ID of the request to which these random words belong
   * @param randomWords The array of random words for the request
   * @notice This function can only be called by the VRF coordinator
   */
  function rawFulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
  ) external override onlyCoordinator {
    _fulfillRandomWords(requestId, randomWords);
  }
}
