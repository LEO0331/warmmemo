const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { after, before, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { collection, doc, getDoc, getDocs, setDoc, updateDoc } = require('firebase/firestore');

const plans = [
  ['城市極簡告別', 120000, 'NT$ 120,000'],
  ['家庭溫馨告別', 220000, 'NT$ 220,000'],
  ['自然環保告別（樹葬／海葬）', 150000, 'NT$ 150,000（不含政府規費）'],
  ['QR 紀念碑 / 數位追思牌', 150000, 'NT$ 150,000'],
];
const userId = 'customer-fixture';
const ownerPaths = ['users/customer-fixture/orders', 'orders'];
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-warmmemo-rules',
    firestore: {
      host: '127.0.0.1',
      port: Number(process.env.WARMMEMO_RULES_EMULATOR_PORT || 18883),
      rules: readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
  await env.clearFirestore();
});

after(async () => {
  await env?.cleanup();
});

function checkoutOrder([planName, priceAmount, priceLabel] = plans[0]) {
  return {
    schemaVersion: 2,
    planName,
    priceLabel,
    priceAmount,
    status: 'pending',
    createdAt: '2026-11-17T01:00:00.000',
    userId,
    companyName: null,
    contactNumber: null,
    agentName: null,
    notes: null,
    paymentProvider: 'stripe',
    paymentStatus: 'awaiting_checkout',
    invoiceId: null,
    checkoutUrl: null,
    paymentCurrency: 'twd',
    paidAt: null,
    paymentIntentId: null,
    verifiedBy: null,
    verifiedAt: null,
    verificationNote: null,
    verificationLogs: [],
    proposal: null,
    vendorAssignment: null,
    materialSelection: null,
    deliverySchedule: [],
  };
}

function checkoutUpdate(orderId) {
  return {
    paymentStatus: 'checkout_created',
    invoiceId: `hosted_${orderId}`,
    checkoutUrl: `https://buy.stripe.com/test_link?client_reference_id=${orderId}`,
  };
}

test('both order paths accept the current plan payload and hosted checkout', async () => {
  const owner = env.authenticatedContext(userId).firestore();
  const other = env.authenticatedContext('another-customer').firestore();
  for (const path of ownerPaths) {
    for (const [index, plan] of plans.entries()) {
      const id = `plan-${index}`;
      const ref = doc(owner, path, id);
      await assertSucceeds(setDoc(ref, checkoutOrder(plan)));
      await assertSucceeds(updateDoc(ref, checkoutUpdate(id)));
      await assertSucceeds(updateDoc(ref, checkoutUpdate(id)));
      await assertSucceeds(getDoc(ref));
      await assertFails(getDoc(doc(other, path, id)));
    }
  }
});

test('both order paths allow proposal writes while preserving confirmed payments', async () => {
  const owner = env.authenticatedContext(userId).firestore();
  const operator = env.authenticatedContext('claim-operator', { admin: true }).firestore();
  for (const path of ownerPaths) {
    const id = 'confirmed-payment';
    const ref = doc(owner, path, id);
    await assertSucceeds(setDoc(ref, checkoutOrder()));
    await assertSucceeds(updateDoc(ref, checkoutUpdate(id)));
    const operatorRef = doc(operator, path, id);
    await assertSucceeds(updateDoc(operatorRef, { paymentStatus: 'failed' }));
    await assertSucceeds(updateDoc(ref, checkoutUpdate(id)));
    await assertSucceeds(updateDoc(operatorRef, { paymentStatus: 'paid' }));
    await assertSucceeds(updateDoc(ref, { proposal: { note: '提案確認' } }));
    await assertFails(updateDoc(ref, { paymentStatus: 'cancelled' }));
    const snapshot = await assertSucceeds(getDoc(ref));
    assert.equal(snapshot.data().paymentStatus, 'paid');
  }
});

test('current legacy administrators can backfill old root and nested orders', async () => {
  const operatorId = 'legacy-operator';
  await env.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await setDoc(doc(firestore, 'users', operatorId), { role: 'admin' });
    for (const path of ownerPaths) {
      await setDoc(doc(firestore, path, 'legacy-order'), {
        schemaVersion: 1,
        userId,
        priceLabel: 'NT$ 120,000',
      });
      await setDoc(doc(firestore, path, 'legacy-complete-order'), {
        ...checkoutOrder(),
        schemaVersion: 1,
        status: 'complete',
      });
    }
  });
  const operator = env.authenticatedContext(operatorId).firestore();
  await assertSucceeds(setDoc(doc(operator, 'admins', operatorId), {}));
  for (const path of ownerPaths) {
    const ref = doc(operator, path, 'legacy-order');
    await assertSucceeds(updateDoc(ref, { schemaVersion: 2, priceAmount: 120000 }));
    await assertSucceeds(getDoc(ref));
    const completedRef = doc(operator, path, 'legacy-complete-order');
    await assertSucceeds(updateDoc(completedRef, { schemaVersion: 2 }));
    const owner = env.authenticatedContext(userId).firestore();
    await assertFails(updateDoc(doc(owner, path, 'legacy-complete-order'),
      checkoutUpdate('legacy-complete-order')));
  }
  await assertFails(updateDoc(doc(operator, 'orders', 'legacy-order'), {
    userId: 'different-customer',
  }));
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'users', operatorId), { role: 'user' });
  });
  await assertFails(getDoc(doc(operator, 'orders', 'legacy-order')));
});

test('public memorials support anonymous slug reads and administrator listing', async () => {
  const owner = env.authenticatedContext(userId).firestore();
  const visitor = env.unauthenticatedContext().firestore();
  const operator = env.authenticatedContext('claim-operator', { admin: true }).firestore();
  const slug = 'memorial-rule-fixture';
  await assertSucceeds(setDoc(doc(owner, 'public_memorials', slug), { ownerUid: userId }));
  await assertSucceeds(getDoc(doc(visitor, 'public_memorials', slug)));
  await assertFails(getDocs(collection(visitor, 'public_memorials')));
  await assertFails(getDocs(collection(owner, 'public_memorials')));
  await assertSucceeds(getDocs(collection(operator, 'public_memorials')));
});
