# Paintswap VRF

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

| Network       | Chain ID | Status      | VRF Coordinator                              |
| ------------- | -------- | ----------- | -------------------------------------------- |
| Blaze Testnet | 57054    | ✅ Live     | `0x63f7B0684E28E6aA48b75b99F94dEa6d25aea646` |
| Sonic Mainnet | 146      | Coming Soon | `0x...`                                      |

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

    constructor(address vrfCoordinator) PaintswapVRFConsumer(vrfCoordinator) {}

    function requestRandomness() external payable returns (uint256 requestId) {
        // Calculate the required payment for the VRF request
        uint256 requestPrice = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
        require(msg.value >= requestPrice, "Insufficient payment");

        // Request one random number
        requestId = _requestRandomnessPayInNative(CALLBACK_GAS_LIMIT, 1, requestPrice);

        // Store the user for this request
        requestToUser[requestId] = msg.sender;

        emit RandomnessRequested(requestId, msg.sender);
        return requestId;
    }

    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address user = requestToUser[requestId];
        require(user != address(0), "Invalid request");

        // Process your random words here
        emit RandomnessReceived(requestId, randomWords);
    }
}
```

### Using the TypeScript SDK

```typescript
import {ethers} from "ethers";
import {PaintswapVRFCoordinator__factory} from "@paintswap/vrf/typechain-types";

// Connect to the VRF Coordinator
const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com");
const coordinator = PaintswapVRFCoordinator__factory.connect(vrfAddress, provider);

// Calculate request price
const callbackGasLimit = 100000;
const requestPrice = await coordinator.calculateRequestPriceNative(callbackGasLimit);

// Request randomness
const tx = await coordinator.requestRandomnessPayInNative(callbackGasLimit, 1, {
  value: requestPrice,
});

// Listen for fulfillment
coordinator.on("RandomWordsFulfilled", (requestId, randomWords, oracle, callSuccess) => {
  console.log(`Request ${requestId} fulfilled with random words:`, randomWords);
});
```

## Contract Imports

This package provides several import paths for different use cases:

```typescript
// TypeScript types and factories
import {PaintswapVRFCoordinator__factory} from "@paintswap/vrf/typechain-types";
import {PaintswapVRFConsumer__factory} from "@paintswap/vrf/typechain-types";

// All factory types
import * as factories from "@paintswap/vrf/typechain-types/factories";
```

```solidity
// Solidity contracts
pragma solidity ^0.8.20;
import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFCoordinator.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFConsumer.sol";
```

```json
// ABI files
{
  "imports": [
    "@paintswap/vrf/abi/contracts/PaintswapVRFCoordinator.sol/PaintswapVRFCoordinator.json",
    "@paintswap/vrf/abi/interfaces/IPaintswapVRFCoordinator.sol/IPaintswapVRFCoordinator.json",
    "@paintswap/vrf/abi/interfaces/IPaintswapVRFConsumer.sol/IPaintswapVRFConsumer.json"
  ]
}
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
        address consumer,
        uint256 callbackGasLimit,
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
        uint256 value
    ) internal returns (uint256 requestId);

    // Calculate the cost of a request
    function _calculateRequestPriceNative(uint256 callbackGasLimit)
        internal view returns (uint256 requestPrice);

    // Override this function to handle random words
    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal virtual;

    // Callback from coordinator (do not override)
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        external override onlyCoordinator;
}
```

## Events

### RandomWordsRequested

```solidity
event RandomWordsRequested(
    uint256 indexed requestId,
    uint256 callbackGasLimit,
    uint256 numWords,
    address indexed consumer,
    uint256 nonce
);
```

### RandomWordsFulfilled

```solidity
event RandomWordsFulfilled(
    uint256 indexed requestId,
    uint256[] randomWords,
    address indexed oracle,
    bool callSuccess
);
```

### ConsumerCallbackFailed

```solidity
event ConsumerCallbackFailed(
    uint256 indexed requestId,
    uint8 indexed reason, // 1 = not enough gas, 2 = no code, 3 = reverted or out of gas
    address indexed target,
    uint256 gasLeft
);
```

## Error Handling

The VRF system includes comprehensive error handling:

```solidity
// Consumer errors
error OnlyVRFCoordinator(address sender, address coordinator);

// Coordinator errors
error ZeroAddress();
error NotOracle(address invalid);
error InsufficientGasLimit(uint256 sent, uint256 required);
error InsufficientGasPayment(uint256 sent, uint256 required);
error InvalidNumWords(uint256 numWords, uint256 max);
error CommitmentMismatch(uint256 requestId);
error InvalidProof(uint256 requestId);
error InvalidPublicKey(uint256 requestId, address proofSigner, address vrfSigner);
error OverConsumerGasLimit(uint256 sent, uint256 max);
```

## Gas Considerations

| Operation   | Estimated Gas       | Notes                                  |
| ----------- | ------------------- | -------------------------------------- |
| Request     | ~70,000             | Creates commitment and emits event     |
| Fulfillment | ~300,000 + callback | VRF proof verification + your callback |

### How It Works

1. **Request Phase**: Your contract calls `requestRandomnessPayInNative()` which:

   - Creates a unique commitment hash for the request
   - Emits a `RandomWordsRequested` event that oracles monitor
   - Uses approximately 70,000 gas for the transaction

2. **Oracle Processing**: Oracles detect the request event and:

   - Calculate the VRF proof off-chain using cryptographic algorithms
   - Submit a fulfillment transaction with the proof

3. **Fulfillment Phase**: The oracle calls `fulfillRandomWords()` which:
   - Verifies the oracle's signature matches the registered signer
   - Validates the VRF proof cryptographically on-chain
   - Generates random words from the verified proof
   - Calls your contract's callback with the random words
   - Can only be called once per unique commitment hash

### Gas Limit Guidelines

- **Minimum callback gas**: 5,000 (system requirement)
- **Maximum callback gas**: 6,000,000 (system limit)
- **Maximum words per request**: 500 (system limit)

### Cost Calculation

The cost of a VRF request is calculated as:

```
Cost = (callbackGasLimit + 300,000) × averageGasPrice
```

Where:

- `callbackGasLimit` is the gas you allocate for your callback function
- `300,000` is the fixed VRF processing overhead for proof verification
- `averageGasPrice` is determined from recent fulfillment transactions

### Security Guarantees

- Each request has a unique commitment hash that prevents replay attacks
- VRF proofs are mathematically verifiable and cannot be forged
- Only registered oracles with valid signatures can fulfill requests
- Failed callbacks don't affect the randomness generation or oracle payments

## Support

For questions and support:

- 🐛 **GitHub Issues**: [paintswap/paintswap-vrf](https://github.com/paintswap/paintswap-vrf/issues)
- 💬 **Discord**: [Paintswap Community](https://discord.gg/paintswap)
- 🐦 **Twitter**: [@paint_swap](https://twitter.com/paint_swap)

---

Built with ❤️ by the Paintswap team for the Sonic ecosystem.
