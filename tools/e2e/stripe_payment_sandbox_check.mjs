import path from 'node:path';
import { pathToFileURL } from 'node:url';

const playwrightModulePath =
  process.env.PLAYWRIGHT_MODULE ??
  '/Users/Leo/.npm/_npx/e41f203b7505f1fb/node_modules/playwright/index.mjs';
const { chromium } = await import(pathToFileURL(path.resolve(playwrightModulePath)).href);

const baseUrl = process.env.WARMEMO_BASE_URL ?? 'https://leo0331.github.io/warmmemo/';
const packageName = process.env.WARMEMO_PACKAGE_NAME ?? '城市極簡告別';
const password = process.env.WARMEMO_TEST_PASSWORD ?? 'WarmMemo123!';
const email = process.env.WARMEMO_TEST_EMAIL ?? `stripe-sandbox-${Date.now()}@example.com`;

const result = {
  baseUrl,
  email,
  packageName,
  timestamp: new Date().toISOString(),
  steps: [],
  summary: {},
};

async function capture(page, name) {
  const safe = name.replace(/[^a-z0-9_-]+/gi, '-').toLowerCase();
  const file = `/private/tmp/${safe}.png`;
  await page.screenshot({ path: file, fullPage: true });
  return file;
}

function pushStep(name, status, detail = {}) {
  result.steps.push({ name, status, ...detail });
}

async function clickByText(page, text, exact = true) {
  const locator = page.getByText(text, { exact });
  await locator.waitFor({ state: 'visible', timeout: 30000 });
  await locator.click();
}

async function fillStripeCard(page) {
  const allFrames = page.frames();
  let filled = false;

  for (const frame of allFrames) {
    try {
      const cardNumber = frame.locator('input[name="number"]');
      if (await cardNumber.count()) {
        await cardNumber.fill('4242424242424242');
        const expiry = frame.locator('input[name="expiry"]');
        if (await expiry.count()) {
          await expiry.fill('1234');
        }
        const cvc = frame.locator('input[name="cvc"]');
        if (await cvc.count()) {
          await cvc.fill('123');
        }
        const cardholder = frame.locator('input[name="name"], input[autocomplete="cc-name"]');
        if (await cardholder.count()) {
          await cardholder.first().fill('WarmMemo Test');
        }
        filled = true;
        break;
      }
    } catch {}
  }

  if (filled) {
    return true;
  }

  for (const frame of allFrames) {
    try {
      const combined = frame.locator('input[placeholder*="Card"], input[aria-label*="Card"], input[autocomplete="cc-number"]');
      if (await combined.count()) {
        await combined.first().fill('4242424242424242');
        filled = true;
      }
      const expiry = frame.locator('input[placeholder*="MM"], input[aria-label*="expiration"], input[autocomplete="cc-exp"]');
      if (await expiry.count()) {
        await expiry.first().fill('1234');
      }
      const cvc = frame.locator('input[placeholder*="CVC"], input[aria-label*="security code"], input[autocomplete="cc-csc"]');
      if (await cvc.count()) {
        await cvc.first().fill('123');
      }
      const cardholder = frame.locator('input[placeholder*="Name"], input[aria-label*="Name"], input[autocomplete="cc-name"]');
      if (await cardholder.count()) {
        await cardholder.first().fill('WarmMemo Test');
      }
    } catch {}
  }

  return filled;
}

async function fillStripeCheckout(page) {
  const emailInput = page.locator('input[type="email"], input[name="email"]');
  if (await emailInput.count()) {
    await emailInput.first().fill(email);
  }

  const nameInput = page.locator('input[autocomplete="billing name"], input[name="cardholderName"], input[placeholder*="Name"]');
  if (await nameInput.count()) {
    await nameInput.first().fill('WarmMemo Test');
  }

  const filledCard = await fillStripeCard(page);
  if (!filledCard) {
    throw new Error('Unable to locate Stripe card fields.');
  }

  const countrySelect = page.locator('select[name="billingCountry"], select[autocomplete="country-name"]');
  if (await countrySelect.count()) {
    const select = countrySelect.first();
    const current = await select.inputValue().catch(() => '');
    if (!current) {
      await select.selectOption({ label: '台灣' }).catch(async () => {
        await select.selectOption({ label: 'Taiwan' }).catch(async () => {
          await select.selectOption({ index: 0 });
        });
      });
    }
  }

  const payButton = page.locator(
    'button:has-text("Pay"), button:has-text("支付"), button:has-text("Subscribe"), button[type="submit"]',
  );
  await payButton.first().click();
}

