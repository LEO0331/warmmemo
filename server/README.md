# WarmMemo Node API (Express)

Minimal HTTPS API to proxy LINE Pay Sandbox from your own backend.

## Prerequisites
- Node 18+
- Environment variables:
  - `PORT` (default 8080)
  - `LINEPAY_CHANNEL_ID`
  - `LINEPAY_CHANNEL_SECRET`
  - `LINEPAY_BASE_URL` (default `https://sandbox-api-pay.line.me`)
  - `LINEPAY_CONFIRM_URL` (e.g. `https://your-host/#/packages?payment=success`)
  - `LINEPAY_CANCEL_URL` (e.g. `https://your-host/#/packages?payment=cancel`)
  - Optional: `ALLOW_INSECURE_LOCAL=true` to skip Firebase token check locally
  - Optional: Firebase Admin creds (e.g. `GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json`)

## Install & Run
```bash
cd server
npm i
PORT=8080 \
LINEPAY_CHANNEL_ID=xxx \
LINEPAY_CHANNEL_SECRET=yyy \
LINEPAY_CONFIRM_URL=https://your-host/#/packages?payment=success \
LINEPAY_CANCEL_URL=https://your-host/#/packages?payment=cancel \
npm run dev
```

## Endpoints
- `POST /api/payments/line/request`
  - Body: `{ amount: number, currency?: "TWD", orderId: string, description: string }`
  - Auth: Bearer Firebase ID token (skip if `ALLOW_INSECURE_LOCAL=true`)
  - Returns: `{ provider: "linepay", invoiceId, checkoutUrl }`

## Frontend configuration
Launch Flutter with:
```bash
flutter run -d chrome \
  --dart-define=WARMEMO_PAYMENT_BACKEND_URL=http://localhost:8080 \
  --dart-define=WARMEMO_LINEPAY_FUNCTION=api/payments/line/request
```
