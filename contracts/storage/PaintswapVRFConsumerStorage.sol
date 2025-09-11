// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../interfaces/IPaintswapVRFCoordinator.sol";

/**
 * @title PaintswapVRFConsumerStorage
 * @notice ERC-7201 style namespaced storage for the VRF consumer.
 *
 * Namespace: paintswap.storage.vrf-consumer
 * keccak256: 0x55babfd4afb3639f1ad2bd51b6ac6a46a851aaaf7dddc61bc22c3b70fc381d87
 * SLOT:      0x55babfd4afb3639f1ad2bd51b6ac6a46a851aaaf7dddc61bc22c3b70fc381d86
 */
library PaintswapVRFConsumerStorage {
  bytes32 internal constant SLOT =
    0x55babfd4afb3639f1ad2bd51b6ac6a46a851aaaf7dddc61bc22c3b70fc381d86;

  struct Layout {
    IPaintswapVRFCoordinator vrfCoordinator;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = SLOT;
    assembly {
      l.slot := slot
    }
  }
}
