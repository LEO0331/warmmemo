# Session Progress Log

## Current State (Last Updated: 2026-10-02)

**Current Objective:** No active feature. Select one `planned` item from `feature_list.json` before starting new product work.

**Status:** Ready for a clean restart.

### Dependabot Alert Remediation Completed (2026-10-02)

Objective: Review the eight open Dependabot alerts and fix worthwhile issues without changing payment or public-route behavior.

- Synced the clean checkout to `origin/main` (`153c9ff`) first; previously merged Firebase/other security upgrades were retained.
- Alerts **#62/#33** (`GHSA-x5fp-wj9c-mxmx`), **#61/#32** (`GHSA-4mjr-xmp4-gh2g`), and **#51/#22** (`GHSA-q8mj-m7cp-5q26`): raised the Express 4 minimum to 4.22.3 and resolved every `qs` copy to 6.16.0 in both backends. Current application code does not enable comma parsing/stringifying or round-trip query objects through `qs.stringify`, so direct exploitability is limited; the compatible patch remains worthwhile preventive maintenance.
- Alerts **#50/#21** (`GHSA-w5hq-g745-h8pq`): pinned Gaxios's transitive `uuid` to 11.1.1. Gaxios uses argument-free UUID v4; the vulnerable v3/v5/v6 buffer APIs are not exposed by the app. This narrow override fixes the vulnerable library without upgrading Firebase again or selecting an ESM-only UUID major.
- Runtime checks found incompatibilities from the earlier Firebase major upgrades: removed `functions.config()` and `admin.auth()`/`admin.apps` APIs. Used explicit first-generation Functions imports and modular Admin app/auth APIs. Bound `STRIPE_SECRET_KEY` through Secret Manager; Functions now targets Node.js 22 and the standalone server declares Node.js >=20, matching Admin's minimum.
- Added ten offline Node regression tests and a Node.js 22 CI step. Tests reproduce all four advisory cases and exercise real local HTTP startup, health/preflight, authentication and invoice validation.
- Simplifications: deduplicated patched `qs` entries and removed obsolete Firebase config access; no new project dependencies.

Changed files: `functions/package.json`, `functions/package-lock.json`, `functions/index.js`, `server/package.json`, `server/package-lock.json`, `server/src/index.js`, `tools/node_security.test.cjs`, `.github/workflows/ci.yml`, `.gitignore`, `docs/info.md`, `docs/progress.md`, and `progress.md`.

Verification evidence:

- Online `npm audit` / clean `npm ci --ignore-scripts` for both backends: **zero vulnerabilities**; installed dependency trees resolve `qs` 6.16.0 and Gaxios's `uuid` 11.1.1.
- `npx --yes --package=node@22 node --test tools/node_security.test.cjs`: **10/10 passed** on the declared Functions runtime, including authenticated validation with mocked Firebase tokens and no external payment requests.
- Windows equivalents of `init.sh`: `flutter pub get`, `flutter analyze` (**no issues**), `flutter test` (**161 passed**). The installed newer Flutter SDK refreshed five SDK-pinned transitive packages locally; that generated `pubspec.lock` change was discarded to keep this commit scoped to npm/backend security.
- `node --check functions/index.js`, `node --check server/src/index.js`, `node tools/verify_seo.mjs`, and `git diff --check`: passed.

Remaining risks / next step: no live Firebase deployment or Stripe invoice creation was performed. Before enabling the optional Cloud Function, set the Secret Manager `STRIPE_SECRET_KEY` as documented in `docs/info.md`; the old `stripe.secret` runtime config is no longer supported by Firebase v7. Revisit the UUID override when Gaxios ships a compatible patched dependency requirement. Product feature state remains unchanged.

### Architecture Diagram Added (2026-09-03)

- Added a Mermaid architecture diagram to `README.md`, covering delivery, Flutter Web layers, Firebase services and rules, plus free-tier and optional Stripe payment paths.
- Verified the README change with `git diff --check`.

### Free-tier Payment Hardening Completed (2026-09-02)

- Stripe Payment Links now require `https://buy.stripe.com` and receive the stable Firestore order ID through `client_reference_id` for Dashboard-to-order reconciliation.
- New orders move from `awaiting_checkout` to `checkout_created` only after the referenced Stripe URL is assembled and persisted.
- The incomplete LINE Pay button and client checkout flow were removed from the user interface; the Firebase `linePayRequest` export was removed because it reserved payment without completing LINE Pay confirmation.
- The dormant Stripe Cloud Function now allowlists the three supported amounts, accepts only Stripe/TWD, derives email and UID from the verified Firebase token, and uses server-owned plan descriptions.
- Free-tier operation remains manual: an administrator verifies the Stripe test/live payment against the order reference before marking an order `paid`.

Verification evidence:

- `flutter analyze` — no issues.
- Payment-targeted suite — all 74 tests passed.
- Full `flutter test` — all 161 tests passed.
- `flutter build web --release --base-href /warmmemo/` with the existing Stripe test Payment Link — passed; only the existing WebAssembly dry-run incompatibility warnings from `printing`/`ffi` and `image` were emitted.
- `node --check functions/index.js`, `node tools/verify_seo.mjs`, and `git diff --check` — passed.
- Live Stripe sandbox verification — the NT$120,000 test Payment Link accepted Stripe's public `4242` card with a fake test email and redirected to the deployed WarmMemo homepage without browser errors; no real charge was created.

