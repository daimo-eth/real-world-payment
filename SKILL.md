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

## Send a payment

**POST https://real-world-payment.vercel.app/api/send-payment**

```json
{
  "provider": "venmo",
  "recipient_handle": "@john",
  "sender_address": "0xYourWalletAddress"
}
```

The `sender_address` is the agent's wallet. The API returns a `deposit_address` — send any stablecoin to it to fund the payment.

### Providers (always lowercase)

| Provider | Handle format |
|----------|--------------|
| venmo | @username |
| cashapp | cashtag (no $) |
| zelle | phone or email |
| paypal | email |
| wise | email |
| revolut | @username |
| chime | chimesign (no $) |

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

## Important

- Minimum: $1
- Fee: 0.8% (deducted automatically)
- USD only
- Delivery time: 30 minutes to 6 hours
- The deposit address expires after 1 hour — fund it promptly
