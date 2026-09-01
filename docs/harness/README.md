# Harness Layer

This folder contains the project-local harness engineering layer for WarmMemo.

Goal:
- keep the repo entry guidance short
- route agents to the right context only when needed
- reduce duplicated instructions across prompt files and docs

Read order:

1. [Task Routing](./task-routing.md)
2. [Verification Matrix](./verification-matrix.md)
3. [Project Review (2026-05-26)](./review-2026-05-26.md)
4. Root [`feature_list.json`](../../feature_list.json) for active feature state and dependencies
5. Root [`progress.md`](../../progress.md) for the latest evidence and next step
6. Root [`session-handoff.md`](../../session-handoff.md) when resuming incomplete work

Principles:

- The root `AGENTS.md` is a router, not a knowledge base.
- Topic-heavy guidance lives here in smaller files.
- Historical lessons should become tests or code invariants when possible.
- New rules must state scope, trigger, and why they are not better enforced in code.
- Use [`../../init.sh`](../../init.sh) as the fail-fast baseline verification entrypoint (from Git Bash or WSL).
