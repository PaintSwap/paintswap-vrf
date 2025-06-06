# MockVRFCoordinator



> MockVRFCoordinator

Simulates VRF coordinator functionality without cryptographic proofs

*Mock implementation of PaintswapVRFCoordinator for testingRequests and fulfillments are separate operations, like the real coordinator*

## Methods

### MIN_CONSUMER_GAS_LIMIT

```solidity
function MIN_CONSUMER_GAS_LIMIT() external view returns (uint32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint32 | undefined |

### calculateNextRequestId

```solidity
function calculateNextRequestId(address consumer) external view returns (uint256 requestId)
```



*Calculate the next request ID based on the consumer&#39;s nonceThis can be used by a consumer to store information ahead of the request*

#### Parameters

| Name | Type | Description |
|---|---|---|
| consumer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The next request ID |

### calculateRequestPriceNative

```solidity
function calculateRequestPriceNative(uint256 callbackGasLimit) external view returns (uint256 payment)
```

Calculate the payment for a given amount of gas using native currency



#### Parameters

| Name | Type | Description |
|---|---|---|
| callbackGasLimit | uint256 | The amount of gas to provide for the callback |

#### Returns

| Name | Type | Description |
|---|---|---|
| payment | uint256 | The amount to pay |

### decodeErrorString

```solidity
function decodeErrorString(bytes errorData) external pure returns (string errorMessage)
```



*Helper function to decode error string with proper error handling*

#### Parameters

| Name | Type | Description |
|---|---|---|
| errorData | bytes | The ABI-encoded error data |

#### Returns

| Name | Type | Description |
|---|---|---|
| errorMessage | string | The decoded error message |

### fulfillRandomWords

```solidity
function fulfillRandomWords(uint256 requestId, address consumer, uint256 callbackGasLimit, uint256 numWords, uint256[2] publicKey, uint256[4] proof, uint256[2], uint256[4], uint8) external nonpayable returns (bool callSuccess)
```

Fulfill the request for random words



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request |
| consumer | address | The amount of gas fees paid to fulfill the request |
| callbackGasLimit | uint256 | undefined |
| numWords | uint256 | The number of words to fulfill |
| publicKey | uint256[2] | The public key of the oracle |
| proof | uint256[4] | The proof of the random words |
| _6 | uint256[2] | undefined |
| _7 | uint256[4] | undefined |
| _8 | uint8 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| callSuccess | bool | If the fulfillment call succeeded |

### fulfillRequestMock

```solidity
function fulfillRequestMock(uint256 requestId, uint256[] randomWords) external nonpayable
```



*Manually fulfill a request for testing*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request to fulfill |
| randomWords | uint256[] | Array of random words to provide |

### fulfillRequestMockWithRandomWords

```solidity
function fulfillRequestMockWithRandomWords(uint256 requestId) external nonpayable
```



*Generate pseudo-random words and fulfill a request for testing*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request to fulfill |

### getFulfillmentStats

```solidity
function getFulfillmentStats() external view returns (uint64 total, uint64 pending, uint64 successes, uint64 failures, uint64 totalWordsRequested)
```



*Get fulfillment statistics (matches real coordinator interface)*


#### Returns

| Name | Type | Description |
|---|---|---|
| total | uint64 | undefined |
| pending | uint64 | undefined |
| successes | uint64 | undefined |
| failures | uint64 | undefined |
| totalWordsRequested | uint64 | undefined |

### getNonce

```solidity
function getNonce(address consumer) external view returns (uint256)
```



*Get nonce for consumer (matches real coordinator interface)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| consumer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getRequest

```solidity
function getRequest(uint256 requestId) external view returns (address consumer, uint256 callbackGasLimit, uint256 numWords, uint256 payment, bool fulfilled)
```



*Get request details for testing*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| consumer | address | undefined |
| callbackGasLimit | uint256 | undefined |
| numWords | uint256 | undefined |
| payment | uint256 | undefined |
| fulfilled | bool | undefined |

### getRequestResult

```solidity
function getRequestResult(uint256 requestId) external view returns (bool wasSuccess, bool wasFulfilled)
```



*Get request result (matches real coordinator interface)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| wasSuccess | bool | undefined |
| wasFulfilled | bool | undefined |

### getSignerAddress

```solidity
function getSignerAddress() external view returns (address)
```



*Get signer address (matches real coordinator interface)*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### isOracle

```solidity
function isOracle(address oracle) external view returns (bool)
```



*Check if address is oracle (matches real coordinator interface)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oracle | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isRequestPending

```solidity
function isRequestPending(uint256 requestId) external view returns (bool isPending)
```

Check to see if a request is pending



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request |

#### Returns

| Name | Type | Description |
|---|---|---|
| isPending | bool | True if the request is pending, false otherwise/does not exist |

### requestRandomnessPayInNative

```solidity
function requestRandomnessPayInNative(uint256 callbackGasLimit, uint256 numWords) external payable returns (uint256 requestId)
```

Request some random words



#### Parameters

| Name | Type | Description |
|---|---|---|
| callbackGasLimit | uint256 | The amount of gas to provide for the callback |
| numWords | uint256 | The number of words to request |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request |



## Events

### ConsumerCallbackFailed

```solidity
event ConsumerCallbackFailed(uint256 indexed requestId, uint8 indexed reason, address indexed target, uint256 gasLeft)
```



*Emitted when a consumer callback is not successful*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| reason `indexed` | uint8 | undefined |
| target `indexed` | address | undefined |
| gasLeft  | uint256 | undefined |

### DebugFulfillment

```solidity
event DebugFulfillment(uint256 indexed requestId, bool callSuccess, string reason)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| callSuccess  | bool | undefined |
| reason  | string | undefined |

