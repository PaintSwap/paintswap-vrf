// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../../interfaces/IPaintswapVRFConsumer.sol";

contract NonErrorSelectorVRFConsumer is IPaintswapVRFConsumer {
    function requestRandomness(
        address coordinator,
        uint256 callbackGasLimit,
        uint256 numWords
    ) external payable returns (uint256) {
        return
            IPaintswapVRFCoordinator(coordinator).requestRandomnessPayInNative{
                value: msg.value
            }(callbackGasLimit, numWords);
    }

    function rawFulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory /* randomWords */
    ) external pure override {
        // Use a different selector (not Error(string)) with some data
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x1234567800000000000000000000000000000000000000000000000000000000
            ) // Different 4-byte selector
            mstore(add(ptr, 0x04), 0x9999) // Some additional data
            revert(ptr, 0x08) // 4 bytes selector + 4 bytes data
        }
    }
}
