# WarmMemo

WarmMemo is a Flutter Web + Firebase app for memorial drafting, package checkout, and admin order operations.

## Release 0.1.0 Readiness

- App version: `0.1.0+1`
- `flutter analyze`: pass
- `flutter test --coverage`: pass
- Latest coverage snapshot:
  - Overall line coverage: `89.22%`
  - `lib/data/services/*` line coverage: `86.24%`

## Key Features

### User
- Email/password login with role-based access (`user` / `admin`)
- First-time onboarding (3 steps): select service, generate first draft, confirm token balance
- Onboarding progress feedback (`X/3`) to improve activation
- Memorial page draft and obituary draft
- PDF/image export for memorial and obituary content
- Package checkout and order status tracking
- Notification center (filter unread + mark as read)

### Admin
- Admin-only dashboard
- Multi-filter order management (status/plan/payment/verifier/date/keyword)
- Batch operations with confirmation and result report
- Manual order processing with audit logs

## Advanced Services and Token Model

- New signup users receive **5 free tokens**.
- Advanced actions consume tokens (1 token per action):
  - memorial preview generation
  - memorial PDF export
  - memorial image export
  - obituary generation
  - obituary rewrite
  - obituary PDF export
  - obituary image export
- When tokens are insufficient, users are prompted to top up.
- Low-friction top-up request dialog can be submitted immediately from insufficient-token flow.

Implementation references:
- `lib/data/services/token_wallet_service.dart`
- `lib/data/services/user_role_service.dart`
- `lib/features/memorial/memorial_page_tab.dart`
- `lib/features/obituary/digital_obituary_tab.dart`
- `lib/core/layout/app_shell.dart`

## Firestore Security (No Cloud Functions)

Rules are hardened for client-only mode:
- Users cannot elevate role.
- New user profile create requires `role == "user"` and `tokenBalance == 5`.
- Users cannot self-increase token balance.
- Token deduction is restricted to one-way decrement updates.
- Token logs are readable by owner/admin; write is constrained for consume behavior.
- Top-up requests can be created by owner and reviewed by admin.
- Users cannot set `paymentStatus = paid`; paid is reserved for admin workflows.

Rules file:
- `firestore.rules`

## Environment Variables

Payment and auth-related defines:
- `WARMEMO_USE_HOSTED_PAYMENT_LINKS`
- `WARMEMO_PAYMENT_BACKEND_URL`
- `WARMEMO_PAYMENT_FUNCTION`
- `STRIPE_PAYMENT_LINK_120000`
- `STRIPE_PAYMENT_LINK_150000`
- `STRIPE_PAYMENT_LINK_220000`
- `WARMEMO_AUTH_PERSISTENCE` (`SESSION` by default)

## Local Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env/payment.dev.json
```

## Build Web

```bash
flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json
```

## SOP Templates (Phase 1)

- Customer Support SOP:
  - `docs/sop/phase1_customer_support_sop.md`
- Admin Operations SOP:
  - `docs/sop/phase1_admin_operations_sop.md`

## SEO Checklist (Publish)

- Ensure these pages are deployed and indexable:
  - `/`
  - `/obituary-guide.html`
  - `/package-comparison.html`
- Submit sitemap in Google Search Console:
  - `https://leo0331.github.io/warmmemo/sitemap.xml`
- Track early metrics weekly:
  - impressions
  - clicks
  - CTR
  - top queries
- Landing already includes:
  - OG/Twitter metadata
  - FAQ JSON-LD
  - WebSite/Organization JSON-LD
  - crawlable FAQ text section

## Image Consistency Notes

- Landing images now include semantic labels for accessibility and SEO-friendly rendering context.
- If you move from remote URLs to local assets later, use consistent naming such as:
  - `assets/images/landing-memorial-gentle.jpg`
  - `assets/images/landing-obituary-guide-clear.jpg`
