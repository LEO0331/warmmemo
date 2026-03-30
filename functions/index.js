const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const stripeSecretKey =
  functions.config().stripe?.secret || process.env.STRIPE_SECRET_KEY;

const stripe = stripeSecretKey
  ? new Stripe(stripeSecretKey, { apiVersion: '2024-08-31' })
  : null;

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post('/', async (req, res) => {
  try {
    await _ensureAuthorized(req);
    const payload = _validatePayload(req.body);
    const invoice = await _createStripeInvoice(payload);
    return res.status(200).json(invoice);
  } catch (err) {
    console.error('createInvoice', err);
    return res.status(err.statusCode ?? 400).json({ error: err.message });
  }
});

exports.createInvoice = functions.region('asia-east1').https.onRequest(app);

// --- LINE Pay (Sandbox) minimal integration ---
// References (conceptually): LINE Pay API requires HMAC signature with a nonce.
// This implementation is intended for sandbox connectivity tests only.
const linePayChannelId =
  functions.config().linepay?.channel_id || process.env.LINEPAY_CHANNEL_ID;
const linePayChannelSecret =
  functions.config().linepay?.channel_secret || process.env.LINEPAY_CHANNEL_SECRET;
const linePayBaseUrl =
  functions.config().linepay?.base_url ||
  process.env.LINEPAY_BASE_URL ||
  'https://sandbox-api-pay.line.me';
const linePayConfirmUrl =
  functions.config().linepay?.confirm_url || process.env.LINEPAY_CONFIRM_URL;
const linePayCancelUrl =
  functions.config().linepay?.cancel_url || process.env.LINEPAY_CANCEL_URL;

const linePayApp = express();
linePayApp.use(cors({ origin: true }));
linePayApp.use(express.json());

linePayApp.post('/', async (req, res) => {
  try {
    await _ensureAuthorized(req);
    const payload = _validateLinePayPayload(req.body);
    const result = await _createLinePayRequest(payload);
    return res.status(200).json(result);
  } catch (err) {
    console.error('linePayRequest', err);
    return res.status(err.statusCode ?? 400).json({
      code: err.code ?? 'bad_request',
      error: err.message,
    });
  }
});

exports.linePayRequest = functions.region('asia-east1').https.onRequest(linePayApp);

async function _ensureAuthorized(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    const error = new Error('Missing authorization token.');
    error.statusCode = 401;
    throw error;
  }
  const token = authHeader.substring('Bearer '.length);
  await admin.auth().verifyIdToken(token);
}

function _validatePayload(body) {
  const required = ['email', 'name', 'amountCents', 'description', 'provider'];
  for (const key of required) {
    if (body[key] == null) {
      const error = new Error(`Missing ${key} in request payload.`);
      error.statusCode = 400;
      throw error;
    }
  }
  return {
    email: String(body.email),
    name: String(body.name),
    amountCents: Number(body.amountCents),
    description: String(body.description),
    currency: String(body.currency ?? 'twd'),
    provider: String(body.provider).toLowerCase(),
  };
}

async function _createStripeInvoice({ email, name, amountCents, description, currency }) {
  if (!stripe) {
    const error = new Error('Stripe secret key is not configured.');
    error.statusCode = 500;
    throw error;
  }
  const customer = await stripe.customers.create({
    email,
    name,
    description: `WarmMemo client (${email})`,
  });

  await stripe.invoiceItems.create({
    customer: customer.id,
    unit_amount: amountCents,
    currency,
    quantity: 1,
    description,
  });

  const invoice = await stripe.invoices.create({
    customer: customer.id,
    collection_method: 'send_invoice',
    auto_advance: false,
    description,
    metadata: { user_email: email },
  });

  const finalized = await stripe.invoices.finalizeInvoice(invoice.id);

  const url = finalized.hosted_invoice_url || finalized.invoice_pdf;
  return {
    provider: 'stripe',
    invoiceId: finalized.id,
    checkoutUrl: url,
  };
}

function _validateLinePayPayload(body) {
  const required = ['amount', 'currency', 'orderId', 'description'];
  for (const key of required) {
    if (body[key] == null) {
      const error = new Error(`Missing ${key} in request payload.`);
      error.statusCode = 400;
      throw error;
    }
  }
  return {
    amount: Number(body.amount),
    currency: String(body.currency).toUpperCase(),
    orderId: String(body.orderId),
    description: String(body.description),
  };
}

function _linePayAuthHeaders({ requestUri, body }) {
  if (!linePayChannelId || !linePayChannelSecret) {
    const error = new Error('LINE Pay channel config is missing.');
    error.statusCode = 500;
    throw error;
  }
  const nonce = crypto.randomUUID();
  const bodyText = body ? JSON.stringify(body) : '';
  // Signature (commonly used by LINE Pay API):
  // Base64(HMAC-SHA256(channelSecret, channelSecret + requestUri + bodyText + nonce))
  const message = `${linePayChannelSecret}${requestUri}${bodyText}${nonce}`;
  const signature = crypto
    .createHmac('sha256', linePayChannelSecret)
    .update(message)
    .digest('base64');
  return {
    'Content-Type': 'application/json',
    'X-LINE-ChannelId': linePayChannelId,
    'X-LINE-Authorization-Nonce': nonce,
    'X-LINE-Authorization': signature,
  };
}

async function _createLinePayRequest({ amount, currency, orderId, description }) {
  if (!linePayConfirmUrl || !linePayCancelUrl) {
    const error = new Error('LINE Pay confirm/cancel URL is not configured.');
    error.statusCode = 500;
    throw error;
  }
  const requestUri = '/v3/payments/request';
  const body = {
    amount,
    currency,
    orderId,
    packages: [
      {
        id: 'warmmemo_pkg',
        amount,
        products: [
          {
            name: description.slice(0, 80),
            quantity: 1,
            price: amount,
          },
        ],
      },
    ],
    redirectUrls: {
      confirmUrl: linePayConfirmUrl,
      cancelUrl: linePayCancelUrl,
    },
  };

  const res = await fetch(`${linePayBaseUrl}${requestUri}`, {
    method: 'POST',
    headers: _linePayAuthHeaders({ requestUri, body }),
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || data?.returnCode !== '0000') {
    const error = new Error(
      `LINE Pay request failed (HTTP ${res.status}): ${data?.returnMessage ?? JSON.stringify(data)}`,
    );
    error.statusCode = 400;
    error.code = data?.returnCode ?? 'linepay_error';
    throw error;
  }

  const transactionId = String(data.info?.transactionId ?? '');
  const checkoutUrl = data.info?.paymentUrl?.web;
  if (!transactionId || !checkoutUrl) {
    const error = new Error('LINE Pay response missing transactionId/paymentUrl.');
    error.statusCode = 500;
    throw error;
  }
  return {
    provider: 'linepay',
    invoiceId: transactionId,
    checkoutUrl,
  };
}
