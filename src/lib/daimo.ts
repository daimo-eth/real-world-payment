import type { Address, Hex } from "viem";

import { BASE_CHAIN_ID, DAIMO_API_BASE, USDC_BASE } from "./constants";

const apiKey = process.env.DAIMO_API_KEY ?? "pay-demo";

function headers(): Record<string, string> {
  return { "Api-Key": apiKey, "Content-Type": "application/json" };
}

export interface DepositResponse {
  depositAddress: string;
  sessionId: string;
  expiresAt: number;
}

/** Create a Daimo deposit session. Returns deposit address + session ID. */
export async function createDeposit(args: {
  destinationAddress: Address;
  calldata: Hex;
  refundAddress: Address;
}): Promise<DepositResponse> {
  const body = {
    destination: {
      destinationAddress: args.destinationAddress,
      chainId: BASE_CHAIN_ID,
      tokenAddress: USDC_BASE,
      calldata: args.calldata,
    },
    refundAddress: args.refundAddress,
    display: {
      paymentOptions: ["AllWallets", "AllExchanges", "AllAddresses"],
    },
  };

  const res = await fetch(`${DAIMO_API_BASE}/deposit`, {
    method: "POST",
    headers: headers(),
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`daimo deposit failed (${res.status}): ${text}`);
  }

  return res.json();
}

export interface TokenOption {
  chainId: number;
  tokenAddress: string;
  symbol: string;
  decimals: number;
  rateUsdPerUnit: number;
  minUnits: string;
  maxUnits: string;
  balanceUnits: string;
  balanceUsd: number;
}

/** Fetch supported tokens + balances for a wallet and session. */
export async function getDepositTokens(
  sessionId: string,
  walletAddress: Address
): Promise<TokenOption[]> {
  const params = new URLSearchParams({ sessionId, walletAddress });
  const res = await fetch(`${DAIMO_API_BASE}/deposit/tokens?${params}`, {
    headers: headers(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`daimo tokens failed (${res.status}): ${text}`);
  }

  const data = await res.json();
  return (data.tokens ?? []).filter(
    (t: TokenOption) => Number(t.balanceUnits) > 0
  );
}

export interface DepositStatus {
  sessionId: string;
  status: string;
  depositAddress: string;
  expiresAt: number;
}

/** Poll session status. */
export async function getDepositStatus(
  sessionId: string
): Promise<DepositStatus> {
  const params = new URLSearchParams({ sessionId });
  const res = await fetch(`${DAIMO_API_BASE}/deposit/status?${params}`, {
    headers: headers(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`daimo status failed (${res.status}): ${text}`);
  }

  return res.json();
}
