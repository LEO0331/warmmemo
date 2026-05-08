# WarmMemo 系統設計與架構權衡（Deep Dive 準備版）

> 目的：整理目前系統設計、資料結構選型理由、替代方案與取捨，供技術深問（architecture review / design review / interview-style deep dive）使用。  
> 範圍：以現有程式碼為準，不推翻既有商業邏輯。

---

## 1) 系統設計總覽

### 1.1 架構分層

```text
Flutter UI (features/*, core/layout)
  -> Repository (cache + in-flight de-dup + optimistic)
    -> Service (Firebase read/write, domain operations)
      -> Firebase Auth + Firestore (rules as policy boundary)
```

### 1.2 關鍵設計目標

1. 低後端依賴：Spark plan 下可運作（支付先採 hosted link / 客服核對）。
2. 權限優先：Firestore Rules 直接保護 role/token/order transition。
3. 漸進升級：資料結構允許 schema 升版與向下相容。
4. 體驗優先：Web 端透過 deferred loading、optimistic update、本地快取降低延遲感。

### 1.3 關鍵元件定位

- Auth/Session: `lib/data/firebase/auth_service.dart`
- Role/Profile bootstrap: `lib/data/services/user_role_service.dart`
- 訂單與流程: `lib/data/services/purchase_service.dart`, `lib/data/models/purchase.dart`
- 支付: `lib/data/services/payment_service.dart`, `lib/features/packages/checkout_page.dart`
- 草稿/公開頁/通知: `lib/data/firebase/draft_service.dart`, `lib/data/services/notification_service.dart`
- Repository 緩衝層: `lib/data/repositories/*`
- 權限策略: `firestore.rules`

---

## 2) 核心資料模型與流程

### 2.1 Firestore 主體模型（簡化）

```text
/users/{uid}
  role, tokenBalance, onboarding...
  /drafts/{memorial|obituary}
  /meta/{stats}
  /orders/{orderId}
  /tokenLogs/{logId}
  /cyberSkills/{skillId}
  /topupRequests/{requestId}

/notifications/{notificationId}
/vendors/{vendorId}
/public_memorials/{slug}
/admins/{uid}

# backward compatibility:
/orders/{orderId}  (root-level legacy path)
```

### 2.2 訂單狀態機（雙軸）

- 案件狀態：`pending -> received -> complete`
- 付款狀態：`awaiting_checkout -> checkout_created -> paid/failed/cancelled/expired`

雙層保護：
1. App layer：`OrderWorkflow.assertTransitionAllowed()`
2. Rules layer：`caseTransitionValid()`, `paymentTransitionValid()`, `completeRequiresPaid()`

---

## 3) 為什麼選這些資料結構（含替代方案）

## 3.1 `users/{uid}/orders`（每使用者子集合）+ `collectionGroup('orders')`

### 為何這樣選

- 使用者讀取自己資料時，授權條件清楚（owner-based rules 最直觀）。
- Admin 仍可透過 `collectionGroup` 統一查全域訂單。
- 與 `users/{uid}` 的 profile/token/onboarding 同邊界，易做規則治理。

### 取捨

- `collectionGroup` 查詢容易踩 index 與規則成本（需特別控分頁、索引）。
- 管理端查詢語句與 cursor 處理較複雜（目前用 doc path cursor）。

### 替代方案

1. 全部改成 root `/orders/{id}`（集中式）
  - 優點：管理端查詢簡單，索引策略集中。
  - 缺點：owner 權限需嚴格檢查 `resource.data.userId`，誤設風險較高。
2. 雙寫（user subcollection + root projection）
  - 優點：user/admin 查詢都快。
  - 缺點：一致性成本高，需 Cloud Functions 或後端交易保證。

---

## 3.2 `admins/{uid}` 做 admin gating（而非只靠 token claim）

### 為何這樣選

- 在不依賴 Cloud Functions 的情況下可手動升降 admin（操作性高）。
- 避免全靠 `request.auth.token.admin`（需 server 端發 claim）。

### 取捨

- 需要多一份 admin 文件維護。
- `exists()/get()` 規則判斷若寫法不慎，會帶來 query 成本或 permission-denied 誤判。

### 替代方案

1. 僅 custom claims
  - 優點：安全清晰，Rules 快。
  - 缺點：必須有後端管理流程（通常 Cloud Functions/Admin SDK）。
2. 僅 `users/{uid}.role == 'admin'`
  - 優點：單一資料源。
  - 缺點：rules cross-document read 成本高於 admin doc exists 檢查。

---

## 3.3 `Purchase` 用扁平欄位 + 少量巢狀物件（proposal/vendor/material/schedule）

### 為何這樣選

- 常用篩選欄位扁平化（status/paymentStatus/planName/createdAt）利於 dashboard。
- 業務流程資料（proposal/vendor/material/schedule）以巢狀 map/list 聚合，便於單次讀取呈現。

