# WarmMemo production-readiness audit

November 12, 2026 · Base main `aad238a0cffffbd97c1a26a144e802386015754d`

Main includes the financial-footing enhancement, offline Traditional Chinese PDF support, backend dependency update, and deployment reliability and landing CTA fixes. [PR #27](https://github.com/LEO0331/warmmemo/pull/27) · [PR #28](https://github.com/LEO0331/warmmemo/pull/28) · [PR #29](https://github.com/LEO0331/warmmemo/pull/29) · [PR #30](https://github.com/LEO0331/warmmemo/pull/30)

| Area | Status | Evidence |
| --- | --- | --- |
| Final Countdown | PASS | The full 177-test Flutter suite passed. The focused model and widget tests cover legacy drafts, distinct current and lifetime figures, the optional section, unchanged readiness and keyboard semantics at 360 px. Traditional Chinese and English render in the fixtures. |
| Financial privacy | PASS | Widget tests confirm that snapshot values remain session-only and are absent from the saved planning draft. |
| Offline Chinese PDF | FAIL | The four existing tests passed. The accepted Chrome evidence confirms both synthetic exports with the network off after assets were loaded. A fresh render on current main showed a separate glyph-embedding defect: the full font maps U+00B7 and U+30FB to the same outline, and the PDF writer can substitute the wrong glyph. The input `·・龘` rendered with two instances of `龘`. The correction is reviewed separately. [Original PDF verification](offline-chinese-pdf-font.md) |
| Firebase Security Rules | OWNER-CONFIRMED PASS | The owner accepted the Firebase Rules Emulator results. The emulator was not rerun for this audit. |
| Stripe Sandbox | OWNER-CONFIRMED PASS | The owner accepted the Stripe Sandbox results. Payment transactions were not rerun. |
| Deployment reliability | PASS | GitHub reports successful build and deploy for the cited main Pages run. [Main CI](https://github.com/LEO0331/warmmemo/actions/runs/43138743271) · [Pages run](https://github.com/LEO0331/warmmemo/actions/runs/43138985291) |
| CI coverage | PASS | Locally, Flutter 3.47.2 covered 3,276/3,545 lines (92.4118%). Hosted CI covered 3,277/3,545 (92.44%), passed the 92% floor, and published `flutter-lcov`. All ten checker tests passed. Raising the local threshold to 92.42% failed as expected. [Hosted CI](https://github.com/LEO0331/warmmemo/actions/runs/43163281410) · [LCOV artifact](https://github.com/LEO0331/warmmemo/actions/runs/43163281410/artifacts/13918359206) |
| Browser and Patrol | PASS WITH LIMITATIONS | All four existing Patrol cases passed with installed Chrome against the current Patrol web server: landing, primary CTA, login validation and registration validation. The stock bundled Playwright runner timed out during global initialization before discovering tests. Fresh public links at 1280 px and 390 px showed the expected missing-memorial state and rendered a synthetic obituary. Changing the hash on an already open landing page returned to the landing page in the tested browser. A populated memorial was outside this check. |
| SEO | PASS | The hosted coverage run passed the existing crawlable-file validation. |
| Backend checks | PASS | The hosted coverage run passed the existing Node.js 22 backend dependency and compatibility step. |

## Acceptance decisions

- **Portfolio and demo — PASS WITH LIMITATIONS.** The guest flow, synthetic obituary and planning fixtures passed. Use fresh public links. The PDF glyph issue affects some full-font documents.
- **GitHub Pages — PASS for the deployed base commit.** The cited Pages build and deployment passed. Validate the matching main CI and Pages run after any release PR is merged.
- **Real-user production — BLOCKED for final acceptance.** Review the coverage draft and the separate PDF correction. Recheck the intended deployed commit and its authenticated flows before formal acceptance. Fresh offline launch is outside the PDF guarantee, and the signed-in export buttons still depend on the existing service-token checks.
- **Payment operations — OWNER-CONFIRMED PASS.** Continue reconciling Stripe payments against the Firestore order reference and updating status manually.

Coverage implementation is verified on [Draft PR #31](https://github.com/LEO0331/warmmemo/pull/31). Formal production acceptance belongs to the intended merged and deployed commit.
