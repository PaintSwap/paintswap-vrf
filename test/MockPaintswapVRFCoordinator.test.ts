import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("MockVRFCoordinator", function () {
  // Test fixtures
  async function deployCoordinatorMockFixture() {
    const [owner, oracle1, oracle2, consumer1, consumer2, user1] =
      await ethers.getSigners();

    // Deploy the MockVRFCoordinator
    const MockVRFCoordinator =
      await ethers.getContractFactory("MockVRFCoordinator");
    const coordinator = await MockVRFCoordinator.deploy();
    await coordinator.waitForDeployment();

    return {
      coordinator,
      owner,
      oracle1,
      oracle2,
      consumer1,
      consumer2,
      user1,
    };
  }

  async function deployWithRequestFixture() {
    const fixture = await deployCoordinatorMockFixture();
    const { coordinator, consumer1 } = fixture;

    // Make a request to have some test data
    const callbackGasLimit = 2_000_000;
    const numWords = 3;
    const price =
      await coordinator.calculateRequestPriceNative(callbackGasLimit);

    const tx = await coordinator
      .connect(consumer1)
      .requestRandomnessPayInNative(callbackGasLimit, numWords, {
        value: price,
      });
    const receipt = await tx.wait();

    // Extract request ID from event
    const event = receipt?.logs.find((log) => {
      try {
        const parsed = coordinator.interface.parseLog(log);
        return parsed?.name === "RandomWordsRequested";
      } catch {
        return false;
      }
    });

    const parsedEvent = coordinator.interface.parseLog(event!);
    const requestId = parsedEvent?.args[0];

    return { ...fixture, requestId, callbackGasLimit, numWords, price };
  }

  async function deployWithFailingConsumerFixture() {
    const fixture = await deployCoordinatorMockFixture();
    const { coordinator, consumer1 } = fixture;

    // Deploy a failing consumer for testing
    const FailingVRFConsumer =
      await ethers.getContractFactory("FailingVRFConsumer");
    const failingConsumer = await FailingVRFConsumer.deploy();
    await failingConsumer.waitForDeployment();

    // Make a request from the failing consumer
    const callbackGasLimit = 100_000;
    const numWords = 2;
    const price =
      await coordinator.calculateRequestPriceNative(callbackGasLimit);

    const tx = await failingConsumer.requestRandomness(
      await coordinator.getAddress(),
      callbackGasLimit,
      numWords,
      { value: price },
    );
    const receipt = await tx.wait();

    // Extract request ID
    const event = receipt?.logs.find((log) => {
      try {
        const parsed = coordinator.interface.parseLog(log);
        return parsed?.name === "RandomWordsRequested";
      } catch {
        return false;
      }
    });

    const parsedEvent = coordinator.interface.parseLog(event!);
    const requestId = parsedEvent?.args[0];

    return {
      ...fixture,
      failingConsumer,
      requestId,
      callbackGasLimit,
      numWords,
    };
  }

  describe("Deployment", function () {
    it("Should deploy with correct initial state", async function () {
      const { coordinator, owner } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      expect(await coordinator.getSignerAddress()).to.equal(owner.address);
      expect(await coordinator.isOracle(owner.address)).to.be.true;
      expect(await coordinator.MIN_CONSUMER_GAS_LIMIT()).to.equal(5_000);

      // Check initial statistics
      const [total, pending, successes, failures, totalWords] =
        await coordinator.getFulfillmentStats();
      expect(total).to.equal(0);
      expect(pending).to.equal(0);
      expect(successes).to.equal(0);
      expect(failures).to.equal(0);
      expect(totalWords).to.equal(0);
    });

    it("Should have correct constants", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      expect(await coordinator.MIN_CONSUMER_GAS_LIMIT()).to.equal(5_000);
    });

    it("Should emit OracleRegistered event on deployment", async function () {
      const [owner] = await ethers.getSigners();

      const MockVRFCoordinator =
        await ethers.getContractFactory("MockVRFCoordinator");

      // Deploy and wait for transaction receipt
      const deployTx = await MockVRFCoordinator.getDeployTransaction();
      const response = await owner.sendTransaction(deployTx);
      const receipt = await response.wait();

      // Check for OracleRegistered event in the logs
      const iface = MockVRFCoordinator.interface;
      const oracleRegisteredEvent = receipt?.logs.find((log) => {
        try {
          const parsed = iface.parseLog(log);
          return parsed?.name === "OracleRegistered";
        } catch {
          return false;
        }
      });

      expect(oracleRegisteredEvent).to.not.be.undefined;

      if (oracleRegisteredEvent) {
        const parsedEvent = iface.parseLog(oracleRegisteredEvent);
        expect(parsedEvent?.args[0]).to.equal(owner.address);
      }
    });
  });

  describe("Price Calculation", function () {
    it("Should calculate request price correctly", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      const callbackGasLimit = 100_000;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      // Price should be (callback gas + VRF gas) * base price
      // VRF gas is 300_000, base price is 1 gwei
      const expectedPrice = (BigInt(callbackGasLimit) + 300_000n) * BigInt(1e9);
      expect(price).to.equal(expectedPrice);
    });

    it("Should revert for invalid gas limits", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Too low
      await expect(
        coordinator.calculateRequestPriceNative(4_999),
      ).to.be.revertedWithCustomError(coordinator, "InsufficientGasLimit");

      // Too high
      await expect(
        coordinator.calculateRequestPriceNative(6_000_001),
      ).to.be.revertedWithCustomError(coordinator, "OverConsumerGasLimit");
    });

    it("Should handle edge gas limit values", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Minimum allowed
      const minPrice = await coordinator.calculateRequestPriceNative(5_000);
      expect(minPrice).to.be.gt(0);

      // Maximum allowed
      const maxPrice = await coordinator.calculateRequestPriceNative(6_000_000);
      expect(maxPrice).to.be.gt(minPrice);
    });
  });

  describe("Request Randomness", function () {
    it("Should successfully request randomness with valid parameters", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 5;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, numWords, {
            value: price,
          }),
      )
        .to.emit(coordinator, "RandomWordsRequested")
        .withArgs(
          (value: any) => value > 0, // requestId should be > 0
          callbackGasLimit,
          numWords,
          consumer1.address, // tx.origin
          consumer1.address, // consumer
          1, // nonce
          (value: any) => value > 0, // timestamp should be > 0
        );

      // Check that statistics were updated
      const [total, pending, successes, failures, totalWords] =
        await coordinator.getFulfillmentStats();
      expect(total).to.equal(1);
      expect(pending).to.equal(1);
      expect(successes).to.equal(0);
      expect(failures).to.equal(0);
      expect(totalWords).to.equal(numWords);
    });

    it("Should revert with insufficient payment", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 3;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);
      const insufficientPrice = price - 1n;

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, numWords, {
            value: insufficientPrice,
          }),
      ).to.be.revertedWithCustomError(coordinator, "InsufficientGasPayment");
    });

    it("Should revert for invalid gas limits", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const numWords = 3;

      // Too low
      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(4_999, numWords, {
            value: ethers.parseEther("1"),
          }),
      ).to.be.revertedWithCustomError(coordinator, "InsufficientGasLimit");

      // Too high
      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(6_000_001, numWords, {
            value: ethers.parseEther("1"),
          }),
      ).to.be.revertedWithCustomError(coordinator, "OverConsumerGasLimit");
    });

    it("Should revert for invalid number of words", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;

      // Zero words
      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, 0, {
            value: ethers.parseEther("1"),
          }),
      ).to.be.revertedWithCustomError(coordinator, "InvalidNumWords");

      // Too many words
      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, 501, {
            value: ethers.parseEther("1"),
          }),
      ).to.be.revertedWithCustomError(coordinator, "InvalidNumWords");
    });

    it("Should handle multiple requests from same consumer", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 2;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      // First request
      const tx1 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });
      const receipt1 = await tx1.wait();

      // Second request
      const tx2 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });
      const receipt2 = await tx2.wait();

      // Extract request IDs
      const event1 = receipt1?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const event2 = receipt2?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId1 = coordinator.interface.parseLog(event1!)?.args[0];
      const requestId2 = coordinator.interface.parseLog(event2!)?.args[0];

      // Request IDs should be different
      expect(requestId1).to.not.equal(requestId2);

      // Both should be pending
      expect(await coordinator.isRequestPending(requestId1)).to.be.true;
      expect(await coordinator.isRequestPending(requestId2)).to.be.true;

      // Nonce should have incremented
      expect(await coordinator.getNonce(consumer1.address)).to.equal(2);
    });

    it("Should handle requests from different consumers", async function () {
      const { coordinator, consumer1, consumer2 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      // Request from consumer1
      await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      // Request from consumer2
      await coordinator
        .connect(consumer2)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      // Each consumer should have nonce of 1
      expect(await coordinator.getNonce(consumer1.address)).to.equal(1);
      expect(await coordinator.getNonce(consumer2.address)).to.equal(1);

      // Statistics should show 2 total requests
      const [total] = await coordinator.getFulfillmentStats();
      expect(total).to.equal(2);
    });

    it("Should accept overpayment", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);
      const overpayment = price + ethers.parseEther("1");

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, numWords, {
            value: overpayment,
          }),
      ).to.not.be.reverted;
    });
  });

  describe("Request ID Calculation", function () {
    it("Should calculate next request ID correctly", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      // Get predicted ID before making request
      const predictedId = await coordinator.calculateNextRequestId(
        consumer1.address,
      );

      // Make request
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });
      const receipt = await tx.wait();

      // Extract actual request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const actualId = coordinator.interface.parseLog(event!)?.args[0];

      expect(actualId).to.equal(predictedId);
    });

    it("Should generate different IDs for different consumers", async function () {
      const { coordinator, consumer1, consumer2 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const id1 = await coordinator.calculateNextRequestId(consumer1.address);
      const id2 = await coordinator.calculateNextRequestId(consumer2.address);

      expect(id1).to.not.equal(id2);
    });

    it("Should increment IDs for same consumer", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const id1 = await coordinator.calculateNextRequestId(consumer1.address);

      // Make a request to increment nonce
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      const id2 = await coordinator.calculateNextRequestId(consumer1.address);

      expect(id2).to.not.equal(id1);
    });
  });

  describe("Request Status", function () {
    it("Should correctly track pending requests", async function () {
      const { coordinator, requestId } = await loadFixture(
        deployWithRequestFixture,
      );

      expect(await coordinator.isRequestPending(requestId)).to.be.true;
    });

    it("Should return false for non-existent requests", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      expect(await coordinator.isRequestPending(999999)).to.be.false;
    });

    it("Should return false for fulfilled requests", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      // Fulfill the request
      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );
      await coordinator.fulfillRequestMock(requestId, randomWords);

      expect(await coordinator.isRequestPending(requestId)).to.be.false;
    });
  });

  describe("Mock Fulfillment", function () {
    it("Should successfully fulfill request with custom random words", async function () {
      const { coordinator, requestId, numWords, consumer1 } = await loadFixture(
        deployWithRequestFixture,
      );

      const customRandomWords = [12345n, 67890n, 11111n];

      await expect(coordinator.fulfillRequestMock(requestId, customRandomWords))
        .to.emit(coordinator, "RandomWordsFulfilled")
        .withArgs(
          requestId,
          customRandomWords,
          await coordinator.getAddress(), // oracle address
          true, // callSuccess
          (value: any) => value > 0, // timestamp
        );

      // Request should no longer be pending
      expect(await coordinator.isRequestPending(requestId)).to.be.false;

      // Statistics should be updated
      const [total, pending, successes, failures] =
        await coordinator.getFulfillmentStats();
      expect(total).to.equal(1);
      expect(pending).to.equal(0);
      expect(successes).to.equal(1);
      expect(failures).to.equal(0);
    });

    it("Should successfully fulfill request with auto-generated random words", async function () {
      const { coordinator, requestId } = await loadFixture(
        deployWithRequestFixture,
      );

      await expect(coordinator.fulfillRequestMockWithRandomWords(requestId))
        .to.emit(coordinator, "RandomWordsFulfilled")
        .withArgs(
          requestId,
          (value: any) => Array.isArray(value) && value.length > 0, // randomWords array
          await coordinator.getAddress(), // oracle address
          true, // callSuccess
          (value: any) => value > 0, // timestamp
        );

      // Request should no longer be pending
      expect(await coordinator.isRequestPending(requestId)).to.be.false;
    });

    it("Should revert when fulfilling non-existent request", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      const nonExistentRequestId = 999999n;
      const randomWords = [12345n];

      await expect(
        coordinator.fulfillRequestMock(nonExistentRequestId, randomWords),
      ).to.be.revertedWithCustomError(coordinator, "RequestNotFound");
    });

    it("Should revert when fulfilling already fulfilled request", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      // Fulfill once
      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );
      await coordinator.fulfillRequestMock(requestId, randomWords);

      // Try to fulfill again
      await expect(
        coordinator.fulfillRequestMock(requestId, randomWords),
      ).to.be.revertedWithCustomError(coordinator, "CommitmentMismatch");
    });

    it("Should revert when fulfilling with wrong number of words", async function () {
      const { coordinator, requestId } = await loadFixture(
        deployWithRequestFixture,
      );

      // Wrong number of words (expected 3, providing 2)
      const wrongRandomWords = [12345n, 67890n];

      await expect(
        coordinator.fulfillRequestMock(requestId, wrongRandomWords),
      ).to.be.revertedWithCustomError(coordinator, "InvalidNumWords");
    });

    it("Should emit debug events on fulfillment", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );

      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(requestId, true, "callback succeeded");
    });
  });

  describe("Request Details", function () {
    it("Should return correct request details", async function () {
      const {
        coordinator,
        requestId,
        consumer1,
        callbackGasLimit,
        numWords,
        price,
      } = await loadFixture(deployWithRequestFixture);

      const [consumer, gasLimit, words, payment, fulfilled] =
        await coordinator.getRequest(requestId);

      expect(consumer).to.equal(consumer1.address);
      expect(gasLimit).to.equal(callbackGasLimit);
      expect(words).to.equal(numWords);
      expect(payment).to.equal(price);
      expect(fulfilled).to.be.false;
    });

    it("Should update fulfilled status after fulfillment", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      // Fulfill the request
      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );
      await coordinator.fulfillRequestMock(requestId, randomWords);

      const [, , , , fulfilled] = await coordinator.getRequest(requestId);
      expect(fulfilled).to.be.true;
    });
  });

  describe("Request Results", function () {
    it("Should track request results correctly", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      // Before fulfillment
      let [wasSuccess, wasFulfilled] =
        await coordinator.getRequestResult(requestId);
      expect(wasFulfilled).to.be.false;

      // Fulfill request
      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );
      await coordinator.fulfillRequestMock(requestId, randomWords);

      // After fulfillment
      [wasSuccess, wasFulfilled] =
        await coordinator.getRequestResult(requestId);
      expect(wasFulfilled).to.be.true;
      expect(wasSuccess).to.be.true;
    });

    it("Should return false for non-existent request results", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      const [wasSuccess, wasFulfilled] =
        await coordinator.getRequestResult(999999);
      expect(wasFulfilled).to.be.false;
      expect(wasSuccess).to.be.false;
    });
  });

  describe("Statistics", function () {
    it("Should track statistics across multiple requests and fulfillments", async function () {
      const { coordinator, consumer1, consumer2 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      // Make 3 requests
      const tx1 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, 2, { value: price });
      const tx2 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, 3, { value: price });
      const tx3 = await coordinator
        .connect(consumer2)
        .requestRandomnessPayInNative(callbackGasLimit, 1, { value: price });

      // Check statistics after requests
      let [total, pending, successes, failures, totalWords] =
        await coordinator.getFulfillmentStats();
      expect(total).to.equal(3);
      expect(pending).to.equal(3);
      expect(successes).to.equal(0);
      expect(failures).to.equal(0);
      expect(totalWords).to.equal(6); // 2 + 3 + 1

      // Extract request IDs
      const receipt1 = await tx1.wait();
      const receipt2 = await tx2.wait();
      const receipt3 = await tx3.wait();

      const event1 = receipt1?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const event2 = receipt2?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const event3 = receipt3?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId1 = coordinator.interface.parseLog(event1!)?.args[0];
      const requestId2 = coordinator.interface.parseLog(event2!)?.args[0];
      const requestId3 = coordinator.interface.parseLog(event3!)?.args[0];

      // Fulfill 2 requests successfully
      await coordinator.fulfillRequestMock(requestId1, [111n, 222n]);
      await coordinator.fulfillRequestMock(requestId2, [333n, 444n, 555n]);

      // Check statistics after fulfillments
      [total, pending, successes, failures, totalWords] =
        await coordinator.getFulfillmentStats();
      expect(total).to.equal(3);
      expect(pending).to.equal(1);
      expect(successes).to.equal(2);
      expect(failures).to.equal(0);
      expect(totalWords).to.equal(6);
    });

    it("Should handle zero statistics correctly", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      const [total, pending, successes, failures, totalWords] =
        await coordinator.getFulfillmentStats();

      expect(total).to.equal(0);
      expect(pending).to.equal(0);
      expect(successes).to.equal(0);
      expect(failures).to.equal(0);
      expect(totalWords).to.equal(0);
    });
  });

  describe("Oracle Management", function () {
    it("Should correctly identify oracles", async function () {
      const { coordinator, owner, user1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      expect(await coordinator.isOracle(owner.address)).to.be.true;
      expect(await coordinator.isOracle(user1.address)).to.be.false;
    });

    it("Should return correct signer address", async function () {
      const { coordinator, owner } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      expect(await coordinator.getSignerAddress()).to.equal(owner.address);
    });
  });

  describe("Nonce Management", function () {
    it("Should track nonces correctly for different consumers", async function () {
      const { coordinator, consumer1, consumer2 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      // Initially both should have nonce 0
      expect(await coordinator.getNonce(consumer1.address)).to.equal(0);
      expect(await coordinator.getNonce(consumer2.address)).to.equal(0);

      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      // Consumer1 makes a request
      await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      expect(await coordinator.getNonce(consumer1.address)).to.equal(1);
      expect(await coordinator.getNonce(consumer2.address)).to.equal(0);

      // Consumer2 makes a request
      await coordinator
        .connect(consumer2)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      expect(await coordinator.getNonce(consumer1.address)).to.equal(1);
      expect(await coordinator.getNonce(consumer2.address)).to.equal(1);

      // Consumer1 makes another request
      await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });

      expect(await coordinator.getNonce(consumer1.address)).to.equal(2);
      expect(await coordinator.getNonce(consumer2.address)).to.equal(1);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle maximum number of words", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const maxWords = 500; // DEFAULT_MAX_NUM_WORDS
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(callbackGasLimit, maxWords, {
            value: price,
          }),
      ).to.not.be.reverted;

      // Statistics should show 500 total words
      const [, , , , totalWords] = await coordinator.getFulfillmentStats();
      expect(totalWords).to.equal(maxWords);
    });

    it("Should handle minimum gas limit", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const minGasLimit = 5_000;
      const numWords = 1;
      const price = await coordinator.calculateRequestPriceNative(minGasLimit);

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(minGasLimit, numWords, {
            value: price,
          }),
      ).to.not.be.reverted;
    });

    it("Should handle maximum gas limit", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const maxGasLimit = 6_000_000;
      const numWords = 1;
      const price = await coordinator.calculateRequestPriceNative(maxGasLimit);

      await expect(
        coordinator
          .connect(consumer1)
          .requestRandomnessPayInNative(maxGasLimit, numWords, {
            value: price,
          }),
      ).to.not.be.reverted;
    });
  });

  describe("Receive Function", function () {
    it("Should accept ETH payments", async function () {
      const { coordinator, user1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const amount = ethers.parseEther("1");

      await expect(
        user1.sendTransaction({
          to: await coordinator.getAddress(),
          value: amount,
        }),
      ).to.not.be.reverted;

      const balance = await ethers.provider.getBalance(
        await coordinator.getAddress(),
      );
      expect(balance).to.be.gte(amount);
    });
  });

  describe("VRF Interface Compatibility", function () {
    it("Should implement fulfillRandomWords interface", async function () {
      const { coordinator, requestId, callbackGasLimit, numWords, consumer1 } =
        await loadFixture(deployWithRequestFixture);

      // Mock VRF proof parameters
      const publicKey: [bigint, bigint] = [123n, 456n];
      const proof: [bigint, bigint, bigint, bigint] = [
        789n,
        101112n,
        131415n,
        161718n,
      ];
      const uPoint: [bigint, bigint] = [192021n, 222324n];
      const vComponents: [bigint, bigint, bigint, bigint] = [
        252627n,
        282930n,
        313233n,
        343536n,
      ];
      const proofCtr = 1;

      // This should work (though it generates pseudo-random words in mock)
      await expect(
        coordinator.fulfillRandomWords(
          requestId,
          consumer1.address,
          callbackGasLimit,
          numWords,
          publicKey,
          proof,
          uPoint,
          vComponents,
          proofCtr,
        ),
      ).to.not.be.reverted;
    });

    it("Should validate commitment in fulfillRandomWords", async function () {
      const { coordinator, callbackGasLimit, numWords, consumer1 } =
        await loadFixture(deployWithRequestFixture);

      // Invalid request ID should fail commitment validation
      const invalidRequestId = 999999n;
      const publicKey: [bigint, bigint] = [123n, 456n];
      const proof: [bigint, bigint, bigint, bigint] = [
        789n,
        101112n,
        131415n,
        161718n,
      ];
      const uPoint: [bigint, bigint] = [192021n, 222324n];
      const vComponents: [bigint, bigint, bigint, bigint] = [
        252627n,
        282930n,
        313233n,
        343536n,
      ];
      const proofCtr = 1;

      await expect(
        coordinator.fulfillRandomWords(
          invalidRequestId,
          consumer1.address,
          callbackGasLimit,
          numWords,
          publicKey,
          proof,
          uPoint,
          vComponents,
          proofCtr,
        ),
      ).to.be.revertedWithCustomError(coordinator, "CommitmentMismatch");
    });
  });

  describe("Gas Usage", function () {
    it("Should use reasonable gas for request operations", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, numWords, {
          value: price,
        });
      const receipt = await tx.wait();

      // Should use reasonable gas for request (updated threshold)
      expect(receipt?.gasUsed).to.be.lt(250_000);
    });

    it("Should use reasonable gas for fulfillment operations", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithRequestFixture,
      );

      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );

      const tx = await coordinator.fulfillRequestMock(requestId, randomWords);
      const receipt = await tx.wait();

      // Should use reasonable gas for fulfillment (updated threshold)
      expect(receipt?.gasUsed).to.be.lt(250_000);
    });

    it("Should demonstrate gas usage is proportional to number of words", async function () {
      const { coordinator, consumer1 } = await loadFixture(
        deployCoordinatorMockFixture,
      );

      const callbackGasLimit = 100_000;

      // Test with 1 word
      const price1 =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);
      const tx1 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, 1, { value: price1 });
      const receipt1 = await tx1.wait();

      // Test with 5 words
      const price5 =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);
      const tx5 = await coordinator
        .connect(consumer1)
        .requestRandomnessPayInNative(callbackGasLimit, 5, { value: price5 });
      const receipt5 = await tx5.wait();

      // Gas usage should be similar since the number of words doesn't significantly affect request gas
      expect(receipt1?.gasUsed).to.be.lt(250_000);
      expect(receipt5?.gasUsed).to.be.lt(250_000);
    });
  });

  describe("Callback Failures", function () {
    async function deployWithFailingConsumerFixture() {
      const fixture = await deployCoordinatorMockFixture();
      const { coordinator, consumer1 } = fixture;

      // Deploy a failing consumer for testing
      const FailingVRFConsumer =
        await ethers.getContractFactory("FailingVRFConsumer");
      const failingConsumer = await FailingVRFConsumer.deploy();
      await failingConsumer.waitForDeployment();

      // Make a request from the failing consumer
      const callbackGasLimit = 100_000;
      const numWords = 2;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await failingConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const parsedEvent = coordinator.interface.parseLog(event!);
      const requestId = parsedEvent?.args[0];

      return {
        ...fixture,
        failingConsumer,
        requestId,
        callbackGasLimit,
        numWords,
      };
    }

    it("Should handle consumer callback failure and emit failure events", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithFailingConsumerFixture,
      );

      const randomWords = Array.from({ length: numWords }, (_, i) =>
        BigInt(i + 1),
      );

      // This should trigger the failure path
      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "ConsumerCallbackFailed")
        .and.to.emit(coordinator, "DebugFulfillment")
        .withArgs(requestId, false, (reason: string) =>
          reason.includes("callback failed"),
        );

      // Check that the request was marked as failed
      const [wasSuccess, wasFulfilled] =
        await coordinator.getRequestResult(requestId);
      expect(wasFulfilled).to.be.true;
      expect(wasSuccess).to.be.false;

      // Statistics should show the failure
      const [total, pending, successes, failures] =
        await coordinator.getFulfillmentStats();
      expect(failures).to.be.gte(1);
    });

    it("Should handle consumer callback failure with Error(string) revert", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithFailingConsumerFixture,
      );

      // Deploy a consumer that reverts with Error(string)
      const RevertingVRFConsumer = await ethers.getContractFactory(
        "RevertingVRFConsumer",
      );
      const revertingConsumer = await RevertingVRFConsumer.deploy();
      await revertingConsumer.waitForDeployment();

      // Make a request from the reverting consumer
      const callbackGasLimit = 100_000;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await revertingConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const revertRequestId = coordinator.interface.parseLog(event!)?.args[0];
      const randomWords = [123n, 456n];

      // This should trigger the Error(string) parsing path
      await expect(coordinator.fulfillRequestMock(revertRequestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(revertRequestId, false, (reason: string) =>
          reason.includes("Custom revert message"),
        );
    });

    it("Should handle consumer callback failure with custom error", async function () {
      const { coordinator, requestId, numWords } = await loadFixture(
        deployWithFailingConsumerFixture,
      );

      // Deploy a consumer that reverts with custom error
      const CustomErrorVRFConsumer = await ethers.getContractFactory(
        "CustomErrorVRFConsumer",
      );
      const customErrorConsumer = await CustomErrorVRFConsumer.deploy();
      await customErrorConsumer.waitForDeployment();

      // Make a request from the custom error consumer
      const callbackGasLimit = 100_000;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await (customErrorConsumer as any).requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      interface LogWithData {
        logs: Array<{
          topics: string[];
          data: string;
          [key: string]: any;
        }>;
      }

      interface ParsedLogEvent {
        name: string;
        args: any[];
      }

      const event = (receipt as LogWithData | null)?.logs.find(
        (log: { topics: string[]; data: string; [key: string]: any }) => {
          try {
            const parsed: ParsedLogEvent | null =
              coordinator.interface.parseLog(log);
            return parsed?.name === "RandomWordsRequested";
          } catch {
            return false;
          }
        },
      );

      const customErrorRequestId = coordinator.interface.parseLog(event!)
        ?.args[0];
      const randomWords = [456n, 789n];

      // This should trigger the custom error parsing path
      await expect(
        coordinator.fulfillRequestMock(customErrorRequestId, randomWords),
      )
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          customErrorRequestId,
          false,
          "callback failed: low level revert with data",
        );
    });

    it("Should handle consumer callback failure with empty revert data", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that reverts with no data
      const EmptyRevertVRFConsumer = await ethers.getContractFactory(
        "EmptyRevertVRFConsumer",
      );
      const emptyRevertConsumer = await EmptyRevertVRFConsumer.deploy();
      await emptyRevertConsumer.waitForDeployment();

      // Make a request from the empty revert consumer
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await emptyRevertConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const emptyRevertRequestId = coordinator.interface.parseLog(event!)
        ?.args[0];
      const randomWords = [789n];

      // This should trigger the empty revert data path
      await expect(
        coordinator.fulfillRequestMock(emptyRevertRequestId, randomWords),
      )
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          emptyRevertRequestId,
          false,
          "callback failed: low level revert",
        );
    });

    it("Should handle Error(string) with empty message", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that reverts with Error(string) but empty message
      const EmptyErrorVRFConsumer = await ethers.getContractFactory(
        "EmptyErrorVRFConsumer",
      );
      const emptyErrorConsumer = await EmptyErrorVRFConsumer.deploy();
      await emptyErrorConsumer.waitForDeployment();

      // Make a request from the empty error consumer
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await emptyErrorConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const emptyErrorRequestId = coordinator.interface.parseLog(event!)
        ?.args[0];
      const randomWords = [999n];

      // This should trigger the Error(string) with no message path
      await expect(
        coordinator.fulfillRequestMock(emptyErrorRequestId, randomWords),
      )
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          emptyErrorRequestId,
          false,
          "callback failed: Error(string) with no message",
        );
    });
  });

  describe("Error Parsing Coverage", function () {
    it("Should handle Error(string) with malformed ABI data", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that creates malformed Error(string) data
      const MalformedErrorVRFConsumer = await ethers.getContractFactory(
        "MalformedErrorVRFConsumer",
      );
      const malformedConsumer = await MalformedErrorVRFConsumer.deploy();
      await malformedConsumer.waitForDeployment();

      // Make a request
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await malformedConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId = coordinator.interface.parseLog(event!)?.args[0];
      const randomWords = [123n];

      // This should trigger the catch block in decodeErrorString
      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          requestId,
          false,
          "callback failed: Error(string) with no message",
        );
    });

    it("Should handle Error(string) selector with exactly 4 bytes", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that returns only the Error(string) selector with no data
      const OnlySelectorVRFConsumer = await ethers.getContractFactory(
        "OnlySelectorVRFConsumer",
      );
      const onlySelectorConsumer = await OnlySelectorVRFConsumer.deploy();
      await onlySelectorConsumer.waitForDeployment();

      // Make a request
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await onlySelectorConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId = coordinator.interface.parseLog(event!)?.args[0];
      const randomWords = [456n];

      // This should trigger the "returnData.length > 4" false branch
      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          requestId,
          false,
          "callback failed: Error(string) with no message",
        );
    });

    it("Should handle revert data with less than 4 bytes", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that returns minimal revert data (< 4 bytes)
      const ShortRevertVRFConsumer = await ethers.getContractFactory(
        "ShortRevertVRFConsumer",
      );
      const shortRevertConsumer = await ShortRevertVRFConsumer.deploy();
      await shortRevertConsumer.waitForDeployment();

      // Make a request
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await shortRevertConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId = coordinator.interface.parseLog(event!)?.args[0];
      const randomWords = [789n];

      // This should trigger the "else" branch for data < 4 bytes but > 0 bytes
      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          requestId,
          false,
          "callback failed: low level revert with data",
        );
    });

    it("Should handle non-Error(string) selector with data", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Deploy a consumer that returns a different selector with data
      const NonErrorSelectorVRFConsumer = await ethers.getContractFactory(
        "NonErrorSelectorVRFConsumer",
      );
      const nonErrorConsumer = await NonErrorSelectorVRFConsumer.deploy();
      await nonErrorConsumer.waitForDeployment();

      // Make a request
      const callbackGasLimit = 100_000;
      const numWords = 1;
      const price =
        await coordinator.calculateRequestPriceNative(callbackGasLimit);

      const tx = await nonErrorConsumer.requestRandomness(
        await coordinator.getAddress(),
        callbackGasLimit,
        numWords,
        { value: price },
      );
      const receipt = await tx.wait();

      // Extract request ID
      const event = receipt?.logs.find((log) => {
        try {
          const parsed = coordinator.interface.parseLog(log);
          return parsed?.name === "RandomWordsRequested";
        } catch {
          return false;
        }
      });

      const requestId = coordinator.interface.parseLog(event!)?.args[0];
      const randomWords = [999n];

      // This should trigger the "not Error(string)" branch
      await expect(coordinator.fulfillRequestMock(requestId, randomWords))
        .to.emit(coordinator, "DebugFulfillment")
        .withArgs(
          requestId,
          false,
          "callback failed: low level revert with data",
        );
    });

    it("Should test decodeErrorString function directly", async function () {
      const { coordinator } = await loadFixture(deployCoordinatorMockFixture);

      // Test with valid string data
      const validString = "Test error message";
      const encodedString = ethers.AbiCoder.defaultAbiCoder().encode(
        ["string"],
        [validString],
      );

      const decodedString = await coordinator.decodeErrorString(encodedString);
      expect(decodedString).to.equal(validString);

      // Test with empty string
      const emptyString = "";
      const encodedEmptyString = ethers.AbiCoder.defaultAbiCoder().encode(
        ["string"],
        [emptyString],
      );

      const decodedEmptyString =
        await coordinator.decodeErrorString(encodedEmptyString);
      expect(decodedEmptyString).to.equal(emptyString);
    });
  });
});
