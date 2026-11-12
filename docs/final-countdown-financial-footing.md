# 財務基礎與人生體驗

人生倒數的 Die with Zero 規劃把健康、時間、財務與體驗目標放在一起考量。「財務基礎與人生體驗」讓使用者在安排家庭、旅行、學習與貢獻等目標時，也能檢視手邊可以動用的資源。區塊預設收合，體驗反思無須填寫任何金額。可考慮哪些體驗受時間限制、哪些主要需要陪伴或時間、縮小規模是否仍能保留意義，以及希望保留哪些資源或承諾。

## 目前財務與終身估算

| 指標 | 公式與輸入條件 |
| --- | --- |
| 目前估計淨資產（NT$） | 可動用現金 + 其他金融投資 + 非流動資產 − 未清償負債。四項都需要明確輸入，結果可以為負。 |
| 可動用現金緩衝（月） | 可動用現金 ÷ 每月必要支出。需要提供現金及大於零的每月必要支出。房產與其他投資不列入這項現金估算。 |
| 預估終身資源與支出（NT$） | 各自加總一次性金額，以及年度金額乘以適用年數。年數依項目設定採用全部剩餘年數、退休前年數或退休後年數。 |
| 預估終身差額（NT$） | 預估終身資源 − 預估終身支出。 |

填 0 表示確認該項金額為零，留白代表未知。輸入接受非負十進位數字、小數點後最多兩位及有效的千分位逗號，每欄上限為 999,999,999,999。超出範圍或格式不符時不會納入計算。終身規劃的既有輸入含未來收入，不會帶入目前財務欄位。

緩衝目標是使用者自行選擇的月數，可依情況調整。現金緩衝與目標都有值時，畫面會說明低於或達到目標。若有負債，提示可一起檢視金額、還款條件及成本。緩衝估算只反映輸入的現金和支出，無法判斷特定消費是否可負擔，也無法預見收入變動、醫療或照護費用、稅負、資產變現時程與未填入的承諾。

現金緩衝月數最多顯示至小數點後兩位，是否達到目標依原始輸入計算。

終身預估是未折現的加總，未計入投資報酬、通膨、稅負、債務還款時程或逐年現金流。生活目標對齊度沿用原本的健康、財務、時間及體驗進度權重，作為個人規劃參考。

## 參考概念與範圍

本功能參考 Nick Maggiulli 的 *The Wealth Ladder*。財務優先順序會隨處境改變，可動用的資源會影響選擇，金錢可用來支持重視的生活體驗。原書依美元淨資產設計六級門檻。WarmMemo 使用新臺幣及使用者自選的緩衝目標，因此未做幣別換算或分級。書中的 0.01% 消費經驗法則仰賴報酬與收入假設，退休或收入不穩時尤其需要考量這些條件。本版未採用每日額度、提領建議、投資建議或情境模擬。 [作者介紹](https://ofdollarsanddata.com/the-wealth-ladder/) · [出版社書介](https://www.penguinrandomhouse.com/books/770215/the-wealth-ladder-by-nick-maggiulli/) · [Morningstar《The Long View》訪談](https://www.morningstar.com/podcasts/the-long-view/nick-maggiulli-climbing-wealth-ladder-2)

## 隱私

財務快照只存在於當次頁面的記憶體，重新整理、登出或關閉頁面即清除。收合區塊時仍可在當次使用期間重新展開查看。快照無儲存或上傳功能，也不會進入分析紀錄、公開分享或匯出。原本的終身規劃草稿仍以 `final_countdown_tab_v1` 存於 SharedPreferences。瀏覽器中的原有本機草稿未加密，共用同一瀏覽器設定檔的人可能存取。

## English summary

Financial Footing is an optional, bilingual section in Final Countdown. It uses reported current assets and liabilities to estimate net worth, and divides readily accessible cash by positive monthly essentials to estimate cash-buffer months. The optional buffer target reflects a personal assumption. Experience prompts remain available with blank fields. The existing Die with Zero projection continues to sum one-time entries and annual entries across applicable years, and its readiness calculation keeps the same inputs and weights.

The snapshot lives in page memory. The existing planner draft continues to use browser-local storage. The feature adapts Maggiulli’s principles of adjusting priorities to financial circumstances and using resources for meaningful choices. Currency conversion, wealth levels, spending allowances, investment recommendations, detailed cash-flow projections and optional local saving are outside this release.

## 驗證 / Verification

- `flutter pub get` 完成，`flutter analyze --no-pub` 無問題。
- `flutter test --no-pub` 通過 173 項測試，其中 12 項涵蓋本功能的計算、目標邊界、草稿相容性、資料隔離與 360 px 版面鍵盤操作。
- `flutter build web --no-pub --release --base-href /warmmemo/` 完成 JavaScript 版本。WebAssembly 試編譯仍回報既有的 `printing`／`ffi` 和 `image` 相容性問題。
- 本機 Windows 的 Flutter Chrome 測試在載入 CanvasKit 時出現 HTTP 錯誤。改用本機 CanvasKit、Chrome 與獨立測試入口，通過 360 px 實際頁面檢查。確認區塊預設收合、六個欄位可操作、負淨資產、現金緩衝、低於自選目標提示，以及輸入未寫入本機儲存。
- 專案原有的 Patrol 首頁與登入測試改用已安裝的 Chrome 執行，四項中通過三項。首頁 CTA 測試仍使用舊文案「開始規劃」，基準版本的按鈕文字已為「開始整理」。
