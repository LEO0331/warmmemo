# WarmMemo Agent Router

This repository is a Flutter Web + Firebase product for memorial content, obituary drafting, digital persona generation, and order workflow management.

Use this file as the project entry router. Do not treat it as a full encyclopedia.

## Quick start

- Install deps: `flutter pub get`
- Static check: `flutter analyze`
- Full test suite: `flutter test`
- E2E smoke (when UI flow changed): `patrol test -t patrol_test/app_smoke_test.dart -d chrome`

## Startup Workflow

1. Read `feature_list.json` and root `progress.md` to identify the active work and its latest evidence.
2. Read the base context and only the task-specific files listed below.
3. Confirm the task's scope, dependencies, and required verification before editing.
4. Run `./init.sh` (Git Bash/WSL) or the equivalent Flutter commands before broad work; record any relevant result in `progress.md`.

## Scope

- **One feature at a time.** Complete or explicitly hand off the active feature before starting another one.
- **Stay in scope.** Do not fold opportunistic refactors, schema migrations, dependency upgrades, or deployment changes into an unrelated task.

## Definition of Done

A task is done only when its requested behavior and documentation are updated, required verification has passed, and `progress.md` records the evidence or a concrete reason it could not be run.

## Hard constraints

1. Do not change business workflow semantics unless explicitly requested.
2. Keep Firestore schema changes additive and backward compatible.
3. Treat `firestore.rules` changes as security-sensitive and verify affected reads/writes.
4. Do not move payment secret handling into the Flutter client.
5. Preserve public memorial / obituary route behavior.
6. Prefer focused diffs over broad refactors.
7. Run `flutter analyze` after code changes.
8. Run targeted tests for touched areas; run `flutter test` for broad or release-facing changes.
9. Update docs when behavior, architecture, or operating procedure changes.
10. If a historical rule can be enforced by code or test, prefer that over adding more prose here.

## Read in this order

1. `docs/progress.md` — current status, known risks, recent changes
2. `docs/info.md` — architecture, data contract, deployment context
3. `docs/flow.md` — button-level behavior and routing flow

## Task routing

Read extra docs only when relevant:

- Auth, routing, public pages:
  - `docs/flow.md`
  - `lib/features/auth/auth_gate.dart`
  - `lib/features/auth/auth_page.dart`
- Admin / order workflow:
  - `docs/info.md`
  - `docs/system_design_architecture_tradeoffs.md`
  - `lib/features/admin/admin_dashboard.dart`
  - `lib/data/services/purchase_service.dart`
- Firestore rules / roles / permissions:
  - `firestore.rules`
  - `docs/info.md`
  - `docs/harness/review-2026-05-26.md`
- Payments / checkout:
  - `lib/features/packages/checkout_page.dart`
  - `lib/data/services/payment_service.dart`
  - `docs/progress.md`
- Digital persona / skills:
  - `lib/features/skills/skill_generator_tab.dart`
  - `lib/data/models/cyber_skill.dart`
  - `lib/data/services/cyber_skill_*`
- Final countdown:
  - `lib/features/final_countdown/final_countdown_tab.dart`
  - `docs/flow.md`
- Harness / operating model:
  - `docs/harness/README.md`
  - `docs/harness/task-routing.md`
  - `docs/harness/verification-matrix.md`

## Verification routing

- UI text/layout only: `flutter analyze`
- Service / model / repository changes: `flutter analyze` + targeted `flutter test`
- Auth / route / payment / admin flow changes: `flutter analyze` + `flutter test`
- Release-facing or broad changes: full `flutter test`

## End of Session

Before ending a work session, update root `progress.md` with the current objective, changed files, verification evidence, blockers, and recommended next step. Use `session-handoff.md` when work is incomplete or requires a decision. This keeps the next session restartable without relying on chat history.

## Docs sync rules

Update these when applicable:

- `docs/flow.md` — button behavior or page flow changed
- `docs/info.md` — architecture, schema, permissions, deployment strategy changed
- `docs/progress.md` — current status, risk, operational notes changed
- `docs/harness/*` — agent operating guidance changed
- `README.md` — setup or user-facing capability changed

## Keep this file short

If you are about to add a long rule here, stop and decide whether it belongs in:

- code
- tests
- `docs/harness/*.md`
- `docs/info.md`
- `docs/flow.md`

This file should remain a router.
