const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');
const admin = require('firebase-admin');

admin.initializeApp();

const stripeSecretKey =
  functions.config().stripe?.secret || process.env.STRIPE_SECRET_KEY;

const stripe = stripeSecretKey
  ? new Stripe(stripeSecretKey, { apiVersion: '2024-08-31' })
  : null;

const stripePlans = new Map([
  [120000, { code: 'city', description: 'WarmMemo - 城市極簡告別' }],
  [150000, { code: 'family', description: 'WarmMemo - 家庭溫馨告別' }],
  [220000, { code: 'nature', description: 'WarmMemo - 自然環保告別' }],
]);

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post('/', async (req, res) => {
  try {
    const identity = await _ensureAuthorized(req);
    const payload = _validatePayload(req.body, identity);
    const invoice = await _createStripeInvoice(payload);
    return res.status(200).json(invoice);
  } catch (err) {
    console.error('createInvoice', err);
    return res.status(err.statusCode ?? 400).json({ error: err.message });
  }
});

exports.createInvoice = functions.region('asia-east1').https.onRequest(app);

async function _ensureAuthorized(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    const error = new Error('Missing authorization token.');
    error.statusCode = 401;
    throw error;
  }
  const token = authHeader.substring('Bearer '.length);
  return admin.auth().verifyIdToken(token);
}

function _validatePayload(body, identity) {
  const required = ['name', 'amountCents', 'provider'];
  for (const key of required) {
    if (body[key] == null) {
      const error = new Error(`Missing ${key} in request payload.`);
      error.statusCode = 400;
      throw error;
    }
  }
  const amountCents = Number(body.amountCents);
  const plan = stripePlans.get(amountCents);
  if (!Number.isInteger(amountCents) || !plan) {
    const error = new Error('Unsupported payment amount.');
    error.statusCode = 400;
    throw error;
  }
  const provider = String(body.provider).toLowerCase();
  if (provider !== 'stripe') {
    const error = new Error('Unsupported payment provider.');
    error.statusCode = 400;
    throw error;
  }
  const currency = String(body.currency ?? 'twd').toLowerCase();
  if (currency !== 'twd') {
    const error = new Error('Unsupported payment currency.');
    error.statusCode = 400;
    throw error;
  }
  const email = identity.email;
  if (!email) {
    const error = new Error('Authenticated account has no email address.');
    error.statusCode = 400;
    throw error;
  }
  return {
    email,
    name: String(body.name).slice(0, 120),
    amountCents,
    description: plan.description,
    planCode: plan.code,
    firebaseUid: identity.uid,
    currency,
    provider,
  };
}

async function _createStripeInvoice({
  email,
  name,
  amountCents,
  description,
  planCode,
  firebaseUid,
  currency,
}) {
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
    metadata: {
      firebase_uid: firebaseUid,
      plan_code: planCode,
      user_email: email,
    },
  });

  const finalized = await stripe.invoices.finalizeInvoice(invoice.id);

  const url = finalized.hosted_invoice_url || finalized.invoice_pdf;
  return {
    provider: 'stripe',
    invoiceId: finalized.id,
    checkoutUrl: url,
  };
}