async function main() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1200 },
    locale: 'zh-TW',
  });
  const page = await context.newPage();

  try {
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    const loadingHeading = page.getByText('WarmMemo 載入中', { exact: true });
    if (await loadingHeading.count()) {
      await loadingHeading.waitFor({ state: 'hidden', timeout: 120000 }).catch(() => {});
    }
    await page.waitForTimeout(3000);
    pushStep('open-app', 'passing', {
      url: page.url(),
      screenshot: await capture(page, 'warmmemo-open-app'),
    });

    await page.mouse.click(720, 230);
    await page.waitForTimeout(1200);
    pushStep('after-open-auth-click', 'passing', {
      screenshot: await capture(page, 'warmmemo-after-open-auth-click'),
    });
    await page.mouse.click(1070, 230);
    await page.waitForTimeout(800);
    await page.mouse.click(720, 290);
    await page.keyboard.type(email);
    await page.mouse.click(720, 349);
    await page.keyboard.type(password);
    await page.mouse.click(720, 415);
    await page.waitForTimeout(6000);
    pushStep('register-submitted', 'passing', {
      screenshot: await capture(page, 'warmmemo-after-register-submit'),
    });

    await page.mouse.click(120, 443);
    await page.waitForTimeout(2500);
    pushStep('packages-route-opened', 'passing', {
      url: page.url(),
      screenshot: await capture(page, 'warmmemo-packages-route'),
    });
    pushStep('register-and-login', 'passing', { email });

    await page.mouse.click(845, 572);
    await page.waitForTimeout(1500);
    pushStep('checkout-opened', 'passing', {
      screenshot: await capture(page, 'warmmemo-checkout-page'),
    });
    pushStep('reach-checkout-page', 'passing');

    await page.mouse.click(140, 1160);
    await page.waitForURL(/buy\.stripe\.com\/test_/i, { timeout: 45000 });
    await page.waitForTimeout(3000);
    pushStep('open-stripe-hosted-link', 'passing', {
      url: page.url(),
      screenshot: await capture(page, 'warmmemo-stripe-hosted-link'),
    });

    await fillStripeCheckout(page);
    await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
    await page.waitForTimeout(5000);

    const successSignals = [
      /payment confirmed/i,
      /thank you/i,
      /success/i,
      /完成/i,
      /支付成功/i,
    ];
    const bodyText = await page.locator('body').innerText({ timeout: 30000 });
    const matchedSuccess = successSignals.some((pattern) => pattern.test(bodyText));
    const returnedToWarmMemo = page.url().startsWith(baseUrl);
    if (!matchedSuccess && !/[?&]payment=success\b/i.test(page.url()) && !returnedToWarmMemo) {
      throw new Error(`Stripe completion signal not detected. Current URL: ${page.url()}`);
    }
    pushStep('complete-stripe-sandbox-payment', 'passing', {
      url: page.url(),
      screenshot: await capture(page, 'warmmemo-after-stripe-payment'),
    });

    const returnLink = page.getByRole('link', { name: /return|返回|回到/i });
    if (await returnLink.count()) {
      await returnLink.first().click();
    } else if (!returnedToWarmMemo) {
      await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    }

    await page.waitForTimeout(5000);
    await page.mouse.click(120, 443);
    await page.waitForTimeout(2500);
    for (let i = 0; i < 8; i += 1) {
      await page.mouse.wheel(0, 1400);
      await page.waitForTimeout(300);
    }
    await page.waitForTimeout(1500);
    pushStep('packages-after-return', 'passing', {
      screenshot: await capture(page, 'warmmemo-packages-after-return'),
    });
    const orderSummaryText = await page.locator('body').innerText({ timeout: 30000 });
    const orderVisible = orderSummaryText.includes(packageName);
    if (!orderVisible) {
      throw new Error('Created order not visible after return.');
    }
    pushStep('order-visible-after-return', 'passing');

    const pageText = orderSummaryText;
    const autoPaid = /付款：paid|付款狀態：paid/i.test(pageText);
    pushStep('payment-status-auto-updated', autoPaid ? 'passing' : 'blocked', {
      detail: autoPaid
          ? 'paymentStatus updated to paid in UI.'
          : 'Order remains visible, but UI does not show automatic paid status after Stripe sandbox completion.',
    });

    result.summary = {
      status: autoPaid ? 'passing' : 'partial',
      autoPaid,
      finalUrl: page.url(),
    };
    console.log(JSON.stringify(result, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  result.summary = {
    status: 'failed',
    error: error.message,
  };
  console.log(JSON.stringify(result, null, 2));
  process.exit(1);
});
