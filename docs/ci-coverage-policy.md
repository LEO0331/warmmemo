# Flutter CI coverage policy

The baseline on main `aad238a0cffffbd97c1a26a144e802386015754d`, using Flutter 3.47.2 and all 177 tests, was **3,276 of 3,545 instrumented lines (92.4118%)**. The initial minimum is **92%**, the baseline rounded down to the nearest whole percentage point. This leaves 0.4118 percentage points of headroom from the measured baseline.

Line coverage is the number of unique instrumented production lines with at least one hit divided by the number of unique instrumented production lines. The checker includes every reported Dart source under `lib/`. It excludes tests, dependencies, and files outside that path. It merges repeated file and line records, and cross-checks LCOV totals when present. Branch and function records are outside the line metric. The comparison uses exact counts. The printed percentage is truncated to four decimal places.

The baseline instrumented 42 of 76 production Dart files. Flutter's LCOV report represents the lines the test runner instrumented. Coverage gaps include files absent from the report, and behavioral assertions still determine whether a test demonstrates correctness.

## Local checks

```sh
flutter pub get
flutter analyze
flutter test --coverage
node --test tools/check_flutter_coverage.test.mjs
node tools/check_flutter_coverage.mjs coverage/lcov.info 92
```

The checker exits nonzero for a missed threshold or an absent, malformed, or uninstrumented report. CI runs the Flutter suite once, posts the gate result in the run summary, and publishes `flutter-lcov` under **Artifacts** for 14 days. The upload contains only `coverage/lcov.info` and still runs when tests pass and the coverage gate fails.

Adjust `MIN_FLUTTER_LINE_COVERAGE` in `.github/workflows/ci.yml` through a reviewed PR. Include the measured counts, rationale for the change, and an explanation of any significant change to which production code is instrumented.
