# Paintswap VRF

[![npm version](https://badge.fury.io/js/%40paintswap%2Fvrf.svg)](https://badge.fury.io/js/%40paintswap%2Fvrf)

A decentralized Verifiable Random Function (VRF) service for the Sonic ecosystem, providing secure and verifiable on-chain randomness for smart contracts.

Paintswap VRF Dashboard: [https://vrf.paintswap.io](https://vrf.paintswap.io)

## Overview

Paintswap VRF is a comprehensive solution for generating verifiable random numbers on-chain. It consists of a coordinator contract that manages randomness requests and oracle fulfillments, along with consumer contracts that can request and receive random numbers. Typical round trip response time to fulfillment is 1-2 seconds.

The only fee required is the fulfillment gas payment, based on the callback gas limit and the current gas prices seen on the network. To use the service implement the `PaintswapVRFConsumer` contract or `IPaintswapVRFConsumer` interface, price the request, then submit the fulfillment gas payment either from the user or supplied at request time by the consumer contract. Our VRF Oracle will do the rest.

Unused gas for the fulfillment callback is refunded to the `refundee` address specified in the callback. This could be anything from `tx.origin`, `msg.sender`, `address(this)`, or use `address(0)` to leave excess gas as a tip for the service 🙏. Note that there is a 50k gas threshold as well as a 10% Sonic network penalty on unused gas.

### Features

- ✅ **Verifiable Randomness**: Uses cryptographic proofs to ensure randomness cannot be manipulated
- ✅ **Gas Efficient**: Optimized for low-cost operations on Sonic
- ✅ **Solidity Support**: Consumer contracts, interfaces, and mocks included
- ✅ **TypeScript Support**: Full type definitions included
- ✅ **Blazing Fast**: Leverages the speed of the Sonic network

## Installation

```bash
npm install @paintswap/vrf
```

## Network Support

| Network       | Chain ID | VRF Coordinator                              |
| ------------- | -------- | -------------------------------------------- |
| Sonic Mainnet | 146      | Coming soon                                  |
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
        uint256 gasPayment = _calculateRequestPriceNative(CALLBACK_GAS_LIMIT);
        require(msg.value >= gasPayment, InsufficientPayment());

        // Request one random number
        uint256 numberOfWords = 1;
        address refundee = msg.sender;
        requestId = _requestRandomnessPayInNative(CALLBACK_GAS_LIMIT, numberOfWords, refundee, gasPayment);

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
import { PaintswapVRFCoordinator__factory } from "@paintswap/vrf";

const vrfAddress = "0xcCD87C20Dc14ED79c1F827800b5a9b8Ef2E43eC5";

// Connect to the VRF Coordinator
const provider = new ethers.JsonRpcProvider("https://rpc.soniclabs.com");
const coordinator = PaintswapVRFCoordinator__factory.connect(
  vrfAddress,
  provider,
);

// Listen for fulfillments
coordinator.on(
  coordinator.filters.RandomWordsFulfilled,
  (requestId, randomWords, oracle, callSuccess, fulfilledAt) => {
    const fulfilledAtMs = Number(fulfilledAt) * 1000;
    console.log(
      `Request ${requestId} fulfilled at ${fulfilledAtMs}:`,
      randomWords,
    );
  },
);

// Calculate request price
const callbackGasLimit = 100000;
const requestPrice =
  await coordinator.calculateRequestPriceNative(callbackGasLimit);

// Request randomness
const numberOfWords = 2;
const tx = await coordinator.requestRandomnessPayInNative(
  callbackGasLimit,
  numberOfWords,
  { value: requestPrice },
);

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
} else {
  console.error("RandomWordsRequested event not found");
}
```

## Development & Testing

### MockVRFCoordinator

For development and testing, use the `MockVRFCoordinator` which simulates the VRF coordinator without requiring cryptographic proofs or oracle networks. **Important: The mock coordinator should only be used in your test files, not in your production consumer contracts.**

#### Basic Testing Setup

```typescript
// test/MyContract.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import { MockVRFCoordinator } from "@paintswap/vrf";
import { MyContract } from "../typechain-types";

describe("MyContract", function () {
  let mockCoordinator: MockVRFCoordinator;
  let myContract: MyContract;

  beforeEach(async function () {
    // Deploy mock coordinator in your test
    const MockCoordinator =
      await ethers.getContractFactory("MockVRFCoordinator");
    mockCoordinator = await MockCoordinator.deploy();

    // Deploy your consumer contract with the mock coordinator address
    const MyContract = await ethers.getContractFactory("MyContract");
    myContract = await MyContract.deploy(await mockCoordinator.getAddress());
  });

  it("should handle randomness request and fulfillment", async function () {
    // Calculate fee and make request
    const fee = await mockCoordinator.calculateRequestPriceNative(100_000);
    const tx = await myContract.requestRandomness({ value: fee });
    const receipt = await tx.wait();

    // Extract request ID from event
    const event = receipt.logs.find(
      (log) =>
        log.topics[0] ===
        myContract.interface.getEvent("RandomnessRequested").topicHash,
    );
    const requestId = myContract.interface.parseLog(event).args.requestId;

    // Manually fulfill the request in the test
    await mockCoordinator.fulfillRequestMock(requestId, [123n]);

    // Verify that your contract processed the randomness
  });
});
```

#### Mock Coordinator Features

- **Manual Fulfillment**: Use `fulfillRequestMock(requestId, randomWords)` to manually fulfill requests
- **Auto-Random Fulfillment**: Use `fulfillRequestMockWithRandomWords(requestId)` to fulfill with pseudo-random data
- **Request Tracking**: Get request details with `getRequest(requestId)` and `getRequestResult(requestId)`
- **Statistics**: Monitor requests and fulfillments with `getFulfillmentStats()`
- **Debug Events**: Detailed `DebugFulfillment` events for callback failure analysis
- **Request ID Prediction**: Use `calculateNextRequestId(consumer)` to predict request IDs

#### Advanced Testing Functions

```typescript
// Get detailed request information
const [consumer, gasLimit, words, payment, fulfilled] =
  await mockCoordinator.getRequest(requestId);

// Check request results with detailed status
const [wasSuccess, wasFulfilled] =
  await mockCoordinator.getRequestResult(requestId);

// Get comprehensive fulfillment statistics
const [total, pending, successes, failures, totalWordsRequested] =
  await mockCoordinator.getFulfillmentStats();

// Predict request IDs for testing
const predictedRequestId =
  await mockCoordinator.calculateNextRequestId(consumerAddress);
```

### ExampleVRFConsumer

The `ExampleVRFConsumer` demonstrates best practices for implementing VRF functionality with dual payment methods, request management, and utility functions.

```solidity
import "@paintswap/vrf/contracts/examples/ExampleVRFConsumer.sol";

// Deploy the example consumer
ExampleVRFConsumer consumer = new ExampleVRFConsumer(coordinatorAddress);

// Fund the contract for requests
consumer.fundVRF{value: 1 ether}();

// Request randomness with direct payment
uint256 fee = consumer.getRequestPrice(3);
uint256 requestId = consumer.requestRandomWords{value: fee}(3);

// Or request using contract funds
uint256 requestId2 = consumer.requestRandomWordsFromContract(2);

// Check request status
(bool exists, bool fulfilled, address requester, uint256 numWords, uint256 requestedAt, uint256[] memory randomWords) =
    consumer.getRequestStatus(requestId);
```

## Contract Imports

```typescript
// TypeScript types and factories
import { PaintswapVRFConsumer__factory } from "@paintswap/vrf";
import { MockPaintswapVRFCoordinator__factory } from "@paintswap/vrf";
```

```solidity
pragma solidity ^0.8.20;

// Production contracts
import "@paintswap/vrf/contracts/PaintswapVRFConsumer.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFCoordinator.sol";
import "@paintswap/vrf/contracts/interfaces/IPaintswapVRFConsumer.sol";

// Development and testing (only import in test contracts)
import "@paintswap/vrf/contracts/mocks/MockVRFCoordinator.sol";
import "@paintswap/vrf/contracts/examples/ExampleVRFConsumer.sol";
```

## API Reference

### IPaintswapVRFCoordinator

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
}
```

IPaintswapVRFCoordinator Docs: [docs/interfaces/IPaintswapVRFCoordinator.md](docs/interfaces/IPaintswapVRFCoordinator.md)

### IPaintswapVRFConsumer

```solidity
interface IPaintswapVRFConsumer {
    // Handle VRF response - must be implemented by consumer contracts
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external;
}
```

IPaintswapVRFConsumer Docs: [docs/interfaces/IPaintswapVRFConsumer.md](docs/interfaces/IPaintswapVRFConsumer.md)

### PaintswapVRFConsumer

```solidity
abstract contract PaintswapVRFConsumer {
    // Request randomness with native payment
    function _requestRandomnessPayInNative(
        uint256 callbackGasLimit, // gas limit for callback
        uint256 numWords,         // number of random words
        uint256 refundee,         // gas refundee or address(0)
        uint256 gasPayment        // fulfillment gas fee
    ) internal returns (uint256 requestId);

    // Calculate the cost of a request
    function _calculateRequestPriceNative(uint256 callbackGasLimit)
        internal view returns (uint256 requestPrice);

    // Override this function to handle random words
    function _fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal virtual;

    // Callback from coordinator (only callable by coordinator)
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        external virtual override;
}
```

PaintswapVRFConsumer Docs: [docs/PaintswapVRFConsumer.md](docs/PaintswapVRFConsumer.md)

## Events

### RandomWordsRequested

```solidity
 event RandomWordsRequested(
  uint256 indexed requestId, // unique request id
  uint256 callbackGasLimit,  // gas limit for consumer callback
  uint256 numWords,          // random words requested
  address indexed origin,    // tx.origin of request
  address indexed consumer,  // msg.sender of request
  uint256 nonce,             // request nonce for consumer
  address refundee,          // gas refunds or address(0)
  uint256 gasPricePaid,      // fulfillment fee gass price
  uint256 requestedAt        // block.timestamp of request
);
```

### RandomWordsFulfilled

```solidity
event RandomWordsFulfilled(
    uint256 indexed requestId, // unique request id
    uint256[] randomWords,     // random words generated
    address indexed oracle,    // fulfillment worker
    bool callSuccess,          // consumer callback result
    uint256 fulfilledAt        // block.timestamp of fulfillment
);
```

### ConsumerCallbackFailed

```solidity
event ConsumerCallbackFailed(
    uint256 indexed requestId, // unique request id
    uint8 indexed reason,      // 1 = NotEnoughGas,
                               // 2 = NoCodeAtAddress,
                               // 3 = RevertedOrOutOfGas
    address indexed target,    // callback consumer contract
    uint256 gasLeft            // gas remaining after callback
);
```

## Error Handling

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

| Operation            | Estimated Gas       | Notes                                       |
| -------------------- | ------------------- | ------------------------------------------- |
| Request              | ~120,000 - 140,000  | Includes request tracking and state updates |
| Mock Fulfillment     | ~100,000 + callback | Simplified verification + your callback     |
| Real VRF Fulfillment | ~300,000 + callback | Full cryptographic verification + callback  |

### How It Works

1. **Request Phase**: Your contract calls `_requestRandomnessPayInNative()` which creates a unique commitment hash and emits a `RandomWordsRequested` event that oracles monitor.

2. **Oracle Processing**: Oracles detect the event and calculate the VRF proof off-chain using cryptographic algorithms.

3. **Fulfillment Phase**: The oracle calls `fulfillRandomWords()` on the coordinator which verifies the proof, generates random words, and calls your consumer's `rawFulfillRandomWords` function.

### Security Guarantees

- Each request has a unique commitment hash preventing replay attacks
- VRF proofs are mathematically verifiable and cannot be forged
- Only registered oracles with valid cryptographic signatures can fulfill requests
- Failed consumer callbacks don't affect the randomness generation or oracle payment

## Testing Best Practices

### Test Fixtures Setup

```typescript
// test/fixtures.ts
import { ethers } from "hardhat";
import { MockVRFCoordinator, ExampleVRFConsumer } from "@paintswap/vrf";

export async function deployVRFFixture() {
  const [owner, user1, user2] = await ethers.getSigners();

  // Deploy mock coordinator
  const MockCoordinator = await ethers.getContractFactory("MockVRFCoordinator");
  const mockCoordinator = await MockCoordinator.deploy();

  // Deploy example consumer
  const Consumer = await ethers.getContractFactory("ExampleVRFConsumer");
  const consumer = await Consumer.deploy(await mockCoordinator.getAddress());

  return {
    mockCoordinator,
    consumer,
    owner,
    user1,
    user2,
  };
}

export async function deployVRFWithRequestFixture() {
  const fixture = await deployVRFFixture();
  const { mockCoordinator, consumer, user1 } = fixture;

  // Make a request for testing
  const fee = await consumer.getRequestPrice(2);
  const tx = await consumer
    .connect(user1)
    .requestRandomWords(2, { value: fee });
  const receipt = await tx.wait();

  // Extract request ID from event
  const event = receipt.logs.find(
    (log) =>
      log.topics[0] ===
      consumer.interface.getEvent("RandomnessRequested").topicHash,
  );
  const requestId = consumer.interface.parseLog(event).args.requestId;

  return {
    ...fixture,
    requestId,
    fee,
  };
}
```

### Unit Testing with Fixtures

```typescript
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { deployVRFFixture, deployVRFWithRequestFixture } from "./fixtures";

describe("VRF Consumer", function () {
  describe("Request and Fulfillment", function () {
    it("should handle randomness request and fulfillment", async function () {
      const { mockCoordinator, consumer, user1 } =
        await loadFixture(deployVRFFixture);

      const fee = await consumer.getRequestPrice(2);
      const tx = await consumer
        .connect(user1)
        .requestRandomWords(2, { value: fee });
      const receipt = await tx.wait();

      // Extract request ID from event
      const event = receipt.logs.find(
        (log) =>
          log.topics[0] ===
          consumer.interface.getEvent("RandomnessRequested").topicHash,
      );
      const requestId = consumer.interface.parseLog(event).args.requestId;

      // Fulfill with mock coordinator
      await mockCoordinator.fulfillRequestMock(requestId, [123n, 456n]);

      // Verify fulfillment
      const [exists, fulfilled, , , , randomWords] =
        await consumer.getRequestStatus(requestId);
      expect(exists).to.be.true;
      expect(fulfilled).to.be.true;
      expect(randomWords).to.deep.equal([123n, 456n]);
    });

    it("should handle multiple requests", async function () {
      const { mockCoordinator, consumer, user1, user2 } =
        await loadFixture(deployVRFFixture);

      // Fund contract for requests
      await consumer.fundVRF({ value: ethers.parseEther("1") });

      // Make multiple requests
      const tx1 = await consumer
        .connect(user1)
        .requestRandomWordsFromContract(3);
      const tx2 = await consumer
        .connect(user2)
        .requestRandomWordsFromContract(5);

      const receipt1 = await tx1.wait();
      const receipt2 = await tx2.wait();

      // Extract request IDs
      const event1 = receipt1.logs.find(
        (log) =>
          log.topics[0] ===
          consumer.interface.getEvent("RandomnessRequested").topicHash,
      );
      const event2 = receipt2.logs.find(
        (log) =>
          log.topics[0] ===
          consumer.interface.getEvent("RandomnessRequested").topicHash,
      );

      const requestId1 = consumer.interface.parseLog(event1).args.requestId;
      const requestId2 = consumer.interface.parseLog(event2).args.requestId;

      // Fulfill both requests
      await mockCoordinator.fulfillRequestMockWithRandomWords(requestId1);
      await mockCoordinator.fulfillRequestMockWithRandomWords(requestId2);

      // Verify statistics
      const [total, fulfilled, pending] = await consumer.getStats();
      expect(total).to.equal(2);
      expect(fulfilled).to.equal(2);
      expect(pending).to.equal(0);
    });
  });

  describe("Request Management", function () {
    it("should track requests by requester", async function () {
      const { consumer, user1, user2 } = await loadFixture(deployVRFFixture);

      // Fund contract
      await consumer.fundVRF({ value: ethers.parseEther("1") });

      // Make requests from different users
      await consumer.connect(user1).requestRandomWordsFromContract(1);
      await consumer.connect(user1).requestRandomWordsFromContract(2);
      await consumer.connect(user2).requestRandomWordsFromContract(3);

      // Check requests per user
      const user1Requests = await consumer.getRequestsByRequester(
        user1.address,
      );
      const user2Requests = await consumer.getRequestsByRequester(
        user2.address,
      );

      expect(user1Requests).to.have.length(2);
      expect(user2Requests).to.have.length(1);
    });
  });

  describe("Error Handling", function () {
    it("should revert with insufficient payment", async function () {
      const { consumer, user1 } = await loadFixture(deployVRFFixture);

      const fee = await consumer.getRequestPrice(1);
      await expect(
        consumer.connect(user1).requestRandomWords(1, { value: fee - 1n }),
      ).to.be.revertedWithCustomError(consumer, "InsufficientPayment");
    });

    it("should handle callback failures gracefully", async function () {
      const { mockCoordinator, requestId } = await loadFixture(
        deployVRFWithRequestFixture,
      );

      // This should emit DebugFulfillment event for debugging callback failures
      await expect(
        mockCoordinator.fulfillRequestMock(requestId, [123n, 456n]),
      ).to.emit(mockCoordinator, "RandomWordsFulfilled");
    });
  });

  describe("Advanced Features", function () {
    it("should predict request IDs", async function () {
      const { mockCoordinator, consumer, user1 } =
        await loadFixture(deployVRFFixture);

      // Predict the next request ID
      const predictedId = await mockCoordinator.calculateNextRequestId(
        await consumer.getAddress(),
      );

      // Make the actual request
      const fee = await consumer.getRequestPrice(1);
      const tx = await consumer
        .connect(user1)
        .requestRandomWords(1, { value: fee });
      const receipt = await tx.wait();

      // Extract actual request ID
      const event = receipt.logs.find(
        (log) =>
          log.topics[0] ===
          consumer.interface.getEvent("RandomnessRequested").topicHash,
      );
      const actualId = consumer.interface.parseLog(event).args.requestId;

      expect(actualId).to.equal(predictedId);
    });

    it("should provide detailed request information", async function () {
      const { mockCoordinator, requestId } = await loadFixture(
        deployVRFWithRequestFixture,
      );

      // Get request details
      const [consumerAddr, gasLimit, numWords, payment, fulfilled] =
        await mockCoordinator.getRequest(requestId);

      expect(consumerAddr).to.not.equal(ethers.ZeroAddress);
      expect(gasLimit).to.be.gt(0);
      expect(numWords).to.equal(2);
      expect(payment).to.be.gt(0);
      expect(fulfilled).to.be.false;

      // Fulfill and check again
      await mockCoordinator.fulfillRequestMock(requestId, [123n, 456n]);
      const [, , , , fulfilledAfter] =
        await mockCoordinator.getRequest(requestId);
      expect(fulfilledAfter).to.be.true;
    });
  });
});
```

### Integration Testing

```typescript
describe("Integration Tests", function () {
  it("should handle complete request lifecycle", async function () {
    const { mockCoordinator, consumer, user1 } =
      await loadFixture(deployVRFFixture);

    // Step 1: Make request
    const fee = await consumer.getRequestPrice(3);
    const tx = await consumer
      .connect(user1)
      .requestRandomWords(3, { value: fee });
    const receipt = await tx.wait();

    // Step 2: Verify request is pending
    const event = receipt.logs.find(
      (log) =>
        log.topics[0] ===
        consumer.interface.getEvent("RandomnessRequested").topicHash,
    );
    const requestId = consumer.interface.parseLog(event).args.requestId;

    expect(await mockCoordinator.isRequestPending(requestId)).to.be.true;

    // Step 3: Fulfill request
    await mockCoordinator.fulfillRequestMock(requestId, [111n, 222n, 333n]);

    // Step 4: Verify fulfillment
    expect(await mockCoordinator.isRequestPending(requestId)).to.be.false;
    const [exists, fulfilled, requester, numWords, , randomWords] =
      await consumer.getRequestStatus(requestId);

    expect(exists).to.be.true;
    expect(fulfilled).to.be.true;
    expect(requester).to.equal(user1.address);
    expect(numWords).to.equal(3);
    expect(randomWords).to.deep.equal([111n, 222n, 333n]);
  });
});
```

## Support

For questions and support:

- 🐛 **GitHub Issues**: [paintswap/paintswap-vrf](https://github.com/paintswap/paintswap-vrf/issues)
- 💬 **Discord**: [Paintswap Community](https://discord.gg/paintswap)
- 🐦 **Twitter**: [@paint_swap](https://twitter.com/paint_swap)

---

Built with ❤️ by the Paintswap team for the Sonic ecosystem.
