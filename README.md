# Paintswap VRF

[![npm version](https://badge.fury.io/js/%40paintswap%2Fvrf.svg)](https://badge.fury.io/js/%40paintswap%2Fvrf)

A decentralized Verifiable Random Function (VRF) service for the Sonic ecosystem, providing secure and verifiable on-chain randomness for smart contracts.

## Overview

Paintswap VRF is a comprehensive solution for generating verifiable random numbers on-chain. It consists of a coordinator contract that manages randomness requests and oracle fulfillments, along with consumer contracts that can request and receive random numbers.

### Features

- ✅ **Verifiable Randomness**: Uses cryptographic proofs to ensure randomness cannot be manipulated
- ✅ **Oracle Network**: Distributed oracle system for reliable fulfillment
- ✅ **Gas Efficient**: Optimized for low-cost operations on Sonic
- ✅ **TypeScript Support**: Full type definitions included

## Installation

```bash
npm install @paintswap/vrf
```

## Network Support

| Network       | Chain ID | VRF Coordinator                              |
| ------------- | -------- | -------------------------------------------- |
| Sonic Mainnet | 146      | `0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5` |
| Blaze Testnet | 57054    | `0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5` |

## Quick Start

### Using the Consumer Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";

contract MyContract is PaintswapVRFConsumer {
    uint256 public constant CALLBACK_GAS_LIMIT = 100_000;

    mapping(uint256 => address) public requestToUser;

    event RandomnessRequested(uint256 indexed requestId, address indexed user);
    event RandomnessReceived(uint256 indexed requestId, uint256[] randomWords);

    error InsufficientPayment();
    error InvalidRequest(uint256 requestId);

    constructor(address vrfCoordinator) PaintswapVRFConsumer(vrfCoordinator) {}

    function requestRandomness() external payable returns (uint256 requestId) {
        // Calculate the required payment for the VRF request
        uint256 requestPrice = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
        require(msg.value >= requestPrice, InsufficientPayment());

        uint256 numberOfWords = 1; // 1-500 words may be requesed

        // Request one random number
        requestId = _requestRandomnessPayInNative(CALLBACK_GAS_LIMIT, numberOfWords, requestPrice);

        // Store the user for this request
        requestToUser[requestId] = msg.sender;

        emit RandomnessRequested(requestId, msg.sender);
        return requestId;
    }

    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address user = requestToUser[requestId];
        require(user != address(0), InvalidRequest(requestId));

        // Process your random words here
        emit RandomnessReceived(requestId, randomWords);
    }
}
```

### Using the TypeScript SDK

```typescript
import { ethers } from "ethers";
import { PaintswapVRFCoordinator__factory } from "@paintswap/vrf/typechain-types";

const vrfAddress = "0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5";

// Connect to the VRF Coordinator
const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com");
const coordinator = PaintswapVRFCoordinator__factory.connect(
  vrfAddress,
  provider,
);

// Listen for fulfillments.
coordinator.on(
  coordinator.filters.RandomWordsFulfilled,
  (
    requestId,
    randomWords,
    oracle,
    callSuccess,
    fulfilledAtBI, // Note: This is a BigInt, convert to number/string if needed for display
    // eventPayload, // This argument might not be present or could be part of a more detailed event object
  ) => {
    const fulfilledAt = fulfilledAtBI.toString(); // Example conversion
    console.log(
      `Request ${requestId} fulfilled at ts ${fulfilledAt}:`,
      randomWords,
    );
  },
);

// Calculate request price
const callbackGasLimit = 100000;
const requestPrice =
  await coordinator.calculateRequestPriceNative(callbackGasLimit);

// Request randomness
const tx = await coordinator.requestRandomnessPayInNative(callbackGasLimit, 1, {
  // Requesting 1 word
  value: requestPrice,
});

console.log(`Transaction hash: ${tx.hash}`);

// Wait for the transaction to be mined
const receipt = await tx.wait();

// Extract the request ID from the RandomWordsRequested event
const requestedEvent = receipt.logs.find(
  (log) =>
    log.topics[0] ===
    coordinator.interface.getEvent("RandomWordsRequested").topicHash,
);

if (requestedEvent) {
  const decodedEvent = coordinator.interface.parseLog(requestedEvent);
  const requestId = decodedEvent.args.requestId;
  console.log(`Request ID: ${requestId}`);

  // You can now use this request ID to track the fulfillment,
  // query events using a filter, get the request status, etc.
} else {
  console.error("RandomWordsRequested event not found in transaction receipt");
}
```

## Contract Imports

This package provides several import paths for different use cases:

_Typescript_

```typescript
// TypeScript types and factories
import { PaintswapVRFConsumer__factory } from "@paintswap/vrf/typechain-types";

// All factory types
import * as factories from "@paintswap/vrf/typechain-types/factories";
```

_Solidity contracts_

```solidity
pragma solidity ^0.8.20;
import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFCoordinator.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFConsumer.sol";
```

_ABI files_

```json
{
  "imports": [
    "@paintswap/vrf/abi/contracts/PaintswapVRFConsumer.sol/PaintswapVRFConsumer.json",
    "@paintswap/vrf/abi/contracts/interfaces/IPaintswapVRFCoordinator.sol/IPaintswapVRFCoordinator.json",
    "@paintswap/vrf/abi/contracts/interfaces/IPaintswapVRFConsumer.sol/IPaintswapVRFConsumer.json"
  ]
}
```

```typescript
import PaintswapVRFConsumerABI from "@paintswap/vrf/abi/contracts/PaintswapVRFConsumer.sol/PaintswapVRFConsumer.json" with { type: "json" };
```

## API Reference

### IPaintswapVRFCoordinator

The main coordinator interface for requesting randomness:

```solidity
interface IPaintswapVRFCoordinator {
    // Calculate the cost of a request
    function calculateRequestPriceNative(uint256 callbackGasLimit)
        external view returns (uint256 payment);

    // Request random words with native payment
    function requestRandomnessPayInNative(uint256 callbackGasLimit, uint256 numWords)
        external payable returns (uint256 requestId);

    // Check if a request is still pending
    function isRequestPending(uint256 requestId)
        external view returns (bool isPending);

    // Oracle fulfillment function
    function fulfillRandomWords(
        uint256 requestId,
        address fulfillAddress, // Address of the consumer contract
        uint256 gasFeePaid,     // Actual gas fee paid by the oracle for fulfillment
        uint256 numWords,
        uint256[2] memory publicKey,
        uint256[4] memory proof,
        uint256[2] memory uPoint,
        uint256[4] memory vComponents,
        uint8 proofCtr
    ) external returns (bool callSuccess);
}
```

### PaintswapVRFConsumer

Abstract base contract for consuming randomness:

```solidity
abstract contract PaintswapVRFConsumer {
    // Request randomness with native payment
    function _requestRandomnessPayInNative(
        uint256 callbackGasLimit,
        uint256 numWords,
        uint256 value // The payment amount, should match calculated price
    ) internal returns (uint256 requestId);

    // Calculate the cost of a request
    function _calculateRequestPriceNative(uint256 callbackGasLimit)
        internal view returns (uint256 requestPrice);

    // Override this function to handle random words
    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal virtual;

    // Callback from coordinator (do not override)
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        external virtual override;
        // Used by PaintswapVRFConsumer to fulfill request with authorization
        // to ensure calls are from the PaintswapVRFCoordinator only. This function
        // should not be overridden.
}
```

## Events

### RandomWordsRequested

```solidity
event RandomWordsRequested(
    uint256 indexed requestId, // Unique request ID
    uint256 callbackGasLimit,  // Amount of gas for callback (5k-6m)
    uint256 numWords,          // Number of random words (<500)
    address indexed origin,    // Address that initiated the VRF request
    address indexed consumer,  // The consumer contract that will receive the callback
    uint256 nonce,             // Consumer nonce for this request
    uint256 requestedAt        // Timestamp of the request
);
```

### RandomWordsFulfilled

```solidity
event RandomWordsFulfilled(
    uint256 indexed requestId, // Unique request ID
    uint256[] randomWords,     // Random words generated
    address indexed oracle,    // Oracle that processed the request
    bool callSuccess,          // Consumer callback succeeded?
    uint256 fulfilledAt        // Timestamp of the fulfillment
);
```

### ConsumerCallbackFailed

```solidity
event ConsumerCallbackFailed(
    uint256 indexed requestId,
    // Reason 1 = NotEnoughGas,
    // Reason 2 = NoCodeAtAddress,
    // Reason 3 = RevertedOrOutOfGas
    uint8 indexed reason,
    address indexed target,   // The consumer contract address
    uint256 gasLeft           // Gas remaining after the failed callback
);
```

(Note: Other events like `OracleRegistered`, `SignerAddressUpdated`, `GasPriceHistoryWindowUpdated`, `RandomRequestLimitsUpdated` are part of `IPaintswapVRFCoordinator` but are more for administrative/operational purposes and not typically directly interacted with by consumers.)

## Error Handling

The VRF system includes comprehensive error handling:

```solidity
// Consumer errors (from PaintswapVRFConsumer.sol)
error OnlyVRFCoordinator(address sender, address coordinator);

// Coordinator errors (from IPaintswapVRFCoordinator.sol)
error ZeroAddress();
error NotOracle(address invalid);
error InsufficientGasLimit(uint256 sent, uint256 required);
error InsufficientGasPayment(uint256 sent, uint256 required);
error InvalidNumWords(uint256 numWords, uint256 max);
error CommitmentMismatch(uint256 requestId);
error InvalidProof(uint256 requestId);
error InvalidPublicKey(uint256 requestId, address proofSigner, address vrfSigner);
error OverConsumerGasLimit(uint256 sent, uint256 max);
error FundingFailed(address oracle, uint256 amount);
error InsufficientOracleBalance(address oracle, uint256 balance);
error InvalidGasPriceHistoryWindow(uint256 window);
error OracleAlreadyRegistered(address oracle);
error WithdrawFailed(address recipient, uint256 amount);
```

## Gas Considerations

| Operation   | Estimated Gas      | Notes                                  |
| ----------- | ------------------ | -------------------------------------- |
| Request     | ~70,000 - 90,000   | Creates commitment and emits event     |
| Fulfillment | 300,000 + callback | VRF proof verification + your callback |

(Gas estimates can vary based on network conditions and specific parameters.)

### How It Works

1.  **Request Phase**: Your contract calls `_requestRandomnessPayInNative()` (if using `PaintswapVRFConsumer`) or `requestRandomnessPayInNative()` (if interacting directly with `IPaintswapVRFCoordinator`). This:

    - Creates a unique commitment hash for the request.
    - Emits a `RandomWordsRequested` event that oracles monitor.
    - Uses gas for these operations.

2.  **Oracle Processing**: Oracles detect the `RandomWordsRequested` event and:

    - Calculate the VRF proof off-chain using cryptographic algorithms.
    - Submit a fulfillment transaction with the proof to the coordinator.

3.  **Fulfillment Phase**: The oracle calls `fulfillRandomWords()` on the coordinator contract, which:
    - Verifies the oracle's identity and permissions.
    - Validates the VRF proof cryptographically on-chain.
    - Generates random words from the verified proof.
    - Calls your consumer contract's `rawFulfillRandomWords` function (which in `PaintswapVRFConsumer` then calls your `_fulfillRandomWords` implementation) with the random words.
    - Ensures that a request can only be fulfilled once.

### Gas Limit Guidelines

- **Minimum callback gas**: As defined by `minimumGasLimit` in `RandomRequestLimitsUpdated` event (e.g., 5,000).
- **Maximum callback gas**: As defined by `maximumGasLimit` in `RandomRequestLimitsUpdated` event (e.g., 6,000,000).
- **Maximum words per request**: As defined by `maxNumWords` in `RandomRequestLimitsUpdated` event (e.g., 500).

### Cost Calculation

The cost of a VRF request is calculated by the `calculateRequestPriceNative(callbackGasLimit)` function in the coordinator. This typically involves:
`Cost = (BaseGasForFulfillment + callbackGasLimit) * EffectiveGasPrice`

Where:

- `BaseGasForFulfillment` is the gas overhead for the coordinator to verify the proof and manage the fulfillment (e.g., ~250,000-350,000).
- `callbackGasLimit` is the gas you allocate for your callback function.
- `EffectiveGasPrice` is a gas price determined by the coordinator, potentially based on recent network conditions or oracle costs.

### Security Guarantees

- Each request has a unique commitment hash that prevents replay attacks and ensures the randomness corresponds to the specific request.
- VRF proofs are mathematically verifiable and cannot be forged by oracles or users.
- Only registered oracles with valid cryptographic signatures can fulfill requests.
- Failed consumer callbacks (e.g., due to out-of-gas in the consumer's `_fulfillRandomWords`) do not affect the randomness generation process or the oracle's ability to get paid for a valid fulfillment. The `callSuccess` flag in `RandomWordsFulfilled` event indicates the callback status.

## Support

For questions and support:

- 🐛 **GitHub Issues**: [paintswap/paintswap-vrf](https://github.com/paintswap/paintswap-vrf/issues)
- 💬 **Discord**: [Paintswap Community](https://discord.gg/paintswap)
- 🐦 **Twitter**: [@paint_swap](https://twitter.com/paint_swap)

---

Built with ❤️ by the Paintswap team for the Sonic ecosystem.

````<!-- filepath: /Users/justin/Workspaces/paintswap-vrf-system/packages/vrf/README.md -->
# Paintswap VRF

[![npm version](https://badge.fury.io/js/%40paintswap%2Fvrf.svg)](https://badge.fury.io/js/%40paintswap%2Fvrf)

A decentralized Verifiable Random Function (VRF) service for the Sonic ecosystem, providing secure and verifiable on-chain randomness for smart contracts.

## Overview

Paintswap VRF is a comprehensive solution for generating verifiable random numbers on-chain. It consists of a coordinator contract that manages randomness requests and oracle fulfillments, along with consumer contracts that can request and receive random numbers.

### Features

- ✅ **Verifiable Randomness**: Uses cryptographic proofs to ensure randomness cannot be manipulated
- ✅ **Oracle Network**: Distributed oracle system for reliable fulfillment
- ✅ **Gas Efficient**: Optimized for low-cost operations on Sonic
- ✅ **TypeScript Support**: Full type definitions included

## Installation

```bash
npm install @paintswap/vrf
````

## Network Support

| Network       | Chain ID | VRF Coordinator                              |
| ------------- | -------- | -------------------------------------------- |
| Sonic Mainnet | 146      | `0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5` |
| Blaze Testnet | 57054    | `0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5` |

## Quick Start

### Using the Consumer Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";

contract MyContract is PaintswapVRFConsumer {
    uint256 public constant CALLBACK_GAS_LIMIT = 100_000;

    mapping(uint256 => address) public requestToUser;

    event RandomnessRequested(uint256 indexed requestId, address indexed user);
    event RandomnessReceived(uint256 indexed requestId, uint256[] randomWords);

    error InsufficientPayment();
    error InvalidRequest(uint256 requestId);

    constructor(address vrfCoordinator) PaintswapVRFConsumer(vrfCoordinator) {}

    function requestRandomness() external payable returns (uint256 requestId) {
        // Calculate the required payment for the VRF request
        uint256 requestPrice = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
        require(msg.value >= requestPrice, InsufficientPayment());

        uint256 numberOfWords = 1; // 1-500 words may be requesed

        // Request one random number
        requestId = _requestRandomnessPayInNative(CALLBACK_GAS_LIMIT, numberOfWords, requestPrice);

        // Store the user for this request
        requestToUser[requestId] = msg.sender;

        emit RandomnessRequested(requestId, msg.sender);
        return requestId;
    }

    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address user = requestToUser[requestId];
        require(user != address(0), InvalidRequest(requestId));

        // Process your random words here
        emit RandomnessReceived(requestId, randomWords);
    }
}
```

### Using the TypeScript SDK

```typescript
import { ethers } from "ethers";
import { PaintswapVRFCoordinator__factory } from "@paintswap/vrf/typechain-types";

