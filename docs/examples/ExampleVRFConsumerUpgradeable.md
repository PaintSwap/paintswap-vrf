# ExampleVRFConsumerUpgradeable









## Methods

### UPGRADE_INTERFACE_VERSION

```solidity
function UPGRADE_INTERFACE_VERSION() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### calculateRequestPriceNative

```solidity
function calculateRequestPriceNative(uint256 callbackGasLimit) external view returns (uint256)
```

Calculate the native request price for a given callback gas limit.



#### Parameters

| Name | Type | Description |
|---|---|---|
| callbackGasLimit | uint256 | The gas limit for the callback function. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(address vrfCoordinator, address initialOwner) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| vrfCoordinator | address | undefined |
| initialOwner | address | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### proxiableUUID

```solidity
function proxiableUUID() external view returns (bytes32)
```



*Implementation of the ERC-1822 {proxiableUUID} function. This returns the storage slot used by the implementation. It is used to validate the implementation&#39;s compatibility when performing an upgrade. IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### rawFulfillRandomWords

```solidity
function rawFulfillRandomWords(uint256 requestId, uint256[] randomWords) external nonpayable
```

This function can only be called by the VRF coordinator

*Callback function called by the VRF coordinator to deliver random wordsSpecial care should be taken when overriding this function. Use `_fulfillRandomWords()` instead.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | The ID of the request to which these random words belong |
| randomWords | uint256[] | The array of random words for the request |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### requestRandomWords

```solidity
function requestRandomWords(uint256 numWords) external payable returns (uint256)
```

Request random words from the VRF coordinator.



#### Parameters

| Name | Type | Description |
|---|---|---|
| numWords | uint256 | The number of random words to request. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### upgradeToAndCall

```solidity
function upgradeToAndCall(address newImplementation, bytes data) external payable
```



*Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call encoded in `data`. Calls {_authorizeUpgrade}. Emits an {Upgraded} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newImplementation | address | undefined |
| data | bytes | undefined |



## Events

### Initialized

```solidity
event Initialized(uint64 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint64 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### Upgraded

```solidity
event Upgraded(address indexed implementation)
```



*Emitted when the implementation is upgraded.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation `indexed` | address | undefined |

### VRFCoordinatorSet

```solidity
event VRFCoordinatorSet(address indexed coordinator)
```



*Emitted when the VRF coordinator is set*

#### Parameters

| Name | Type | Description |
|---|---|---|
| coordinator `indexed` | address | The address of the VRF coordinator |



## Errors

### AddressEmptyCode

```solidity
error AddressEmptyCode(address target)
```



*There&#39;s no code at `target` (it is not a contract).*

#### Parameters

| Name | Type | Description |
|---|---|---|
| target | address | undefined |

### ERC1967InvalidImplementation

```solidity
error ERC1967InvalidImplementation(address implementation)
```



*The `implementation` of the proxy is invalid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation | address | undefined |

### ERC1967NonPayable

```solidity
error ERC1967NonPayable()
```



*An upgrade function sees `msg.value &gt; 0` that may be lost.*


### FailedCall

```solidity
error FailedCall()
```



*A call to an address target failed. The target may have reverted.*


### InvalidInitialization

```solidity
error InvalidInitialization()
```



*The contract is already initialized.*


### NotInitializing

```solidity
error NotInitializing()
```



*The contract is not initializing.*


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

### OwnableInvalidOwner

```solidity
error OwnableInvalidOwner(address owner)
```



*The owner is not a valid owner account. (eg. `address(0)`)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

### OwnableUnauthorizedAccount

```solidity
error OwnableUnauthorizedAccount(address account)
```



*The caller account is not authorized to perform an operation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### UUPSUnauthorizedCallContext

```solidity
error UUPSUnauthorizedCallContext()
```



*The call is from an unauthorized context.*


### UUPSUnsupportedProxiableUUID

```solidity
error UUPSUnsupportedProxiableUUID(bytes32 slot)
```



*The storage `slot` is unsupported as a UUID.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| slot | bytes32 | undefined |

### ZeroAddress

```solidity
error ZeroAddress()
```



*Error thrown when a zero address is provided where it is not allowed*



