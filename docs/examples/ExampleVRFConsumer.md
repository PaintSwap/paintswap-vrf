# ExampleVRFConsumer



> ExampleVRFConsumer

Example implementation of a Paintswap VRF consumer contract

*Demonstrates best practices for using Paintswap VRF to generate random numbers This example shows: - How to request randomness with proper gas calculation - How to fund the VRF requests - How to handle VRF fulfillment callbacks - How to store and manage request state - How to implement proper access controls - How to handle edge cases and errors*

## Methods

### CALLBACK_GAS_LIMIT

```solidity
function CALLBACK_GAS_LIMIT() external view returns (uint256)
```

Gas limit for the VRF callback function

*Should be sufficient for your _fulfillRandomWords implementation*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### MAX_WORDS_PER_REQUEST

```solidity
function MAX_WORDS_PER_REQUEST() external view returns (uint256)
```

Maximum number of random words that can be requested in a single call




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### allRequestIds

```solidity
function allRequestIds(uint256) external view returns (uint256)
```

Array to track all request IDs (for enumeration)



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### checkContractFunds

```solidity
function checkContractFunds() external view returns (bool sufficient, uint256 available, uint256 required)
```

Check if contract has sufficient funds for a request




#### Returns

| Name | Type | Description |
|---|---|---|
| sufficient | bool | Whether the contract has enough funds |
| available | uint256 | Current contract balance |
| required | uint256 | Required amount for the request |

### fulfilledRequests

```solidity
function fulfilledRequests() external view returns (uint256)
```

Counter for tracking fulfilled requests




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### fundVRF

```solidity
function fundVRF() external payable
```

Deposit funds to the contract for VRF requests

*Anyone can deposit funds to support VRF operations*


### getRequestPrice

```solidity
function getRequestPrice(uint256 numWords) external view returns (uint256 cost)
```

Get the cost to request randomness

*Use this function to calculate the required payment before calling requestRandomWords*

#### Parameters

| Name | Type | Description |
|---|---|---|
| numWords | uint256 | Number of words that will be requested |

#### Returns

| Name | Type | Description |
|---|---|---|
| cost | uint256 | The cost in native currency (wei) |

### getRequestStatus

```solidity
function getRequestStatus(uint256 requestId) external view returns (bool exists, bool fulfilled, address requester, uint256 numWords, address refundee, uint256 requestedAt, uint256[] randomWords)
```

Check the status of a randomness request



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| exists | bool | Whether the request exists |
| fulfilled | bool | Whether the request has been fulfilled |
| requester | address | Address that made the request |
| numWords | uint256 | Number of words requested |
| refundee | address | Address to refund gas fees |
| requestedAt | uint256 | Timestamp when request was made |
| randomWords | uint256[] | The random words (empty if not fulfilled) |

### getRequestsByRequester

```solidity
function getRequestsByRequester(address requester) external view returns (uint256[] requestIds)
```

Get all request IDs made by a specific address

*This function may be gas-expensive for addresses with many requests*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requester | address | The address to filter by |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestIds | uint256[] | Array of request IDs made by the requester |

### getStats

```solidity
function getStats() external view returns (uint256 total, uint256 fulfilled, uint256 pending)
```

Get the total number of requests and fulfillments




#### Returns

| Name | Type | Description |
|---|---|---|
| total | uint256 | Total number of requests made |
| fulfilled | uint256 | Number of requests that have been fulfilled |
| pending | uint256 | Number of requests still pending |

### getVRFCoordinator

```solidity
function getVRFCoordinator() external view returns (address coordinator)
```

Get the VRF coordinator address being used




#### Returns

| Name | Type | Description |
|---|---|---|
| coordinator | address | Address of the VRF coordinator |

### rawFulfillRandomWords

```solidity
function rawFulfillRandomWords(uint256 requestId, uint256[] randomWords) external nonpayable
```

This function can only be called by the VRF coordinator

*Callback function called by the VRF coordinator to deliver random words*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request to which these random words belong |
| randomWords | uint256[] | The array of random words for the request |

### requestRandomWords

```solidity
function requestRandomWords(uint256 numWords) external payable returns (uint256 requestId)
```

Request random words from the VRF coordinator with direct payment

*Requirements: - numWords must be between 1 and MAX_WORDS_PER_REQUEST - msg.value must cover the exact VRF request cost Example usage: ```solidity // Calculate required payment uint256 fee = exampleConsumer.getRequestPrice(3); // Request 3 random words with direct payment uint256 requestId = exampleConsumer.requestRandomWords{value: fee}(3); ```*

