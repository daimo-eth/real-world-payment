import { NextResponse } from "next/server";
import { getAddress, isAddress } from "viem";
import { z } from "zod";

import { encodeRouteCalldata, PAYMENT_ROUTER } from "@/lib/calldata";
import {
  ALL_PROVIDERS,
  FULFILLMENT_TIMES,
  MIN_USD,
  TOTAL_FEE_BPS,
  expandProvider,
  type Provider,
} from "@/lib/constants";
import { createDeposit, getDepositTokens } from "@/lib/daimo";
import { registerDepositDetails } from "@/lib/peer";

const requestSchema = z.object({
  provider: z.enum(ALL_PROVIDERS as [Provider, ...Provider[]]),
  recipient_handle: z.string().min(1),
  sender_address: z.string().refine(isAddress, "invalid evm address"),
});

export async function POST(req: Request) {
  const body = await req.json().catch(() => null);
  if (!body) {
    return NextResponse.json({ error: "invalid json" }, { status: 400 });
  }

  const parsed = requestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const { provider, recipient_handle, sender_address } = parsed.data;
  const senderAddr = getAddress(sender_address);

  try {
    const processors = expandProvider(provider);

    const registrations = await registerDepositDetails(
      processors,
      recipient_handle
    );

    const calldata = encodeRouteCalldata(provider, registrations);

    const deposit = await createDeposit({
      destinationAddress: PAYMENT_ROUTER,
      calldata,
      refundAddress: senderAddr,
    });

    const tokens = await getDepositTokens(deposit.sessionId, senderAddr);

    return NextResponse.json({
      deposit_address: deposit.depositAddress,
      session_id: deposit.sessionId,
      expires_at: deposit.expiresAt,
      supported_tokens: tokens.map((t) => ({
        token: t.tokenAddress,
        chain_id: t.chainId,
        symbol: t.symbol,
        rate_usd_per_unit: t.rateUsdPerUnit,
        balance: t.balanceUnits,
        min_units: t.minUnits,
        max_units: t.maxUnits,
      })),
      fee_bps: TOTAL_FEE_BPS,
      minimum_usd: MIN_USD,
      estimated_fulfillment: FULFILLMENT_TIMES[provider],
      warning:
        "send stablecoin to deposit_address within 1 hour. " +
        "fiat delivery depends on peer LP availability.",
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
