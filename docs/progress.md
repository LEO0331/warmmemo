# WarmMemo — 專案進度紀錄

> 最後更新：2026-11-12

## 2026-11-12 Flutter CI 行覆蓋率

- 使用 Flutter 3.47.2 執行完整測試，最低行覆蓋率設為 92%。GitHub Actions 測得 92.44%（3,277 / 3,545），並提供保留 14 天的 LCOV 檔案。[覆蓋率政策](ci-coverage-policy.md) · [上線驗收稽核](production-readiness-audit-2026-11.md)
- PR #31 已合併至 `42c4976`。該版本通過主分支 CI 與 GitHub Pages 建置及部署。[CI](https://github.com/LEO0331/warmmemo/actions/runs/43164696341) · [LCOV](https://github.com/LEO0331/warmmemo/actions/runs/43164696341/artifacts/13918844345) · [部署](https://github.com/LEO0331/warmmemo/actions/runs/43164913849)

## 2026-11-12 紀念頁與訃聞 PDF 本機中文字型

- 已內建授權可追溯的 Noto Sans TC 正文及粗體子集。子集缺字時載入完整靜態字型，完整字型缺字時會提示該字元的 Unicode 代碼。
- Chrome 已驗證首屏無 PDF 字型請求、外網封鎖時可首次匯出，以及所需字型載入後完全離線時兩種 PDF 仍可下載。登入後的服務額度檢查沿用既有流程。[測試與限制](offline-chinese-pdf-font.md)
- PR #32 修正共用字形造成的 PDF 字元替換。修正已通過 178 項 Flutter 測試及 Chrome 離線匯出驗證，目前待審查及合併。[PR #32](https://github.com/LEO0331/warmmemo/pull/32)

## 2026-11-12 人生倒數：財務基礎與人生體驗

- 預設收合的中英文區塊可估計目前淨資產與現金緩衝。目標月數由使用者自行選擇，未填金額也可使用家庭、旅行、學習與貢獻的體驗反思。
- 終身資源、支出與差額採用原本公式，沿用既有的生活目標對齊度與本機草稿。新增的財務快照僅存在當次使用期間的記憶體。[欄位、公式、隱私與驗證](final-countdown-financial-footing.md)

## 2026-11-02 Dependabot applicability review

Read all five open alerts through GitHub's authenticated Dependabot API; checked both backend lockfiles against the current npm advisory database.

