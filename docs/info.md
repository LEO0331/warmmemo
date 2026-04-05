# WarmMemo — AI Reference Document

This file is intended for AI assistants resuming work on this project.
Read this alongside `docs/progress.md` before starting any task.
For workflow rules and coding conventions, see `claude.md` at the project root.
For a human-readable button-by-button flow diagram, see `docs/flow.md`.

---

## Project Identity

- **Name**: WarmMemo
- **Type**: Flutter Web + Firebase application
- **Purpose**: 提供紀念頁、訃聞草稿、商務訂單流程（提案到交付）與 Admin 管理能力
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

PDF 匯出字型策略（on-demand）：
1. `PdfGoogleFonts.notoSerifHKRegular/Bold`
2. `assets/fonts/NotoSansTC-Subset.ttf`（若存在）
3. `assets/fonts/NotoSansTC-VariableFont_wght.ttf`
4. Helvetica fallback

影響：
- 首屏載入更快。
- 若網路受限且本地 subset 不存在，PDF 可能回退字型。

---

## File Map (High Value)

- `lib/features/auth/auth_gate.dart`
- `lib/features/landing/landing_page.dart`
- `lib/features/memorial/memorial_page_tab.dart`
- `lib/features/obituary/digital_obituary_tab.dart`
- `lib/features/admin/admin_dashboard.dart`
- `lib/core/export/pdf_exporter.dart`
- `lib/core/export/compliance_exporter.dart`
- `lib/data/services/*`
- `lib/data/repositories/*`
- `firestore.rules`

---

## CI/CD

- CI workflow: `.github/workflows/ci.yml`
  - `flutter analyze`
  - `flutter test`
- Deploy workflow: `.github/workflows/deploy.yml`
  - Triggered after CI success on `main` (plus manual dispatch)
  - GitHub Pages artifact deployment + SPA fallback (`404.html`)

---

## Assistant Workflow

Before changing code:
1. Read `claude.md`
2. Read `docs/progress.md`
3. If user asks about behavior flow, align with `docs/flow.md`

After changing code:
1. Run `flutter analyze`
2. Run targeted tests (or full tests for release/demo)
3. Update docs when architecture/flow/progress materially changes