const vrfAddress = "0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5";

// Connect to the VRF Coordinator
const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com");
const coordinator = PaintswapVRFCoordinator__factory.connect(
  vrfAddress,
  provider,
);

// Listen for fulfillments.
coordinator.on(
  coordinator.filters.RandomWordsFulfilled,
  (
    requestId,
    randomWords,
    oracle,
    callSuccess,
    fulfilledAtBI, // Note: This is a BigInt, convert to number/string if needed for display
    // eventPayload, // This argument might not be present or could be part of a more detailed event object
  ) => {
    const fulfilledAt = fulfilledAtBI.toString(); // Example conversion
    console.log(
      `Request ${requestId} fulfilled at ts ${fulfilledAt}:`,
      randomWords,
    );
  },
);

// Calculate request price
const callbackGasLimit = 100000;
const requestPrice =
  await coordinator.calculateRequestPriceNative(callbackGasLimit);

// Request randomness
const tx = await coordinator.requestRandomnessPayInNative(callbackGasLimit, 1, {
  // Requesting 1 word
  value: requestPrice,
});

console.log(`Transaction hash: ${tx.hash}`);

// Wait for the transaction to be mined
const receipt = await tx.wait();

// Extract the request ID from the RandomWordsRequested event
const requestedEvent = receipt.logs.find(
  (log) =>
    log.topics[0] ===
    coordinator.interface.getEvent("RandomWordsRequested").topicHash,
);

