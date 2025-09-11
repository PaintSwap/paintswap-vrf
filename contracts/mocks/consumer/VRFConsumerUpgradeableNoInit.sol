// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ExampleVRFConsumerUpgradeable} from "../../examples/ExampleVRFConsumerUpgradeable.sol";

contract VRFConsumerUpgradeableNoInit is ExampleVRFConsumerUpgradeable {
  // Call the internal initializer from a regular (non-initializer) function to force
  // the onlyInitializing modifier to revert.
  function callInitNoInit(address vrfCoordinator) public {
    __PaintswapVRFConsumerUpgradeable_init(vrfCoordinator);
  }
}
