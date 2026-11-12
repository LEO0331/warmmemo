# Offline Traditional Chinese PDF exports

The memorial and obituary exporters use bundled fonts for Traditional Chinese, Latin text, digits, and punctuation. The exporter checks the actual text against the font's Unicode character map. It uses the small regular and bold subsets when they cover the text and opens the full local regular font only when a subset is unavailable or lacks a glyph. The PDF embeds glyphs used by the document. A character absent from the full font produces an export error with its Unicode code point.

Flutter registers the files as assets so the app can load them on demand. The landing page uses system fonts. The exporter retains fonts it has already loaded in the current app session. A first export needs access to the applicable bundled assets, either from the app host or the browser cache. Both signed-in export buttons still require the existing service-token check before PDF generation.

The memorial exporter continues to include the public link and its QR code when the page is published. The administrator compliance exporter retains its Google Fonts preference and uses the full local font for its existing local fallback.

## Font source and regeneration

The assets derive from Noto Sans TC 2.004-H2, distributed under the SIL Open Font License 1.1. The bundle includes the original license and copyright notice. The build script verifies SHA-256 `864727d210d54f2537bbe23b3a839436c3992af72de9322af5270897246bd44f` and names the modified fonts WarmMemo PDF. [Pinned Google Fonts source](https://github.com/google/fonts/blob/b950a7257470b900078f2bf3223823a8602de7e1/ofl/notosanstc/NotoSansTC%5Bwght%5D.ttf) · [FontTools subset documentation](https://fonttools.readthedocs.io/en/stable/subset/index.html)

```sh
python -m pip install fonttools==4.61.1
python tools/build_pdf_fonts.py
```

Supply `--source /path/to/upstream.ttf` to rebuild with a predownloaded copy. The subset inputs in the script include fixed PDF labels, deterministic fixtures, Latin and common punctuation.

| Bundled font | Weight | Unicode mappings | Bytes |
| --- | ---: | ---: | ---: |
| Regular subset | 400 | 185 | 31,032 |
| Bold subset | 700 | 185 | 30,964 |
| Full regular | 400 | 20,745 | 7,149,192 |

The previous 11,917,560-byte files were byte-identical Noto Sans TC variable fonts with a default weight of 100. Their checksum differs from the pinned Google Fonts release. The generated full static fallback preserves the pinned release's Unicode repertoire. The combined font and license bundle is 7,215,575 bytes.

Supplementary-plane glyphs supported by the full font, such as 𠱓, render on the page. The current PDF library's Unicode map can omit them during copy or text extraction.

## Verification

```sh
flutter test test/pdf_exporter_test.dart
flutter build web --release --base-href /warmmemo/ --no-web-resources-cdn
flutter build web --release --base-href /warmmemo/ --no-web-resources-cdn --target tools/pdf_web_smoke.dart --output .dart_tool/pdf-smoke/fixture
node tools/verify_pdf_web.cjs build/web .dart_tool/pdf-smoke/fixture .dart_tool/pdf-smoke/output
```

The browser check uses Playwright and Chromium. Set `PLAYWRIGHT_MODULE` if the package is installed outside the repo and `CHROME_EXECUTABLE` to use installed Chrome. It checks the production build at startup and runs the same PDF and download code through a separate release-mode fixture with synthetic drafts. The fixture bypasses the signed-in service-token check.

Chrome made zero PDF font requests at production startup. A cold memorial export fetched only the 61,996 bytes of subsets and generated a 12,681-byte PDF in 247 ms. A cold obituary export fetched the full fallback for its uncommon glyphs and generated a 10,879-byte PDF in 174 ms. With the browser offline and its service worker disabled, both exports downloaded again from the live session in 83 ms and 99 ms respectively, without requests to the asset server. Timings are from one local run and include the download.

Poppler rendered both downloaded pages. Traditional Chinese, English, punctuation, and the uncommon characters 龘 and 𠱓 were legible. The memorial QR decoded to the exact synthetic public URL. Flutter analysis and all 177 tests passed.

## 繁體中文

紀念頁及訃聞可用應用程式內建的繁體中文字型產生 PDF。程式會逐字檢查涵蓋範圍，子集缺字時改用完整字型。完整字型也缺字時，畫面會提示 Unicode 字元代碼，讓使用者可修正後再試。第一次匯出需能讀取應用程式字型資源，已載入的字型可在同一工作階段離線使用。登入後的兩個匯出按鈕仍會先連線檢查服務額度。
