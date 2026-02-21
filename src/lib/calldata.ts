import { encodeFunctionData, keccak256, toHex, type Hex } from "viem";

import {
  FIAT_USD,
  PAYMENT_ROUTER,
  PROVIDER_HASHES,
  TAKER_RATE,
  type Provider,
} from "./constants";

const paymentRouterAbi = [
  {
    inputs: [
      { name: "paymentMethodHash", type: "bytes32" },
      { name: "payeeDetails", type: "bytes32" },
    ],
    name: "route",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

/** Hash a recipient handle (e.g. "@john", "john@email.com") into bytes32 for Peer payeeDetails. */
export function hashRecipientHandle(handle: string): Hex {
  return keccak256(toHex(handle));
}

/** Encode PaymentRouter.route(paymentMethodHash, payeeDetails) calldata. */
export function encodeRouteCalldata(
  provider: Provider,
  recipientHandle: string
): Hex {
  const paymentMethodHash = PROVIDER_HASHES[provider];
  const payeeDetails = hashRecipientHandle(recipientHandle);

  return encodeFunctionData({
    abi: paymentRouterAbi,
    functionName: "route",
    args: [paymentMethodHash, payeeDetails],
  });
}

export { PAYMENT_ROUTER };
