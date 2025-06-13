# PaintswapVRFConsumer



> PaintswapVRFConsumer

Implement this contract to request and receive verifiable randomness from Paintswap&#39;s VRF

*Abstract contract for consuming randomness from the Paintswap VRF (Verifiable Random Function) service*

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


