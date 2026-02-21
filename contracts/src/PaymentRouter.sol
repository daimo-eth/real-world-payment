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

    event PaymentRouted(
        uint256 numMethods,
        uint256 depositAmount,
        uint256 fee
    );

    IERC20 public immutable usdc;
    IPeerEscrow public immutable peerEscrow;
    address public immutable treasury;
    address public immutable intentGatingService;

    uint256 public constant FEE_BPS = 30;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// 1.005 × 10^18 — 50bps premium for Peer LPs
    uint256 public constant TAKER_RATE = 1_005_000_000_000_000_000;

    /// USD fiat currency bytes32, from resolveFiatCurrencyBytes32('USD')
    bytes32 public constant FIAT_USD =
        0xc4ae21aac0c6549d71dd96035b7e0bdb6c79ebdba8891b666115bc976d16a29e;

    uint256 public constant MIN_AMOUNT = 1e6; // $1 USDC (6 decimals)

    constructor(
        IERC20 _usdc,
        IPeerEscrow _peerEscrow,
        address _treasury,
        address _intentGatingService
    ) {
        usdc = _usdc;
        peerEscrow = _peerEscrow;
        treasury = _treasury;
        intentGatingService = _intentGatingService;
    }

    /// @notice Route USDC into Peer escrow with one or more payment methods.
    /// @dev Caller must approve this contract to spend USDC before calling.
    ///      Pulls the full approved amount from the caller.
    ///      Supports batching (e.g. 3 zelle variants in one deposit).
    /// @param paymentMethodHashes Peer payment method hashes
    /// @param payeeDetailsList hashedOnchainId per method from Peer's API
    function route(
        bytes32[] calldata paymentMethodHashes,
        bytes32[] calldata payeeDetailsList
    ) external {
        uint256 n = paymentMethodHashes.length;
        require(n > 0 && n == payeeDetailsList.length, "length mismatch");

        uint256 amount = usdc.allowance(msg.sender, address(this));
        require(amount >= MIN_AMOUNT, "below $1 minimum");
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = (amount * FEE_BPS) / BPS_DENOMINATOR;
        uint256 depositAmount = amount - fee;

        usdc.safeTransfer(treasury, fee);
        usdc.forceApprove(address(peerEscrow), depositAmount);

        peerEscrow.createDeposit(_buildDepositParams(
            depositAmount, paymentMethodHashes, payeeDetailsList
        ));

        emit PaymentRouted(n, depositAmount, fee);
    }

    function _buildDepositParams(
        uint256 amount,
        bytes32[] calldata paymentMethodHashes,
        bytes32[] calldata payeeDetailsList
    ) internal view returns (IPeerEscrow.CreateDepositParams memory) {
        uint256 n = paymentMethodHashes.length;

        IPeerEscrow.DepositPaymentMethodData[]
            memory methodData = new IPeerEscrow.DepositPaymentMethodData[](n);
        IPeerEscrow.Currency[][] memory currencies =
            new IPeerEscrow.Currency[][](n);

        for (uint256 i = 0; i < n; ++i) {
            methodData[i] = IPeerEscrow.DepositPaymentMethodData({
                intentGatingService: intentGatingService,
                payeeDetails: payeeDetailsList[i],
                data: ""
            });
            currencies[i] = new IPeerEscrow.Currency[](1);
            currencies[i][0] = IPeerEscrow.Currency({
                code: FIAT_USD,
                minConversionRate: TAKER_RATE
            });
        }

        return IPeerEscrow.CreateDepositParams({
            token: usdc,
            amount: amount,
            intentAmountRange: IPeerEscrow.Range({min: amount, max: amount}),
            paymentMethods: paymentMethodHashes,
            paymentMethodData: methodData,
            currencies: currencies,
            delegate: address(0),
            intentGuardian: address(0),
            retainOnEmpty: false
        });
    }
}
