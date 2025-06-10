// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

interface IPaintswapVRFCoordinator {
  /* -------------------------------------------------------------------------- */
  /*                                 Events                                     */
  /* -------------------------------------------------------------------------- */

  /// @dev Emitted when a request is made to PaintswapVRFCoordinator
  event RandomWordsRequested(
    uint256 indexed requestId,
    uint256 callbackGasLimit,
    uint256 numWords,
    address indexed origin,
    address indexed consumer,
    uint256 nonce,
    address refundee,
    uint256 gasPricePaid,
    uint256 requestedAt
  );
  /// @dev Emitted when PaintswapVRFCoordinator fulfills a request
  event RandomWordsFulfilled(
    uint256 indexed requestId,
    uint256[] randomWords,
    address indexed oracle,
    bool callSuccess,
    uint256 fulfilledAt
  );
  /// @dev Emitted when a consumer callback is not successful
  event ConsumerCallbackFailed(
    uint256 indexed requestId,
    uint8 indexed reason, // 1 = not enough gas, 2 = no code, 3 = reverted or out of gas
    address indexed target,
    uint256 gasLeft
  );

  /// @dev Emitted when the gas refund after fulfillment fails
  event FulfillmentGasRefunded(
    uint256 indexed requestId,
    address indexed refundee,
    uint256 gasRefunded,
    bool refundedSuccessfully
  );
  /// @dev Emitted when the signer address is updated
  event SignerAddressUpdated(address indexed signerAddress);
  /// @dev Emitted when a new oracle is registered
  event OracleRegistered(address indexed oracle);
  /// @dev Emitted whne the gas price history window is updated
  event GasPriceHistoryWindowUpdated(uint256 newWindow);
  /// @dev Emitted when request limits are updated
  event RandomRequestLimitsUpdated(
    uint32 minimumGasLimit,
    uint32 maximumGasLimit,
    uint16 maxNumWords
  );

  /* -------------------------------------------------------------------------- */
  /*                                 Errors                                     */
  /* -------------------------------------------------------------------------- */

  /// @dev Revert when submitted address is the zero address
  error ZeroAddress();
  /// @dev Revert when the oracle is already registered
  error OracleAlreadyRegistered(address oracle);
  /// @dev Revert when the oracle has an insufficient balance
  error InsufficientOracleBalance(address oracle, uint256 balance);
  /// @dev Revert when the address is not an oracle
  error NotOracle(address invalid);
  /// @dev Revert when the request has an insufficient gas limit to fulfill
  error InsufficientGasLimit(uint256 sent, uint256 required);
  /// @dev Revert when the consumer gas limit is too high
  error OverConsumerGasLimit(uint256 sent, uint256 max);
  /// @dev Revert when the payment is too low for the requested gas limit
  error InsufficientGasPayment(uint256 sent, uint256 required);
  /// @dev Revert when the request has an invalid number of words
  error InvalidNumWords(uint256 numWords, uint256 max);
  /// @dev Revert when the fufillment call does not match the commitment
  error CommitmentMismatch(uint256 requestId);
  /// @dev Revert when the oracle has an invalid public key
  error InvalidPublicKey(
    uint256 requestId,
    address proofSigner,
    address vrfSigner
  );
  /// @dev Revert when the proof is invalid
  error InvalidProof(uint256 requestId);
  /// @dev Revert when the withdraw fails
  error WithdrawFailed(address recipient, uint256 amount);
  /// @dev Revert when the gas price history is invalid
  error InvalidGasPriceHistoryWindow(uint256 window);
  /// @dev Revert when funding has failed
  error FundingFailed(address oracle, uint256 amount);

  /* -------------------------------------------------------------------------- */
  /*                               Oracle structs                               */
  /* -------------------------------------------------------------------------- */

  struct VRFStatistics {
    uint64 totalRequests;
    uint64 totalWordsRequested;
    uint64 successfulFulfillments;
    uint64 failedFulfillments;
  }

  /* -------------------------------------------------------------------------- */
  /*                               Oracle enums                                 */
  /* -------------------------------------------------------------------------- */

  enum CallbackStatus {
    PENDING,
    SUCCESS,
    FAILURE
  }

  /* -------------------------------------------------------------------------- */
  /*                               Oracle methods                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Calculate the payment for a given amount of gas using native currency
  /// @param callbackGasLimit The amount of gas to provide for the callback
  /// @return payment The amount to pay
  function calculateRequestPriceNative(
    uint256 callbackGasLimit
  ) external view returns (uint256 payment);

  /// @notice Request some random words
  ///
  /// @param callbackGasLimit The amount of gas to provide for the callback
  /// @param numWords The number of words to request
  /// @param refundee The address to refund the gas fees to
  /// @return requestId The ID of the request
  function requestRandomnessPayInNative(
    uint256 callbackGasLimit,
    uint256 numWords,
    address refundee
  ) external payable returns (uint256 requestId);

  /// @notice Check to see if a request is pending
  ///
  /// @param requestId The ID of the request
  /// @return isPending True if the request is pending, false otherwise/does not exist
  function isRequestPending(
    uint256 requestId
  ) external view returns (bool isPending);

  /// @notice Fulfill the request for random words
  ///
  /// @param requestId The ID of the request
  /// @param consumer The address to fulfill the request
  /// @param consumer The amount of gas fees paid to fulfill the request
  /// @param numWords The number of words to fulfill
  /// @param refundee The address to refund the gas fees to
  /// @param gasPricePaid The gas price paid for the request
  /// @param publicKey The public key of the oracle
  /// @param proof The proof of the random words
  /// @param uPoint The `u` EC point defined as `U = s*B - c*Y`
  /// @param vComponents The components required to compute `v` as `V = s*H - c*Gamma`
  /// @param proofCtr The proof counter
  /// @return callSuccess If the fulfillment call succeeded
  function fulfillRandomWords(
    uint256 requestId,
    address consumer,
    uint256 callbackGasLimit,
    uint256 numWords,
    address refundee,
    uint256 gasPricePaid,
    uint256[2] memory publicKey,
    uint256[4] memory proof,
    uint256[2] memory uPoint,
    uint256[4] memory vComponents,
    uint8 proofCtr
  ) external returns (bool callSuccess);
}
