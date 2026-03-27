# WarmMemo

WarmMemo is a Flutter + Firebase web app for public users and admins to manage memorial drafts, package checkout, and order handling.

## Core Features

- Public landing page with package overview.
- Email/password auth and role-based access (`user` / `admin`).
- User drafts:
  - Memorial page draft and export (PDF / image).
  - Digital obituary draft with tone + template controls.
- Checkout flow with hosted Stripe payment links.
- User order center:
  - Payment status filters.
  - Order details and verification logs.
  - Notification center timeline.
- Admin dashboard:
  - Metrics panel (orders, paid rate, avg completion time).
  - Search and segmentation filters (status / plan / payment / verifier / keyword / date).
  - Batch operations (`received`, `complete`, `paid`).
  - Order detail editor with workflow guard and audit logs.

## Status Workflow

### Case status

- `pending -> received -> complete`
- Reverse transitions are blocked in the admin editor and batch updater.

### Payment status

- `awaiting_checkout -> checkout_created -> paid`
- retry branches:
  - `failed -> checkout_created`
  - `cancelled -> checkout_created`
  - `expired -> checkout_created`

## Tech Stack

- Flutter (web-first, responsive layout)
- Firebase:
  - Authentication (email/password)
  - Cloud Firestore (users, drafts, orders, notifications, admins)
- Stripe Payment Links (Spark-compatible mode)

## Local Development

1. Install dependencies

```bash
flutter pub get
```

2. Run web (dev payment config)

```bash
flutter run -d chrome --dart-define-from-file=env/payment.dev.json
```

3. Build web

```bash
flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json
```

## Payment Configuration

- `env/payment.sample.json` is tracked and safe for GitHub.
- `env/payment.dev.json` should remain local and include test links.

Supported keys:

- `WARMEMO_USE_HOSTED_PAYMENT_LINKS`
- `WARMEMO_PAYMENT_BACKEND_URL`
- `WARMEMO_PAYMENT_FUNCTION`
- `STRIPE_PAYMENT_LINK_120000`
- `STRIPE_PAYMENT_LINK_150000`
- `STRIPE_PAYMENT_LINK_220000`
- `WARMEMO_AUTH_PERSISTENCE` (`LOCAL` or `SESSION`, default `LOCAL`)

## Web SEO Assets

- `web/index.html`: SEO/OG/Twitter metadata.
- `web/robots.txt`: crawler policy and sitemap hint.
- `web/sitemap.xml`: base URL map.

## Admin Access

- User must have:
  - `users/{uid}.role == "admin"`
  - and `admins/{uid}` doc for rules that rely on `isAdminDoc()`

## Notes

- Spark plan cannot use paid webhooks/Cloud Functions for secure payment confirmation in production.
- For production-grade payment verification, move to Blaze and implement Stripe webhook confirmation (`payment_intent.succeeded`) before auto-marking `paid`.
