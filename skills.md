# WarmMemo Skills Prompt (Project Template)

目的：把本專案可重用的產品/技術做法整理成可持續更新的提示模板，供人或 AI 在新專案快速複製。

## 使用方式

- 在開新專案或新功能時，先貼上本文件內容作為系統/開發提示。
- 每次重大改版後更新本文件（流程、資料模型、限制、驗收）。
- 搭配 `docs/flow.md` 與 `docs/progress.md` 一起維護。

## 1) 產品目標模板

- 目標：先交付可運營版本（feature first），再補回歸與深度測試。
- 商業漏斗：`提案 -> 審核 -> 供應商指派 -> 材質確認 -> 排程建立/交付`。
- 指標：提案率、審核通過率、指派完成率、交付完成率、每週趨勢。

## 2) 技術架構模板

- UI 層：保持既有風格，避免大改框架。
- Data 層：Repository 封裝 service + cache + request policy。
- 效能：TTL cache + in-flight 去重 + debounce。
- 低延遲：optimistic update + rollback。
- 強健性：統一錯誤分類（network/permission/validation/unknown）。

## 3) Guardrails 模板

- 寫入前檢核：日期、數字、文字長度、非法字元。
- 禁止空提交/重複提交。
- 欄位級錯誤訊息需可讀且不破壞版面。

## 4) 部署模板

- CI：PR/main 跑 `flutter analyze` + `flutter test`。
- CD：部署只在 CI success 後執行。
- Web：SPA fallback（`404.html`）、`.nojekyll`、可手動重部署。

## 5) 匯出/字型模板

- Web 首屏不綁大字型。
- 匯出時才載入 CJK 字型：
  - 優先小字型（on-demand）
  - 其次本地 subset
  - 最後 fallback

## 6) 驗收模板

- 最低門檻：`flutter analyze` pass、`flutter test` pass。
- 核心 smoke flow：登入、紀念頁公開連結/QR、訃聞生成、Admin 指派與排程。

## 7) 更新規則

- 每次版本更新需同步調整：
  - 本文件（`skills.md`）
  - `docs/flow.md`
  - `docs/progress.md`
- 若商業規則有變更，先更新資料契約與 Firestore 規則說明，再改 UI。

