# WarmMemo — 功能流程說明

本文件用人類看得懂的方式說明：按下每個按鈕後，程式碼的哪些部分會被執行，以及發生了什麼事。

---

## 一、主要執行環境

WarmMemo（Flutter Web + Firebase）主要可分為三層：

```
┌────────────────────────────┐
│         Flutter UI         │
│  features/* + core/layout  │
└─────────────┬──────────────┘
              │ 呼叫 service/repository
┌─────────────▼──────────────┐
│   Data / Domain Layer      │
│ data/services + repositories│
└─────────────┬──────────────┘
              │ Firebase SDK
┌─────────────▼──────────────┐
│ Firebase (Auth/Firestore)  │
│  firestore.rules 控制權限   │
└────────────────────────────┘
```

- UI 層：顯示頁面、處理按鈕事件、展示 loading/error。
- Data 層：封裝查詢、寫入、快取、樂觀更新。
- Firebase：身份驗證、資料持久化、權限管控。

---

## 二、核心模組對照

| 檔案 | 負責內容 |
|------|---------|
| `lib/features/auth/auth_gate.dart` | 路由入口、登入狀態判斷、公開頁路由解析 |
| `lib/features/memorial/memorial_page_tab.dart` | 簡易紀念頁編輯、公開連結/QR、提案送出 |
| `lib/features/obituary/digital_obituary_tab.dart` | 數位訃聞生成/重寫、分享連結/QR、匯出 |
| `lib/features/admin/admin_dashboard.dart` | Admin 訂單漏斗、供應商/材質/排程管理 |
| `lib/data/services/*` | Firebase 寫入與查詢 |
| `lib/data/repositories/*` | request policy、cache、optimistic 包裝 |
| `lib/core/export/pdf_exporter.dart` | 紀念頁/訃聞 PDF 匯出 |
| `lib/core/export/compliance_exporter.dart` | 歷史與合規資料匯出 |

---

## 三、按鈕流程

### 3-1. 進站與登入

```
AuthGate.build()
  ├─ _resolvePublicObituaryPayload() / _resolvePublicMemorialSlug()
  │    ├─ 命中公開路由：PublicObituaryPage / PublicMemorialPage
  │    └─ 未命中：進登入狀態判斷
  └─ StreamBuilder(authStateChanges)
       ├─ hasData: AppShell
       └─ noData : LandingPage
```

- `登入 / 註冊`：`AuthService` 處理；成功後 `authStateChanges` 觸發進內頁。
- `登出`：`AuthService.signOut()`；回到 Landing/Auth。

---

### 3-2. 簡易紀念頁：`儲存草稿`

```
MemorialPageTab._saveDraft()
  ├─ 輸入正規化（single/multiline/date/number guard）
  ├─ 組裝 MemorialDraft
  └─ FirebaseDraftService.saveMemorial(uid, draft)
```

結果：草稿寫入 Firestore，重新進頁可回填。

---

### 3-3. 簡易紀念頁：`發佈/關閉發佈`、`QR/複製連結`

```
發佈切換
  ├─ slug 檢核 + 可用性檢查
  ├─ 更新 draft.isPublished / slug
  └─ 寫入 public profile

QR/連結
  ├─ _effectivePublicUrl
  └─ 產生 QR / copy / open link
```

結果：公開頁可由 `#/m/:slug` 存取。

---

### 3-4. 商業作業區：`提案送出`

```
MemorialPageTab -> ProposalController.submit()
  ├─ proposal 欄位檢核
  ├─ 防重複提交
  └─ PurchaseService / Repository update proposal
```

結果：訂單進入漏斗第一步（proposal）。

---

### 3-5. 數位訃聞：`產生訃聞文案` / `一鍵重寫`

```
DigitalObituaryTab
  ├─ 欄位檢核與格式化
  ├─ 點數檢查（token wallet）
  ├─ 呼叫生成/重寫邏輯
  └─ 寫回草稿 + 更新 UI 狀態
```

結果：生成內容顯示於頁面，可進一步分享或匯出。

---

### 3-6. 數位訃聞：`分享 / QR / 匯出`

```
分享連結
  ├─ 建立 payload
  └─ 組公開 URL（#/o?...）

QR
  ├─ 以分享連結產生 QR
  └─ 下載或複製連結

PDF/圖片匯出
  └─ PdfExporter / ComplianceExporter
```

---

### 3-7. Admin：`供應商/材質/排程`

```
AdminDashboard
  ├─ load() -> orders/vendors/notifications
  ├─ 指派供應商 -> update vendorAssignment
  ├─ 材質確認   -> update materialSelection
  └─ 排程更新   -> update deliverySchedule milestones
```

結果：漏斗可追蹤到交付完成，並反映在每週趨勢。

---

### 3-8. 人生倒數：`現況 vs 目標` + `記憶分佈`

```
FinalCountdownTab.build()
  ├─ 既有：資產/支出計算、零結餘分數
  ├─ 新增：健康五面向（現況/目標）計算
  ├─ 新增：三軸比較（健康/財務/壽命）
  ├─ 新增：記憶進度（完成度 70% + 滿意度 30%）
  ├─ 新增：體驗類別分佈（家庭/旅行/學習/貢獻）
  └─ SharedPreferences 儲存擴充欄位（向下相容）
```

- 健康自評：五面向 `1-5` 分，顯示現況/目標/差距。
- 目標參數：目標壽命、目標期末結餘。
- 記憶體驗：每筆可設定「類別、是否完成、滿意度」，並顯示分佈比例。
- 綜合指標：`Die with Zero 準備度` 以多軸對齊度加權。

---

## 四、漏斗狀態（業務視角）

`提案送出 -> Admin 審核 -> 供應商指派 -> 材質確認 -> 排程建立/交付`

- 提案率：有 proposal / 全訂單
- 審核通過率：符合審核條件
- 指派完成率：vendorAssignment 完整
- 交付完成率：delivery milestone 完成

---

## 五、字型與匯出流程

Web 首屏不綁大型中文字型，改系統字型 fallback。

匯出字型解析順序：
1. `PdfGoogleFonts.notoSerifHK*`（on-demand）
2. `assets/fonts/NotoSansTC-Subset.ttf`（若存在）
3. `assets/fonts/NotoSansTC-VariableFont_wght.ttf`
4. Helvetica fallback

---

## 六、權限重點（Firestore）

- 使用者可寫：`proposal`
- Admin 可寫：`vendorAssignment`、`materialSelection`、`deliverySchedule`、`vendors`
- 既有付款與訂單規則保持不變
