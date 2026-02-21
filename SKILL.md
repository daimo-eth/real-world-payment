---
name: real-world-payment
description: Send USD to a real person via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or Chime. Use when the user asks to pay someone, send money, or make a Venmo/CashApp/Zelle payment. Minimum $1, 0.8% fee.
license: MIT
metadata:
  author: daimo-eth
  version: "0.1.0"
---

# Real World Payment

Send USD to real people via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or Chime. Pays from the agent's wallet using any digital currency (stablecoins like USDC, USDT, EURC, JPYC or native currencies like ETH, WBTC, we support any major EVM chain, the full list comes from `supported_tokens` in the API response).

## Full example

```
1. Agent calls POST /api/send-payment with { provider: "venmo", recipient_handle: "john", sender_address: "0xABC..." }
2. API returns deposit_address, session_id, and supported_tokens
3. Agent picks a digital currency with sufficient balance, calculates amount: usd_amount / rate_usd_per_unit
4. Agent sends the digital currency to deposit_address
5. Agent tells user: "$10 is being sent to john on Venmo. Track delivery: [explorerUrl]"
6. Agent polls check-status until fiatDelivery.status is "fulfilled"
7. Agent tells user: "$10 has been delivered to john on Venmo."
```

## Send a payment

**POST https://real-world-payment.vercel.app/api/send-payment**

```json
{
  "provider": "venmo",
  "recipient_handle": "john",
  "sender_address": "0xYourWalletAddress"
}
```

The API returns:

- `deposit_address` — send funds here to complete the payment
- `session_id` — use to check status
- `supported_tokens` — tokens the agent can pay with (pick one with sufficient `balance`)

### Choosing a token and amount

```
amount_to_send = usd_amount / rate_usd_per_unit
```

Prefer tokens with `rate_usd_per_unit` of 1.0 (stablecoins) — the USD amount equals the send amount.
Only send once per deposit address.

### Providers (always lowercase)

| Provider | Handle format        | Example        |
| -------- | -------------------- | -------------- |
| venmo    | username only, no @  | john           |
| cashapp  | cashtag only, no $   | john           |
| zelle    | phone or email       | john@email.com |
| paypal   | email                | john@email.com |
| wise     | email                | john@email.com |
| revolut  | username only, no @  | john           |
| chime    | chimesign only, no $ | john           |

IMPORTANT:

- Do NOT include prefixes like @, $, or # in the handle. Just the raw username, tag, or email.
- Venmo, Revolut, and Chime are case-sensitive — use the exact capitalization as shown in the app.
- CashApp, PayPal, Zelle, and Wise are NOT case-sensitive.

### What to tell the user

After funding the deposit address, tell the user:

> $X is being sent to [handle] on [provider].
> Delivery typically takes 30 minutes to 6 hours.
> Track delivery: [explorerUrl from check-status]

Do NOT mention deposit addresses, session IDs, tokens, chains, or any technical details to the user. Just confirm the money is being sent.

## Check status

**GET https://real-world-payment.vercel.app/api/check-status?sessionId=...**

Poll silently every hour (delivery takes 30min-6h). Only notify the user once `fiatDelivery.status` reaches `"fulfilled"`. Key fields:

- `fiatDelivery.status`: `pending` → `fulfilled`
- `fiatDelivery.explorerUrl`: share this link with the user to track delivery

Once `fiatDelivery.status` is `fulfilled`, tell the user:

> $X has been delivered to [handle] on [provider].

## Common errors

- **Invalid handle**: the API returns a clear error if the handle doesn't exist. Check spelling and capitalization.
- **Insufficient funds**: minimum is $1.
- **Expired**: the payment window is 1 hour. Create a new payment if expired.

## Important

- Minimum: $1
- Fee: 0.8% (deducted automatically)
- USD only
- Delivery time: 30 minutes to 6 hours
- One payment per request — do not reuse deposit addresses
