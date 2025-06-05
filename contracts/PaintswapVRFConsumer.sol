// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "./interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "./interfaces/IPaintswapVRFConsumer.sol";

/**
 * @title PaintswapVRFConsumer
 * @dev Abstract contract for consuming randomness from the Paintswap VRF (Verifiable Random Function) service
 * @notice Implement this contract to request and receive verifiable randomness from Paintswap's VRF
 */
abstract contract PaintswapVRFConsumer is IPaintswapVRFConsumer {
    /**
     * @dev Reference to the Paintswap VRF coordinator contract
     * @notice This is immutable and set during contract construction
     */
    IPaintswapVRFCoordinator internal immutable _vrfCoordinator;

    /**
     * @dev Error thrown when a function restricted to the VRF coordinator is called by another address
     * @param sender The address that attempted to call the function
     * @param coordinator The address of the authorized VRF coordinator
     */
    error OnlyVRFCoordinator(address sender, address coordinator);

    /**
     * @dev Restricts function access to only the VRF coordinator
     * @notice Functions with this modifier can only be called by the VRF coordinator contract
     */
    modifier onlyCoordinator() {
        if (msg.sender != address(_vrfCoordinator)) {
            revert OnlyVRFCoordinator(msg.sender, address(_vrfCoordinator));
        }
        _;
    }

    /**
     * @dev Initializes the consumer contract with the VRF coordinator address
     * @param vrfCoordinator Address of the Paintswap VRF coordinator contract
     */
    constructor(address vrfCoordinator) {
        _vrfCoordinator = IPaintswapVRFCoordinator(vrfCoordinator);
    }

    /**
     * @dev Requests random words from the VRF coordinator, paying with native currency
     * @param callbackGasLimit Maximum gas allowed for the fulfillment callback
     * @param numWords Number of random words to request
     * @param value Amount of native currency to pay for the request
     * @return requestId Unique identifier for this randomness request
     * @notice The contract must have sufficient balance to cover the value parameter
     */
    function _requestRandomnessPayInNative(
        uint256 callbackGasLimit,
        uint256 numWords,
        uint256 value
    ) internal returns (uint256 requestId) {
        return
            _vrfCoordinator.requestRandomnessPayInNative{value: value}(
                callbackGasLimit,
                numWords
            );
    }

    /**
     * @dev Calculates the price in native currency for a randomness request
     * @param callbackGasLimit Maximum gas allowed for the fulfillment callback
     * @return requestPrice The price in native currency for the request
     * @notice The price depends on the current gas price and the callback gas limit
     */
    function _calculateRequestPriceNative(
        uint256 callbackGasLimit
    ) internal view returns (uint256 requestPrice) {
        requestPrice = _vrfCoordinator.calculateRequestPriceNative(
            callbackGasLimit
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
