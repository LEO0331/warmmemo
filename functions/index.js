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
