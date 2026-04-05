# WarmMemo — AI Project Guide

Flutter Web + Firebase 專案，目標是讓使用者完成紀念內容、訃聞與商務訂單流程管理（提案到交付）。

---

## 開始任何任務前，請先讀

1. `docs/info.md` — 完整技術架構、資料契約、部署與字型策略
2. `docs/progress.md` — 最新進度、限制與待辦
3. `docs/flow.md` — 以按鈕為單位的人類可讀流程

---

## 工作流程

1. 先理解使用者需求與影響範圍
2. 有高風險或多路徑時先對齊，再實作
3. 以最小變更完成需求，不破壞既有商業流程
4. 完成後做必要驗證與回報

---

## 文件更新規則

| 改動類型 | 需要更新 |
|---------|---------|
| 架構、資料契約、部署策略改動 | `docs/info.md` |
| 重要功能完成、風險/限制更新 | `docs/progress.md` |
| 按鈕流程或頁面行為改動 | `docs/flow.md` |
| 安裝/使用方式改動 | `README.md` |

---

## 技術規範（基本）

### 1) Business Safety

- 不可無故改動既有商業規則。
- 資料模型變更應保持向後相容（nullable/additive 優先）。
- Firestore 權限規則改動前需確認風險。

### 2) Code Quality

- 變更應最小且聚焦。
- 維持現有 UI/UX 風格，除非需求明確要重設計。
- 避免引入大規模框架重構。

### 3) Validation

- 每次程式修改後至少執行：`flutter analyze`。
- 有改測試就跑對應測試；發版前跑全量 `flutter test`。

### 4) Performance

- 降低不必要 re-render 與重複請求。
- 優先局部 loading/error，不阻塞整頁。
- Web 首屏避免綁大型字型或重量資產。

### 5) Input Guardrails

- 所有輸入（日期/數字/文字）都應做格式檢核與清理。
- 阻擋空提交、重複提交與非法型別寫入。
- 錯誤訊息要能回到欄位層級。

---

## CI/CD 準則

- CI（`.github/workflows/ci.yml`）必須通過後才能部署。
- Deploy（`.github/workflows/deploy.yml`）僅在 CI success（main）或手動觸發。
- Pages 需維持 SPA fallback（`404.html`）設定。

---

## 備註

- 若你是 AI assistant，請先輸出你將修改的檔案範圍，再進行實作。
- 若遇到外部依賴不穩（網路、字型下載、第三方 API），優先提供降級方案。

