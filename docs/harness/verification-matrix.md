# WarmMemo Verification Matrix

Use the lightest verification that still proves the change.

## Minimum by change type

| Change type | Required verification |
| --- | --- |
| Docs only | proofread changed docs |
| Small Dart logic change | `flutter analyze` |
| Service / repository / model | `flutter analyze` + targeted `flutter test` |
| Auth / routing / payment / admin flow | `flutter analyze` + `flutter test` |
| Release-facing or broad changes | `flutter analyze` + full `flutter test` |
| UI flow regression risk | add Patrol or widget verification if practical |

## Common commands

- Analyze: `flutter analyze`
- Full tests: `flutter test`
- Single test file: `flutter test test/<file>.dart`
- Patrol smoke: `patrol test -t patrol_test/app_smoke_test.dart -d chrome`

## Evidence standard

Do not claim completion until you have:

1. run the relevant command
2. read the result
3. reported the concrete outcome

## Replace prose with enforcement

If the same issue repeats, prefer:
- a unit test
- a widget test
- a service invariant
- a typed data contract

Do not keep stacking warning text into `AGENTS.md`.
