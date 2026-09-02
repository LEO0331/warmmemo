# WarmMemo

[![version](https://img.shields.io/badge/version-0.1.0%2B1-blue)](pubspec.yaml)
[![deploy](https://github.com/leo0331/warmmemo/actions/workflows/deploy.yml/badge.svg)](https://github.com/leo0331/warmmemo/actions/workflows/deploy.yml)
![platform](https://img.shields.io/badge/platform-Flutter%20Web-42A5F5)

[繁體中文文件](README-zh.md)

WarmMemo is a Flutter Web and Firebase application that helps families and funeral-service teams prepare memorial content and manage the journey from a proposal to delivery.

## Highlights

- Create and share memorial pages, including public links and QR codes.
- Draft, rewrite, export, and share digital obituaries.
- Plan end-of-life finances and meaningful experiences with the Final Countdown planner.
- Purchase service packages, follow order progress, and receive notifications.
- Generate digital-persona skills from daily-life or workplace templates.
- Give administrators a secure workspace for orders, suppliers, materials, delivery milestones, and funnel reporting.

## Workflow

The core business workflow is:

`proposal → admin review → supplier assignment → material confirmation → delivery schedule`

## Technology

- Flutter Web
- Firebase Authentication
- Cloud Firestore
- GitHub Actions and GitHub Pages

## Getting Started

Prerequisites: a Flutter SDK compatible with Dart `^3.11.0`, plus a Firebase project configured for the app.

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env/payment.dev.json
```

## Configuration

Configure payment, authentication, and public-link behavior with Dart defines or your deployment environment.

| Variable | Purpose |
| --- | --- |
| `WARMEMO_USE_HOSTED_PAYMENT_LINKS` | Enable hosted payment links. |
| `WARMEMO_PAYMENT_BACKEND_URL` | Payment backend base URL. |
| `WARMEMO_PAYMENT_FUNCTION` | Firebase payment function name. |
| `STRIPE_PAYMENT_LINK_120000` | Stripe link for the 120,000 tier. |
| `STRIPE_PAYMENT_LINK_150000` | Stripe link for the 150,000 tier. |
| `STRIPE_PAYMENT_LINK_220000` | Stripe link for the 220,000 tier. |
| `WARMEMO_AUTH_PERSISTENCE` | Authentication persistence; defaults to `SESSION`. |
| `PUBLIC_BASE_URL` | Recommended base URL for public pages and QR codes. |

### Free-tier payment mode

The GitHub Pages deployment uses Stripe-hosted Payment Links and does not require Cloud Functions. Each checkout appends the Firestore order ID as Stripe's `client_reference_id`, allowing an administrator to match the Stripe Dashboard payment to the order before manually setting `paymentStatus=paid`.

LINE Pay is not shown in the application because its request-and-confirm protocol requires an executable backend. Do not expose the experimental `server/` reservation endpoint as a complete payment flow without adding the confirmation call and authoritative status reconciliation.

## Quality Checks

```bash
flutter analyze
flutter test
flutter test --coverage
```

Coverage is written to `coverage/lcov.info`.

## Build for GitHub Pages

```bash
flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json
```

## Security

Firestore rules protect role assignment, token balances, payment status, and order ownership. Administrative operations such as supplier management, material confirmation, and delivery scheduling are restricted to administrators. Review [firestore.rules](firestore.rules) before changing data access.

## Documentation

- [Project status](docs/progress.md)
- [Architecture and data contract](docs/info.md)
- [User-flow guide](docs/flow.md)
- [Documentation index](docs/README.md)

## Known Constraints

- PDF exports can fall back to a less complete Chinese font when network access is unavailable and no local subset font is included.
- After a GitHub Pages deployment, browsers with an older cached service worker may briefly request outdated assets; use a hard refresh if needed.
