// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {PaymentRouter} from "../src/PaymentRouter.sol";
import {IPeerEscrow} from "../src/interfaces/IPeerEscrow.sol";

/// @dev Minimal mock USDC for testing (6 decimals).
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Mock Peer escrow that records the last deposit call.
contract MockPeerEscrow is IPeerEscrow {
    CreateDepositParams internal _lastParams;
    bool public called;

    function createDeposit(
        CreateDepositParams calldata params
    ) external override {
        _lastParams.token = params.token;
        _lastParams.amount = params.amount;
        _lastParams.intentAmountRange = params.intentAmountRange;
        _lastParams.delegate = params.delegate;
        _lastParams.intentGuardian = params.intentGuardian;
        _lastParams.retainOnEmpty = params.retainOnEmpty;

        delete _lastParams.paymentMethods;
        for (uint256 i = 0; i < params.paymentMethods.length; i++) {
            _lastParams.paymentMethods.push(params.paymentMethods[i]);
        }

        delete _lastParams.paymentMethodData;
        for (uint256 i = 0; i < params.paymentMethodData.length; i++) {
            _lastParams.paymentMethodData.push(params.paymentMethodData[i]);
        }

        delete _lastParams.currencies;
        for (uint256 i = 0; i < params.currencies.length; i++) {
            _lastParams.currencies.push();
            for (uint256 j = 0; j < params.currencies[i].length; j++) {
                _lastParams.currencies[i].push(params.currencies[i][j]);
            }
        }

        called = true;
    }

    function getLastAmount() external view returns (uint256) {
        return _lastParams.amount;
    }

    function getLastPaymentMethod() external view returns (bytes32) {
        return _lastParams.paymentMethods[0];
    }

    function getLastPayeeDetails() external view returns (bytes32) {
        return _lastParams.paymentMethodData[0].payeeDetails;
    }

    function getLastCurrencyCode() external view returns (bytes32) {
        return _lastParams.currencies[0][0].code;
    }

    function getLastConversionRate() external view returns (uint256) {
        return _lastParams.currencies[0][0].minConversionRate;
    }

    function getLastDelegate() external view returns (address) {
        return _lastParams.delegate;
    }

    function getLastIntentGuardian() external view returns (address) {
        return _lastParams.intentGuardian;
    }

    function getLastRetainOnEmpty() external view returns (bool) {
        return _lastParams.retainOnEmpty;
    }
}

contract PaymentRouterTest is Test {
    MockUSDC private usdc;
    MockPeerEscrow private escrow;
    PaymentRouter private router;

    address private constant TREASURY =
        0x4E04D236A5aEd4EB7d95E0514c4c8394c690BB58;

    bytes32 private constant VENMO_HASH =
        0x90262a3db0edd0be2369c6b28f9e8511ec0bac7136cefbada0880602f87e7268;
    bytes32 private constant PAYEE = keccak256("@john");

    function setUp() public {
        usdc = new MockUSDC();
        escrow = new MockPeerEscrow();
        router = new PaymentRouter(usdc, escrow, TREASURY);
    }

    // --- route() happy path ---

    function test_route_100USDC() public {
        uint256 amount = 100e6; // $100
        usdc.mint(address(router), amount);

        router.route(VENMO_HASH, PAYEE);

        // 30bps fee = 100 * 30 / 10000 = 0.3 USDC = 300000
        uint256 expectedFee = 300_000;
        uint256 expectedDeposit = amount - expectedFee;

        assertEq(usdc.balanceOf(TREASURY), expectedFee, "treasury fee");
        assertTrue(escrow.called(), "escrow called");
        assertEq(escrow.getLastAmount(), expectedDeposit, "deposit amount");
        assertEq(escrow.getLastPaymentMethod(), VENMO_HASH, "payment method");
        assertEq(escrow.getLastPayeeDetails(), PAYEE, "payee details");
        assertEq(
            escrow.getLastConversionRate(),
            1_005_000_000_000_000_000,
            "taker rate"
        );
        assertEq(escrow.getLastCurrencyCode(), router.FIAT_USD(), "fiat usd");
    }

    function test_route_minimumAmount() public {
        usdc.mint(address(router), 1e6); // exactly $1

        router.route(VENMO_HASH, PAYEE);

        assertTrue(escrow.called(), "escrow called");
        uint256 expectedFee = (1e6 * 30) / 10_000; // 3000
        assertEq(usdc.balanceOf(TREASURY), expectedFee, "treasury fee");
    }

    // --- route() reverts ---

    function test_route_revertsBelow1USD() public {
        usdc.mint(address(router), 999_999); // $0.999999

        vm.expectRevert("below $1 minimum");
        router.route(VENMO_HASH, PAYEE);
    }

    function test_route_revertsZeroBalance() public {
        vm.expectRevert("below $1 minimum");
        router.route(VENMO_HASH, PAYEE);
    }

    // --- fee math ---

    function test_feeMath_variousAmounts() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1e6; // $1
        amounts[1] = 10e6; // $10
        amounts[2] = 1_000e6; // $1,000
        amounts[3] = 100_000e6; // $100,000

        for (uint256 i = 0; i < amounts.length; i++) {
            MockPeerEscrow freshEscrow = new MockPeerEscrow();
            PaymentRouter freshRouter = new PaymentRouter(
                usdc, freshEscrow, TREASURY
            );

            uint256 treasuryBefore = usdc.balanceOf(TREASURY);
            usdc.mint(address(freshRouter), amounts[i]);
            freshRouter.route(VENMO_HASH, PAYEE);

            uint256 fee = usdc.balanceOf(TREASURY) - treasuryBefore;
            uint256 expectedFee = (amounts[i] * 30) / 10_000;
            assertEq(fee, expectedFee, "fee mismatch");

            uint256 deposited = freshEscrow.getLastAmount();
            assertEq(deposited, amounts[i] - expectedFee, "deposit mismatch");
        }
    }

    // --- struct construction ---

    function test_depositParams_singlePaymentMethod() public {
        usdc.mint(address(router), 50e6);
        router.route(VENMO_HASH, PAYEE);

        uint256 deposit = escrow.getLastAmount();
        assertGt(deposit, 0, "deposit > 0");

        assertEq(escrow.getLastDelegate(), address(0), "delegate zero");
        assertEq(escrow.getLastIntentGuardian(), address(0), "guardian zero");
        assertFalse(escrow.getLastRetainOnEmpty(), "retainOnEmpty false");
    }
}
