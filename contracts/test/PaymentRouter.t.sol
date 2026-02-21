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

    function getNumMethods() external view returns (uint256) {
        return _lastParams.paymentMethods.length;
    }

    function getPaymentMethod(uint256 i) external view returns (bytes32) {
        return _lastParams.paymentMethods[i];
    }

    function getPayeeDetails(uint256 i) external view returns (bytes32) {
        return _lastParams.paymentMethodData[i].payeeDetails;
    }

    function getIntentGatingService(uint256 i) external view returns (address) {
        return _lastParams.paymentMethodData[i].intentGatingService;
    }

    function getCurrencyCode(uint256 i) external view returns (bytes32) {
        return _lastParams.currencies[i][0].code;
    }

    function getConversionRate(uint256 i) external view returns (uint256) {
        return _lastParams.currencies[i][0].minConversionRate;
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
    address private constant GATING_SERVICE =
        0x396D31055Db28C0C6f36e8b36f18FE7227248a97;

    bytes32 private constant VENMO_HASH =
        0x90262a3db0edd0be2369c6b28f9e8511ec0bac7136cefbada0880602f87e7268;
    bytes32 private constant PAYEE = keccak256("@john");

    // Zelle variants
    bytes32 private constant ZELLE_CITI =
        0x817260692b75e93c7fbc51c71637d4075a975e221e1ebc1abeddfabd731fd90d;
    bytes32 private constant ZELLE_CHASE =
        0x6aa1d1401e79ad0549dced8b1b96fb72c41cd02b32a7d9ea1fed54ba9e17152e;
    bytes32 private constant ZELLE_BOFA =
        0x4bc42b322a3ad413b91b2fde30549ca70d6ee900eded1681de91aaf32ffd7ab5;

    function setUp() public {
        usdc = new MockUSDC();
        escrow = new MockPeerEscrow();
        router = new PaymentRouter(usdc, escrow, TREASURY, GATING_SERVICE);
    }

    function _singleMethod()
        internal pure returns (bytes32[] memory m, bytes32[] memory p)
    {
        m = new bytes32[](1);
        m[0] = VENMO_HASH;
        p = new bytes32[](1);
        p[0] = PAYEE;
    }

    function _mintApproveRoute(
        PaymentRouter r,
        uint256 amount
    ) internal {
        (bytes32[] memory m, bytes32[] memory p) = _singleMethod();
        usdc.mint(address(this), amount);
        usdc.approve(address(r), amount);
        r.route(m, p);
    }

    // --- single method ---

    function test_route_100USDC() public {
        uint256 amount = 100e6;
        _mintApproveRoute(router, amount);

        uint256 expectedFee = 300_000;
        uint256 expectedDeposit = amount - expectedFee;

        assertEq(usdc.balanceOf(TREASURY), expectedFee, "treasury fee");
        assertTrue(escrow.called(), "escrow called");
        assertEq(escrow.getLastAmount(), expectedDeposit, "deposit amount");
        assertEq(escrow.getNumMethods(), 1, "num methods");
        assertEq(escrow.getPaymentMethod(0), VENMO_HASH, "payment method");
        assertEq(escrow.getPayeeDetails(0), PAYEE, "payee details");
        assertEq(
            escrow.getConversionRate(0),
            1_005_000_000_000_000_000,
            "taker rate"
        );
        assertEq(escrow.getCurrencyCode(0), router.FIAT_USD(), "fiat usd");
        assertEq(
            escrow.getIntentGatingService(0), GATING_SERVICE, "gating service"
        );
    }

    function test_route_minimumAmount() public {
        _mintApproveRoute(router, 1e6);

        assertTrue(escrow.called(), "escrow called");
        uint256 expectedFee = (1e6 * 30) / 10_000;
        assertEq(usdc.balanceOf(TREASURY), expectedFee, "treasury fee");
    }

    // --- batched zelle (3 methods) ---

    function test_route_batchedZelle() public {
        bytes32[] memory methods = new bytes32[](3);
        methods[0] = ZELLE_CITI;
        methods[1] = ZELLE_CHASE;
        methods[2] = ZELLE_BOFA;

        bytes32[] memory payees = new bytes32[](3);
        payees[0] = keccak256("zelle-citi-id");
        payees[1] = keccak256("zelle-chase-id");
        payees[2] = keccak256("zelle-bofa-id");

        uint256 amount = 50e6;
        usdc.mint(address(this), amount);
        usdc.approve(address(router), amount);
        router.route(methods, payees);

        assertTrue(escrow.called(), "escrow called");
        assertEq(escrow.getNumMethods(), 3, "3 zelle methods");
        assertEq(escrow.getPaymentMethod(0), ZELLE_CITI, "citi");
        assertEq(escrow.getPaymentMethod(1), ZELLE_CHASE, "chase");
        assertEq(escrow.getPaymentMethod(2), ZELLE_BOFA, "bofa");

        for (uint256 i = 0; i < 3; i++) {
            assertEq(
                escrow.getIntentGatingService(i),
                GATING_SERVICE,
                "gating per method"
            );
            assertEq(
                escrow.getCurrencyCode(i), router.FIAT_USD(), "usd per method"
            );
        }
    }

    // --- event emission ---

    function test_route_emitsPaymentRouted() public {
        uint256 amount = 100e6;
        uint256 expectedFee = (amount * 30) / 10_000;
        uint256 expectedDeposit = amount - expectedFee;

        (bytes32[] memory m, bytes32[] memory p) = _singleMethod();
        usdc.mint(address(this), amount);
        usdc.approve(address(router), amount);

        vm.expectEmit(false, false, false, true);
        emit PaymentRouter.PaymentRouted(1, expectedDeposit, expectedFee);
        router.route(m, p);
    }

    // --- reverts ---

    function test_route_revertsBelow1USD() public {
        (bytes32[] memory m, bytes32[] memory p) = _singleMethod();
        usdc.mint(address(this), 999_999);
        usdc.approve(address(router), 999_999);

        vm.expectRevert("below $1 minimum");
        router.route(m, p);
    }

    function test_route_revertsNoAllowance() public {
        (bytes32[] memory m, bytes32[] memory p) = _singleMethod();

        vm.expectRevert("below $1 minimum");
        router.route(m, p);
    }

    function test_route_revertsLengthMismatch() public {
        bytes32[] memory m = new bytes32[](2);
        m[0] = VENMO_HASH;
        m[1] = ZELLE_CITI;
        bytes32[] memory p = new bytes32[](1);
        p[0] = PAYEE;

        usdc.mint(address(this), 10e6);
        usdc.approve(address(router), 10e6);

        vm.expectRevert("length mismatch");
        router.route(m, p);
    }

    function test_route_revertsEmptyArrays() public {
        bytes32[] memory m = new bytes32[](0);
        bytes32[] memory p = new bytes32[](0);

        usdc.mint(address(this), 10e6);
        usdc.approve(address(router), 10e6);

        vm.expectRevert("length mismatch");
        router.route(m, p);
    }

    // --- fee math ---

    function test_feeMath_variousAmounts() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1e6;
        amounts[1] = 10e6;
        amounts[2] = 1_000e6;
        amounts[3] = 100_000e6;

        for (uint256 i = 0; i < amounts.length; i++) {
            MockPeerEscrow freshEscrow = new MockPeerEscrow();
            PaymentRouter freshRouter = new PaymentRouter(
                usdc, freshEscrow, TREASURY, GATING_SERVICE
            );

            uint256 treasuryBefore = usdc.balanceOf(TREASURY);
            (bytes32[] memory m, bytes32[] memory p) = _singleMethod();
            usdc.mint(address(this), amounts[i]);
            usdc.approve(address(freshRouter), amounts[i]);
            freshRouter.route(m, p);

            uint256 fee = usdc.balanceOf(TREASURY) - treasuryBefore;
            uint256 expectedFee = (amounts[i] * 30) / 10_000;
            assertEq(fee, expectedFee, "fee mismatch");

            uint256 deposited = freshEscrow.getLastAmount();
            assertEq(deposited, amounts[i] - expectedFee, "deposit mismatch");
        }
    }
}
