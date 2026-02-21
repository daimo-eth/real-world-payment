// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {CREATE3Factory} from "../../vendor/create3/CREATE3Factory.sol";

// CREATE3 factory deployed at deterministic address on all chains
CREATE3Factory constant CREATE3 =
    CREATE3Factory(0x37922885311Bc9d18E136e4FE6654409d3F45FFd);

// Base mainnet
uint256 constant BASE_MAINNET = 8453;
address constant BASE_MAINNET_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

// Peer Protocol escrow on Base (from @zkp2p/sdk production)
address constant PEER_ESCROW = 0x2f121CDDCA6d652f35e8B3E560f9760898888888;

// Protocol fee treasury
address constant TREASURY = 0x4E04D236A5aEd4EB7d95E0514c4c8394c690BB58;

// Peer intent gating service on Base (from getGatingServiceAddress(8453, 'production'))
address constant INTENT_GATING_SERVICE = 0x396D31055Db28C0C6f36e8b36f18FE7227248a97;