if (requestedEvent) {
  const decodedEvent = coordinator.interface.parseLog(requestedEvent);
  const requestId = decodedEvent.args.requestId;
  console.log(`Request ID: ${requestId}`);

  // You can now use this request ID to track the fulfillment,
  // query events using a filter, get the request status, etc.
} else {
  console.error("RandomWordsRequested event not found in transaction receipt");
}
```

## Contract Imports

This package provides several import paths for different use cases:

_Typescript_

```typescript
// TypeScript types and factories
import { PaintswapVRFConsumer__factory } from "@paintswap/vrf/typechain-types";

// All factory types
import * as factories from "@paintswap/vrf/typechain-types/factories";
```

_Solidity contracts_

```solidity
pragma solidity ^0.8.20;
import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFCoordinator.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFConsumer.sol";
```

_ABI files_

```json
{
  "imports": [
    "@paintswap/vrf/abi/contracts/PaintswapVRFConsumer.sol/PaintswapVRFConsumer.json",
    "@paintswap/vrf/abi/contracts/interfaces/IPaintswapVRFCoordinator.sol/IPaintswapVRFCoordinator.json",
    "@paintswap/vrf/abi/contracts/interfaces/IPaintswapVRFConsumer.sol/IPaintswapVRFConsumer.json"
  ]
}
```

```typescript
import PaintswapVRFConsumerABI from "@paintswap/vrf/abi/contracts/PaintswapVRFConsumer.sol/PaintswapVRFConsumer.json" with { type: "json" };
```

## API Reference

### IPaintswapVRFCoordinator

The main coordinator interface for requesting randomness:

```solidity
interface IPaintswapVRFCoordinator {
    // Calculate the cost of a request
    function calculateRequestPriceNative(uint256 callbackGasLimit)
        external view returns (uint256 payment);

