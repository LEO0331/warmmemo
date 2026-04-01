# WarmMemo Phase 1 SOP（管理員版）

適用範圍：Spark 方案、無 webhook 自動對帳。  
版本：v1.0

## 1) 管理員職責

- 審核與更新付款狀態（`checkout_created -> paid`）。
- 審核加值申請（`topupRequests`）並人工加點。
- 維護訂單狀態流程（`pending -> received -> complete`）。
- 確保每次人工變更皆保留操作紀錄。

## 2) 每日作業清單（建議 2 次）

- 檢查 `paymentStatus=checkout_created` 且建立時間超過 24 小時的訂單。
- 檢查 `topupRequests/status=pending`。
- 檢查客服升級案件（付款核對、權限異常）。

## 3) 付款核對流程（人工）

1. 取得客服提供資訊：Email、UID、付款單號、付款時間。  
2. 後台找到對應訂單，核對 `invoiceId` 與方案金額。  
3. 確認後更新：
   - `paymentStatus = paid`
   - `paidAt = 現在時間`
   - `paymentIntentId`（若有）
4. 在訂單編輯頁填寫核對備註，保存操作日誌。  
5. 回傳客服結果，由客服通知用戶。

## 4) 加值審核流程（人工）

1. 開啟 `users/{uid}/topupRequests/{requestId}`，確認：
   - `status = pending`
   - `requestedTokens` 合理（例如 10/20/50）
2. 人工確認付款或內部核准後：
   - 將 `users/{uid}.tokenBalance` 增加對應點數
   - 寫入 `users/{uid}/tokenLogs`：
     - `type=topup`
     - `source=manual_admin`
     - `balanceBefore/balanceAfter`
3. 更新該 request：
   - `status=approved`（或 `rejected`）
   - `updatedAt`
   - `adminNote`（建議欄位，可在後續擴充）

## 5) 批次操作守則

- 操作前必看確認彈窗（筆數 + 目標狀態 + 預覽項目）。
- 批次完成後必看結果報告（成功/略過/原因）。
- 若略過比例 > 30%，停止下一批並先排除資料異常。

## 6) 狀態機操作限制

- 案件狀態只允許：
  - `pending -> received -> complete`
- 付款狀態建議：
  - `checkout_created -> paid`
  - 異常可用 `failed/cancelled/expired -> checkout_created` 重試
- 禁止：把 `complete` 直接改回 `pending`。

## 7) 權限維護（admin）

- 管理員帳號需同時滿足：
  - `users/{uid}.role = "admin"`
  - `admins/{uid}` 文件存在
- 若 admin 無法讀後台：
  1. 先檢查規則是否已部署最新版。
  2. 檢查 `admins/{uid}` 是否存在。
  3. 檢查登入帳號 UID 是否一致。

## 8) 稽核與留痕

- 每次人工更新需保留：
  - 操作者（email/uid）
  - 變更前後狀態
  - 變更時間
  - 備註（核對依據）
- 建議每週匯出：
  - orders
  - tokenLogs
  - topupRequests

## 9) 風險處理準則

- 若出現疑似錯誤加點：
  - 立即凍結該帳號後續人工加點
  - 保留 logs 與訂單證據
  - 通知技術排查規則/前端流程
- 若出現大量 permission-denied：
  - 優先檢查 rules 部署版本
  - 再檢查查詢路徑與索引需求

## 10) 管理員結案紀錄模板

```
案件編號：
用戶 UID / Email：
處理類型：付款核對 / 加值審核 / 訂單狀態
變更內容：
核對依據：
處理結果：
處理時間：
處理人員：
```
