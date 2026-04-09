# WarmMemo — 專案進度紀錄

> 最後更新：2026-04-09

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

1. **GitHub Pages 部署強化**
- 改為 GitHub 官方 Pages actions。
- 加入 SPA fallback (`404.html`) 與 `.nojekyll`。
- Deploy 由 CI success 觸發。

2. **字型載入策略優化**
- Web UI 不再啟動時綁大型中文字型。
- 匯出改為 on-demand 字型解析（Google fonts -> subset -> full -> fallback）。

3. **Landing 內容優化**
- 搜尋友善區塊改為圖文卡片。
- 指定文案對應圖片已替換。

4. **人生倒數頁升級（Die with Zero）**
- 新增健康自評表（五面向，現況/目標）。
- 新增三軸比較（健康/財務/壽命）與綜合「Die with Zero 準備度」。
- 新增記憶體驗清單（完成度/滿意度）與類別分佈（家庭/旅行/學習/貢獻）。

5. **跨平台 stub 與測試覆蓋提升**
- `download_text_stub.dart` 增加可測試注入點與 fallback 路徑。
- `import_json_stub.dart` 明確非 web 平台錯誤語意。
- 新增 `test/core_utils_stub_test.dart`，覆蓋 stub 主要分支。

---

## 已知風險 / 限制

- 若外網受限且本地 subset 字型不存在，PDF 中文可能退回不完整字型。
- GitHub Pages 若瀏覽器快取舊 service worker，可能仍短暫請求舊資源（需 hard refresh）。

---

## 下一步建議

- 補入真正的 `assets/fonts/NotoSansTC-Subset.ttf`（可離線穩定匯出中文）。
- 在 CI 增加 coverage artifact 與閾值檢查。
- 增加 release checklist 腳本化（analyze/test/build 一鍵執行）。
