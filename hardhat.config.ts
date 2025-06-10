import "dotenv/config";

import { type HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-solhint";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "hardhat-storage-layout";
import "@primitivefi/hardhat-dodoc";

const defaultConfig = {
  version: "0.8.30",
  settings: {
    evmVersion: "cancun",
    optimizer: {
      enabled: true,
      runs: 99999999,
      details: {
        yul: true,
      },
    },
    viaIR: true,
    outputSelection: {
      "*": {
        "*": ["storageLayout"],
      },
    },
  },
};

const config: HardhatUserConfig = {
  solidity: {
    compilers: [defaultConfig],
  },
  gasReporter: {
    enabled: process.env.GAS_REPORTER != "false",
    currency: process.env.GAS_CURRENCY || "USD",
    token: process.env.GAS_TOKEN || "S",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    gasPriceApi:
      "https://api.sonicscan.org/api?module=proxy&action=eth_gasPrice",
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
    except: ["@openzeppelin"],
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "sonic",
        chainId: 146,
        urls: {
          apiURL: "https://api.sonicscan.org/api",
          browserURL: "https://sonicscan.org",
        },
      },
      {
        network: "blaze",
        chainId: 57054,
        urls: {
          apiURL: "https://api-testnet.sonicscan.org/api",
          browserURL: "https://testnet.sonicscan.org",
        },
      },
    ],
  },
  abiExporter: {
    path: "./abi",
    clear: true,
    flat: false,
    except: ["test"],
  },
  dodoc: {
    freshOutput: true,
    runOnCompile: true,
    keepFileStructure: true,
    include: [
      "IPaintswapVRFCoordinator.sol",
      "IPaintswapVRFConsumer.sol",
      "EllipticCurve.sol",
      "VRF.sol",
      "FeeM.sol",
      "PaintswapVRFConsumer.sol",
      "PaintswapVRFCoordinatorCore.sol",
      "ExampleVRFConsumer.sol",
      "MockVRFCoordinator.sol",
    ],
  },
  typechain: {
    target: "ethers-v6",
  },
};

export default config;
