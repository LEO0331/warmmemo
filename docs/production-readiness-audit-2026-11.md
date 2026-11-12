# WarmMemo production-readiness audit

November 12, 2026 · Audit baseline `aad238a0cffffbd97c1a26a144e802386015754d` · Verified deployed main `42c49767f355326274187457c266fe41ba81fbd4`

Main includes financial footing, offline Traditional Chinese PDF support, the backend dependency update, deployment reliability and landing CTA fixes, and the CI coverage gate. [PR #27](https://github.com/LEO0331/warmmemo/pull/27) · [PR #28](https://github.com/LEO0331/warmmemo/pull/28) · [PR #29](https://github.com/LEO0331/warmmemo/pull/29) · [PR #30](https://github.com/LEO0331/warmmemo/pull/30) · [PR #31](https://github.com/LEO0331/warmmemo/pull/31)

| Area | Status | Evidence |
| --- | --- | --- |
| Final Countdown | PASS | The full 177-test Flutter suite passed. The focused model and widget tests cover legacy drafts, distinct current and lifetime figures, the optional section, unchanged readiness and keyboard semantics at 360 px. Traditional Chinese and English render in the fixtures. |
| Financial privacy | PASS | Widget tests confirm that snapshot values remain session-only and are absent from the saved planning draft. |
| Offline Chinese PDF | FAIL on deployed main | The offline exporter passed the original Chrome smoke. The deployed font can substitute a glyph when two characters share one outline. PR #32 corrects the defect and passed all five PDF tests, all 178 Flutter tests, and both offline browser exports after asset loading. [PDF verification](offline-chinese-pdf-font.md) · [Open correction](https://github.com/LEO0331/warmmemo/pull/32) |
| Firebase Security Rules | OWNER-CONFIRMED PASS | The owner accepted the Firebase Rules Emulator results. The emulator was not rerun for this audit. |
| Stripe Sandbox | OWNER-CONFIRMED PASS | The owner accepted the Stripe Sandbox results. Payment transactions were not rerun. |
| Deployment reliability | PASS | The Pages build and deployment passed for main at `42c4976` after PR #31 merged. [Main CI](https://github.com/LEO0331/warmmemo/actions/runs/43164696341) · [Pages run](https://github.com/LEO0331/warmmemo/actions/runs/43164913849) |
| CI coverage | PASS | Locally, Flutter 3.47.2 covered 3,276/3,545 lines (92.4118%). Main CI covered 3,277/3,545 (92.44%), passed the 92% floor, and published `flutter-lcov`. All ten checker tests passed. Raising the local threshold to 92.42% failed as expected. [Main CI](https://github.com/LEO0331/warmmemo/actions/runs/43164696341) · [LCOV artifact](https://github.com/LEO0331/warmmemo/actions/runs/43164696341/artifacts/13918844345) |
| Browser and Patrol | PASS WITH LIMITATIONS | All four existing Patrol cases passed with installed Chrome against the current Patrol web server: landing, primary CTA, login validation and registration validation. The stock bundled Playwright runner timed out during global initialization before discovering tests. Fresh public links at 1280 px and 390 px showed the expected missing-memorial state and rendered a synthetic obituary. Changing the hash on an already open landing page returned to the landing page in the tested browser. A populated memorial was outside this check. |
| SEO | PASS | The hosted coverage run passed the existing crawlable-file validation. |
| Backend checks | PASS | The hosted coverage run passed the existing Node.js 22 backend dependency and compatibility step. |

## Acceptance decisions

- **Portfolio and demo — PASS WITH LIMITATIONS.** The guest flow, synthetic obituary and planning fixtures passed. Use fresh public links. The PDF glyph issue affects some full-font documents.
- **GitHub Pages — PASS for main at `42c4976`.** Verify the matching main CI and Pages run again after the PDF correction merges.
- **Real-user production — BLOCKED for final acceptance.** Review and deploy the PDF correction, then recheck the intended release and its authenticated flows. Fresh offline launch is outside the PDF guarantee, and the signed-in export buttons still depend on the existing service-token checks.
- **Payment operations — OWNER-CONFIRMED PASS.** Continue reconciling Stripe payments against the Firestore order reference and updating status manually.

Coverage is merged and verified on main. Formal production acceptance remains pending for the release that includes [PR #32](https://github.com/LEO0331/warmmemo/pull/32).
