import type { Address, Hex } from "viem";

export const USDC_BASE: Address = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
export const BASE_CHAIN_ID = 8453;
export const PEER_ESCROW: Address =
  "0x2f121CDDCA6d652f35e8B3E560f9760898888888";

export const PAYMENT_ROUTER: Address =
  "0x0A944Ed9Dc3beA24A97b9B0fDF6E129baa50f88E";

export const PROTOCOL_FEE_BPS = 30;
export const TAKER_FEE_BPS = 50;
export const TOTAL_FEE_BPS = 80;
export const MIN_USD = 1.0;

// 1.005 × 10^18 — 50bps premium for Peer LPs
export const TAKER_RATE = BigInt("1005000000000000000");
// USD fiat currency bytes32 from Peer SDK
export const FIAT_USD: Hex =
  "0xc4ae21aac0c6549d71dd96035b7e0bdb6c79ebdba8891b666115bc976d16a29e";

/** User-facing provider names (USD only). "zelle" expands to 3 Peer methods. */
export type Provider =
  | "venmo"
  | "cashapp"
  | "zelle"
  | "paypal"
  | "wise"
  | "revolut"
  | "chime";

/** Internal Peer processor keys — used for API calls and hash lookups. */
export type PeerProcessor =
  | "venmo"
  | "cashapp"
  | "zelle-citi"
  | "zelle-chase"
  | "zelle-bofa"
  | "paypal"
  | "wise"
  | "revolut"
  | "chime"
  | "monzo"
  | "n26"
  | "alipay"
  | "mercadopago";

export const PROVIDER_HASHES: Record<PeerProcessor, Hex> = {
  venmo: "0x90262a3db0edd0be2369c6b28f9e8511ec0bac7136cefbada0880602f87e7268",
  revolut: "0x617f88ab82b5c1b014c539f7e75121427f0bb50a4c58b187a238531e7d58605d",
  cashapp: "0x10940ee67cfb3c6c064569ec92c0ee934cd7afa18dd2ca2d6a2254fcb009c17d",
  wise: "0x554a007c2217df766b977723b276671aee5ebb4adaea0edb6433c88b3e61dac5",
  mercadopago:
    "0xa5418819c024239299ea32e09defae8ec412c03e58f5c75f1b2fe84c857f5483",
  "zelle-citi":
    "0x817260692b75e93c7fbc51c71637d4075a975e221e1ebc1abeddfabd731fd90d",
  "zelle-chase":
    "0x6aa1d1401e79ad0549dced8b1b96fb72c41cd02b32a7d9ea1fed54ba9e17152e",
  "zelle-bofa":
    "0x4bc42b322a3ad413b91b2fde30549ca70d6ee900eded1681de91aaf32ffd7ab5",
  paypal: "0x3ccc3d4d5e769b1f82dc4988485551dc0cd3c7a3926d7d8a4dde91507199490f",
  monzo: "0x62c7ed738ad3e7618111348af32691b5767777fbaf46a2d8943237625552645c",
  n26: "0xd9ff4fd6b39a3e3dd43c41d05662a5547de4a878bc97a65bcb352ade493cdc6b",
  alipay: "0xcac9daea62d7b89d75ac73af4ee14dcf25721012ae82b568c2ea5c808eaa04ff",
  chime: "0x5908bb0c9b87763ac6171d4104847667e7f02b4c47b574fe890c1f439ed128bb",
};

/** Map user-facing provider to Peer processor key(s). Zelle expands to 3. */
export function expandProvider(provider: Provider): PeerProcessor[] {
  if (provider === "zelle") {
    return ["zelle-citi", "zelle-chase", "zelle-bofa"];
  }
  return [provider];
}

export const FULFILLMENT_TIMES: Record<Provider, string> = {
  venmo: "30min - 6 hours",
  cashapp: "30min - 6 hours",
  zelle: "30min - 6 hours",
  paypal: "30min - 6 hours",
  wise: "30min - 6 hours",
  revolut: "30min - 6 hours",
  chime: "30min - 6 hours",
};

export const ALL_PROVIDERS: Provider[] = [
  "venmo",
  "cashapp",
  "zelle",
  "paypal",
  "wise",
  "revolut",
  "chime",
];

export const DAIMO_API_BASE = "https://daimo.com/api";
