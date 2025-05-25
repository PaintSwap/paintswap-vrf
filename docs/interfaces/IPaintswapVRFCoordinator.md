# IPaintswapVRFCoordinator









## Methods

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

### fulfillRandomWords

```solidity
function fulfillRandomWords(uint256 requestId, address fulfillAddress, uint256 gasFeePaid, uint256 numWords, uint256[2] publicKey, uint256[4] proof, uint256[2] uPoint, uint256[4] vComponents, uint8 proofCtr) external nonpayable returns (bool callSuccess)
```

Fulfill the request for random words



#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request |
| fulfillAddress | address | The address to fulfill the request |
| gasFeePaid | uint256 | The amount of gas fees paid to fulfill the request |
| numWords | uint256 | The number of words to fulfill |
| publicKey | uint256[2] | The public key of the oracle |
| proof | uint256[4] | The proof of the random words |
| uPoint | uint256[2] | The `u` EC point defined as `U = s*B - c*Y` |
| vComponents | uint256[4] | The components required to compute `v` as `V = s*H - c*Gamma` |
| proofCtr | uint8 | The proof counter |

#### Returns

| Name | Type | Description |
|---|---|---|
| callSuccess | bool | If the fulfillment call succeeded |

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
event RandomWordsFulfilled(uint256 indexed requestId, uint256[] randomWords, address indexed oracle, bool callSuccess)
```



*Emitted when PaintswapVRFCoordinator fulfills a request*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| randomWords  | uint256[] | undefined |
| oracle `indexed` | address | undefined |
| callSuccess  | bool | undefined |

### RandomWordsRequested

```solidity
event RandomWordsRequested(uint256 indexed requestId, uint256 callbackGasLimit, uint256 numWords, address indexed consumer, uint256 nonce)
```



*Emitted when a request is made to PaintswapVRFCoordinator*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId `indexed` | uint256 | undefined |
| callbackGasLimit  | uint256 | undefined |
| numWords  | uint256 | undefined |
| consumer `indexed` | address | undefined |
| nonce  | uint256 | undefined |

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



