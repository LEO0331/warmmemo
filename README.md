# WarmMemo

[![version](https://img.shields.io/badge/version-0.2.0--rc-blue)](pubspec.yaml)
![platform](https://img.shields.io/badge/platform-Flutter%20Web-42A5F5)
![analyze](https://img.shields.io/badge/flutter%20analyze-passing-success)
![tests](https://img.shields.io/badge/tests-78%20passed-success)
![coverage](https://img.shields.io/badge/coverage-81.22%25-yellowgreen)

WarmMemo is a Flutter Web + Firebase app for memorial drafting, obituary generation, package checkout, and admin-side order operations.

## 0.2 Release Status

Target: `v0.2.0` (release candidate)

- App version (current): `0.1.0+1` (update to `0.2.0+0` when cutting release)
- `flutter analyze`: pass
- `flutter test`: pass (`78` tests)
- `flutter test --coverage`: pass
- Latest line coverage: `81.22% (1527/1880)` from `coverage/lcov.info` (updated: 2026-04-05)

## What’s New In 0.2

### Business Workspace V2

- Supplier management (admin): supplier master profile + active/inactive toggle
- Material menu (v1 tiers): Basic / Standard / Premium with admin-side business fields
- Delivery schedule milestones: `設計確認` / `製作中` / `已交付`
- Conversion funnel visibility:
  - Proposal rate
  - Approval rate
  - Assignment completion rate
  - Delivery completion rate
- Weekly funnel trend panel (last 8 weeks) in Admin dashboard

### Production Hardening

- Repository + request policy + cache/in-flight de-dup baseline
- Optimistic updates for key user/admin actions
- Guardrails and error-state handling for key forms
- Input normalization/sanitization for text/date/number fields
- Field-level validation analytics (best-effort tracking)

## Product Features

### User

- Email/password login with role-based access (`user` / `admin`)
- First-time onboarding (3 steps): select service, generate first draft, confirm token balance
- Memorial page:
  - public link + QR code generation/download
  - proposal submission for tombstone/columbarium purchase workflow
- Digital obituary:
  - content generation/rewrite
  - share link + QR + export options
- Final countdown planner:
  - asset/cost planning with zero-balance guidance
- Package checkout and order status tracking
- Notification center (unread filter + mark read)

### Admin

- Admin-only dashboard
- Multi-filter order management (status/plan/payment/verifier/date/keyword)
- Batch operations with confirmation and result report
- Manual order processing with audit logs
- Vendor assignment, material confirmation, delivery milestone updates
- Funnel metrics + weekly trend visibility

## Token Model

- New signup users receive **5 free tokens**
- Advanced actions consume tokens (1 token per action):
  - memorial preview / PDF / image export
  - obituary generation / rewrite / PDF / image export
- Insufficient balance flow:
  - immediate message + top-up request dialog

Key references:

- `lib/data/services/token_wallet_service.dart`
- `lib/data/services/user_profile_service.dart`
- `lib/features/memorial/memorial_page_tab.dart`
- `lib/features/obituary/digital_obituary_tab.dart`

## Security & Data Rules

Firestore security is hardened for client-only operation:

- Users cannot elevate roles or self-increase token balance
- Owner-only editable keys are restricted on orders
- Users cannot set `paymentStatus = paid`
- Proposal shape is validated in rules
- Vendor management and broad order operations are admin-only

Rules file:

- `firestore.rules`

## Environment Variables

### Payment/Auth

- `WARMEMO_USE_HOSTED_PAYMENT_LINKS`
- `WARMEMO_PAYMENT_BACKEND_URL`
- `WARMEMO_PAYMENT_FUNCTION`
- `STRIPE_PAYMENT_LINK_120000`
- `STRIPE_PAYMENT_LINK_150000`
- `STRIPE_PAYMENT_LINK_220000`
- `WARMEMO_AUTH_PERSISTENCE` (`SESSION` by default)

### Public URL

- `PUBLIC_BASE_URL` (recommended for QR/public page consistency across envs)

## Local Development

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=env/payment.dev.json
```

## Build Web

```bash
flutter build web --release --base-href "/warmmemo/" --dart-define-from-file=env/payment.dev.json
```

## Test & Coverage Commands

```bash
flutter analyze
flutter test
flutter test --coverage
```

Coverage output:

- `coverage/lcov.info`

## Release Checklist (v0.2)

- Update `pubspec.yaml` version to `0.2.0+0`
- Re-run:
  - `flutter analyze`
  - `flutter test`
  - `flutter test --coverage`
- Confirm Firestore rules deployed:
  - `firestore.rules`
- Verify key flows in smoke run:
  - memorial public link + QR
  - obituary generation/share path
  - proposal -> admin assign -> material -> schedule
  - top-up request and admin processing
- Confirm environment variables for production (especially `PUBLIC_BASE_URL`)

## SOP Templates

- Customer Support SOP: `docs/sop/phase1_customer_support_sop.md`
- Admin Operations SOP: `docs/sop/phase1_admin_operations_sop.md`

## Known Constraints

- Coverage badge is manually synced from local run output.
- Weekly funnel is derived from available order timestamps and verification logs (best-effort inference).
- Validation analytics is best-effort and never blocks user flow.
