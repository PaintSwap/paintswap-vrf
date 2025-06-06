// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "../interfaces/IPaintswapVRFCoordinator.sol";
import {IPaintswapVRFConsumer} from "../interfaces/IPaintswapVRFConsumer.sol";

/**
 * @title MockVRFCoordinator
 * @dev Mock implementation of PaintswapVRFCoordinator for testing
 * @notice Simulates VRF coordinator functionality without cryptographic proofs
 * @dev Requests and fulfillments are separate operations, like the real coordinator
 */
contract MockVRFCoordinator is IPaintswapVRFCoordinator {
    /* -------------------------------------------------------------------------- */
    /*                                Constants                                   */
    /* -------------------------------------------------------------------------- */

    uint32 public constant MIN_CONSUMER_GAS_LIMIT = 5_000;
    uint32 private constant DEFAULT_MAX_CONSUMER_GAS_LIMIT = 6_000_000;
    uint16 private constant DEFAULT_MAX_NUM_WORDS = 500;
    uint256 private constant BASE_GAS_PRICE = 1 gwei;

    /* -------------------------------------------------------------------------- */
    /*                                 Storage                                    */
    /* -------------------------------------------------------------------------- */

    struct Request {
        address consumer;
        uint256 callbackGasLimit;
        uint256 numWords;
        uint256 payment;
        bool fulfilled;
        uint256 requestedAt;
    }

    // Core state from real coordinator
    mapping(address => uint256) private _nonces;
    mapping(uint256 => uint256) private _commitments;
    mapping(uint256 => Request) private _requests;
    mapping(uint256 => CallbackStatus) private _requestResults;

    address private _signerAddress;
    mapping(address => bool) private _oracles;

    uint32 private _gasForVRF = 300_000;
    uint32 private _maxConsumerGasLimit = DEFAULT_MAX_CONSUMER_GAS_LIMIT;
    uint16 private _maxNumWords = DEFAULT_MAX_NUM_WORDS;

    VRFStatistics private _vrfStatistics;

    /* -------------------------------------------------------------------------- */
    /*                                 Events                                     */
    /* -------------------------------------------------------------------------- */

    event DebugFulfillment(
        uint256 indexed requestId,
        bool callSuccess,
        string reason
    );

    /* -------------------------------------------------------------------------- */
    /*                                 Errors                                     */
    /* -------------------------------------------------------------------------- */

    error RequestNotFound(uint256 requestId);

    /* -------------------------------------------------------------------------- */
    /*                              Constructor                                   */
    /* -------------------------------------------------------------------------- */

    constructor() {
        _signerAddress = msg.sender;
        _oracles[msg.sender] = true;

        // Initialize statistics
        _vrfStatistics = VRFStatistics({
            totalRequests: 0,
            totalWordsRequested: 0,
            successfulFulfillments: 0,
            failedFulfillments: 0
        });

        emit OracleRegistered(msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Mock Functions                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Manually fulfill a request for testing
     * @param requestId The ID of the request to fulfill
     * @param randomWords Array of random words to provide
     */
    function fulfillRequestMock(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external {
        Request storage request = _requests[requestId];
        require(request.consumer != address(0), RequestNotFound(requestId));
        require(
            randomWords.length == request.numWords,
            InvalidNumWords(randomWords.length, request.numWords)
        );

        _fulfillRequest(requestId, randomWords);
    }

    /**
     * @dev Generate pseudo-random words and fulfill a request for testing
     * @param requestId The ID of the request to fulfill
     */
    function fulfillRequestMockWithRandomWords(uint256 requestId) external {
        Request storage request = _requests[requestId];

        // Generate pseudo-random words
        uint256[] memory randomWords = new uint256[](request.numWords);
        for (uint256 i = 0; i < request.numWords; i++) {
            randomWords[i] = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        requestId,
                        i,
                        request.consumer,
                        msg.sender
                    )
                )
            );
        }

        _fulfillRequest(requestId, randomWords);
    }

    /**
     * @dev Calculate the next request ID based on the consumer's nonce
     * @return requestId The next request ID
     * @dev This can be used by a consumer to store information ahead of the request
     */
    function calculateNextRequestId(
        address consumer
    ) external view returns (uint256 requestId) {
        uint256 nonce = _nonces[consumer] + 1; // Incremented nonce
        requestId = _computeRequestId(consumer, nonce);
    }

    /* -------------------------------------------------------------------------- */
    /*                         VRF Coordinator Interface                         */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IPaintswapVRFCoordinator
    function calculateRequestPriceNative(
        uint256 callbackGasLimit
    ) external view override returns (uint256 payment) {
        _validateGasLimit(callbackGasLimit);
        // Simple pricing: (callback gas + VRF gas) * base price
        payment = (callbackGasLimit + _gasForVRF) * BASE_GAS_PRICE;
    }

    /// @inheritdoc IPaintswapVRFCoordinator
    function requestRandomnessPayInNative(
        uint256 callbackGasLimit,
        uint256 numWords
    ) external payable override returns (uint256 requestId) {
        // Validate inputs (same as real coordinator)
        _validateGasLimit(callbackGasLimit);
        _validateNumWords(numWords);

        // Calculate required payment
        uint256 requiredPayment = this.calculateRequestPriceNative(
            callbackGasLimit
        );
        require(
            msg.value >= requiredPayment,
            InsufficientGasPayment(msg.value, requiredPayment)
        );

        // Generate request ID using same logic as real coordinator
        address consumer = msg.sender;
        uint256 nonce = _nonces[consumer] + 1;
        _nonces[consumer] = nonce;
        requestId = _computeRequestId(consumer, nonce);

        // Store commitment (same format as real coordinator)
        _commitments[requestId] = uint256(
            keccak256(
                abi.encode(
                    requestId,
                    callbackGasLimit,
                    numWords,
                    consumer,
                    block.chainid
                )
            )
        );

        // Store request details
        _requests[requestId] = Request({
            consumer: consumer,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            payment: msg.value,
            fulfilled: false,
            requestedAt: block.number
        });

        // Update statistics
        unchecked {
            ++_vrfStatistics.totalRequests;
            _vrfStatistics.totalWordsRequested += uint64(numWords);
        }

        // Emit event (same format as real coordinator)
        emit RandomWordsRequested(
            requestId,
            callbackGasLimit,
            numWords,
            tx.origin,
            consumer,
            nonce,
            block.timestamp
        );

        return requestId;
    }

    /// @inheritdoc IPaintswapVRFCoordinator
    function isRequestPending(
        uint256 requestId
    ) external view override returns (bool isPending) {
        return _commitments[requestId] != 0 && !_requests[requestId].fulfilled;
    }

    /// @inheritdoc IPaintswapVRFCoordinator
    function fulfillRandomWords(
        uint256 requestId,
        address consumer,
        uint256 callbackGasLimit,
        uint256 numWords,
        uint256[2] memory publicKey,
        uint256[4] memory proof,
        uint256[2] memory /* uPoint */,
        uint256[4] memory /* vComponents */,
        uint8 /* proofCtr */
    ) external override returns (bool callSuccess) {
        // Validate commitment (same as real coordinator)
        uint256 commitment = uint256(
            keccak256(
                abi.encode(
                    requestId,
                    callbackGasLimit,
                    numWords,
                    consumer,
                    block.chainid
                )
            )
        );
        require(
            _commitments[requestId] == commitment,
            CommitmentMismatch(requestId)
        );

        // In mock, we skip cryptographic verification and generate pseudo-random words
        uint256[] memory randomWords = new uint256[](numWords);
        for (uint256 i = 0; i < numWords; i++) {
            randomWords[i] = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        requestId,
                        i,
                        publicKey[0],
                        proof[0]
                    )
                )
            );
        }

        return _fulfillRequest(requestId, randomWords);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Internal Functions                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Internal function to fulfill a request
     * @param requestId The ID of the request to fulfill
     * @param randomWords The random words to provide
     * @return callSuccess Whether the callback was successful
     */
    function _fulfillRequest(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal returns (bool callSuccess) {
        Request storage request = _requests[requestId];

        require(_commitments[requestId] != 0, CommitmentMismatch(requestId));

        // Mark as fulfilled and delete commitment BEFORE calling the consumer
        // This prevents reentrancy and matches the real coordinator behavior
        request.fulfilled = true;
        delete _commitments[requestId];

        // Initialize the result as PENDING first
        _requestResults[requestId] = CallbackStatus.PENDING;

        // Attempt callback with low-level call
        (bool success, bytes memory returnData) = request.consumer.call{
            gas: request.callbackGasLimit
        }(
            abi.encodeWithSelector(
                IPaintswapVRFConsumer.rawFulfillRandomWords.selector,
                requestId,
                randomWords
            )
        );

        if (success) {
            callSuccess = true;
            unchecked {
                ++_vrfStatistics.successfulFulfillments;
            }
            _requestResults[requestId] = CallbackStatus.SUCCESS;
            emit DebugFulfillment(requestId, true, "callback succeeded");
        } else {
            callSuccess = false;
            unchecked {
                ++_vrfStatistics.failedFulfillments;
            }
            _requestResults[requestId] = CallbackStatus.FAILURE;
            emit ConsumerCallbackFailed(
                requestId,
                3,
                request.consumer,
                gasleft()
            );

            string memory reason = "callback failed: low level revert";

            if (returnData.length >= 4) {
                // Check for Error(string) selector: 0x08c379a0
                if (
                    returnData[0] == 0x08 &&
                    returnData[1] == 0xc3 &&
                    returnData[2] == 0x79 &&
                    returnData[3] == 0xa0
                ) {
                    // Error(string) selector found
                    if (returnData.length > 4) {
                        // Extract the string data
                        bytes memory errorData = new bytes(
                            returnData.length - 4
                        );
                        for (uint256 i = 0; i < errorData.length; i++) {
                            errorData[i] = returnData[i + 4];
                        }

                        // Try to decode the string
                        try this.decodeErrorString(errorData) returns (
                            string memory errorMessage
                        ) {
                            if (bytes(errorMessage).length > 0) {
                                reason = string.concat(
                                    "callback failed: ",
                                    errorMessage
                                );
                            } else {
                                reason = "callback failed: Error(string) with no message";
                            }
                        } catch {
                            reason = "callback failed: Error(string) with no message";
                        }
                    } else {
                        reason = "callback failed: Error(string) with no message";
                    }
                } else {
                    // Not Error(string), so it's some other revert with data
                    reason = "callback failed: low level revert with data";
                }
            } else if (returnData.length == 0) {
                // Empty revert data
                reason = "callback failed: low level revert";
            } else {
                // Has some revert data but less than 4 bytes
                reason = "callback failed: low level revert with data";
            }

            emit DebugFulfillment(requestId, false, reason);
        }

        // Emit fulfillment event
        emit RandomWordsFulfilled(
            requestId,
            randomWords,
            address(this), // Use this contract as the oracle for mock
            callSuccess,
            block.timestamp
        );

        return callSuccess;
    }

    /**
     * @dev Helper function to decode error string with proper error handling
     * @param errorData The ABI-encoded error data
     * @return errorMessage The decoded error message
     */
    function decodeErrorString(
        bytes memory errorData
    ) external pure returns (string memory errorMessage) {
        return abi.decode(errorData, (string));
    }

    /**
     * @dev Compute request ID using same logic as real coordinator
     */
    function _computeRequestId(
        address sender,
        uint256 nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(sender, nonce)));
    }

    /**
     * @dev Validate gas limit parameters
     */
    function _validateGasLimit(uint256 callbackGasLimit) internal view {
        require(
            callbackGasLimit >= MIN_CONSUMER_GAS_LIMIT,
            InsufficientGasLimit(callbackGasLimit, MIN_CONSUMER_GAS_LIMIT)
        );
        require(
            callbackGasLimit <= _maxConsumerGasLimit,
            OverConsumerGasLimit(callbackGasLimit, _maxConsumerGasLimit)
        );
    }

    /**
     * @dev Validate number of words parameter
     */
    function _validateNumWords(uint256 numWords) internal view {
        require(
            numWords > 0 && numWords <= _maxNumWords,
            InvalidNumWords(numWords, _maxNumWords)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              View Functions                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Get request details for testing
     */
    function getRequest(
        uint256 requestId
    )
        external
        view
        returns (
            address consumer,
            uint256 callbackGasLimit,
            uint256 numWords,
            uint256 payment,
            bool fulfilled
        )
    {
        Request storage request = _requests[requestId];
        return (
            request.consumer,
            request.callbackGasLimit,
            request.numWords,
            request.payment,
            request.fulfilled
        );
    }

    /**
     * @dev Get nonce for consumer (matches real coordinator interface)
     */
    function getNonce(address consumer) external view returns (uint256) {
        return _nonces[consumer];
    }

    /**
     * @dev Check if address is oracle (matches real coordinator interface)
     */
    function isOracle(address oracle) external view returns (bool) {
        return _oracles[oracle];
    }

    /**
     * @dev Get signer address (matches real coordinator interface)
     */
    function getSignerAddress() external view returns (address) {
        return _signerAddress;
    }

    /**
     * @dev Get fulfillment statistics (matches real coordinator interface)
     */
    function getFulfillmentStats()
        external
        view
        returns (
            uint64 total,
            uint64 pending,
            uint64 successes,
            uint64 failures,
            uint64 totalWordsRequested
        )
    {
        VRFStatistics memory stats = _vrfStatistics;
        uint64 pendingFulfillments = stats.totalRequests -
            (stats.successfulFulfillments + stats.failedFulfillments);
        return (
            stats.totalRequests,
            pendingFulfillments,
            stats.successfulFulfillments,
            stats.failedFulfillments,
            stats.totalWordsRequested
        );
    }

    /**
     * @dev Get request result (matches real coordinator interface)
     */
    function getRequestResult(
        uint256 requestId
    ) external view returns (bool wasSuccess, bool wasFulfilled) {
        bool fulfilled = _requestResults[requestId] != CallbackStatus.PENDING;
        return (
            _requestResults[requestId] == CallbackStatus.SUCCESS,
            fulfilled
        );
    }

    /**
     * @dev Accept ETH for testing
     */
    receive() external payable {}
}