### GasPriceHistoryWindowUpdated

```solidity
event GasPriceHistoryWindowUpdated(uint256 newWindow)
```



*Emitted whne the gas price history window is updated*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newWindow  | uint256 | undefined |

### OracleRegistered

```solidity
event OracleRegistered(address indexed oracle)
```



*Emitted when a new oracle is registered*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oracle `indexed` | address | undefined |

### RandomRequestLimitsUpdated

```solidity
event RandomRequestLimitsUpdated(uint32 minimumGasLimit, uint32 maximumGasLimit, uint16 maxNumWords)
```



*Emitted when request limits are updated*

#### Parameters

| Name | Type | Description |
|---|---|---|
| minimumGasLimit  | uint32 | undefined |
| maximumGasLimit  | uint32 | undefined |
| maxNumWords  | uint16 | undefined |

### RandomWordsFulfilled

```solidity
event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords, address indexed oracle, bool callSuccess, uint256 fulfilledAt)
```



*Emitted when PaintswapVRFCoordinator fulfills a request*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| randomWords  | uint256[] | undefined |
| oracle `indexed` | address | undefined |
| callSuccess  | bool | undefined |
| fulfilledAt  | uint256 | undefined |

### RandomWordsRequested

```solidity
event RandomWordsRequested(uint256 indexed requestId, uint256 callbackGasLimit, uint256 numWords, address indexed origin, address indexed consumer, uint256 nonce, uint256 requestedAt)
```



*Emitted when a request is made to PaintswapVRFCoordinator*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| callbackGasLimit  | uint256 | undefined |
| numWords  | uint256 | undefined |
| origin `indexed` | address | undefined |
| consumer `indexed` | address | undefined |
| nonce  | uint256 | undefined |
| requestedAt  | uint256 | undefined |

### SignerAddressUpdated

```solidity
event SignerAddressUpdated(address indexed signerAddress)
```



*Emitted when the signer address is updated*

#### Parameters

| Name | Type | Description |
|---|---|---|
| signerAddress `indexed` | address | undefined |



## Errors

### CommitmentMismatch

```solidity
error CommitmentMismatch(uint256 requestId)
```



*Revert when the fufillment call does not match the commitment*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

### FundingFailed

```solidity
error FundingFailed(address oracle, uint256 amount)
```



*Revert when funding has failed*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oracle | address | undefined |
| amount | uint256 | undefined |

### InsufficientGasLimit

```solidity
error InsufficientGasLimit(uint256 sent, uint256 required)
```



*Revert when the request has an insufficient gas limit to fulfill*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sent | uint256 | undefined |
| required | uint256 | undefined |

### InsufficientGasPayment

```solidity
error InsufficientGasPayment(uint256 sent, uint256 required)
```



*Revert when the payment is too low for the requested gas limit*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sent | uint256 | undefined |
| required | uint256 | undefined |

### InsufficientOracleBalance

```solidity
error InsufficientOracleBalance(address oracle, uint256 balance)
```



*Revert when the oracle has an insufficient balance*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oracle | address | undefined |
| balance | uint256 | undefined |

### InvalidGasPriceHistoryWindow

```solidity
error InvalidGasPriceHistoryWindow(uint256 window)
```



*Revert when the gas price history is invalid*

#### Parameters

| Name | Type | Description |
|---|---|---|
| window | uint256 | undefined |

### InvalidNumWords

```solidity
error InvalidNumWords(uint256 numWords, uint256 max)
```



*Revert when the request has an invalid number of words*

#### Parameters

| Name | Type | Description |
|---|---|---|
| numWords | uint256 | undefined |
| max | uint256 | undefined |

### InvalidProof

```solidity
error InvalidProof(uint256 requestId)
```



*Revert when the proof is invalid*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

### InvalidPublicKey

```solidity
error InvalidPublicKey(uint256 requestId, address proofSigner, address vrfSigner)
```



*Revert when the oracle has an invalid public key*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |
| proofSigner | address | undefined |
| vrfSigner | address | undefined |

### NotOracle

```solidity
error NotOracle(address invalid)
```



*Revert when the address is not an oracle*

#### Parameters

| Name | Type | Description |
|---|---|---|
| invalid | address | undefined |

### OracleAlreadyRegistered

```solidity
error OracleAlreadyRegistered(address oracle)
```



*Revert when the oracle is already registered*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oracle | address | undefined |

### OverConsumerGasLimit

```solidity
error OverConsumerGasLimit(uint256 sent, uint256 max)
```



*Revert when the consumer gas limit is too high*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sent | uint256 | undefined |
| max | uint256 | undefined |

### RequestNotFound

```solidity
error RequestNotFound(uint256 requestId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

### WithdrawFailed

```solidity
error WithdrawFailed(address recipient, uint256 amount)
```



*Revert when the withdraw fails*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | undefined |
| amount | uint256 | undefined |

### ZeroAddress

```solidity
error ZeroAddress()
```



*Revert when submitted address is the zero address*



