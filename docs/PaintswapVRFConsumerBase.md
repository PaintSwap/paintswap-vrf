# PaintswapVRFConsumerBase



> PaintswapVRFConsumerBase

Shared logic for VRF consumer contracts (both upgradeable and non-upgradeable).

*Children must implement `_getVRFCoordinator()` to supply the coordinator reference      and `_fulfillRandomWords()` to process received randomness.*

## Methods

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



## Events

### VRFCoordinatorSet

```solidity
event VRFCoordinatorSet(address indexed coordinator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| coordinator `indexed` | address | undefined |



## Errors

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

### ZeroAddress

```solidity
error ZeroAddress()
```



*Error thrown when a zero address is provided where it is not allowed*



