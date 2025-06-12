// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPaintswapVRFCoordinator} from "./interfaces/IPaintswapVRFCoordinator.sol";

abstract contract PaintswapVRFCoordinatorCore is IPaintswapVRFCoordinator {
  /**
   * @notice Computes the commitment hash for a VRF request.
   *
   * @param requestId The unique identifier for the VRF request.
   * @param consumer The address of the consumer contract making the request.
   * @param callbackGasLimit The gas limit for the callback function.
   * @param numWords The number of random words requested.
   * @param refundee The address to refund in case of failure.
   * @param gasPricePaid The gas price paid for the request.
   *
   * @return The computed commitment hash as a uint256 value.
   */
  function _getCommitmentHash(
    uint256 requestId,
    address consumer,
    uint256 callbackGasLimit,
    uint256 numWords,
    address refundee,
    uint256 gasPricePaid
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encode(
            requestId,
            consumer,
            callbackGasLimit,
            numWords,
            refundee,
            gasPricePaid,
            block.chainid
          )
        )
      );
  }

  /**
   * @notice Computes the request ID for a VRF request.
   *
   * @param sender The address of the sender making the request.
   * @param nonce The nonce associated with the request.
   *
   * @return The computed request ID as a uint256 value.
   */
  function _computeRequestId(
    address sender,
    uint256 nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(sender, nonce)));
  }

  /**
   * @notice Refunds the remaining gas to the specified refundee address.
   *
   * @param requestId The unique identifier for the VRF request.
   * @param callbackGasLimit The gas limit for the callback function.
   * @param gasUsed The amount of gas used during the request.
   * @param gasPricePaid The gas price paid for the request.
   * @param refundee The address to refund in case of failure.
   */
  function _refundRemainingGas(
    uint256 requestId,
    uint256 callbackGasLimit,
    uint256 gasUsed,
    uint256 gasPricePaid,
    address refundee
  ) internal {
    if (refundee != address(0) && refundee != address(this)) {
      // Calculate unused gas
      uint256 unUsedGas = callbackGasLimit > gasUsed
        ? (callbackGasLimit - gasUsed)
        : 0;
      // 10% penalty on used gas
      uint256 gasRefund = (unUsedGas * 9) / 10;
      // Don't bother refunding small amounts to avoid gas overhead
      if (gasRefund > 50_000) {
        uint256 refundAmount = (gasRefund * gasPricePaid);
        (bool success, ) = refundee.call{value: refundAmount}("");
        emit FulfillmentGasRefunded(requestId, refundee, refundAmount, success);
      }
    }
  }
}
