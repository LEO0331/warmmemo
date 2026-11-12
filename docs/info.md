# WarmMemo — AI Reference Document

This file is intended for AI assistants resuming work on this project.
Read this alongside `docs/progress.md` before starting any task.
For project-local agent routing, see `AGENTS.md` at the project root.
For tool-specific fallback guidance, see `claude.md`.
For a human-readable button-by-button flow diagram, see `docs/flow.md`.

---

## Project Identity

- **Name**: WarmMemo
- **Type**: Flutter Web + Firebase application
- **Purpose**: 提供紀念頁、訃聞草稿、商務訂單流程（提案到交付）與 Admin 管理能力
- **Current expansion**: 人生倒數頁已擴充健康自評、三軸目標比較與記憶分佈統計
- **Primary use case**: 家屬與禮儀服務團隊協作，縮短從提案到交付的流程時間
- **Tech stack**: Flutter, Firebase Auth, Cloud Firestore, GitHub Actions (CI/CD)

---

## Problem Context

傳統流程常見問題：
- 家屬資訊分散、內容反覆確認
- 訂單狀態不透明，客服回覆成本高
- 供應商與材質決策缺乏一致資料

WarmMemo 目標：
- 將內容準備、提案、審核、指派、排程串成可追蹤流程
- 讓前台與後台在同一資料契約下運作

---

## Runtime Layers

| Layer | 主要位置 | 職責 |
|------|---------|------|
| UI | `lib/features/*` | 顯示頁面、按鈕事件、局部 loading/error、文案互動 |
| Data | `lib/data/services/*`, `lib/data/repositories/*` | 查詢/寫入封裝、快取與 request policy、optimistic 更新 |
| Backend | Firebase Auth + Firestore | 身份驗證、資料持久化、權限規則 |

---

## Key Entry and Routing

- Entry: `lib/main.dart`
- Runtime gate: `lib/features/auth/auth_gate.dart`
  - `#/m/:slug` -> `PublicMemorialPage`
  - `#/o?...` -> `PublicObituaryPage`
  - default -> auth state routing (`AppShell` / `LandingPage`)

---

## Business Workflow Contract (V2)

`proposal -> admin review -> vendor assignment -> material confirmation -> delivery schedule`

主要資料欄位（`Purchase` 擴充）：
- `proposal`
- `vendorAssignment`
- `materialSelection`
- `deliverySchedule`

Admin 主檔：
- `vendors`

權限原則：
- User writable: `proposal`
- Admin writable: `vendorAssignment`, `materialSelection`, `deliverySchedule`, `vendors`

---

## Export / Font Strategy

UI 字型策略：
- Web 首屏不綁大型中文字型，使用系統 fallback，降低首載時間。

紀念頁與訃聞 PDF 在匯出時才讀取本機 Noto Sans TC。正文與標題優先使用各自的子集，任何字元超出子集涵蓋範圍時改用完整本機字型。匯出會回報缺少的 Unicode 字元或無法載入的字型資源。[字型來源、重建與驗證](offline-chinese-pdf-font.md)

管理員的合規 PDF 仍優先使用 Google Fonts，本機備援採用完整 Noto Sans TC。

---

## File Map (High Value)

- `lib/features/auth/auth_gate.dart`
- `lib/features/landing/landing_page.dart`
- `lib/features/memorial/memorial_page_tab.dart`
- `lib/features/obituary/digital_obituary_tab.dart`
- `lib/features/admin/admin_dashboard.dart`
- `lib/features/final_countdown/final_countdown_tab.dart`
- `lib/core/export/pdf_exporter.dart`
- `lib/core/export/compliance_exporter.dart`
- `lib/data/services/*`
- `lib/data/repositories/*`
- `firestore.rules`

---

## CI/CD

### Optional Node backends

- `server/` requires Node.js 20 or newer; `functions/` targets the Firebase Node.js 22 runtime.
- Both backends require Express 4.22.3 or newer within major 4. Their lockfiles resolve patched `qs` 6.16.2 and `body-parser` 1.20.9; Firebase Functions' nested Express 5 resolves `qs` 6.17.1 and `body-parser` 2.4.0. Gaxios alone overrides `uuid` to 11.1.1, which fixes buffer bounds checks while retaining CommonJS support. Recheck Gaxios compatibility before removing or changing this override.
- The optional first-generation `createInvoice` function uses `firebase-functions/v1` and binds the Secret Manager secret `STRIPE_SECRET_KEY`. Before enabling this backend, configure it with `firebase functions:secrets:set STRIPE_SECRET_KEY`; the removed `functions.config().stripe.secret` setting is no longer read. Local emulation can supply the same variable through an ignored `functions/.secret.local` file.
- Both backends use the modular `firebase-admin/app` and `firebase-admin/auth` APIs required by Admin 14.
- Run `npm ci --prefix server --ignore-scripts`, `npm ci --prefix functions --ignore-scripts`, then `node --test tools/node_security.test.cjs`. CI runs these checks on Node.js 22; they exercise the patched dependency behavior (including compressed-body trailing bytes), both backend entrypoints, and authentication/validation without external payment calls. See `docs/progress.md` for the 2026-11-02 applicability assessment of deferred optional Firestore `glob`/`minimatch` findings.

- CI workflow: `.github/workflows/ci.yml`
  - Uses Flutter 3.47.2 for reproducible analysis and tests. Revisit the pin when the app migrates its Material imports and localization delegates for Flutter 3.50.
  - `flutter analyze`
  - `flutter test --coverage`, a 92% line coverage gate, and a 14-day LCOV artifact. [Coverage policy](ci-coverage-policy.md)
- Deploy workflow: `.github/workflows/deploy.yml`
  - Builds and deploys only after successful `push` CI on `main` (or manual dispatch); PR CI completion must never publish.
  - Production-eligible runs share the `pages-production` concurrency group; ineligible runs use unique run-ID groups so a skipped PR-triggered deployment cannot cancel production.
  - Release builds use the same pinned Flutter 3.47.2 SDK as CI.
  - GitHub Pages artifact deployment + SPA fallback (`404.html`).
  - After a merge, verify the Pages workflow completed both `build` and `deploy` for the intended `main` commit SHA; passing CI alone does not prove deployment.

---

## Assistant Workflow

Before changing code:
1. Read `AGENTS.md`
2. Read `docs/progress.md`
3. If user asks about behavior flow, align with `docs/flow.md`
4. If the task is cross-cutting, read `docs/harness/task-routing.md`

After changing code:
1. Run `flutter analyze`
2. Run targeted tests (or full tests for release/demo)
3. Update docs when architecture/flow/progress materially changes

Recent documentation-relevant changes to keep in sync:
- Final countdown now stores extended keys in `final_countdown_tab_v1`:
  - `healthCurrent`, `healthTarget`
  - `targetEndBalance`, `targetLifeExpectancy`
  - `experienceItems` (with `category`, `completed`, `satisfaction`)
- Utility stubs with dedicated tests:
  - `lib/core/utils/download_text_stub.dart`
  - `lib/core/utils/import_json_stub.dart`
  - `test/core_utils_stub_test.dart`