    // Request random words with native payment
    function requestRandomnessPayInNative(uint256 callbackGasLimit, uint256 numWords)
        external payable returns (uint256 requestId);

    // Check if a request is still pending
    function isRequestPending(uint256 requestId)
        external view returns (bool isPending);

    // Oracle fulfillment function
    function fulfillRandomWords(
        uint256 requestId,
        address fulfillAddress, // Address of the consumer contract
        uint256 gasFeePaid,     // Actual gas fee paid by the oracle for fulfillment
        uint256 numWords,
        uint256[2] memory publicKey,
        uint256[4] memory proof,
        uint256[2] memory uPoint,
        uint256[4] memory vComponents,
        uint8 proofCtr
    ) external returns (bool callSuccess);
}
```

### PaintswapVRFConsumer

Abstract base contract for consuming randomness:

```solidity
abstract contract PaintswapVRFConsumer {
    // Request randomness with native payment
    function _requestRandomnessPayInNative(
        uint256 callbackGasLimit,
        uint256 numWords,
        uint256 value // The payment amount, should match calculated price
    ) internal returns (uint256 requestId);

    // Calculate the cost of a request
    function _calculateRequestPriceNative(uint256 callbackGasLimit)
        internal view returns (uint256 requestPrice);

    // Override this function to handle random words
    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal virtual;

    // Callback from coordinator (do not override)
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        external virtual override;
        // Used by PaintswapVRFConsumer to fulfill request with authorization
        // to ensure calls are from the PaintswapVRFCoordinator only. This function
        // should not be overridden.
}
```

## Events

### RandomWordsRequested

```solidity
event RandomWordsRequested(
    uint256 indexed requestId, // Unique request ID
    uint256 callbackGasLimit,  // Amount of gas for callback (5k-6m)
    uint256 numWords,          // Number of random words (<500)
    address indexed origin,    // Address that initiated the VRF request
    address indexed consumer,  // The consumer contract that will receive the callback
    uint256 nonce,             // Consumer nonce for this request
    uint256 requestedAt        // Timestamp of the request
);
```

### RandomWordsFulfilled

```solidity
event RandomWordsFulfilled(
    uint256 indexed requestId, // Unique request ID
    uint256[] randomWords,     // Random words generated
    address indexed oracle,    // Oracle that processed the request
    bool callSuccess,          // Consumer callback succeeded?
    uint256 fulfilledAt        // Timestamp of the fulfillment
);
```

### ConsumerCallbackFailed

```solidity
event ConsumerCallbackFailed(
    uint256 indexed requestId,
    // Reason 1 = NotEnoughGas,
    // Reason 2 = NoCodeAtAddress,
    // Reason 3 = RevertedOrOutOfGas
    uint8 indexed reason,
    address indexed target,   // The consumer contract address
    uint256 gasLeft           // Gas remaining after the failed callback
);
```

(Note: Other events like `OracleRegistered`, `SignerAddressUpdated`, `GasPriceHistoryWindowUpdated`, `RandomRequestLimitsUpdated` are part of `IPaintswapVRFCoordinator` but are more for administrative/operational purposes and not typically directly interacted with by consumers.)

## Error Handling

The VRF system includes comprehensive error handling:

```solidity
// Consumer errors (from PaintswapVRFConsumer.sol)
error OnlyVRFCoordinator(address sender, address coordinator);

