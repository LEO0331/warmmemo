# Session Progress Log

## Offline Traditional Chinese PDF Fonts (2026-11-12)

- Fetched `origin/main` at `f2c5dfcf8e9d402a44ba010a10660cc560058a5f`. Final Countdown is complete. The offline PDF font and CI coverage features were both still planned.
- Baseline on Flutter 3.47.2: `flutter pub get` passed, `flutter analyze --no-pub` found no issues, and all 173 Flutter tests passed.
- Replaced the two byte-identical source assets with reproducible SIL OFL 1.1 fonts from a checksum-pinned Google Fonts release. The two subsets total 61,996 bytes, and the full font covers 20,745 Unicode code points in 7,149,192 bytes. Regenerating the assets reproduced the hashes.
- Updated the two PDF exports and the compliance PDF's existing local fallback. Registered assets explicitly, added byte-generation seams, glyph validation, four focused tests and a browser smoke fixture. Updated the READMEs, flow and architecture docs.
- Post-change analysis reported no issues and all 177 tests passed. The production and fixture JavaScript release builds succeeded. The production startup made zero PDF font requests. Chrome passed both cold exports with external requests denied and both downloads fully offline after loading the assets, without a service worker. Rendered PDF pages showed legible mixed text, both uncommon glyphs, and the memorial QR. Outputs were 12,681 and 10,879 bytes.
- The browser fixture exercised the production exporters and sharing wrappers with synthetic drafts. Signed-in export buttons still have their service-token preflight, and the current PDF writer can omit supplementary characters from extracted text even when they render. [Offline PDF guide](docs/offline-chinese-pdf-font.md)
- Next step: review the offline PDF draft PR. Coverage is tracked separately from main.

## Current State (Last Updated: 2026-11-12)

**Current Objective:** `final-countdown-financial-footing` — optional current financial context for the Final Countdown planner.

**Status:** Implementation and feature verification complete. Ready for draft PR review.

**Baseline:** Fetched `origin/main` and created `codex/final-countdown-wealth-aware-planning` at `27f0a5318bd18846df667ad420988fdec7ea53a9`.

- Added `financial_footing_model.dart`, `financial_footing_card.dart`, and focused model and widget tests. Updated `final_countdown_tab.dart` to put the lifetime projections before the optional section and distinguish projections from present-day balances. The lifetime calculations, readiness weights, and `final_countdown_tab_v1` format are preserved.
- The snapshot uses only explicitly entered inputs and remains in memory. The optional target compares the estimated cash-buffer months with the user's own buffer assumption. There is no snapshot dependency in Firebase, analytics, public sharing or exports.
- Updated `feature_list.json`, both READMEs, `docs/flow.md`, `docs/progress.md`, and the [financial footing guide](docs/final-countdown-financial-footing.md).
- Windows equivalent of `init.sh` before implementation: `flutter pub get` succeeded, `flutter analyze --no-pub` reported no issues, and `flutter test --no-pub` passed 161 tests. The installed Flutter SDK refreshed five pinned transitive versions in the local lockfile during verification.
- Focused desktop tests passed: 10 model tests and 2 widget tests, including prior draft loading, preserved readiness, session isolation and keyboard/semantics at a 360 px viewport.
- Post-change `flutter analyze --no-pub` reported no issues and `flutter test --no-pub` passed 173 tests. The legacy-draft widget fixture exposed a Material ink ancestor assertion in the experience checkbox, fixed with a transparent Material wrapper.
- `flutter build web --no-pub --release --base-href /warmmemo/` built the JavaScript release bundle with default payment configuration. The Wasm dry run reported the existing `printing`/`ffi` and `image` incompatibilities.
- Focused `flutter test --platform chrome` stalled during browser setup. Headless Chrome reported an HTTP load failure for the Flutter test runner's local `/canvaskit/chromium/canvaskit.js` and its Wasm asset. Stopped that runner before it could execute test assertions.
- An isolated web build of `FinalCountdownTab` with bundled CanvasKit passed a Playwright smoke check using installed Chrome at 360 px. Verified collapsed-by-default behavior, all six labeled fields, NT$−40,000 estimated net worth, a three-month cash buffer against a four-month target, and an empty browser local-storage area after entry.
- The pinned Patrol CLI started its web server, then stalled downloading Playwright Chromium. Ran the existing cases with Playwright and installed Chrome against that server. Three of four passed. The landing CTA case still expects `開始規劃`, while the baseline renders `開始整理`. The unrelated smoke mismatch is recorded in `session-handoff.md`.
- `git diff --check` passed. The SDK-generated lockfile refresh and temporary smoke harness are excluded from the feature.

Recommended next step: Review the draft PR, with particular attention to the projection labels and the distinction between current liquidity and lifetime resources.

### PR #27 CI Flutter SDK Pin (2026-11-12)

- The Analyze step in GitHub Actions job `130883709292` selected Flutter 3.50.0 and exited on 29 Material import and localization deprecations. The Test step was skipped.
- Pinned `.github/workflows/ci.yml` to Flutter 3.47.2 and documented the pin in `docs/info.md`. The official Linux release manifest lists that version on the stable channel.
- On Flutter 3.47.2, dependency resolution and sitemap verification passed, `flutter analyze --no-pub` reported no issues, and `flutter test --no-pub` passed all 173 tests. The generated SDK-only lockfile refresh was excluded.