#### Parameters

| Name | Type | Description |
|---|---|---|
| numWords | uint256 | Number of random words to request (1-10) |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the VRF request |

### requestRandomWordsFromContract

```solidity
function requestRandomWordsFromContract(uint256 numWords) external nonpayable returns (uint256 requestId)
```

Request random words from the VRF coordinator using contract funds

*Requirements: - numWords must be between 1 and MAX_WORDS_PER_REQUEST - Contract must have sufficient funds to cover the VRF request cost Example usage: ```solidity // Fund the contract first exampleConsumer.fundVRF{value: 1 ether}(); // Request 3 random words using contract funds uint256 requestId = exampleConsumer.requestRandomWordsFromContract(3); ```*

#### Parameters

| Name | Type | Description |
|---|---|---|
| numWords | uint256 | Number of random words to request (1-10) |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the VRF request |

### requests

```solidity
function requests(uint256) external view returns (address requester, uint256 numWords, uint256 requestedAt, bool fulfilled)
```

Mapping from request ID to request details



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| requester | address | undefined |
| numWords | uint256 | undefined |
| requestedAt | uint256 | undefined |
| fulfilled | bool | undefined |

### totalRequests

```solidity
function totalRequests() external view returns (uint256)
```

Counter for tracking total requests made




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### FundsDeposited

```solidity
event FundsDeposited(address indexed depositor, uint256 amount)
```

Emitted when funds are deposited to the contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| depositor `indexed` | address | undefined |
| amount  | uint256 | undefined |

### RandomDiceRoll

```solidity
event RandomDiceRoll(uint256 indexed requestId, address indexed requester, uint256 roll)
```

Emitted when a dice roll is processed



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| requester `indexed` | address | undefined |
| roll  | uint256 | undefined |

### RandomLotteryNumbers

```solidity
event RandomLotteryNumbers(uint256 indexed requestId, address indexed requester, uint256[] numbers)
```

Emitted when lottery numbers are processed



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| requester `indexed` | address | undefined |
| numbers  | uint256[] | undefined |

### RandomPercentage

```solidity
event RandomPercentage(uint256 indexed requestId, address indexed requester, uint256 percentage)
```

Emitted when a random percentage is processed



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| requester `indexed` | address | undefined |
| percentage  | uint256 | undefined |

### RandomnessFulfilled

```solidity
event RandomnessFulfilled(uint256 indexed requestId, address indexed requester, uint256[] randomWords, uint256 timestamp)
```

Emitted when randomness is fulfilled



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| requester `indexed` | address | undefined |
| randomWords  | uint256[] | undefined |
| timestamp  | uint256 | undefined |

### RandomnessRequested

```solidity
event RandomnessRequested(uint256 indexed requestId, address indexed requester, uint256 numWords, uint256 timestamp, bool paidFromContract)
```

Emitted when randomness is requested



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| requester `indexed` | address | undefined |
| numWords  | uint256 | undefined |
| timestamp  | uint256 | undefined |
| paidFromContract  | bool | undefined |



## Errors

### InsufficientContractFunds

```solidity
error InsufficientContractFunds(uint256 available, uint256 required)
```

Thrown when contract has insufficient funds



#### Parameters

| Name | Type | Description |
|---|---|---|
| available | uint256 | undefined |
| required | uint256 | undefined |

### InsufficientPayment

```solidity
error InsufficientPayment(uint256 provided, uint256 required)
```

Thrown when insufficient payment is provided



#### Parameters

| Name | Type | Description |
|---|---|---|
| provided | uint256 | undefined |
| required | uint256 | undefined |

### InvalidNumWords

```solidity
error InvalidNumWords(uint256 requested, uint256 max)
```

Thrown when an invalid number of words is requested



#### Parameters

| Name | Type | Description |
|---|---|---|
| requested | uint256 | undefined |
| max | uint256 | undefined |

### OnlyVRFCoordinator

```solidity
error OnlyVRFCoordinator(address sender, address coordinator)
```



*Error thrown when a function restricted to the VRF coordinator is called by another address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | The address that attempted to call the function |
| coordinator | address | The address of the authorized VRF coordinator |

### ZeroDepositAmount

```solidity
error ZeroDepositAmount()
```

Thrown when deposit amount is zero





