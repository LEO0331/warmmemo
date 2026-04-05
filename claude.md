# Claude Rules (Basic)

This file defines the default working rules for contributors and AI assistants.

## 1) Safety and Scope

- Do not change existing business logic unless explicitly requested.
- Prefer additive, backward-compatible changes.
- Do not modify Firestore permission semantics without approval.

## 2) Code Change Policy

- Keep changes minimal and focused on the task.
- Preserve current UI/UX style unless a redesign is requested.
- Avoid introducing new architecture/framework migrations in small tasks.

## 3) Quality Gate

- Run `flutter analyze` after code edits.
- Run targeted tests for touched areas; run full tests before release/demo when possible.
- Do not silence errors by removing functionality.

## 4) Performance and Reliability

- Avoid unnecessary rebuilds, duplicate API calls, and blocking UI operations.
- Use guardrails for user input (date/number/text validation and sanitization).
- Add lightweight loading/error states for async actions.

## 5) Documentation Discipline

- Update `docs/progress.md` when major behavior changes land.
- Update `docs/flow.md` when button flows or routes change.
- Keep `skills.md` aligned with current project patterns.

## 6) Deployment and CI/CD

- CI must pass (`flutter analyze` + `flutter test`) before deployment.
- Keep GitHub Pages deployment workflow gated by CI success.
- Use manual redeploy only for controlled recovery.

