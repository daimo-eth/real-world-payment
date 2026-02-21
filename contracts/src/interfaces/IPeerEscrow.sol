// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Peer Protocol (ZKP2P) escrow interface, derived from @zkp2p/sdk.
interface IPeerEscrow {
    struct Range {
        uint256 min;
        uint256 max;
    }

    struct DepositPaymentMethodData {
        address intentGatingService;
        bytes32 payeeDetails;
        bytes data;
    }

    struct Currency {
        bytes32 code;
        uint256 minConversionRate;
    }

    struct CreateDepositParams {
        IERC20 token;
        uint256 amount;
        Range intentAmountRange;
        bytes32[] paymentMethods;
        DepositPaymentMethodData[] paymentMethodData;
        Currency[][] currencies;
        address delegate;
        address intentGuardian;
        bool retainOnEmpty;
    }

    function createDeposit(CreateDepositParams calldata params) external;
}