### Dependabot Applicability Review Completed (2026-11-02)

Objective: Review the repository's current Dependabot warnings and patch dependencies relevant to the project's usage without changing workflows.

- Read all five open alerts using the authenticated GitHub REST API. Alert #73 (`qs`, GHSA-6pq8-jhm2-2vcw) is patched in both backend lockfiles with the compatible 6.16.2 release. The vulnerable comma-array serialization is not used by application code, but the patch is worthwhile preventive maintenance.
- Online npm audits found an additional directly applicable high-severity issue: GHSA-27r3-jxmh-p828. Both backends use default `express.json()` decompression before authentication. Updated their `body-parser` 1.20.8 copies to 1.20.9 and Firebase Functions' nested 2.3.0 copy to 2.4.0.
- Deferred #74/#78 (`glob`) and #75/#79 (`minimatch`): no reachable application use or attacker-controlled pattern path was found. These packages enter through optional Firestore dependencies and unused `rimraf` dependencies in Google clients; the actual Admin app/auth imports do not load them. Published fixes require major-version jumps. No overrides, manifests, business logic, or deployment settings changed. Detailed triage is in `docs/progress.md`.
- Before pushing, rebased onto `origin/main` (`6ed9adb`), which already included Dependabot's three `body-parser` patches and the server `qs` patch. Preserved its nested Firebase Functions `qs` 6.17.1 resolution. The final dependency diff updates only the Functions root `qs` to 6.16.2; regression tests and the applicability review cover both backends. A fresh Functions install and all 17 Node.js 22 tests passed again after integration.
- Changed files relative to the updated main: `functions/package-lock.json`, `tools/node_security.test.cjs`, `docs/info.md`, `docs/progress.md`, and `progress.md`.

Verification evidence:

- Five new regression tests all failed against the old installed versions: three uncaught compressed-body decoder errors and two `qs` serialization exceptions. After clean `npm ci --ignore-scripts` installs for both backends, all **17/17 Node.js 22.23.3 tests passed**, including existing authentication and validation tests. `npm ls body-parser qs` confirms all parser copies and shared `qs` resolutions are patched.
- Both online npm audits now report **zero high/critical findings** and no `body-parser` or `qs` findings. Six moderate package findings remain per backend, all from the deferred `glob`/`minimatch` chain and its parents; audit exits nonzero for those known findings.
- Windows equivalents of `init.sh`: `flutter pub get` passed, `flutter analyze --no-pub` reported **no issues**, and `flutter test --no-pub` passed **161/161 tests**. The local newer SDK refreshed five SDK-pinned transitive Dart packages; discarded only that generated `pubspec.lock` diff to keep the requested npm maintenance focused.
- `git diff --check`: passed. Initial sandbox npm DNS access failed and Flutter startup could not acquire its SDK cache lock; retries with the required access passed. The npm installer is Node.js 24, so it emitted the expected Functions Node.js 22 engine warning; runtime verification used Node.js 22 explicitly.

Blockers: none for the scoped fixes. No alerts were dismissed and no live backend deployment was performed.

Recommended next step: merge the patched lockfiles to the default branch for GitHub to close #73, and deploy the patched backends wherever enabled. Reassess the four deferred alerts when a compatible upstream fix removes the dependency chain or application filesystem-globbing usage changes. Product feature state remains unchanged.

### Proxy Trust Dependency Patch Completed (2026-10-12)

Objective: Fix Dependabot alert #71 (GHSA-jqcg-44mw-7w3h) by updating `proxy-addr` to 2.0.8 in both backend lockfiles.

- Both backend lockfiles now resolve `proxy-addr` 2.0.8. Before pushing, rebased onto `origin/main` (`da3440e`), which already contained the Functions patch and separate `@fastify/busboy` fixes. This commit changes only the server's `proxy-addr` package entry. Existing dependency ranges accept the patch, so no manifest changes, overrides, or new dependencies were needed.
- Added regression coverage in `tools/node_security.test.cjs` for spoofed forwarding through short IPv4-mapped IPv6 and zero-prefix IPv6 trust subnets, plus correctly configured IPv4 and mapped IPv6 subnets. Both new tests failed on installed 2.0.7 and passed after installing 2.0.8.
- Updated `docs/progress.md` and this log. No application workflow or configuration changes; no refactor was needed.

Verification evidence:

- Clean `npm ci --ignore-scripts` installs passed for both backends. `npm ls proxy-addr` confirms 2.0.8 for server Express, Functions Express, and Firebase Functions' nested Express.
- `npx --yes --package=node@22 node --test tools/node_security.test.cjs`: **12/12 passed**, including local HTTP authentication and validation checks.
- `flutter analyze --no-pub`: **no issues**. Full Flutter tests were not run for this focused npm lockfile/test change.
- Initial online audits reported separate `@fastify/busboy` findings. After integrating the already-merged Dependabot fixes, clean installs/audits report **zero vulnerabilities** in both backends, and all 12 Node.js 22 tests pass again.
- `git diff --check`: passed. Initial sandbox-only npm access and local HTTP checks were blocked by network restrictions; rerunning with the necessary access succeeded.

Remaining risks / next step: no live backend deployment or payment operation was performed; GitHub alert closure requires the patched lockfile to reach the default branch. Product feature state remains unchanged.

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
