# WarmMemo 系統設計與架構權衡（Deep Dive，利害關係人會議版）

> 目的：用會議可討論的方式，整理目前系統設計、資料結構選擇理由、替代方案與取捨。  
> 範圍：以現行產品與程式碼為準，不變更既有商業流程。

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

1. **低後端依賴**：在 Spark 方案下可先上線運作（付款先採 hosted link + 人工核對）。
2. **權限優先**：以 Firestore Rules 直接約束角色、點數、訂單狀態流轉。
3. **可漸進升級**：資料結構支援 schema 演進，不需一次性重構。
4. **使用體驗優先**：Web 端採 deferred loading、optimistic update 與快取，降低等待感。

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

雙層保護機制：
1. App 層：`OrderWorkflow.assertTransitionAllowed()`
2. Rules 層：`caseTransitionValid()`, `paymentTransitionValid()`, `completeRequiresPaid()`

---

## 3) 為什麼選這些資料結構（含替代方案）

## 3.1 `users/{uid}/orders`（每使用者子集合）+ `collectionGroup('orders')`

### 為何這樣選

- 使用者只能看到自己資料，授權邊界清楚。
- 管理端仍可透過 `collectionGroup` 做全域檢視。
- 與使用者 profile/token/onboarding 在同一權限上下文。

### 取捨

- 管理端查詢與索引治理較複雜。
- 若查詢維度增加，需更嚴謹索引管理。

### 替代方案

1. 改成 root `/orders/{id}`（集中式）
  - 優點：管理端查詢較直觀。
  - 缺點：owner 權限控制更容易出錯。
2. 雙寫（user 子集合 + root projection）
  - 優點：user/admin 查詢都快。
  - 缺點：一致性成本高，需要後端協調。

---

## 3.2 `admins/{uid}` 做 admin gating（不只靠 token claim）

### 為何這樣選

- 在未導入 Cloud Functions 前，可手動升降權限，營運可落地。
- 減少完全依賴 custom claims 的部署流程門檻。

### 取捨

- 需維護一份 admin 文件。
- 規則寫法若不當，可能增加查詢成本或誤觸 permission-denied。

### 替代方案

1. 僅 custom claims
  - 優點：安全模型清楚，規則判斷快。
  - 缺點：需要後端管理流程。
2. 僅 `users/{uid}.role == 'admin'`
  - 優點：單一資料來源。
  - 缺點：rules cross-document read 成本較高。

---

## 3.3 `Purchase` 採扁平欄位 + 少量巢狀物件（proposal/vendor/material/schedule）

### 為何這樣選

- 常用篩選欄位（status/paymentStatus/planName/createdAt）利於 dashboard。
- 業務流程資料聚合在同筆訂單，單次讀取即可完整呈現。

### 取捨

- 文件有膨脹風險（特別是 logs/schedule）。
- 欄位演進需有 schema discipline（已用 `schemaVersion` 管控）。

### 替代方案

1. 高度正規化（子集合拆分）
  - 優點：單文件更小、按需讀取。
  - 缺點：查詢與組裝複雜度提高。
2. Event-sourcing
  - 優點：審計完整。
  - 缺點：前端讀模型成本高，現階段不經濟。

---

## 3.4 `verificationLogs` 內嵌陣列（embedded list）

### 為何這樣選

- 單筆訂單詳情頁可一次讀完核對歷史，實作簡潔。
- 在目前資料量下，讀取延遲可控。

### 取捨

- 日誌成長過快會接近 Firestore 單文件上限。
- 併發更新同筆訂單時衝突機率提升。

### 替代方案

1. `/orders/{id}/verificationLogs/{logId}` 子集合
  - 優點：擴展性與併發能力更好。
  - 缺點：需更多查詢、排序與規則管理。

---

## 3.5 `notifications` 用 root collection + `userId`

### 為何這樣選

- 可同時支援個人通知與管理端全域追蹤（pending/reminder）。
- 避免管理端需要昂貴的多層子集合彙總。

### 取捨

- 需更嚴格 rules 來限制讀寫與欄位更新。
- 對索引依賴較高。

### 替代方案

1. `/users/{uid}/notifications`
  - 優點：隔離直觀。
  - 缺點：全域營運分析成本高。

---

## 3.6 Token wallet：`tokenBalance` + `tokenLogs`

### 為何這樣選

- 即時顯示餘額效率高（單欄位）。
- 同時保留扣點紀錄，兼顧審計與體驗。
- 交易扣點 (`runTransaction`) 可保證原子性。

### 取捨

- 目前仍偏 client-driven 經濟模型。
- 若涉及真金流，需後端核銷與防重放。

### 替代方案

1. 純 ledger（即時計算餘額）
  - 優點：審計完整性更高。
  - 缺點：查餘額成本大，體驗較差。
2. 全後端錢包服務
  - 優點：安全性最高。
  - 缺點：需後端長期維運。

---

## 3.7 `schemaVersion` + read-time backfill

### 為何這樣選

- 可在線演進，不需停機 migration。
- 讀到舊資料時再補寫，升級平滑。

### 取捨

- 讀路徑可能觸發寫回，流程較複雜。
- 初次掃描舊資料時會有額外寫入成本。

### 替代方案

1. 離線批次 migration
  - 優點：線上讀取邏輯更單純。
  - 缺點：需要維運時窗與回滾計畫。

