const assert = require('node:assert/strict');
const { once } = require('node:events');
const http = require('node:http');
const { createRequire } = require('node:module');
const path = require('node:path');
const test = require('node:test');
const { pathToFileURL } = require('node:url');

for (const backend of ['server', 'functions']) {
  const backendRequire = createRequire(path.resolve(__dirname, '..', backend, 'package.json'));
  const qs = backendRequire('qs');
  const gaxiosRequire = createRequire(backendRequire.resolve('gaxios'));
  const uuid = gaxiosRequire('uuid');

  test(`${backend}: qs rejects bracket-key comma arrays exceeding the limit`, () => {
    assert.throws(() => qs.parse('a[]=1,2,3,4', {
      comma: true, arrayLimit: 3, throwOnLimitExceeded: true,
    }), RangeError);
  });

  test(`${backend}: qs safely serializes attacker-controlled constructor keys`, () => {
    const parsed = qs.parse('x[constructor][isBuffer]=y', { plainObjects: true });
    assert.equal(qs.stringify(parsed), 'x%5Bconstructor%5D%5BisBuffer%5D=y');
  });

  test(`${backend}: qs handles null and undefined comma-array entries`, () => {
    for (const empty of [null, undefined]) {
      assert.equal(qs.stringify({ a: [empty, 'b'] }, {
        arrayFormat: 'comma', encodeValuesOnly: true,
      }), 'a=,b');
    }
  });

  test(`${backend}: Gaxios resolves a compatible UUID with buffer bounds checks`, () => {
    assert.ok(uuid.validate(uuid.v4()));
    assert.throws(() => uuid.v3('x', uuid.v3.DNS, new Uint8Array(8), 4), RangeError);
    assert.throws(() => uuid.v5('x', uuid.v5.DNS, new Uint8Array(8), 4), RangeError);
    assert.throws(() => uuid.v6({}, new Uint8Array(8), 4), RangeError);
    assert.equal(typeof backendRequire('gaxios').request, 'function');
    assert.equal(typeof backendRequire('firebase-admin/auth').getAuth, 'function');
  });
}

test('Firebase v7 entrypoint loads and preserves invoice authentication and validation', async (t) => {
  const backendRequire = createRequire(path.resolve(__dirname, '../functions/package.json'));
  // Keep this test offline even when the developer has a Stripe key configured.
  const savedKey = process.env.STRIPE_SECRET_KEY;
  delete process.env.STRIPE_SECRET_KEY;
  t.after(() => {
    if (savedKey !== undefined) process.env.STRIPE_SECRET_KEY = savedKey;
  });
  const { createInvoice } = backendRequire('./index.js');
  const auth = backendRequire('firebase-admin/auth').getAuth();
  t.mock.method(auth, 'verifyIdToken', async () => ({ uid: 'test-user', email: 'test@example.invalid' }));
  t.mock.method(console, 'error', () => {});
  const server = http.createServer(createInvoice).listen(0, '127.0.0.1');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}/`;
  const unauthorized = await fetch(url, { method: 'POST' });
  assert.equal(unauthorized.status, 401);
  assert.equal((await unauthorized.json()).error, 'Missing authorization token.');
  for (const [payload, status, error] of [
    [{ name: 'Test', amountCents: 1, provider: 'stripe' }, 400, 'Unsupported payment amount.'],
    [{ name: 'Test', amountCents: 120000, provider: 'linepay' }, 400, 'Unsupported payment provider.'],
    [{ name: 'Test', amountCents: 120000, provider: 'stripe', currency: 'usd' }, 400, 'Unsupported payment currency.'],
    [{ name: 'Test', amountCents: 120000, provider: 'stripe' }, 500, 'Stripe secret key is not configured.'],
  ]) {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer test-only' },
      body: JSON.stringify(payload),
    });
    assert.equal(response.status, status);
    assert.equal((await response.json()).error, error);
  }
});

test('standalone server preserves health, preflight and Firebase authentication', async (t) => {
  const backendRequire = createRequire(path.resolve(__dirname, '../server/package.json'));
  const savedInsecure = process.env.ALLOW_INSECURE_LOCAL;
  delete process.env.ALLOW_INSECURE_LOCAL;
  t.after(() => {
    if (savedInsecure !== undefined) process.env.ALLOW_INSECURE_LOCAL = savedInsecure;
  });
  // Capture the existing entrypoint's listener on an ephemeral port.
  const originalListen = http.Server.prototype.listen;
  let server;
  t.mock.method(http.Server.prototype, 'listen', function (...args) {
    server = this;
    args[0] = 0;
    return Reflect.apply(originalListen, this, args);
  });
  await import(pathToFileURL(path.resolve(__dirname, '../server/src/index.js')).href);
  t.after(() => new Promise((resolve) => server.close(resolve)));
  if (!server.listening) await once(server, 'listening');
  const auth = backendRequire('firebase-admin/auth').getAuth();
  const verify = t.mock.method(auth, 'verifyIdToken', async (token) => {
    if (token !== 'test-valid') throw new Error('Test invalid token');
    return { uid: 'test-user' };
  });
  const url = `http://127.0.0.1:${server.address().port}`;
  const health = await fetch(`${url}/health`);
  assert.equal(health.status, 200);
  assert.equal((await health.json()).ok, true);
  const route = `${url}/api/payments/line/request`;
  assert.equal((await fetch(route, { method: 'OPTIONS' })).status, 204);
  for (const [token, status, error] of [
    [null, 401, 'Missing authorization token.'],
    ['test-invalid', 401, 'Invalid authorization token.'],
    ['test-valid', 400, 'Missing amount/orderId/description.'],
  ]) {
    const response = await fetch(route, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: '{}',
    });
    assert.equal(response.status, status);
    assert.equal((await response.json()).error, error);
  }
  assert.equal(verify.mock.callCount(), 2);
});
