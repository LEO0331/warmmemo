# WarmMemo Task Routing

Use progressive disclosure. Load only the files needed for the task.

## Base context for every task

- `AGENTS.md`
- `docs/progress.md`

Add `docs/info.md` when the task touches architecture, service boundaries, Firestore, deployment, or data contracts.
Add `docs/flow.md` when the task touches UI behavior, routing, buttons, or user-facing transitions.

## Task map

### Auth / session / landing / public routes

Read:
- `docs/flow.md`
- `lib/features/auth/auth_gate.dart`
- `lib/features/auth/auth_page.dart`
- `lib/features/landing/landing_page.dart`
- `lib/data/firebase/auth_service.dart`

### Admin workflow / order processing

Read:
- `docs/info.md`
- `docs/system_design_architecture_tradeoffs.md`
- `lib/features/admin/admin_dashboard.dart`
- `lib/features/admin/order_detail_page.dart`
- `lib/data/models/purchase.dart`
- `lib/data/services/purchase_service.dart`

### Payment / checkout

Read:
- `docs/progress.md`
- `lib/features/packages/checkout_page.dart`
- `lib/features/packages/packages_tab.dart`
- `lib/data/services/payment_service.dart`

### Firestore rules / roles / permissions

Read:
- `firestore.rules`
- `docs/info.md`
- `docs/harness/review-2026-05-26.md`
- `lib/data/services/user_role_service.dart`
- `lib/data/services/user_profile_service.dart`

### Digital persona / cyber skill generation

Read:
- `lib/features/skills/skill_generator_tab.dart`
- `lib/data/models/cyber_skill.dart`
- `lib/data/services/cyber_skill_generator_service.dart`
- `lib/data/services/cyber_skill_storage_service.dart`

### Memorial / obituary / export

Read:
- `docs/flow.md`
- `lib/features/memorial/memorial_page_tab.dart`
- `lib/features/obituary/digital_obituary_tab.dart`
- `lib/core/export/pdf_exporter.dart`
- `lib/data/services/export_service.dart`

### Final countdown / Die with Zero

Read:
- `docs/flow.md`
- `lib/features/final_countdown/final_countdown_tab.dart`

### Documentation-only tasks

Read only the directly affected doc plus `docs/README.md`.

## Escalation rule

If the task spans 3 or more of the areas above, load:
- `docs/info.md`
- `docs/flow.md`
- `docs/system_design_architecture_tradeoffs.md`

Do not load every doc by default.