---

## 3.8 時間欄位採 `ISO string`（多數模型）而非全 `Timestamp`

### 為何這樣選

- 序列化與匯出更直觀。
- 前端 model mapping 一致性較好。

### 取捨

- 必須確保 ISO8601 格式一致，才可安全排序。
- Firestore 原生時間查詢便利性不如 Timestamp。

### 替代方案

1. 全 Timestamp
  - 優點：查詢/排序語義更一致。
  - 缺點：轉換層與匯出層複雜度較高。

---

## 3.9 Cyber Skill：僅存 `analysisSummary + markdown`，不存 raw materials

### 為何這樣選

- 降低隱私風險與儲存成本。
- 符合最小必要保存原則。
- 規則可直接約束 size/version。

### 取捨

- 無法完整重放原始素材再分析。
- 若需高可追溯性，需另建合規儲存方案。

### 替代方案

1. 原始素材加密存放（冷儲存）
  - 優點：可追溯性強。
  - 缺點：治理複雜、成本高。

---

## 3.10 Repository 採 `TTL cache + in-flight de-dup + optimistic map`

### 為何這樣選

- 降低重複請求與畫面抖動。
- 不新增重量級框架即可改善體驗。
- 對高延遲網路更友善。

### 取捨

- 只在本 session 生效，跨 session 不持久。
- optimistic rollback 必須設計完整錯誤處理。

### 替代方案

1. 統一狀態框架（例如 Riverpod/BLoC + persistent cache）
  - 優點：一致性與可測性提升。
  - 缺點：改造成本高、導入風險高。

---

## 3.11 AppShell deferred tabs（按需載入）

### 為何這樣選

- 首屏載入可明顯改善。
- 不需改商業邏輯即可生效。

### 取捨

- 首次切換某些 tab 會短暫 loading。
- 例外狀況排查略複雜。

### 替代方案

1. 全量預載
  - 優點：切 tab 快。
  - 缺點：首載慢、初次體驗差。

---

## 4) 目前架構風險與可擴展性評估

### 4.1 短期（可接受）

- Spark + hosted payment links + 人工核對可支撐當前營運。
- Rules 已建立 owner/admin 邊界與關鍵 transition 保護。
- Web 首載與 SEO 已有基礎改善。

### 4.2 中期風險（建議優先）

1. `paid` 若未走 webhook authoritative path，仍需人工核對。
2. `verificationLogs` 持續增長可能碰到單文件上限。
3. `collectionGroup('orders')` 的查詢與索引治理需持續投入。
4. string/Timestamp 混用，長期需一致化。

### 4.3 長期升級方向

1. 升級 Blaze + Cloud Functions，改為 webhook 核銷支付狀態。
2. 高增長資料（logs/events）拆分為子集合或事件表。
3. 建立管理端 read model/projection，降低複雜查詢成本。

---

## 5) Deep Dive 問答準備（會議可直接使用）

## Q1：為什麼訂單放在 `users/{uid}/orders`？
- A：因為 owner 權限最直觀，且管理端仍可用 collectionGroup 做全域檢視，安全性與可操作性平衡最好。

## Q2：為什麼要 `admins/{uid}`？
- A：在未導入 claims 管理平台前，這是最實務且可維運的 admin gating 方式。

## Q3：為什麼前端與 Rules 都做狀態檢查？
- A：前端負責體驗（即時提示），Rules 負責最終安全（不可繞過），兩者角色不同。

## Q4：為什麼核對日誌先放在訂單內？
- A：目前量級下可一次讀完，開發與維運成本最低；若增長再拆分子集合。

## Q5：Token 為什麼不是純 ledger？
- A：因為需要即時顯示餘額，`balance + logs` 在體驗與審計間較平衡。

## Q6：為什麼不保存完整原始技能素材？
- A：隱私與最小保存優先，先滿足產品功能，避免過度留存敏感資料。

## Q7：字串時間會不會不安全？
- A：ISO8601 可運作，但中期建議收斂為一致策略以降低風險。

## Q8：Spark 沒 Cloud Functions 時，付款怎麼可信？
- A：現階段用 hosted link + 人工核對；要完全自動可信，必須升級到 webhook 後端。

## Q9：為什麼不一次導入大型狀態框架？
- A：目前資料層已有快取與 optimistic 機制，先維持小步迭代，避免大改風險。

## Q10：deferred loading 值得嗎？
- A：值得。它直接改善首載速度，代價只是首次進入某 tab 的短暫 loading。

---

## 6) 若被追問「下一步會怎麼做？」

建議回應順序：

1. **安全**：導入 webhook authoritative payment flow，`paid` 只允許後端寫入。  
2. **資料**：把高成長審計資料拆分，建立 retention policy。  
3. **查詢**：管理端導入 projection/read model。  
4. **一致性**：統一時間欄位策略。  
5. **效能**：持續追蹤 bundle、預取高頻頁、治理索引。

---

## 7) 審查結論（TL;DR）

- 目前是「可上線、可維運、可升級」的務實架構。  
- 對現階段（Spark + 快速迭代）合理。  
- 關鍵技術債聚焦在支付權威性、資料增長治理、查詢投影與時間欄位一致化。  
- 升級路徑清楚，不需要推翻重建。

