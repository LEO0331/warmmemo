# 功能流程說明（Flow）

本文件用人類看得懂的方式說明：按下每個按鈕後，程式碼哪些部分會被執行、會發生什麼事。

## 1) 進站與登入

- 入口：`lib/features/auth/auth_gate.dart`
- 主要流程：
  - App 啟動後先進 `AuthGate`，判斷是否為公開頁路由（`#/m/:slug`、`#/o?...`）。
  - 若是公開頁：直接渲染公開紀念頁或公開訃聞頁。
  - 若不是公開頁：監聽 Firebase Auth 狀態。
  - 已登入：進 `AppShell`。
  - 未登入：進 `LandingPage` 或 `AuthPage`。

### 常見按鈕

- `登入 / 註冊`：呼叫 `AuthService`；成功後回到 `AuthGate` 進入內頁。
- `登出`：呼叫 `AuthService.signOut()`，回到未登入畫面。

## 2) 簡易紀念頁（Memorial）

- 主檔：`lib/features/memorial/memorial_page_tab.dart`
- 輸入欄位更新：先走輸入正規化（文字/日期/數字 guard），再進本地 state。
- `儲存草稿`：寫入 `FirebaseDraftService.load/saveMemorial` 對應資料。
- `發佈 / 關閉發佈`：更新 `slug`、公開狀態與公開資料。
- `QR / 公開連結`：組合 `_effectivePublicUrl`，可複製、下載 QR、開新頁。
- `提案送出`（商業作業區）：送出 `proposal`，再由 Admin 端接續審核/指派/排程。

## 3) 數位訃聞（Obituary）

- 主檔：`lib/features/obituary/digital_obituary_tab.dart`
- `產生訃聞文案`：組合輸入，呼叫生成流程（含點數檢查）。
- `一鍵重寫`：以現有內容再生成更清楚版本。
- `分享 / QR / 複製連結`：建立公開 payload，產出可分享 URL 與 QR。
- `匯出 PDF/圖片`：呼叫匯出器；字型改為「匯出時才載入」。

## 4) Admin 商務流程

- 主要頁：`lib/features/admin/admin_dashboard.dart`
- 訂單流程：`提案 -> 審核 -> 供應商指派 -> 材質確認 -> 交付里程碑`
- 常用操作：
  - 供應商啟用/停用
  - 指派供應商到訂單
  - 材質 tier 與價格帶確認
  - 更新交付里程碑（設計確認 / 製作中 / 已交付）
- 漏斗指標：提案率、審核通過率、指派完成率、交付完成率 + 每週趨勢。

## 5) 匯出（PDF/CSV）

- `PdfExporter`：紀念頁/訃聞 PDF。
- `ComplianceExporter`：通知歷史與合規草稿匯出。
- 字型策略：
  - 優先使用 Google Fonts `Noto Serif HK`（on-demand）。
  - 其次嘗試本地 `NotoSansTC-Subset.ttf`（若存在）。
  - 再退回本地大型字型或 Helvetica。

## 6) Firestore 權限（概念）

- `proposal`：一般使用者可寫。
- `vendorAssignment/materialSelection/deliverySchedule/vendors`：僅 Admin 可寫。
- 付款與既有訂單規則維持原本規範。

