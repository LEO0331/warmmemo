# WarmMemo — Claude Guide

This file now follows the same harness split as the repo-local `AGENTS.md`.

Read in this order:

1. `AGENTS.md`
2. `docs/progress.md`
3. `docs/info.md`
4. `docs/flow.md`

If the task is operational or cross-cutting, also read:

- `docs/harness/README.md`
- `docs/harness/task-routing.md`
- `docs/harness/verification-matrix.md`

Core rules:

- Do not change business logic unless requested.
- Keep schema changes additive and backward compatible.
- Treat Firestore rules as security-sensitive.
- Run `flutter analyze` after code changes.
- Run targeted tests for changed areas; run full `flutter test` for broad or release-facing changes.
- Update `docs/info.md`, `docs/progress.md`, `docs/flow.md`, or `docs/harness/*` when their contract changes.

This file should stay short and act as a pointer, not a second full instruction source.
