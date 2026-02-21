// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPeerEscrow.sol";

/// @notice Routes USDC received from Daimo into Peer Protocol escrow for fiat
/// offramp. Takes a protocol fee, then deposits the remainder so a Peer LP can
/// fulfill the payment to the recipient via Venmo, CashApp, Zelle, etc.
///
/// Called by Daimo's DepositAddress finalCallData after bridging to Base.
/// Daimo approves USDC to this contract before calling route().
contract PaymentRouter {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    IPeerEscrow public immutable peerEscrow;
    address public immutable treasury;

    uint256 public constant FEE_BPS = 30;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// 1.005 × 10^18 — 50bps premium for Peer LPs
    uint256 public constant TAKER_RATE = 1_005_000_000_000_000_000;

    /// USD fiat currency bytes32, from resolveFiatCurrencyBytes32('USD')
    bytes32 public constant FIAT_USD =
        0xc4ae21aac0c6549d71dd96035b7e0bdb6c79ebdba8891b666115bc976d16a29e;

    uint256 public constant MIN_AMOUNT = 1e6; // $1 USDC (6 decimals)

    constructor(IERC20 _usdc, IPeerEscrow _peerEscrow, address _treasury) {
        usdc = _usdc;
        peerEscrow = _peerEscrow;
        treasury = _treasury;
    }

    /// @notice Route USDC into Peer escrow. Called by Daimo after bridging.
    /// @param paymentMethodHash Peer payment method hash (e.g. venmo, cashapp)
    /// @param payeeDetails keccak256 of recipient handle (e.g. "@john")
    function route(bytes32 paymentMethodHash, bytes32 payeeDetails) external {
        uint256 balance = usdc.balanceOf(address(this));
        require(balance >= MIN_AMOUNT, "below $1 minimum");

        uint256 fee = (balance * FEE_BPS) / BPS_DENOMINATOR;
        uint256 depositAmount = balance - fee;

        usdc.safeTransfer(treasury, fee);
        usdc.forceApprove(address(peerEscrow), depositAmount);

        peerEscrow.createDeposit(_buildDepositParams(
            depositAmount, paymentMethodHash, payeeDetails
        ));
    }

    function _buildDepositParams(
        uint256 amount,
        bytes32 paymentMethodHash,
        bytes32 payeeDetails
    ) internal view returns (IPeerEscrow.CreateDepositParams memory) {
        bytes32[] memory methods = new bytes32[](1);
        methods[0] = paymentMethodHash;

        IPeerEscrow.DepositPaymentMethodData[]
            memory methodData = new IPeerEscrow.DepositPaymentMethodData[](1);
        methodData[0] = IPeerEscrow.DepositPaymentMethodData({
            intentGatingService: address(0),
            payeeDetails: payeeDetails,
            data: ""
        });

        IPeerEscrow.Currency[][] memory currencies =
            new IPeerEscrow.Currency[][](1);
        currencies[0] = new IPeerEscrow.Currency[](1);
        currencies[0][0] = IPeerEscrow.Currency({
            code: FIAT_USD,
            minConversionRate: TAKER_RATE
        });

        return IPeerEscrow.CreateDepositParams({
            token: usdc,
            amount: amount,
            intentAmountRange: IPeerEscrow.Range({min: amount, max: amount}),
            paymentMethods: methods,
            paymentMethodData: methodData,
            currencies: currencies,
            delegate: address(0),
            intentGuardian: address(0),
            retainOnEmpty: false
        });
    }
}
