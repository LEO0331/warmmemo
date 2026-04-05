# AI Reference Document

This file is intended for AI assistants resuming work on this project.
Read this alongside docs/PROGRESS.md before starting any task.
For workflow rules and coding conventions, see claude.md at the project root.
For a human-readable button-by-button flow diagram, see docs/FLOW.md.
Current repository filenames are lowercase: `docs/progress.md` and `docs/flow.md`.

## Project Snapshot

- Stack: Flutter Web + Firebase Auth + Firestore.
- Product focus: memorial drafting, obituary generation, business order funnel (proposal -> review -> vendor assign -> material -> delivery milestones).
- Current release track: v0.2.

## Critical Runtime Notes

- Public routes are resolved in `lib/features/auth/auth_gate.dart`:
  - `#/m/:slug` => public memorial page.
  - `#/o?...` => public obituary page.
- Firestore permissions are strict for admin-only fields:
  - User writable: proposal-related fields.
  - Admin writable: vendor assignment/material/delivery schedule/vendors.

## Font/Performance Strategy (Web)

- UI no longer hard-binds heavy bundled Chinese TTF for startup.
- Exporters now resolve fonts on-demand:
  - Prefer Google Fonts `Noto Serif HK` (runtime fetch).
  - Then local subset `assets/fonts/NotoSansTC-Subset.ttf` if provided.
  - Then local full font / Helvetica fallback.
- Goal: reduce first paint latency while keeping Chinese export capability.

## Where To Start When Debugging

- Auth/entry: `lib/features/auth/auth_gate.dart`
- Landing: `lib/features/landing/landing_page.dart`
- Memorial workspace: `lib/features/memorial/memorial_page_tab.dart`
- Obituary workspace: `lib/features/obituary/digital_obituary_tab.dart`
- Admin dashboard/funnel: `lib/features/admin/admin_dashboard.dart`
- Exporters: `lib/core/export/pdf_exporter.dart`, `lib/core/export/compliance_exporter.dart`

## Operational Rules

- Do not break existing business flow.
- Prefer additive changes and nullable-compatible data shape updates.
- Keep UI/UX style consistent unless explicitly requested.
- Run `flutter analyze` after code edits.