### 取捨

- 文件尺寸持續膨脹風險（尤其 `verificationLogs`、schedule）。
- 欄位演進需 schema discipline（已用 `schemaVersion` 管控）。

### 替代方案

1. 高度正規化（每個模組獨立子集合）
  - 優點：文件更小，可按需讀取。
  - 缺點：查詢與交易複雜，前端組裝成本高。
2. Event-sourcing（狀態只由事件推導）
  - 優點：審計完整、可回放。
  - 缺點：前端讀模型與聚合層複雜，Spark/client-only 不友善。

---

## 3.4 `verificationLogs` 內嵌陣列（embedded list）

### 為何這樣選

- 單筆訂單詳情頁可一次取回核對歷史，UI 實作簡單。
- 小到中量 log 下，讀取成本固定且可控。

### 取捨

- 寫入越多，文件越大；1MB 文件上限是長期風險。
- 併發更新同一文件會增加衝突機率。

### 替代方案

1. `/orders/{id}/verificationLogs/{logId}` 子集合
  - 優點：可無限擴展，併發友好。
  - 缺點：UI 需額外查詢與排序；規則與索引管理更複雜。

---

## 3.5 `notifications` 用 root collection + `userId` 欄位

### 為何這樣選

- 同時支援 user timeline 與 admin 全域處理（pending/reminder）。
- 避免 per-user 子集合導致 admin 全局查詢昂貴。

### 取捨

- 需嚴格規則保護 `userId` 可見性與更新限制。
- 需要索引支援常見查詢（`userId + occurredAt/status`）。

### 替代方案

1. `/users/{uid}/notifications`
  - 優點：使用者隔離更自然。
  - 缺點：全域營運分析與批次提醒不便（collectionGroup 成本上升）。

---

## 3.6 Token wallet: `tokenBalance` + `tokenLogs`

### 為何這樣選

- 即時餘額查詢快（單欄位）。
- `tokenLogs` 保留消耗紀錄，平衡可觀察性與性能。
- 交易扣點 (`runTransaction`) 保證扣點原子性。

### 取捨

- 若無 server-side authoritative accounting，仍偏 client-driven 經濟模型。
- 後續若接真金流，需後端核銷與防重放。

### 替代方案

1. 純 ledger 即時計算餘額（無 balance 欄位）
  - 優點：不可篡改審計更強。
  - 缺點：每次查餘額成本高，前端體驗差。
2. 全後端錢包服務
  - 優點：安全最高，可對接金流核銷。
  - 缺點：需 Cloud Functions/Backend 長期維運。

---

## 3.7 `schemaVersion` + read-time backfill

### 為何這樣選

- 支援線上演進，不需停機或一次性全量 migration。
- 實際讀取到舊資料時才補寫，平滑遷移。

### 取捨

- 讀路徑帶有寫回副作用，增加請求複雜度。
- 若資料量大，第一次掃描會有額外寫入成本。

### 替代方案

1. 離線批次 migration 腳本
  - 優點：讀路徑純粹。
  - 缺點：需維運窗口與失敗回滾計畫。

---

## 3.8 時間欄位採 `ISO string`（許多模型）而非全 `Timestamp`

### 為何這樣選

- JSON 序列化與跨層傳遞直觀（尤其匯出/前端處理）。
- 與現有 Flutter model mapping 一致，避免多型別轉換失誤。

### 取捨

- 依字串排序需格式一致（ISO8601 才安全）。
- Firestore 原生時間查詢與 serverTimestamp 語義不如 Timestamp 直接。

### 替代方案

1. 全 Timestamp（Firestore native）
  - 優點：查詢/排序/時區語義更一致。
  - 缺點：序列化與匯出層需要更多轉換。

---

## 3.9 Cyber Skill：只存 `analysisSummary + markdown`，不存 raw materials

### 為何這樣選

- 隱私風險與資料量顯著下降。
- 符合「可再現輸出」與「最小必要保存」原則。
- 規則可限制 markdown size、list size、version 遞增。

### 取捨

- 無法直接重放完整原始素材來再訓練/重算分析。
- 若後續需要可追溯 raw evidence，需另建合規留存流程。

### 替代方案

1. 原始素材加密存放（另庫/冷儲存）
  - 優點：可追溯性更高。
  - 缺點：隱私治理與成本顯著上升。

---

## 3.10 Repository 層用 `TTL cache + in-flight de-dup + optimistic map`

### 為何這樣選

- 降低重複請求與 UI 抖動。
- 輕量、不引入額外狀態管理依賴。
- 對 Firestore 高延遲網路環境更友善。

### 取捨

- 記憶體快取僅本 session，有失效與一致性複雜度。
- optimistic rollback 需要嚴謹錯誤處理。

