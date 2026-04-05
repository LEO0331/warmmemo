---
name: shipping-template-lite
description: Low-token template for fast, safe Flutter/Firebase feature delivery.
tags:
  - template
  - flutter
  - firebase
  - ci-cd
version: 0.2
---

# Shipping Template Lite

Use when token budget is tight and you still need reliable implementation quality.

## Goal

Ship features quickly without breaking existing business flow.

## Rules

1. Do not change existing logic unless requested.
2. Keep UI style consistent.
3. Validate/sanitize all date/number/text inputs before write.
4. Prefer additive, backward-compatible data changes.
5. Add lightweight loading/error states for async actions.

## Business Flow

`proposal -> review -> vendor assignment -> material confirmation -> delivery`

Track:
- proposal rate
- approval rate
- assignment rate
- delivery rate

## Firestore Safety

- User writes: proposal-facing fields only
- Admin writes: vendor/material/schedule/master data

## Delivery Checklist

1. Implement minimal focused change
2. Run `flutter analyze`
3. Run targeted tests
4. Report changed files + risks + next steps

## Docs Sync

If behavior changed, update:
- `docs/flow.md`
- `docs/progress.md`
- `docs/info.md`
