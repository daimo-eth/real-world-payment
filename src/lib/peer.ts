import type { Hex } from "viem";

import type { PeerProcessor } from "./constants";

const PEER_API_BASE = "https://api.zkp2p.xyz";
const PEER_INDEXER = "https://indexer.zkp2p.xyz/v1/graphql";

/** Processor-specific field names for deposit data. */
const DEPOSIT_DATA_FIELD: Record<PeerProcessor, string> = {
  venmo: "venmoUsername",
  cashapp: "cashtag",
  chime: "chimesign",
  revolut: "revolutUsername",
  wise: "wisetag",
  "zelle-citi": "zelleEmail",
  "zelle-chase": "zelleEmail",
  "zelle-bofa": "zelleEmail",
  paypal: "paypalEmail",
  monzo: "monzoMeUsername",
  n26: "iban",
  alipay: "alipayId",
  mercadopago: "cvu",
};

export interface DepositRegistration {
  processor: PeerProcessor;
  hashedOnchainId: Hex;
}

/** Register deposit details with Peer's off-chain API for each processor.
 *  Returns hashedOnchainId per processor (used as payeeDetails on-chain). */
export async function registerDepositDetails(
  processors: PeerProcessor[],
  recipientHandle: string
): Promise<DepositRegistration[]> {
  const apiKey = process.env.PEER_API_KEY;
  if (!apiKey) throw new Error("PEER_API_KEY env var required");

  const results = await Promise.all(
    processors.map(async (processor) => {
      const field = DEPOSIT_DATA_FIELD[processor];

      const res = await fetch(`${PEER_API_BASE}/v1/makers/create`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
        },
        body: JSON.stringify({
          processorName: processor,
          depositData: { [field]: recipientHandle, telegramUsername: "" },
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        throw new Error(
          `peer api failed for ${processor} (${res.status}): ${text}`
        );
      }

      const data = await res.json();
      if (!data.success || !data.responseObject?.hashedOnchainId) {
        throw new Error(
          `peer api returned no hashedOnchainId for ${processor}: ${JSON.stringify(data)}`
        );
      }

      return {
        processor,
        hashedOnchainId: data.responseObject.hashedOnchainId as Hex,
      };
    })
  );

  return results;
}

export interface FiatDeliveryStatus {
  status: "pending" | "fulfilled";
  depositId: string;
  explorerUrl: string;
}

const DEPOSIT_QUERY = `
  query DepositStatus($id: String!) {
    Deposit_by_pk(id: $id) {
      depositId
      fulfilledIntents
    }
  }
`;

/** Query Peer indexer for fiat delivery status. */
export async function getFiatDeliveryStatus(
  escrowAddress: string,
  depositId: string
): Promise<FiatDeliveryStatus | null> {
  const compositeId = `${escrowAddress.toLowerCase()}_${depositId}`;

  const res = await fetch(PEER_INDEXER, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      query: DEPOSIT_QUERY,
      variables: { id: compositeId },
    }),
  });

  if (!res.ok) return null;

  const data = await res.json();
  const deposit = data.data?.Deposit_by_pk;
  if (!deposit) return null;

  const fulfilled = (deposit.fulfilledIntents ?? 0) > 0;

  return {
    status: fulfilled ? "fulfilled" : "pending",
    depositId: deposit.depositId,
    explorerUrl: `https://peerlytics.xyz/explorer/deposit/${compositeId}`,
  };
}
