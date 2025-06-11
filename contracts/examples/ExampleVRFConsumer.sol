// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {PaintswapVRFConsumer} from "../PaintswapVRFConsumer.sol";

/**
 * @title ExampleVRFConsumer
 * @notice Example implementation of a Paintswap VRF consumer contract
 * @dev Demonstrates best practices for using Paintswap VRF to generate random numbers
 *
 * This example shows:
 * - How to request randomness with proper gas calculation
 * - How to fund the VRF requests
 * - How to handle VRF fulfillment callbacks
 * - How to store and manage request state
 * - How to implement proper access controls
 * - How to handle edge cases and errors
 */
contract ExampleVRFConsumer is PaintswapVRFConsumer {
  /// @notice Maximum number of random words that can be requested in a single call
  uint256 public constant MAX_WORDS_PER_REQUEST = 10;

  /// @notice Gas limit for the VRF callback function
  /// @dev Should be sufficient for your _fulfillRandomWords implementation
  uint256 public constant CALLBACK_GAS_LIMIT = 2_000_000;

  /* -------------------------------------------------------------------------- */
  /*                                 Storage                                    */
  /* -------------------------------------------------------------------------- */

  /// @notice Structure to track randomness requests
  struct RandomnessRequest {
    address requester; // Who made the request
    uint256 numWords; // Number of random words requested
    uint256 requestedAt; // Block timestamp when requested
    bool fulfilled; // Whether the request has been fulfilled
    uint256[] randomWords; // The fulfilled random words (empty until fulfilled)
  }

  /// @notice Mapping from request ID to request details
  mapping(uint256 => RandomnessRequest) public requests;

  /// @notice Array to track all request IDs (for enumeration)
  uint256[] public allRequestIds;

  /// @notice Counter for tracking total requests made
  uint256 public totalRequests;

  /// @notice Counter for tracking fulfilled requests
  uint256 public fulfilledRequests;

  /* -------------------------------------------------------------------------- */
  /*                                 Events                                     */
  /* -------------------------------------------------------------------------- */

  /// @notice Emitted when randomness is requested
  event RandomnessRequested(
    uint256 indexed requestId,
    address indexed requester,
    uint256 numWords,
    uint256 timestamp,
    bool paidFromContract
  );

  /// @notice Emitted when randomness is fulfilled
  event RandomnessFulfilled(
    uint256 indexed requestId,
    address indexed requester,
    uint256[] randomWords,
    uint256 timestamp
  );

  /// @notice Emitted when a dice roll is processed
  event RandomDiceRoll(
    uint256 indexed requestId,
    address indexed requester,
    uint256 roll
  );

  /// @notice Emitted when lottery numbers are processed
  event RandomLotteryNumbers(
    uint256 indexed requestId,
    address indexed requester,
    uint256[] numbers
  );

  /// @notice Emitted when a random percentage is processed
  event RandomPercentage(
    uint256 indexed requestId,
    address indexed requester,
    uint256 percentage
  );

  /// @notice Emitted when funds are deposited to the contract
  event FundsDeposited(address indexed depositor, uint256 amount);

  /* -------------------------------------------------------------------------- */
  /*                                 Errors                                     */
  /* -------------------------------------------------------------------------- */

  /// @notice Thrown when an invalid number of words is requested
  error InvalidNumWords(uint256 requested, uint256 max);

  /// @notice Thrown when insufficient payment is provided
  error InsufficientPayment(uint256 provided, uint256 required);

  /// @notice Thrown when contract has insufficient funds
  error InsufficientContractFunds(uint256 available, uint256 required);

  /// @notice Thrown when deposit amount is zero
  error ZeroDepositAmount();

  /**
   * @notice Initialize the VRF consumer contract
   * @param vrfCoordinator Address of the Paintswap VRF coordinator
   */
  constructor(address vrfCoordinator) PaintswapVRFConsumer(vrfCoordinator) {}

  /**
   * @notice Request random words from the VRF coordinator with direct payment
   * @param numWords Number of random words to request (1-10)
   * @return requestId The ID of the VRF request
   *
   * @dev Requirements:
   * - numWords must be between 1 and MAX_WORDS_PER_REQUEST
   * - msg.value must cover the exact VRF request cost
   *
   * Example usage:
   * ```solidity
   * // Calculate required payment
   * uint256 fee = exampleConsumer.getRequestPrice(3);
   *
   * // Request 3 random words with direct payment
   * uint256 requestId = exampleConsumer.requestRandomWords{value: fee}(3);
   * ```
   */
  function requestRandomWords(
    uint256 numWords
  ) external payable returns (uint256 requestId) {
    // Validate input parameters
    require(
      numWords > 0 && numWords <= MAX_WORDS_PER_REQUEST,
      InvalidNumWords(numWords, MAX_WORDS_PER_REQUEST)
    );

    // Calculate required payment for the request
    uint256 requiredPayment = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
    require(
      msg.value >= requiredPayment,
      InsufficientPayment(msg.value, requiredPayment)
    );

    // Request randomness from VRF coordinator
    requestId = _requestRandomnessPayInNative(
      CALLBACK_GAS_LIMIT,
      numWords,
      msg.value, // fullfillment gas
      msg.sender // refundee
    );

    // Store request details
    requests[requestId] = RandomnessRequest({
      requester: msg.sender,
      numWords: numWords,
      requestedAt: block.timestamp,
      fulfilled: false,
      randomWords: new uint256[](0)
    });

    // Track request for enumeration
    allRequestIds.push(requestId);
    totalRequests++;

    // Emit event
    emit RandomnessRequested(
      requestId,
      msg.sender,
      numWords,
      block.timestamp,
      false // Not paid from contract
    );

    return requestId;
  }

  /**
   * @notice Request random words from the VRF coordinator using contract funds
   * @param numWords Number of random words to request (1-10)
   * @return requestId The ID of the VRF request
   *
   * @dev Requirements:
   * - numWords must be between 1 and MAX_WORDS_PER_REQUEST
   * - Contract must have sufficient funds to cover the VRF request cost
   *
   * Example usage:
   * ```solidity
   * // Fund the contract first
   * exampleConsumer.fundVRF{value: 1 ether}();
   *
   * // Request 3 random words using contract funds
   * uint256 requestId = exampleConsumer.requestRandomWordsFromContract(3);
   * ```
   */
  function requestRandomWordsFromContract(
    uint256 numWords
  ) external returns (uint256 requestId) {
    // Validate input parameters
    require(
      numWords > 0 && numWords <= MAX_WORDS_PER_REQUEST,
      InvalidNumWords(numWords, MAX_WORDS_PER_REQUEST)
    );

    // Calculate required payment for the request
    uint256 requiredPayment = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);

    // Check contract has sufficient funds
    require(
      address(this).balance >= requiredPayment,
      InsufficientContractFunds(address(this).balance, requiredPayment)
    );

    // Request randomness from VRF coordinator using contract funds
    requestId = _requestRandomnessPayInNative(
      CALLBACK_GAS_LIMIT,
      numWords,
      requiredPayment
    );

    // Store request details
    requests[requestId] = RandomnessRequest({
      requester: msg.sender,
      numWords: numWords,
      requestedAt: block.timestamp,
      fulfilled: false,
      randomWords: new uint256[](0)
    });

    // Track request for enumeration
    allRequestIds.push(requestId);
    totalRequests++;

    // Emit event
    emit RandomnessRequested(
      requestId,
      msg.sender,
      numWords,
      block.timestamp,
      true // Paid from contract
    );

    return requestId;
  }

  /**
   * @notice Deposit funds to the contract for VRF requests
   * @dev Anyone can deposit funds to support VRF operations
   */
  function fundVRF() external payable {
    require(msg.value > 0, ZeroDepositAmount());
    emit FundsDeposited(msg.sender, msg.value);
  }

  /**
   * @notice Get the cost to request randomness
   * @param numWords Number of words that will be requested
   * @return cost The cost in native currency (wei)
   *
   * @dev Use this function to calculate the required payment before calling requestRandomWords
   */
  function getRequestPrice(
    uint256 numWords
  ) external view returns (uint256 cost) {
    // Validate input (same validation as request function)
    require(
      numWords > 0 && numWords <= MAX_WORDS_PER_REQUEST,
      InvalidNumWords(numWords, MAX_WORDS_PER_REQUEST)
    );

    return _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
  }

  /**
   * @notice Check if contract has sufficient funds for a request
   * @return sufficient Whether the contract has enough funds
   * @return available Current contract balance
   * @return required Required amount for the request
   */
  function checkContractFunds()
    external
    view
    returns (bool sufficient, uint256 available, uint256 required)
  {
    available = address(this).balance;
    required = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
    sufficient = available >= required;
  }

  /**
   * @notice Check the status of a randomness request
   * @param requestId The ID of the request to check
   * @return exists Whether the request exists
   * @return fulfilled Whether the request has been fulfilled
   * @return requester Address that made the request
   * @return numWords Number of words requested
   * @return refundee Address to refund gas fees
   * @return requestedAt Timestamp when request was made
   * @return randomWords The random words (empty if not fulfilled)
   */
  function getRequestStatus(
    uint256 requestId
  )
    external
    view
    returns (
      bool exists,
      bool fulfilled,
      address requester,
      uint256 numWords,
      address refundee,
      uint256 requestedAt,
      uint256[] memory randomWords
    )
  {
    RandomnessRequest storage request = requests[requestId];

    // Non-zero timestamp indicates request exists
    exists = request.requestedAt != 0;
    fulfilled = request.fulfilled;
    requester = request.requester;
    numWords = request.numWords;
    refundee = request.requester;
    requestedAt = request.requestedAt;
    randomWords = request.randomWords;
  }

  /**
   * @notice Get all request IDs made by a specific address
   * @param requester The address to filter by
   * @return requestIds Array of request IDs made by the requester
   *
   * @dev This function may be gas-expensive for addresses with many requests
   */
  function getRequestsByRequester(
    address requester
  ) external view returns (uint256[] memory requestIds) {
    // Count requests by this requester
    uint256 count = 0;
    for (uint256 i = 0; i < allRequestIds.length; i++) {
      if (requests[allRequestIds[i]].requester == requester) {
        count++;
      }
    }

    // Build array of request IDs
    requestIds = new uint256[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < allRequestIds.length; i++) {
      if (requests[allRequestIds[i]].requester == requester) {
        requestIds[index] = allRequestIds[i];
        index++;
      }
    }
  }

  /**
   * @notice Get the total number of requests and fulfillments
   * @return total Total number of requests made
   * @return fulfilled Number of requests that have been fulfilled
   * @return pending Number of requests still pending
   */
  function getStats()
    external
    view
    returns (uint256 total, uint256 fulfilled, uint256 pending)
  {
    total = totalRequests;
    fulfilled = fulfilledRequests;
    pending = total - fulfilled;
  }

  /**
   * @notice Get the VRF coordinator address being used
   * @return coordinator Address of the VRF coordinator
   */
  function getVRFCoordinator() external view returns (address coordinator) {
    return address(_vrfCoordinator);
  }

  /**
   * @notice Callback function called by VRF coordinator when randomness is ready
   * @param requestId The ID of the request being fulfilled
   * @param randomWords Array of random words generated by VRF
   *
   * @dev This function is called by the VRF coordinator. Do not call directly.
   * @dev Keep this function gas-efficient as it's limited by CALLBACK_GAS_LIMIT
   */
  function _fulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
  ) internal override {
    // Get the request (this should always exist if called by coordinator)
    RandomnessRequest storage request = requests[requestId];

    // Store the random words
    request.randomWords = randomWords;
    request.fulfilled = true;

    // Update global counter
    fulfilledRequests++;

    // Emit fulfillment event
    emit RandomnessFulfilled(
      requestId,
      request.requester,
      randomWords,
      block.timestamp
    );

    // Optional: Add custom logic here for processing the random words
    _processRandomWords(requestId, request.requester, randomWords);
  }

  /**
   * @notice Process the received random words (override in derived contracts)
   * @param requestId The request ID that was fulfilled
   * @param requester The address that made the original request
   * @param randomWords The random words received from VRF
   *
   * @dev Override this function in derived contracts to add custom logic
   * @dev Keep gas usage low as this is called within the VRF callback
   */
  function _processRandomWords(
    uint256 requestId,
    address requester,
    uint256[] memory randomWords
  ) internal virtual {
    // Use first random word to generate a dice roll (1-6)
    uint256 diceRoll = _randomInRange(randomWords[0], 1, 6);

    // Use first random word to generate 3 lottery numbers (1-50)
    uint256[] memory lotteryNumbers = _multipleRandomInRange(
      randomWords[0],
      3,
      1,
      50
    );

    // Emit events with the processed results
    emit RandomDiceRoll(requestId, requester, diceRoll);
    emit RandomLotteryNumbers(requestId, requester, lotteryNumbers);

    // If we have more random words, process them too
    if (randomWords.length > 1) {
      // Generate a random percentage from second word
      uint256 percentage = _randomInRange(randomWords[1], 0, 100);
      emit RandomPercentage(requestId, requester, percentage);
    }
  }

  /**
   * @notice Generate a random number within a specific range
   * @param randomWord The random word from VRF
   * @param min Minimum value (inclusive)
   * @param max Maximum value (inclusive)
   * @return result Random number between min and max
   *
   * @dev Utility function for converting VRF output to specific ranges
   */
  function _randomInRange(
    uint256 randomWord,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256 result) {
    return (randomWord % (max - min + 1)) + min;
  }

  /**
   * @notice Generate multiple random numbers in a range from a single random word
   * @param randomWord The random word from VRF
   * @param count Number of random numbers to generate
   * @param min Minimum value (inclusive)
   * @param max Maximum value (inclusive)
   * @return results Array of random numbers
   *
   * @dev Uses keccak256 to derive additional randomness from a single word
   */
  function _multipleRandomInRange(
    uint256 randomWord,
    uint256 count,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256[] memory results) {
    results = new uint256[](count);
    for (uint256 i = 0; i < count; i++) {
      uint256 derivedRandom = uint256(keccak256(abi.encode(randomWord, i)));
      results[i] = _randomInRange(derivedRandom, min, max);
    }
  }
}
