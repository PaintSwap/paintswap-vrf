// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IPaintswapVRFCoordinator} from "./interfaces/IPaintswapVRFCoordinator.sol";
import {PaintswapVRFConsumerBase} from "./PaintswapVRFConsumerBase.sol";
import {PaintswapVRFConsumerStorage as VRFS} from "./storage/PaintswapVRFConsumerStorage.sol";

/**
 * @title PaintswapVRFConsumerUpgradeable (UUPS, namespaced storage)
 * @notice Upgradeable VRF consumer base that stores the coordinator in a custom storage slot.
 * @dev Inherit and implement `_fulfillRandomWords`. Call `initialize` instead of a constructor.
 */
abstract contract PaintswapVRFConsumerUpgradeable is
  Initializable,
  PaintswapVRFConsumerBase
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize with the VRF coordinator.
   * @param vrfCoordinator Address of the Paintswap VRF coordinator
   */
  function __PaintswapVRFConsumerUpgradeable_init(
    address vrfCoordinator
  ) internal onlyInitializing {
    _setVRFCoordinator(vrfCoordinator);
  }

  /**
   * @notice Set the VRF coordinator
   * @param newCoordinator Address of the new Paintswap VRF coordinator
   */
  function _setVRFCoordinator(address newCoordinator) private {
    require(newCoordinator != address(0), ZeroAddress());
    VRFS.layout().vrfCoordinator = IPaintswapVRFCoordinator(newCoordinator);
    emit VRFCoordinatorSet(newCoordinator);
  }

  /**
   * @notice Get the VRF coordinator
   * @return Address of the Paintswap VRF coordinator
   */
  function _getVRFCoordinator()
    internal
    view
    override
    returns (IPaintswapVRFCoordinator)
  {
    return VRFS.layout().vrfCoordinator;
  }
}
