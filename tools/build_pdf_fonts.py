"""Build WarmMemo's local PDF fonts with fontTools 4.61.1."""

import argparse
from copy import deepcopy
from hashlib import sha256
from io import BytesIO
from pathlib import Path
from urllib.request import urlopen

import fontTools
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont


SOURCE_URL = (
    "https://raw.githubusercontent.com/google/fonts/"
    "b950a7257470b900078f2bf3223823a8602de7e1/ofl/notosanstc/"
    "NotoSansTC%5Bwght%5D.ttf"
)
SOURCE_SHA256 = "864727d210d54f2537bbe23b3a839436c3992af72de9322af5270897246bd44f"
FONTTOOLS_VERSION = "4.61.1"
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "fonts"

# Fixed PDF labels, meaning prompts, common punctuation, and synthetic fixtures.
SUBSET_TEXT = (
    "WarmMemo 紀念頁 姓名 暱稱 一句話 生平摘要 人生亮點 給後人的話 公開紀念頁"
    "訃聞 逝者姓名 關係 地點 時間 語氣 補充註記"
    "他們的人生說出什麼故事？ 什麼給了他們方向與目的？ 他們的人生對誰很重要？ 哪些回憶不該被忘記？"
    "，。、；：？！「」『』（）《》〈〉【】—…·"
    "陳美玲，John 2026。王小明，Mary 2026。"
)


def source_bytes(source: Path | None) -> bytes:
    if source is None:
        with urlopen(SOURCE_URL, timeout=60) as response:
            data = response.read()
    else:
        data = source.read_bytes()
    if sha256(data).hexdigest() != SOURCE_SHA256:
        raise ValueError("Noto Sans TC source does not match the pinned SHA-256")
    return data


def keep_glyphs(font: TTFont, codepoints: set[int]) -> None:
    options = subset.Options()
    options.harfbuzz_repacker = False
    # The PDF library embeds TrueType outlines and maps glyphs by Unicode.
    options.layout_features = []
    options.name_IDs = ["*"]
    options.ignore_missing_unicodes = False
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=sorted(codepoints))
    subsetter.subset(font)
    if set(font.getBestCmap()) != codepoints:
        raise ValueError("Generated font's Unicode coverage differs from its input")


def separate_unicode_glyphs(font: TTFont) -> None:
    # pdf 3.11.3 removes each source glyph from its subset queue after first use.
    # Give each Unicode mapping its own glyph ID while keeping its outline.
    mappings = font.getBestCmap()
    unicode_maps = [
        table.cmap
        for table in font["cmap"].tables
        if table.isUnicode() and table.format != 14
    ]
    order = list(font.getGlyphOrder())
    seen = set()
    for codepoint, glyph in sorted(mappings.items()):
        if glyph not in seen:
            seen.add(glyph)
            continue
        alias = f"warmmemo.u{codepoint:06X}"
        if alias in font["glyf"]:
            raise ValueError(f"Generated glyph name already exists: {alias}")
        font["glyf"][alias] = deepcopy(font["glyf"][glyph])
        font["hmtx"][alias] = font["hmtx"][glyph]
        if "vmtx" in font:
            font["vmtx"][alias] = font["vmtx"][glyph]
        order.append(alias)
        for mapping in unicode_maps:
            if mapping.get(codepoint) == glyph:
                mapping[codepoint] = alias
    font.setGlyphOrder(order)
    if len(set(mappings.values())) != len(mappings):
        raise ValueError("Generated font still has shared Unicode glyph IDs")


def save(font: TTFont, path: Path, style: str, is_subset: bool = False) -> None:
    family = "WarmMemo PDF Subset" if is_subset else "WarmMemo PDF"
    postscript = f"WarmMemoPDF-{style}{'Subset' if is_subset else ''}"
    names = {
        1: family,
        2: style,
        3: f"{postscript};2.004-H2",
        4: f"{family} {style}",
        6: postscript,
        16: family,
        17: style,
    }
    name_table = font["name"]
    for name_id, value in names.items():
        name_table.removeNames(nameID=name_id)
        name_table.setName(value, name_id, 3, 1, 0x409)
    font.save(path, reorderTables=True)
    print(f"{path.name}: {path.stat().st_size:,} bytes, {len(font.getBestCmap()):,} code points")


def build(data: bytes, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    subset_codepoints = set(range(0x20, 0x7F)) | {ord(char) for char in SUBSET_TEXT}
    with TTFont(BytesIO(data), recalcTimestamp=False) as regular:
        full_codepoints = set(regular.getBestCmap())
        instantiateVariableFont(regular, {"wght": 400}, inplace=True)
        if set(regular.getBestCmap()) != full_codepoints:
            raise ValueError("Static instantiation changed the full font's Unicode coverage")
        separate_unicode_glyphs(regular)
        save(regular, output_dir / "NotoSansTC-Regular.ttf", "Regular")

    for weight, style, name in (
        (400, "Regular", "NotoSansTC-Subset.ttf"),
        (700, "Bold", "NotoSansTC-Bold-Subset.ttf"),
    ):
        with TTFont(BytesIO(data), recalcTimestamp=False) as font:
            keep_glyphs(font, subset_codepoints)
            instantiateVariableFont(font, {"wght": weight}, inplace=True)
            save(font, output_dir / name, style, is_subset=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="Use a local copy of the pinned upstream TTF")
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    args = parser.parse_args()
    if fontTools.__version__ != FONTTOOLS_VERSION:
        parser.exit(1, f"Install fonttools=={FONTTOOLS_VERSION} before regenerating fonts.\n")
    build(source_bytes(args.source), args.output_dir)


if __name__ == "__main__":
    main()