// Coordinator errors (from IPaintswapVRFCoordinator.sol)
error ZeroAddress();
error NotOracle(address invalid);
error InsufficientGasLimit(uint256 sent, uint256 required);
error InsufficientGasPayment(uint256 sent, uint256 required);
error InvalidNumWords(uint256 numWords, uint256 max);
error CommitmentMismatch(uint256 requestId);
error InvalidProof(uint256 requestId);
error InvalidPublicKey(uint256 requestId, address proofSigner, address vrfSigner);
error OverConsumerGasLimit(uint256 sent, uint256 max);
error FundingFailed(address oracle, uint256 amount);
error InsufficientOracleBalance(address oracle, uint256 balance);
error InvalidGasPriceHistoryWindow(uint256 window);
error OracleAlreadyRegistered(address oracle);
error WithdrawFailed(address recipient, uint256 amount);
```

## Gas Considerations

| Operation   | Estimated Gas      | Notes                                  |
| ----------- | ------------------ | -------------------------------------- |
| Request     | ~70,000 - 90,000   | Creates commitment and emits event     |
| Fulfillment | 300,000 + callback | VRF proof verification + your callback |

(Gas estimates can vary based on network conditions and specific parameters.)

### How It Works

1.  **Request Phase**: Your contract calls `_requestRandomnessPayInNative()` (if using `PaintswapVRFConsumer`) or `requestRandomnessPayInNative()` (if interacting directly with `IPaintswapVRFCoordinator`). This:

    - Creates a unique commitment hash for the request.
    - Emits a `RandomWordsRequested` event that oracles monitor.
    - Uses gas for these operations.

2.  **Oracle Processing**: Oracles detect the `RandomWordsRequested` event and:

    - Calculate the VRF proof off-chain using cryptographic algorithms.
    - Submit a fulfillment transaction with the proof to the coordinator.

3.  **Fulfillment Phase**: The oracle calls `fulfillRandomWords()` on the coordinator contract, which:
    - Verifies the oracle's identity and permissions.
    - Validates the VRF proof cryptographically on-chain.
    - Generates random words from the verified proof.
    - Calls your consumer contract's `rawFulfillRandomWords` function (which in `PaintswapVRFConsumer` then calls your `_fulfillRandomWords` implementation) with the random words.
    - Ensures that a request can only be fulfilled once.

### Gas Limit Guidelines

- **Minimum callback gas**: As defined by `minimumGasLimit` in `RandomRequestLimitsUpdated` event (e.g., 5,000).
- **Maximum callback gas**: As defined by `maximumGasLimit` in `RandomRequestLimitsUpdated` event (e.g., 6,000,000).
- **Maximum words per request**: As defined by `maxNumWords` in `RandomRequestLimitsUpdated` event (e.g., 500).

### Cost Calculation

The cost of a VRF request is calculated by the `calculateRequestPriceNative(callbackGasLimit)` function in the coordinator. This typically involves:
`Cost = (BaseGasForFulfillment + callbackGasLimit) * EffectiveGasPrice`

Where:

- `BaseGasForFulfillment` is the gas overhead for the coordinator to verify the proof and manage the fulfillment (e.g., ~250,000-350,000).
- `callbackGasLimit` is the gas you allocate for your callback function.
- `EffectiveGasPrice` is a gas price determined by the coordinator, potentially based on recent network conditions or oracle costs.

### Security Guarantees

- Each request has a unique commitment hash that prevents replay attacks and ensures the randomness corresponds to the specific request.
- VRF proofs are mathematically verifiable and cannot be forged by oracles or users.
- Only registered oracles with valid cryptographic signatures can fulfill requests.
- Failed consumer callbacks (e.g., due to out-of-gas in the consumer's `_fulfillRandomWords`) do not affect the randomness generation process or the oracle's ability to get paid for a valid fulfillment. The `callSuccess` flag in `RandomWordsFulfilled` event indicates the callback status.

## Support

For questions and support:

- 🐛 **GitHub Issues**: [paintswap/paintswap-vrf](https://github.com/paintswap/paintswap-vrf/issues)
- 💬 **Discord**: [Paintswap Community](https://discord.gg/paintswap)
- 🐦 **Twitter**: [@paint_swap](https://twitter.com/paint_swap)

---

Built with ❤️ by the Paintswap team for the Sonic ecosystem.
