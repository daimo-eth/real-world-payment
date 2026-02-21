import { NextResponse } from "next/server";
import { decodeEventLog, type Hex } from "viem";

import { PEER_ESCROW } from "@/lib/constants";
import { getDepositStatus } from "@/lib/daimo";
import { getFiatDeliveryStatus } from "@/lib/peer";

const depositReceivedAbi = [
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "depositId", type: "uint256" },
      { indexed: true, name: "depositor", type: "address" },
      { indexed: true, name: "token", type: "address" },
      { indexed: false, name: "amount", type: "uint256" },
      {
        indexed: false,
        name: "intentAmountRange",
        type: "tuple",
        components: [
          { name: "min", type: "uint256" },
          { name: "max", type: "uint256" },
        ],
      },
      { indexed: false, name: "delegate", type: "address" },
      { indexed: false, name: "intentGuardian", type: "address" },
    ],
    name: "DepositReceived",
    type: "event",
  },
] as const;

const DAIMO_STATUS_MAP: Record<string, string> = {
  pending: "waiting",
  processing: "processing",
  completed: "completed",
  bounced: "bounced",
  expired: "expired",
};

async function parsePeerDepositId(txHash: string): Promise<string | null> {
  const rpcUrl = process.env.BASE_RPC_URL;
  if (!rpcUrl) return null;

  try {
    const res = await fetch(rpcUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "eth_getTransactionReceipt",
        params: [txHash],
        id: 1,
      }),
    });

    const data = await res.json();
    const logs = data.result?.logs ?? [];
    const escrowLower = PEER_ESCROW.toLowerCase();

    for (const log of logs) {
      if (log.address.toLowerCase() !== escrowLower) continue;
      try {
        const decoded = decodeEventLog({
          abi: depositReceivedAbi,
          data: log.data as Hex,
          topics: log.topics as [Hex, ...Hex[]],
        });
        if (decoded.eventName === "DepositReceived") {
          return decoded.args.depositId.toString();
        }
      } catch {
        continue;
      }
    }
  } catch {
    return null;
  }
  return null;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const sessionId = searchParams.get("sessionId");

  if (!sessionId || !/^[0-9a-f]{32}$/.test(sessionId)) {
    return NextResponse.json(
      { error: "sessionId required (32-char hex)" },
      { status: 400 }
    );
  }

  try {
    const raw = await getDepositStatus(sessionId);
    const destTxHash = raw.destination?.txHash ?? null;

    const onchainPayment = {
      status: DAIMO_STATUS_MAP[raw.status] ?? raw.status,
      depositAddress: raw.depositAddress,
      expiresAt: raw.expiresAt,
      source: raw.source
        ? {
            chainId: raw.source.chainId,
            token: raw.source.tokenSymbol,
            amount: raw.source.amountUnits,
            usdValue: raw.source.usdValue,
          }
        : null,
      destination: destTxHash
        ? {
            txHash: destTxHash,
            token: raw.destination!.tokenSymbol,
            amount: raw.destination!.amountUnits,
          }
        : null,
    };

    let fiatDelivery = null;
    if (destTxHash) {
      const depositId = await parsePeerDepositId(destTxHash);
      if (depositId) {
        fiatDelivery = await getFiatDeliveryStatus(PEER_ESCROW, depositId);
      }
    }

    return NextResponse.json({
      sessionId: raw.sessionId,
      onchainPayment,
      fiatDelivery,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