| Finding | Applicability and action |
| --- | --- |
| #73, `qs`, [GHSA-6pq8-jhm2-2vcw](https://github.com/advisories/GHSA-6pq8-jhm2-2vcw) | No application call to the vulnerable comma-array serializer; Express query parsing does not trigger it. Applied the compatible preventive patch to 6.16.2 in both backends, including the server copy reported by npm. |
| #74/#78, `glob`, [GHSA-3g3m-2fjr-6pw4](https://github.com/advisories/GHSA-3g3m-2fjr-6pw4) | No application glob traversal or AbortSignal-based glob timeout. Present through optional Firestore dependencies and `rimraf`; no runtime `rimraf` calls found in the installed Google clients. Retained 10.5.0; the published fix requires major 14. |
| #75/#79, `minimatch`, [GHSA-g3hv-75wg-m249](https://github.com/advisories/GHSA-g3hv-75wg-m249) | Same unused chain; no attacker-controlled glob patterns reach it. Retained 9.0.9; the published fix requires major 11. |
| Additional npm finding: `body-parser`, [GHSA-27r3-jxmh-p828](https://github.com/advisories/GHSA-27r3-jxmh-p828) | Both backend entrypoints call `express.json()` with default decompression before authentication. Patched the Express 4 copies from 1.20.8 to 1.20.9 and Firebase Functions' nested Express 5 copy from 2.3.0 to 2.4.0. |

- No application behavior, manifests, major versions, or overrides changed. The existing Admin app/auth imports do not load Firestore, `glob`, `minimatch`, or `rimraf`. Reassess the deferred alerts if filesystem globbing is introduced or upstream compatible updates remove the chain.
- Added five regression tests: all three parser copies receive compressed JSON with trailing bytes, and both `qs` copies receive comma arrays containing a shadowed `toString`. All five failed on the old installed versions; all 17 backend tests passed after clean installs on Node.js 22.23.3.
- Flutter dependency initialization passed, analysis reported no issues, and all 161 Flutter tests passed. Discarded only the generated SDK-pinned `pubspec.lock` refresh to retain the existing Dart dependency scope.
- Before pushing, rebased onto latest main (`6ed9adb`), retaining Dependabot's already-merged parser/server fixes and nested Firebase Functions `qs` 6.17.1. The final dependency diff updates only Functions' root `qs` to 6.16.2.
- Both online npm audits now report zero high/critical findings and no `body-parser` or `qs` findings. Six moderate package findings remain per backend, all from the deferred `glob`/`minimatch` chain and its parents. GitHub alerts were not dismissed; closure of #73 requires merging the lockfile change to the default branch. No backend deployment was performed.

## 2026-10-12 Proxy trust dependency patch

- Updated both npm backend lockfiles from `proxy-addr` 2.0.7 to 2.0.8 for Dependabot alert #71 (GHSA-jqcg-44mw-7w3h), with no other dependency version or application behavior changes.
- Added two regression tests that reproduce IPv6 trust-subnet IP spoofing on 2.0.7 and pass on 2.0.8. Clean backend installs passed; all 12 Node.js 22 security/compatibility tests passed; Flutter analysis reported no issues.
- Before pushing, integrated the latest main commits, which already included the Functions `proxy-addr` patch and separate `@fastify/busboy` fixes. Clean installs/audits now report zero vulnerabilities in both backends; all 12 Node.js 22 tests passed again. No live backend deployment was performed.

## 2026-10-02 Dependency security maintenance

- Reviewed all eight open Dependabot alerts; both npm backends now resolve patched `qs` 6.16.0 and Gaxios's `uuid` 11.1.1. Online npm audits report zero vulnerabilities.
- Updated removed Firebase Functions/Admin APIs after earlier SDK upgrades, and added ten passing Node.js 22 regression tests to CI. Flutter analysis and all 161 Flutter tests passed.
- The optional Cloud Function now requires the Secret Manager `STRIPE_SECRET_KEY` before deployment; see `docs/info.md` for setup. No live backend deployment or payment operation was performed.

---

## 專案簡介

WarmMemo 是 Flutter Web + Firebase 應用，目標是把「紀念內容準備 + 商務訂單流程」整合成可追蹤、可管理、可交付的產品。

核心商務路徑：`提案 -> 審核 -> 供應商指派 -> 材質確認 -> 排程/交付`。

---

## 技術棧

| 項目 | 說明 |
|------|------|
| Frontend | Flutter Web |
| Backend | Firebase Auth + Firestore |
| Data layer | Service + Repository（request policy / cache / optimistic） |
| CI | GitHub Actions (`ci.yml`) |
| CD | GitHub Pages (`deploy.yml`) |

---

## 目前進度（v0.2）

### 已完成

| 模組 | 狀態 | 備註 |
|------|------|------|
| V2 商務作業區 | ✅ | 供應商管理、材質確認、交付排程 |
| 漏斗指標 | ✅ | 提案率/審核率/指派率/交付率 + 每週趨勢 |
| 輸入 guardrails | ✅ | 日期/數字/文字清理 + 欄位級錯誤提示 |
| QR/公開頁流程 | ✅ | 公開連結路由與分享流程修正 |
| 測試穩定性 | ✅ | off-screen tap warning 已清理 |
| CI/CD | ✅ | CI 通過後才部署 Pages |
| 文件基礎 | ✅ | `docs/flow.md`, `docs/info.md`, `docs/progress.md`, `claude.md` |

---

## 近期變更摘要

1. **Harness engineering layer**
- 新增 repo-local `AGENTS.md`，作為短版任務路由入口。
- 新增 `docs/harness/`，把 task routing / verification / harness review 與產品文件分離。
- `claude.md` 改為 pointer file，避免形成第二份逐漸膨脹的主指令檔。

2. **GitHub Pages 部署強化**
- 改為 GitHub 官方 Pages actions。
- 加入 SPA fallback (`404.html`) 與 `.nojekyll`。
- Deploy 由 CI success 觸發。

3. **字型載入策略優化**
- Web UI 不再啟動時綁大型中文字型。
- 匯出改為 on-demand 字型解析（Google fonts -> subset -> full -> fallback）。

4. **Landing 內容優化**
- 搜尋友善區塊改為圖文卡片。
- 指定文案對應圖片已替換。

5. **人生倒數頁升級（Die with Zero）**
- 新增健康自評表（五面向，現況/目標）。
- 新增三軸比較（健康/財務/壽命）與綜合「Die with Zero 準備度」。
- 新增記憶體驗清單（完成度/滿意度）與類別分佈（家庭/旅行/學習/貢獻）。

6. **跨平台 stub 與測試覆蓋提升**
- `download_text_stub.dart` 增加可測試注入點與 fallback 路徑。
- `import_json_stub.dart` 明確非 web 平台錯誤語意。
- 新增 `test/core_utils_stub_test.dart`，覆蓋 stub 主要分支。

---

## 已知風險 / 限制

- 紀念頁與訃聞 PDF 首次離線匯出前，須先載入該份內容所需的應用程式字型資源。[離線 PDF 驗證與限制](offline-chinese-pdf-font.md)
- GitHub Pages 若瀏覽器快取舊 service worker，可能仍短暫請求舊資源（需 hard refresh）。

---

## 下一步建議

- 補入真正的 `assets/fonts/NotoSansTC-Subset.ttf`（可離線穩定匯出中文）。
- 在 CI 增加 coverage artifact 與閾值檢查。
- 增加 release checklist 腳本化（analyze/test/build 一鍵執行）。
