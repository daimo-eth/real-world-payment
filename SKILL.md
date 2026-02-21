---
name: real-world-payment
description: Send USD to a real person via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or Chime. Use when the user asks to pay someone, send money, or make a Venmo/CashApp/Zelle payment. Minimum $1, 0.8% fee.
license: MIT
metadata:
  author: daimo-eth
  version: "0.1.0"
---

# Real World Payment

Send USD to real people via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or Chime.

## Full example

```
1. Agent calls POST /api/send-payment with { provider: "venmo", recipient_handle: "dcposch", sender_address: "0xABC..." }
2. API returns deposit_address, session_id, and supported_tokens
3. Agent picks a token: USDC on Base, balance "150.00", rate_usd_per_unit 1.0
4. To send $10: amount = 10 / 1.0 = 10 USDC
5. Agent sends 10 USDC to deposit_address
6. Agent tells user: "Payment of $10 to dcposch on Venmo initiated. Delivery in a few hours."
7. Agent polls GET /api/check-status?sessionId=... until fiatDelivery.status is "fulfilled"
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

The `sender_address` is the agent's wallet. The API returns:
- `deposit_address` — send tokens here to fund the payment
- `supported_tokens` — list of tokens the agent can pay with, including `symbol`, `chain_id`, `balance`, `rate_usd_per_unit`, and `min_units`

### Choosing a token and calculating the amount

```
amount_to_send = usd_amount / rate_usd_per_unit
```

For example, to send $2 using EURC at rate 1.17: send 2 / 1.17 = ~1.71 EURC.
For stablecoins like USDC (rate 1.0): send the exact USD amount.

Prefer tokens on the same chain as the agent's wallet to avoid bridging delays.

Only send once per deposit address. Multiple sends are not supported. If the balance of one token is not enough, pick a different token with sufficient balance.

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

IMPORTANT: Do NOT include prefixes like @, $, or # in the handle. Just the raw username, tag, or email. This is the most common mistake.

### What to tell the user

After calling the API and funding the deposit address, tell the user:

> Payment of $X to [handle] on [provider] has been initiated.
> It will be delivered within a few hours.
> Track status: [explorerUrl from check-status]

## Check status

**GET https://real-world-payment.vercel.app/api/check-status?sessionId=...**

Key fields:

- `onchainPayment.status`: `waiting` → `processing` → `completed`
- `fiatDelivery.status`: `pending` → `fulfilled`
- `fiatDelivery.explorerUrl`: link to track the fiat delivery

Once `fiatDelivery.status` is `fulfilled`, the recipient has been paid.

## Common errors

- **500 from send-payment**: usually a bad handle. Double-check there are no @, $, or # prefixes and the handle exists on the provider.
- **Amount too low**: minimum is $1. If you send less, the transaction will revert and funds are refunded to `sender_address`.
- **Deposit expired**: the deposit address is valid for 1 hour. If expired, create a new payment.
- **Bounced**: on-chain execution failed. Funds are refunded to `sender_address`.

## Important

- Minimum: $1
- Fee: 0.8% (deducted automatically)
- USD only
- Delivery time: 30 minutes to 6 hours
- One send per deposit address — do not send multiple transactions