### SEO/AEO Discoverability Completed (2026-09-02)

- Added crawlable product and FAQ pages with matching Organization, WebApplication, Article, and FAQ structured data.
- Expanded the digital-obituary and package-comparison guides with people-first explanatory content, internal navigation, canonical metadata, and social previews.
- Added `llms.txt` and `ai.txt` summaries for answer-engine discovery while keeping private/public memorial hash routes out of the sitemap.
- Removed placeholder public contact and social-account metadata that could weaken trust signals.
- Added `tools/verify_seo.mjs` and a CI step that validates sitemap targets, canonical URLs, language/title/description/H1 metadata, JSON-LD syntax, robots.txt, and answer-engine files.

Verification evidence:

- `node tools/verify_seo.mjs` — passed for all 6 sitemap URLs.
- `flutter analyze` — no issues.
- `flutter test` — all 160 tests passed.
- `flutter build web --release --base-href /warmmemo/` — passed; expected WebAssembly dry-run warnings remain from `printing`/`ffi` and `image`, while the JavaScript release build completed.
- Built artifact comparison confirmed `about.html`, `faq.html`, `llms.txt`, `ai.txt`, `robots.txt`, `sitemap.xml`, `obituary-guide.html`, and `package-comparison.html` were copied byte-for-byte into `build/web`.
- Live pre-change check confirmed the deployed `robots.txt`, sitemap, obituary guide, and package comparison returned HTTP 200. Search-result checks did not surface WarmMemo, so Search Console/Bing submission remains an external follow-up after deployment.

Files changed:

- `.github/workflows/ci.yml`
- `feature_list.json`
- `progress.md`
- `tools/verify_seo.mjs`
- `web/index.html`
- `web/about.html`
- `web/faq.html`
- `web/obituary-guide.html`
- `web/package-comparison.html`
- `web/privacy-policy.html`
- `web/sitemap.xml`
- `web/llms.txt`
- `web/ai.txt`

### What Is Complete

- The project has a lightweight agent harness: root instructions, feature state, progress logging, handoff guidance, and a fail-fast verification entrypoint.
- The English and Traditional Chinese READMEs are available as `README.md` and `README-zh.md`.

### Verification Evidence

- `node C:\Users\150592\.agents\skills\harness-creator\scripts\validate-harness.mjs --target D:\Practice\warmmemo` — passed, 100/100 across instructions, state, verification, scope, and lifecycle.
- Browser QA against `https://leo0331.github.io/warmmemo/` — guest landing, sign-in and registration validation, invalid credentials, malformed public links, and refresh behavior exercised. Same-tab navigation from the landing page to `#/m/qa-nonexistent-slug-20260901` reproduced an uncaught `Null check operator used on a null value` twice and returned to the landing page instead of the public-memorial unavailable state.
- Fix verified locally: `AuthGate` now rebuilds on browser hash/history changes through conditional web route-change listeners. `flutter analyze` completed with no issues and `flutter test` passed all 159 tests using `D:\Practice\flutter`. The release compiler emitted `build/web/main.dart.js`; the browser client blocked loopback testing with `ERR_BLOCKED_BY_CLIENT`, so the final browser regression must run from a normal local browser or deployed preview.
- Content polish pass: landing, account access, and public memorial/obituary pages now use clearer action language, less alarming sensitive-language phrasing, and actionable unavailable-link guidance. `flutter analyze` completed with no issues and `flutter test` passed all 159 tests.
- Remaining content polish pass: packages/checkout, skills, final-countdown planning, and admin operation screens now explain status, next steps, and estimates in plain language. Updated skills widget expectations match the new action labels. `flutter analyze`, the affected skills suite, and the full 159-test suite passed.

### Files Changed in This Session

- `AGENTS.md`
- `docs/harness/README.md`
- `feature_list.json`
- `progress.md`
- `session-handoff.md`
- `init.sh`
- Browser QA evidence recorded; the subsequent routing fix is limited to `AuthGate` and its web-only route-change helper.
- `lib/features/auth/auth_gate.dart`
- `lib/core/utils/browser_route_changes_stub.dart`
- `lib/core/utils/browser_route_changes_web.dart`
- `docs/flow.md`
- `lib/features/landing/landing_page.dart`
- `lib/features/auth/auth_page.dart`
- `lib/features/memorial/public_memorial_page.dart`
- `lib/features/obituary/public_obituary_page.dart`
- `lib/features/packages/packages_tab.dart`
- `lib/features/packages/checkout_page.dart`
- `lib/features/skills/skill_generator_tab.dart`
- `lib/features/final_countdown/final_countdown_tab.dart`
- `lib/features/admin/admin_dashboard.dart`
- `lib/features/admin/order_detail_page.dart`
- `test/skill_generator_tab_test.dart`

### Blockers

- None.

### Recommended Next Step

1. For product work, set `activeFeatureId` to one planned item and replace this entry with that feature's evidence.
2. Run a browser check from a normal local browser or deployed preview that changes from the landing page to a `#/m/<slug>` link in the same tab.
3. Run `./init.sh` (or its equivalent Flutter commands on Windows) before broad implementation work.
