# WarmMemo

WarmMemo is a Flutter Web + Firebase app for memorial drafting, package checkout, and admin order operations.

## Key Features

### User
- Email/password login with role-based access (`user` / `admin`)
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
