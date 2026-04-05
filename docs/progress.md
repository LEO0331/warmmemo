# 專案進度紀錄

## 目前里程碑

- V2 商務作業區：已落地
  - 供應商管理（啟停、主檔）
  - 材質選單（tier/價格帶）
  - 交付排程（三里程碑）
  - 提案到交付漏斗指標與每週趨勢
- UX/Guardrails：已加強
  - 輕量 loading/error states
  - 輸入清理與欄位級錯誤提示
  - 可選取文字（多頁）與引導調整
- 測試與品質：已提升
  - `flutter analyze`: pass
  - 全量測試：pass
  - 目標資料夾 coverage 已提升（core/theme、data/models）
- Web 部署：已改為 GitHub Actions
  - `ci.yml`：PR/main 跑 analyze + test
  - `deploy.yml`：僅 CI success 後部署 Pages

## 近期優化

- 修正 `final_countdown_tab_test` 兩個 off-screen tap warning（改為 scroll+tap）。
- Landing 搜尋友善區塊加入圖片卡。
- 字型載入策略調整，降低 Web 首載卡頓。

## 進行中 / 待辦

- 可選：提供真正的 `NotoSansTC-Subset.ttf`（本地字型子集）以提升離線匯出穩定性。
- 可選：為 CI 加入 coverage report artifact 與最低門檻檢查。
- 可選：補強 smoke checklist 文件（demo/上線前）。

## 風險備註

- 若未提供 subset 字型且外網受限，PDF 匯出可能降級到 Helvetica（中文可能缺字）。
- GitHub Pages 需設定為 `GitHub Actions` source 才會正確走新部署流程。

