// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../../interfaces/IPaintswapVRFConsumer.sol";

contract MalformedErrorVRFConsumer is IPaintswapVRFConsumer {
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
        // Create malformed Error(string) data - selector + invalid ABI data
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x08c379a000000000000000000000000000000000000000000000000000000000
            ) // Error(string) selector
            mstore(add(ptr, 0x04), 0x1234) // Invalid ABI data (too short)
            revert(ptr, 0x08) // 4 bytes selector + 4 bytes invalid data
        }
    }
}
