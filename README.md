# 🕊️ WarmMemo: 數位追思與訂單管理系統
WarmMemo 是一個基於 **Flutter Web** 與 **Firebase** 的全方位解決方案。旨在為用戶提供數位追思導覽、訃聞草稿設計，並為管理員提供高效的訂單處置與支付追蹤後台。
---## ✨ 核心功能### 👤 使用者端 (Public & User)*   **數位追思與訃聞**：支援線上編輯草稿、自定義語氣與模板，並可匯出為 PDF 或圖片。
*   **身份驗證**：整合 Firebase Auth（Email/密碼），具備角色權限控管 (`User` / `Admin`)。*   **訂單中心**：
    *   **結帳流程**：整合 Stripe Hosted Payment Links（兼容 Firebase Spark 免費方案）。
    *   **狀態追蹤**：提供支付狀態篩選、詳細驗證日誌與通知中心時間軸。
### 🛡️ 管理員端 (Admin Dashboard)*   **數據維度儀表板**：監控訂單總數、支付轉換率及平均結案時間。*   **進階篩選系統**：支援狀態、方案、支付方式、核銷員、關鍵字及日期區間等多重過濾。
*   **批次作業中心**：一鍵處理 `已接收`、`已完成`、`已支付` 等大量訂單變更。*   **工作流守衛**：內建編輯器工作流鎖定與審計日誌（Audit Logs），防止誤操作。
---## 🔄 狀態工作流 (Workflow)### 📂 案件狀態 (Case Status)*   `pending (待處理)` → `received (已接收)` → `complete (已完成)`*   **安全規則**：管理員編輯器與批次更新器均**禁止逆向操作**（例如：已完成不可跳回待處理）。
### 💳 支付狀態 (Payment Status)*   `awaiting_checkout` → `checkout_created` → `paid`
*   **異常處理路徑**：`failed` / `cancelled` / `expired` 均可重定向回 `checkout_created`。
---## 🛠️ 技術棧*   **Frontend**: Flutter (Web-first, 響應式佈局)*   **Backend**: 
    *   **Firebase Hosting**: 靜態部署。
    *   **Cloud Firestore**: 存儲用戶、訂單、通知及管理員權限。*   **Payment**: Stripe Payment Links (免 Server 模式)。
---## 💻 本地開發與編譯### 1. 安裝依賴```bash
flutter pub get

2. 啟動 Web 測試 (開發模式金鑰)

flutter run -d chrome --dart-define-from-file=env/payment.dev.json

3. 編譯生產版本

flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json

------------------------------
⚙️ 環境變數配置 (Payment Configuration)
專案使用 env/ 資料夾管理不同環境的支付金鑰：

* env/payment.sample.json: 範例檔（可提交至 GitHub）。
* env/payment.dev.json: 本地金鑰（已加入 .gitignore）。

支援的參數鍵值：

* WARMEMO_USE_HOSTED_PAYMENT_LINKS: 是否啟用 Stripe 託管連結。
* STRIPE_PAYMENT_LINK_[金額]: 不同方案的 Stripe 支付網址。
* WARMEMO_AUTH_PERSISTENCE: 登入持久化設定 (LOCAL 或 SESSION)。

### LINE Pay（Sandbox，透過 Cloud Functions / Node.js）

已新增一個最小可測通的 LINE Pay Sandbox 建單 endpoint（`functions/index.js` 的 `linePayRequest`），Flutter 端在 `CheckoutPage` 會以此取得 `checkoutUrl` 後導向。

Functions 端需要設定以下環境變數（或用 Firebase functions config `linepay.*`）：

* LINEPAY_CHANNEL_ID
* LINEPAY_CHANNEL_SECRET
* LINEPAY_CONFIRM_URL
* LINEPAY_CANCEL_URL
* LINEPAY_BASE_URL（可選，預設為 Sandbox `https://sandbox-api-pay.line.me`）

------------------------------
🔒 安全性說明 (針對 Spark 方案優化)
由於目前採用 Firebase Spark (免費) 方案，無法使用 Cloud Functions Webhooks，因此安全規則（Security Rules）已進行加固：

   1. 禁止權限提升：普通用戶無法修改自己的 role。
   2. 訂單完整性：用戶僅能建立 pending 狀態的訂單，且無法自行將 paymentStatus 改為 paid。
   3. 管理員驗證：必須同時滿足 users/{uid}.role == "admin" 且 admins/{uid} 文件存在，才具備管理權限。

------------------------------
🔍 SEO 與 Web 優化

* web/index.html: 包含 Meta 標籤、OG 分享縮圖及 Twitter Card。
* web/robots.txt: 配置爬蟲政策。
* web/sitemap.xml: 提供網站地圖導航。

