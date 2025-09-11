// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "./interfaces/IPaintswapVRFCoordinator.sol";

import {PaintswapVRFConsumerBase} from "./PaintswapVRFConsumerBase.sol";

/**
 * @title PaintswapVRFConsumer
 * @dev Abstract contract for consuming randomness from the Paintswap VRF (Verifiable Random Function) service
 * @notice Implement this contract to request and receive verifiable randomness from Paintswap's VRF
 */
abstract contract PaintswapVRFConsumer is PaintswapVRFConsumerBase {
  /**
   * @dev Reference to the Paintswap VRF coordinator contract
   * @notice This is immutable and set during contract construction
   */
  IPaintswapVRFCoordinator internal immutable _vrfCoordinator;

  /**
   * @dev Initializes the consumer contract with the VRF coordinator address
   * @param vrfCoordinator Address of the Paintswap VRF coordinator contract
   */
  constructor(address vrfCoordinator) {
    require(vrfCoordinator != address(0), ZeroAddress());
    _vrfCoordinator = IPaintswapVRFCoordinator(vrfCoordinator);
    emit VRFCoordinatorSet(vrfCoordinator);
  }

  /**
   * @dev Returns the reference to the Paintswap VRF coordinator contract
   * @notice This function is called by the base contract to get the coordinator reference
   */
  function _getVRFCoordinator()
    internal
    view
    override
    returns (IPaintswapVRFCoordinator)
  {
    return _vrfCoordinator;
  }
}
