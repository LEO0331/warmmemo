import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const webRoot = path.join(root, 'web');
const siteBase = 'https://leo0331.github.io/warmmemo/';

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const sitemap = read('web/sitemap.xml');
const urls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
assert(urls.length >= 6, 'sitemap.xml must include the public SEO pages');
assert(new Set(urls).size === urls.length, 'sitemap.xml contains duplicate URLs');

for (const url of urls) {
  assert(url.startsWith(siteBase), `Sitemap URL is outside the canonical site: ${url}`);
  assert(!url.includes('#'), `Fragment routes must not be included in the sitemap: ${url}`);
  const relative = url.slice(siteBase.length) || 'index.html';
  const localPath = path.join(webRoot, relative);
  assert(fs.existsSync(localPath), `Sitemap target does not exist: web/${relative}`);

  if (!relative.endsWith('.html')) continue;
  const html = fs.readFileSync(localPath, 'utf8');
  assert(/<html[^>]+lang="zh-Hant-TW"/i.test(html), `${relative} needs a zh-Hant-TW lang attribute`);
  assert(/<title>[^<]{10,}<\/title>/i.test(html), `${relative} needs a descriptive title`);
  // Traditional Chinese conveys useful detail in fewer characters than English.
  assert(/<meta name="description" content="[^\"]{24,}"/i.test(html), `${relative} needs a useful meta description`);
  assert(html.includes(`<link rel="canonical" href="${url}">`), `${relative} canonical URL does not match the sitemap`);
  assert(/<h1>[^<]+<\/h1>/i.test(html), `${relative} needs one visible h1`);
  assert(!html.includes('.example'), `${relative} contains a placeholder .example address`);

  for (const match of html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/gi)) {
    JSON.parse(match[1]);
  }
}

const robots = read('web/robots.txt');
assert(robots.includes(`Sitemap: ${siteBase}sitemap.xml`), 'robots.txt must reference the canonical sitemap');
assert(read('web/llms.txt').includes(`Canonical site: ${siteBase}`), 'llms.txt must identify the canonical site');
assert(read('web/ai.txt').includes(`${siteBase}llms.txt`), 'ai.txt must point to llms.txt');

console.log(`SEO verification passed for ${urls.length} sitemap URLs.`);
