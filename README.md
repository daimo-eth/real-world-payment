# Real World Payment

Send USD to real people via Venmo, CashApp, Zelle, PayPal, Wise, Revolut, or Chime. Powered by [Daimo](https://daimo.com) + [Peer Protocol](https://peer.com) (ZKP2P).

An agent skill that any AI agent can install and use to make fiat payments from crypto.

## Install as agent skill

```bash
npx skills add daimo-eth/real-world-payment
```

## API

### POST /api/send-payment

```bash
curl -X POST https://real-world-payment.vercel.app/api/send-payment \
  -H "Content-Type: application/json" \
  -d '{"provider":"venmo","recipient_handle":"@john","sender_address":"0x..."}'
```

Returns a deposit address. Send any stablecoin from any chain to complete the payment.

### GET /api/check-status?sessionId=...

Returns two status fields:

- **onchainPayment.status**: `waiting` → `processing` → `completed`
- **fiatDelivery.status**: `pending` → `fulfilled`

## Supported providers

venmo, cashapp, zelle, paypal, wise, revolut, chime

## Fees

80bps total (30bps protocol + 50bps market maker). Minimum $1.

## Development

```bash
npm install
cp .env.example .env.local
npm run dev
```

## Architecture

```
Agent → POST /api/send-payment → Peer API + Daimo deposit API → deposit address
Agent → sends stablecoin to deposit address
Daimo → bridges to USDC on Base → PaymentRouter contract
PaymentRouter → 30bps fee to treasury → createDeposit on Peer escrow
Peer LP → sends fiat to recipient → ZK proof → escrow releases USDC
```

## License

MIT
