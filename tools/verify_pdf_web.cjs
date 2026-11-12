// Usage: node tools/verify_pdf_web.cjs <app-build> <fixture-build> <pdf-dir>
// Both builds use --base-href /warmmemo/ --no-web-resources-cdn.
const assert = require('node:assert/strict');
const { readFile, mkdir } = require('node:fs/promises');
const { createServer } = require('node:http');
const path = require('node:path');
const { performance } = require('node:perf_hooks');

const base = '/warmmemo/';
const pdfFont = /\/assets\/assets\/fonts\/[^/]+\.ttf$/;
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.png': 'image/png',
};

async function serve(build) {
  const root = path.resolve(build);
  const fonts = [];
  const server = createServer(async (request, response) => {
    const url = new URL(request.url, 'http://127.0.0.1');
    const relative = decodeURIComponent(url.pathname.slice(base.length));
    const file = path.resolve(root, relative || 'index.html');
    if (!url.pathname.startsWith(base) || !file.startsWith(root + path.sep)) {
      response.writeHead(404).end();
      return;
    }
    if (pdfFont.test(url.pathname)) fonts.push(path.basename(file));
    try {
      const bytes = await readFile(file);
      response.writeHead(200, {
        'Content-Type': types[path.extname(file)] ?? 'application/octet-stream',
      }).end(bytes);
    } catch {
      response.writeHead(404).end();
    }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  return { server, fonts, origin: 'http://127.0.0.1:' + server.address().port };
}

async function downloadPdf(page, kind, outputPath) {
  const start = performance.now();
  const [file] = await Promise.all([
    page.waitForEvent('download', { timeout: 20000 }),
    page.getByRole('button', { name: 'Export ' + kind }).click({ force: true }),
  ]).catch(async (error) => {
    const status = await page.getByText(/^Export error:/).textContent({ timeout: 1000 }).catch(() => null);
    if (status) throw new Error(status, { cause: error });
    throw error;
  });
  assert.equal(file.suggestedFilename(), 'warmmemo_' + kind + '.pdf');
  if (outputPath) await file.saveAs(outputPath);
  const bytes = await readFile(await file.path());
  assert.match(bytes.subarray(0, 12).toString(), /^%PDF-/);
  assert.ok(bytes.includes(Buffer.from('/FontFile2')), 'missing embedded TrueType font');
  assert.ok(bytes.length > 2000 && bytes.length < 120000, 'unexpected PDF size');
  console.log(kind + ': ' + bytes.length + ' bytes in ' + Math.round(performance.now() - start) + ' ms');
}

async function main() {
  const [appBuild, fixtureBuild, output] = process.argv.slice(2);
  assert.ok(appBuild && fixtureBuild && output, 'supply production build, fixture build and PDF output paths');
  const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
  await mkdir(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_EXECUTABLE || undefined,
    headless: true,
  });
  const app = await serve(appBuild);
  const fixture = await serve(fixtureBuild);
  try {
    const production = await browser.newPage();
    await production.goto(app.origin + base);
    await production.locator('#wm-loader').waitFor({ state: 'detached', timeout: 30000 });
    await production.locator('flt-semantics-placeholder').dispatchEvent('click');
    await production.getByRole('button', { name: '登入 / 註冊' }).waitFor({ timeout: 30000 });
    assert.deepEqual(app.fonts, [], 'PDF fonts fetched during production app startup');
    console.log('Production landing: no PDF font requests');
    await production.close();

    // Disable the service worker to verify the browser really goes offline
    // and the final export uses parsed fonts from the loaded page's memory.
    const context = await browser.newContext({ serviceWorkers: 'block' });
    const outside = [];
    await context.route('**/*', async (route) => {
      const url = new URL(route.request().url());
      if (url.origin === fixture.origin) await route.continue();
      else {
        outside.push(url.origin);
        await route.abort('internetdisconnected');
      }
    });
    const page = await context.newPage();
    await page.goto(fixture.origin + base);
    await page.getByRole('button', { name: 'Export memorial' }).waitFor();
    assert.deepEqual(fixture.fonts, [], 'fixture loaded PDF fonts before export');
    outside.length = 0;

    console.log('Cold export with external network blocked');
    await downloadPdf(page, 'memorial');
    assert.deepEqual(new Set(fixture.fonts), new Set([
      'NotoSansTC-Subset.ttf',
      'NotoSansTC-Bold-Subset.ttf',
    ]));
    await downloadPdf(page, 'obituary');
    assert.ok(fixture.fonts.includes('NotoSansTC-Regular.ttf'), 'uncommon glyph did not load full font');
    assert.deepEqual(outside, [], 'PDF generation attempted an external request');

    const fontsBeforeOffline = fixture.fonts.length;
    await context.setOffline(true);
    assert.equal(await page.evaluate(() => navigator.onLine), false);
    console.log('Fully offline export after local assets are loaded');
    await downloadPdf(page, 'memorial', path.join(output, 'memorial.pdf'));
    await downloadPdf(page, 'obituary', path.join(output, 'obituary.pdf'));
    assert.equal(fixture.fonts.length, fontsBeforeOffline, 'offline export hit asset server');
    console.log('Production startup and both offline PDF exports passed');
  } finally {
    await browser.close();
    app.server.close();
    fixture.server.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
