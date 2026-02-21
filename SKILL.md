---
name: real-world-payment
description: Send USD to a real person via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or other providers. Returns a deposit address — send any stablecoin from any chain to complete the payment. 80bps fee (30bps protocol + 50bps market maker). Minimum $1. Use when the user asks to pay someone in fiat, send money to a real person, or make a Venmo/CashApp/Zelle payment.
---

# Real World Payment

Send USD to real people via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, Monzo, N26, Alipay, MercadoPago, or Chime. Powered by Daimo + Peer Protocol (ZKP2P).

## How it works

1. You call the API with a provider, recipient handle, and agent wallet address
2. The API returns a deposit address and the agent's token balances
3. The agent sends any supported stablecoin (any chain) to the deposit address
4. Daimo bridges to USDC on Base and executes the PaymentRouter contract
5. The contract takes a 30bps fee and deposits into Peer Protocol escrow
6. A market maker sends fiat USD to the recipient and proves it with a ZK proof
7. The escrow releases USDC to the market maker

## API base URL

```
https://real-world-payment.vercel.app
```

## Send a payment

**POST /api/send-payment**

```json
{
  "provider": "venmo",
  "recipient_handle": "@john",
  "sender_address": "0xYourWalletAddress"
}
```

### Providers

| Provider | Handle format | Fulfillment time |
|----------|--------------|------------------|
| venmo | @username | 30min - 2 hours |
| cashapp | $cashtag | 30min - 2 hours |
| zelle-chase | phone or email | 1 - 4 hours |
| zelle-citi | phone or email | 1 - 4 hours |
| zelle-bofa | phone or email | 1 - 4 hours |
| paypal | email | 1 - 4 hours |
| wise | email | 1 - 8 hours |
| revolut | @username | 1 - 4 hours |
| chime | $chimesign | 30min - 2 hours |
| monzo | email or phone | 1 - 4 hours |
| n26 | email | 1 - 4 hours |
| alipay | phone or email | 1 - 4 hours |
| mercadopago | phone or email | 1 - 4 hours |

### Response

```json
{
  "deposit_address": "0x...",
  "session_id": "abc123...",
  "expires_at": 1700000000,
  "supported_tokens": [
    {
      "token": "0x...",
      "chain_id": 8453,
      "symbol": "USDC",
      "rate_usd_per_unit": 1.0,
      "balance": "150.00",
      "min_units": "1.00",
      "max_units": "10000.00"
    }
  ],
  "fee_bps": 80,
  "minimum_usd": 1.0,
  "estimated_fulfillment": "30min - 2 hours",
  "warning": "send stablecoin to deposit_address within 1 hour. fiat delivery depends on peer LP availability."
}
```

After receiving the response, send the desired amount of any listed token to `deposit_address`. The deposit address expires after 1 hour.

## Check payment status

**GET /api/check-status?sessionId=abc123...**

Returns the current session status: `pending`, `processing`, `completed`, or `bounced`.

Poll every 30-60 seconds after sending funds. Settlement typically takes 10-30 minutes for the on-chain portion, plus the provider-specific fulfillment time for fiat delivery.

## Fees

- Protocol fee: 30bps (0.3%) to treasury
- Market maker incentive: 50bps (0.5%) to Peer LP
- Total all-in: 80bps (0.8%)
- Minimum payment: $1 USD

## When NOT to use

- For crypto-to-crypto transfers (use a DEX or bridge instead)
- For amounts under $1
- When the recipient doesn't have the specified payment provider
- For non-USD currencies (USD only)

## Failure modes

- **Session expired**: Deposit address is valid for 1 hour. Create a new payment if expired.
- **Bounced**: On-chain execution failed. Funds are refunded to `sender_address`.
- **No LP liquidity**: If no Peer market maker fills the order, the escrow may time out. Check Peer Protocol docs for escrow timeout behavior.
