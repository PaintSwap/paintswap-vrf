import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  ExampleVRFConsumerUpgradeable,
  MockVRFCoordinator,
  PaintswapVRFConsumer,
} from "../typechain-types";

describe("PaintswapVRFConsumerUpgradeable", function () {
  it("initialize and coordinator/owner behaviors", async function () {
    const [deployer, other] = await ethers.getSigners();

    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const mockCoordinator = await (
      await ethers.getContractFactory("MockVRFCoordinator")
    ).deploy();
    await mockCoordinator.waitForDeployment();

    // Deploy as an upgradeable proxy using Hardhat Upgrades
    const instance = await upgrades.deployProxy(
      TestContract,
      [await mockCoordinator.getAddress(), deployer.address],
      { initializer: "initialize" },
    );
    await instance.waitForDeployment();
    const inst: PaintswapVRFConsumer = instance;
    const mock: MockVRFCoordinator = mockCoordinator;
  });

  it("onlyCoordinator behavior on upgradeable proxy", async function () {
    const [deployer, user] = await ethers.getSigners();

    // Deploy a Mock coordinator
    const mockCoordinator = await (
      await ethers.getContractFactory("MockVRFCoordinator")
    ).deploy();
    await mockCoordinator.waitForDeployment();

    // Deploy the upgradeable test consumer as a proxy
    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const proxy = await upgrades.deployProxy(
      TestContract,
      [await mockCoordinator.getAddress(), await deployer.getAddress()],
      { initializer: "initialize", kind: "uups" },
    );
    await proxy.waitForDeployment();
    const inst: any = proxy;

    // EOA (non-coordinator) cannot call rawFulfillRandomWords
    await expect(
      inst.rawFulfillRandomWords(1n, [111n]),
    ).to.be.revertedWithCustomError(inst, "OnlyVRFCoordinator");
  });

  it("request/fulfill flow on upgradeable proxy", async function () {
    const [deployer, user] = await ethers.getSigners();

    const mockCoordinator = await (
      await ethers.getContractFactory("MockVRFCoordinator")
    ).deploy();
    await mockCoordinator.waitForDeployment();

    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const proxy = await upgrades.deployProxy(
      TestContract,
      [await mockCoordinator.getAddress(), await deployer.getAddress()],
      { initializer: "initialize", kind: "uups" },
    );
    await proxy.waitForDeployment();
    const inst: ExampleVRFConsumerUpgradeable = proxy;

    // Calculate price and request randomness
    const price = await inst.calculateRequestPriceNative(2_000_000);
    const tx = await inst.connect(user).requestRandomWords(2, { value: price });
    const receipt = await tx.wait();

    const requestEvent = receipt?.logs.find((log: any) => {
      try {
        const parsed = mockCoordinator.interface.parseLog(log);
        return parsed?.name === "RandomWordsRequested";
      } catch {
        return false;
      }
    });

    expect(requestEvent, "RandomWordsRequested event not found in tx logs").to
      .not.be.undefined;
    const parsedEvent = mockCoordinator.interface.parseLog(requestEvent as any);
    expect(parsedEvent, "parsed RandomWordsRequested event is null").to.not.be
      .undefined;
    const requestId = parsedEvent!.args[0];

    // Coordinator fulfills the request
    const fulfillTx = await mockCoordinator.fulfillRequestMock(
      requestId,
      [111n, 222n],
      await inst.getAddress(),
    );
    await fulfillTx.wait();
  });

  it("calling initialize on implementation should revert", async function () {
    const [deployer] = await ethers.getSigners();

    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const impl = await TestContract.deploy();
    await impl.waitForDeployment();

    // Calling initialize on the implementation should revert because initializers are disabled
    await expect(impl.initialize(deployer.address, await deployer.getAddress()))
      .to.be.reverted;
  });

  it("only owner can perform UUPS upgrades", async function () {
    const [owner, other] = await ethers.getSigners();

    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const MockCoordinator =
      await ethers.getContractFactory("MockVRFCoordinator");
    const mock = await MockCoordinator.deploy();
    await mock.waitForDeployment();

    // Deploy proxy with owner as the admin
    const proxy = await upgrades.deployProxy(
      TestContract,
      [await mock.getAddress(), await owner.getAddress()],
      { initializer: "initialize", kind: "uups" },
    );
    await proxy.waitForDeployment();

    // Attempt to upgrade as non-owner should revert
    const NewFactory = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    await expect(
      upgrades.upgradeProxy(proxy, NewFactory.connect(other), { kind: "uups" }),
    ).to.be.reverted;

    // Owner can upgrade
    await expect(
      upgrades.upgradeProxy(proxy, NewFactory.connect(owner), { kind: "uups" }),
    ).to.not.be.reverted;
  });

  it("reverts with ZeroAddress() when given zero address", async function () {
    const [owner] = await ethers.getSigners();

    const TestContract = await ethers.getContractFactory(
      "ExampleVRFConsumerUpgradeable",
    );
    const MockCoordinator =
      await ethers.getContractFactory("MockVRFCoordinator");
    const mock = await MockCoordinator.deploy();
    await mock.waitForDeployment();

    await expect(
      upgrades.deployProxy(
        TestContract,
        [ethers.ZeroAddress, await owner.getAddress()],
        { initializer: "initialize", kind: "uups" },
      ),
    ).to.be.revertedWithCustomError(TestContract, "ZeroAddress");
  });
  it("reverts NotInitializing when internal init is called outside initializer", async function () {
    const [owner] = await ethers.getSigners();

    const MockCoordinator =
      await ethers.getContractFactory("MockVRFCoordinator");
    const mock = await MockCoordinator.deploy();
    await mock.waitForDeployment();

    const TestCaller = await ethers.getContractFactory(
      "VRFConsumerUpgradeableNoInit",
    );
    const caller = await TestCaller.deploy();
    await caller.waitForDeployment();

    await expect(
      caller.callInitNoInit(await mock.getAddress()),
    ).to.be.revertedWithCustomError(caller, "NotInitializing");
  });
});
