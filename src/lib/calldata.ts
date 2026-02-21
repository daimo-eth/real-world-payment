import { encodeFunctionData, type Hex } from "viem";

import {
  PAYMENT_ROUTER,
  PROVIDER_HASHES,
  expandProvider,
  type PeerProcessor,
  type Provider,
} from "./constants";

const paymentRouterAbi = [
  {
    inputs: [
      { name: "paymentMethodHashes", type: "bytes32[]" },
      { name: "payeeDetailsList", type: "bytes32[]" },
    ],
    name: "route",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

/** Encode PaymentRouter.route(hashes[], payeeDetails[]) calldata. */
export function encodeRouteCalldata(
  provider: Provider,
  hashedOnchainIds: { processor: PeerProcessor; hashedOnchainId: Hex }[]
): Hex {
  const processors = expandProvider(provider);
  const hashes = processors.map((p) => PROVIDER_HASHES[p]);
  const payeeDetails = hashedOnchainIds.map((h) => h.hashedOnchainId);

  return encodeFunctionData({
    abi: paymentRouterAbi,
    functionName: "route",
    args: [hashes, payeeDetails],
  });
}

export { PAYMENT_ROUTER };