### 替代方案

1. 統一狀態框架（Riverpod/BLoC + persistent cache）
  - 優點：一致性/可測性更高。
  - 缺點：改造面積大，學習與遷移成本高。

---

## 3.11 AppShell deferred tabs（按需載入）

### 為何這樣選

- Flutter Web 首包過大時，deferred import 可把非首要 tab 分包。
- 不改商業邏輯即可改善首屏可用時間。

### 取捨

- 首次切換 tab 會看到一次 loading spinner。
- 程式碼路徑與錯誤排查稍微複雜。

### 替代方案

1. 全量預載（不 deferred）
  - 優點：切 tab 幾乎無等待。
  - 缺點：首載最慢。

---

## 4) 目前架構風險與可擴展性評估

### 4.1 短期（目前可接受）

- Spark + hosted payment links + admin manual verify 可以運作。
- Rules 已有 owner/admin 邊界與關鍵欄位/transition 限制。
- SEO 與首載體驗已有基礎優化。

### 4.2 中期風險（建議優先）

1. 支付狀態 `paid` 目前若未接 webhook authoritative path，仍需人工核對為主。
2. `verificationLogs` 持續成長可能逼近單文件上限。
3. `collectionGroup('orders')` 查詢與索引治理要持續管理（尤其 dashboard 過濾變複雜時）。
4. 時間欄位 string/Timestamp 混用，長期需一致化策略。

### 4.3 長期升級方向

1. Blaze + Cloud Functions：支付 webhook 核銷（Stripe/Line Pay） authoritative update。
2. 對高增長資料（logs/events）拆分到子集合或事件表。
3. 導入管理端 projection（read model）降低複雜查詢成本。

---

## 5) Deep Dive 問答準備（可直接背）

## Q1: 為什麼訂單放在 `users/{uid}/orders` 而不是只有 `/orders`？
- A: owner 權限邏輯最直接，資料邊界與 profile 綁定清楚；admin 透過 collectionGroup 補全全域查詢。這是「安全清晰優先」的取捨。

## Q2: 為什麼需要 `admins/{uid}`，不是只用 `users.role`？
- A: `admins` 的 exists 檢查成本與語義都更穩定；在無 custom claims 發布管道時，維運可行性更高。

## Q3: 為什麼前端還要檢查 transition，Rules 不是已經會擋？
- A: 前端先擋提供更快回饋與更好 UX；Rules 是最後防線，兩層互補而非重複。

## Q4: 為什麼 `verificationLogs` 放陣列，不拆子集合？
- A: 目前 log 量級下，單查詢詳情頁更簡單；若未來成長，子集合是已知可遷移路徑。

## Q5: 為什麼 token 用 balance + logs，不純 ledger？
- A: balance 讓 UI 即時查詢便宜；logs 保留審計。純 ledger 讀放大太高，不適合高互動前端。

## Q6: 為什麼不直接把 raw skills material 存起來？
- A: 隱私與資料最小化優先；目前產品需求是輸出結果可用，不是建立可回放訓練資料湖。

## Q7: Firestore string timestamp 會不會有問題？
- A: ISO8601 可以排序，但一致性與時區語義不如 Timestamp；這是可運作但建議中期收斂的點。

## Q8: Spark 不開 Cloud Functions，支付狀態怎麼可信？
- A: 現階段以 hosted link + admin manual verify；若要自動化與抗偽造，必須升級到 webhook authoritative backend。

## Q9: 為什麼不用單一狀態管理框架？
- A: 現有 Repository + cache + optimistic 已達需求，避免一次重構風險；後續若狀態複雜度再升，可再引入。

## Q10: deferred loading 的收益與成本？
- A: 首包顯著下降、首屏更快；成本是首次切 tab 有 loading，但整體體驗可接受且可漸進優化（預取熱門 tab）。

---

## 6) 若被追問「你下一步會怎麼做？」

建議回答順序：

1. **安全面**：支付改 webhook authoritative path（Blaze + Functions），`paid` 僅後端可寫。
2. **資料面**：把高成長審計資料（verification logs / events）拆分子集合並建立 retention 策略。
3. **查詢面**：對 admin dashboard 建 projection/read model，避免前端重組太多 collectionGroup 結果。
4. **一致性面**：統一時間欄位策略（全 Timestamp 或明確雙軌規則）。
5. **效能面**：持續監測 bundle、預取高頻 tab、索引治理自動化。

---

## 7) 審查結論（TL;DR）

- 現有架構是「前端主導 + Rules 強防線 + 漸進可升級」的務實設計。  
- 對目前產品階段（Spark、快速迭代）是合理取捨。  
- 主要技術債集中在：支付權威性、高增長資料拆分、查詢投影與時間欄位一致化。  
- 已具備清晰升級路徑，不需推翻重建。

