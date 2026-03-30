import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import admin from 'firebase-admin';

// Initialize Firebase Admin if credentials are available
let firebaseAdminReady = false;
try {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  firebaseAdminReady = admin.apps.length > 0;
} catch (_) {
  // ignore init errors in local without creds
}

const app = express();
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'OPTIONS'],
    // Flutter web 會帶上 Authorization header
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.use(express.json());

// Ensure OPTIONS preflight is handled
app.options('*', cors());

// Health
app.get('/health', (_req, res) => {
  res.status(200).json({ ok: true, ts: new Date().toISOString() });
});

// Auth middleware (Firebase ID token)
async function ensureAuthorized(req, res, next) {
  const allowInsecure = String(process.env.ALLOW_INSECURE_LOCAL || '').toLowerCase() === 'true';
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    if (allowInsecure) return next();
    return res.status(401).json({ error: 'Missing authorization token.' });
  }
  const token = authHeader.substring('Bearer '.length);

  // If Admin is not configured, we should not pretend token is invalid.
  if (!firebaseAdminReady && !allowInsecure) {
    return res.status(500).json({
      error: 'Firebase Admin is not configured.',
      detail:
        'Set GOOGLE_APPLICATION_CREDENTIALS to a valid service account JSON from the same Firebase project as the frontend.',
    });
  }

  try {
    await admin.auth().verifyIdToken(token);
    return next();
  } catch (err) {
    return res.status(401).json({
      error: 'Invalid authorization token.',
      detail: String(err?.message || err),
    });
  }
}

// LINE Pay config
const linePay = {
  channelId: process.env.LINEPAY_CHANNEL_ID,
  channelSecret: process.env.LINEPAY_CHANNEL_SECRET,
  baseUrl: process.env.LINEPAY_BASE_URL || 'https://sandbox-api-pay.line.me',
  confirmUrl: process.env.LINEPAY_CONFIRM_URL,
  cancelUrl: process.env.LINEPAY_CANCEL_URL,
};

function linePayHeaders(requestUri, bodyObj) {
  const nonce = crypto.randomUUID();
  const bodyText = bodyObj ? JSON.stringify(bodyObj) : '';
  const message = `${linePay.channelSecret}${requestUri}${bodyText}${nonce}`;
  const signature = crypto.createHmac('sha256', linePay.channelSecret).update(message).digest('base64');
  return {
    'Content-Type': 'application/json',
    'X-LINE-ChannelId': linePay.channelId,
    'X-LINE-Authorization-Nonce': nonce,
    'X-LINE-Authorization': signature,
  };
}

// Amount allowlist (optional hardening)
const ALLOWED_AMOUNTS = new Set([120000, 150000, 220000]);

// Request payment (Sandbox)
app.post('/api/payments/line/request', ensureAuthorized, async (req, res) => {
  try {
    const { amount, currency = 'TWD', orderId, description } = req.body ?? {};
    if (amount == null || !orderId || !description) {
      return res.status(400).json({ error: 'Missing amount/orderId/description.' });
    }
    const amt = Number(amount);
    if (!Number.isFinite(amt) || amt <= 0) {
      return res.status(400).json({ error: 'Invalid amount.' });
    }
    if (ALLOWED_AMOUNTS.size && !ALLOWED_AMOUNTS.has(amt)) {
      return res.status(400).json({ error: 'Amount not allowed.' });
    }
    if (!linePay.channelId || !linePay.channelSecret) {
      return res.status(500).json({ error: 'LINE Pay config missing.' });
    }
    if (!linePay.confirmUrl || !linePay.cancelUrl) {
      return res.status(500).json({ error: 'Confirm/Cancel URL missing.' });
    }

    const requestUri = '/v3/payments/request';
    const body = {
      amount: amt,
      currency: String(currency).toUpperCase(),
      orderId: String(orderId),
      packages: [
        {
          id: 'warmmemo_pkg',
          amount: amt,
          products: [
            { name: String(description).slice(0, 80), quantity: 1, price: amt },
          ],
        },
      ],
      redirectUrls: {
        confirmUrl: linePay.confirmUrl,
        cancelUrl: linePay.cancelUrl,
      },
    };

    const resp = await fetch(`${linePay.baseUrl}${requestUri}`, {
      method: 'POST',
      headers: linePayHeaders(requestUri, body),
      body: JSON.stringify(body),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok || data?.returnCode !== '0000') {
      return res.status(400).json({
        code: data?.returnCode ?? 'linepay_error',
        error: data?.returnMessage ?? JSON.stringify(data),
      });
    }
    const transactionId = String(data.info?.transactionId ?? '');
    const checkoutUrl = data.info?.paymentUrl?.web;
    if (!transactionId || !checkoutUrl) {
      return res.status(500).json({ error: 'LINE Pay missing transactionId/paymentUrl.' });
    }
    return res.status(200).json({
      provider: 'linepay',
      invoiceId: transactionId,
      checkoutUrl,
    });
  } catch (err) {
    console.error('line.request', err);
    return res.status(500).json({ error: String(err?.message || err) });
  }
});

// Start server
const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`WarmMemo API listening on http://localhost:${port}`);
});
