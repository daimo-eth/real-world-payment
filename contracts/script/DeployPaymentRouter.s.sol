// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../src/PaymentRouter.sol";
import "../src/interfaces/IPeerEscrow.sol";
import "./constants/Constants.s.sol";
import {DEPLOY_SALT_PAYMENT_ROUTER} from "./constants/DeploySalts.sol";

contract DeployPaymentRouter is Script {
    function run() public {
        address usdc = vm.envOr("USDC", BASE_MAINNET_USDC);
        address peerEscrow = vm.envOr("PEER_ESCROW", PEER_ESCROW);
        address treasury = vm.envOr("TREASURY", TREASURY);

        vm.startBroadcast();

        address paymentRouter = CREATE3.deploy(
            DEPLOY_SALT_PAYMENT_ROUTER,
            abi.encodePacked(
                type(PaymentRouter).creationCode,
                abi.encode(usdc, peerEscrow, treasury)
            )
        );
        console.log("PaymentRouter deployed at:", paymentRouter);
        console.log("  usdc:", usdc);
        console.log("  peerEscrow:", peerEscrow);
        console.log("  treasury:", treasury);

        vm.stopBroadcast();
    }

    // Exclude from forge coverage
    function test() public {}
}
