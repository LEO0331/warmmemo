# WarmMemo

[![version](https://img.shields.io/badge/version-0.1.0%2B1-blue)](pubspec.yaml)
[![deploy](https://github.com/leo0331/warmmemo/actions/workflows/deploy.yml/badge.svg)](https://github.com/leo0331/warmmemo/actions/workflows/deploy.yml)
![platform](https://img.shields.io/badge/platform-Flutter%20Web-42A5F5)

[English README](README.md)

WarmMemo 是一個以 Flutter Web 與 Firebase 建置的應用程式，協助家屬與禮儀服務團隊準備紀念內容，並管理從提案到交付的完整流程。

## 主要功能

- 建立並分享紀念頁，支援公開連結與 QR Code。
- 撰寫、改寫、匯出及分享數位訃聞。
- 使用「人生倒數」規劃工具安排身後財務與重要人生體驗。
- 購買服務方案、追蹤訂單進度與接收通知。
- 以日常生活或職場範本產生數位分身技能。
- 提供管理者安全的後台，處理訂單、供應商、材質、交付里程碑與漏斗報表。

## 作業流程

核心商務流程：

`提案 → 管理員審核 → 指派供應商 → 確認材質 → 安排交付`

## 技術棧

- Flutter Web
- Firebase Authentication
- Cloud Firestore
- GitHub Actions 與 GitHub Pages

## 開始使用

前置需求：與 Dart `^3.11.0` 相容的 Flutter SDK，以及已完成應用程式設定的 Firebase 專案。

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env/payment.dev.json
```

## 環境設定

透過 Dart defines 或部署環境設定付款、登入與公開連結行為。

| 變數 | 用途 |
| --- | --- |
| `WARMEMO_USE_HOSTED_PAYMENT_LINKS` | 啟用代管付款連結。 |
| `WARMEMO_PAYMENT_BACKEND_URL` | 付款後端的基礎網址。 |
| `WARMEMO_PAYMENT_FUNCTION` | Firebase 付款函式名稱。 |
| `STRIPE_PAYMENT_LINK_120000` | 120,000 方案的 Stripe 付款連結。 |
| `STRIPE_PAYMENT_LINK_150000` | 150,000 方案的 Stripe 付款連結。 |
| `STRIPE_PAYMENT_LINK_220000` | 220,000 方案的 Stripe 付款連結。 |
| `WARMEMO_AUTH_PERSISTENCE` | 登入狀態保存方式；預設為 `SESSION`。 |
| `PUBLIC_BASE_URL` | 建議設定，用於公開頁與 QR Code 的基礎網址。 |

## 品質檢查

```bash
flutter analyze
flutter test
flutter test --coverage
```

覆蓋率結果會輸出至 `coverage/lcov.info`。

## 建置 GitHub Pages

```bash
flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json
```

## 安全性

Firestore 規則會保護角色指派、代幣餘額、付款狀態與訂單所有權。供應商管理、材質確認及交付排程等後台操作僅限管理員使用。調整資料存取前，請先檢視 [firestore.rules](firestore.rules)。

## 文件

- [專案進度](docs/progress.md)
- [架構與資料契約](docs/info.md)
- [使用流程指南](docs/flow.md)
- [文件索引](docs/README.md)

## 已知限制

- 當網路無法使用，且專案未內建本機子集字型時，PDF 匯出可能回退至中文支援較不完整的字型。
- GitHub Pages 部署後，若瀏覽器仍快取舊版 service worker，可能暫時請求舊資源；必要時請強制重新整理頁面。
