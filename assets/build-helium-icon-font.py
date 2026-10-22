#!/usr/bin/env python3
"""Build the one-glyph icon font used by the Helium menu rows.

Omarchy menu rows render their `icon` field as TEXT in the row font, so an
image icon is impossible — but a row may override the font family via
`iconFont`. This script turns Helium's official app icon (the white
8-spike starburst, straight from https://helium.computer/icon/helium-app-icon.svg)
into a tiny TTF so the menu row can show the real logo shape.

Output: assets/OmarchyHeliumIcon.ttf  (glyph at U+E00B, a PUA codepoint the
Nerd Font does NOT use, so a missing font shows tofu instead of a wrong icon)

Rebuild with:  python3 assets/build-helium-icon-font.py
"""

import os
import re
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

FAMILY = "OmarchyHeliumIcon"
GLYPH_NAME = "heliumStar"
GLYPH_CODEPOINT = 0xE00B  # BMP private use, unused by Nerd Fonts
UPM = 1000
SRC_SVG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "helium-app-icon.svg")
OUT_TTF = os.path.join(os.path.dirname(os.path.abspath(__file__)), "OmarchyHeliumIcon.ttf")

# The starburst outline: a single closed polygon of straight segments, taken
# verbatim from the official SVG (256x256 viewBox, y pointing down).
SVG_SIZE = 256.0
# Glyph placement inside the em square: the star is scaled to ~73% of the em
# and centred on the text line box centre (ascender 800 / descender -200),
# so it renders optically centred in a menu row like the Nerd Font icons do.
STAR_HEIGHT_UNITS = 726.0
LINE_CENTRE = 300.0  # (800 + -200) / 2 — middle of the line box, above baseline

# Placement of the star inside its advance box. The menu centers the icon
# TEXT (its advance box) inside a fixed-width cell, so the advance determines
# where the ink lands. We make the advance exactly the ink width and start the
# ink at the origin, which puts the ink dead-centre in the cell. (A zero
# advance would centre it too, but Qt drops zero-advance glyphs — they render
# as nothing. A full-em advance with centred ink pushes the icon half an em
# left, making it hug the row's left edge.)


def parse_star_points(svg_path):
    """Extract the starburst path from the SVG and return its points."""
    with open(svg_path, "r", encoding="utf-8") as fh:
        svg = fh.read()
    match = re.search(r'\bd="([^"]+)"', svg)
    if not match:
        sys.exit(f"no path data found in {svg_path}")
    tokens = re.findall(r"([MLZmlz])|(-?\d+(?:\.\d+)?)", match.group(1))
    points, cmd, coords = [], None, []
    for flag, num in tokens:
        if flag:
            if cmd == "L" and coords:
                points.extend(zip(coords[0::2], coords[1::2]))
            cmd, coords = flag.upper(), []
            if cmd == "Z":
                break
        else:
            coords.append(float(num))
    if cmd == "M" and coords:  # first move is the first vertex
        points.extend(zip(coords[0::2], coords[1::2]))
    if len(points) < 3:
        sys.exit(f"parsed too few points from {svg_path}: {points}")
    return points


def to_font_units(points):
    """Map SVG coords (y down, 256 grid) to font units (y up, centred)."""
    scale = STAR_HEIGHT_UNITS / 186.0  # star spans y 35..221 in the SVG
    cx = SVG_SIZE / 2.0
    cy = SVG_SIZE / 2.0
    return [((x - cx) * scale, LINE_CENTRE - (y - cy) * scale) for x, y in points]


def build():
    points = to_font_units(parse_star_points(SRC_SVG))

    # Shift the ink so it starts at the origin: with lsb=0 and an advance
    # equal to the ink width, the shaper sees a normal glyph AND the ink is
    # centred inside its advance box (the star is symmetric around its middle).
    x_min = min(p[0] for p in points)
    x_max = max(p[0] for p in points)
    points = [(x - x_min, y) for x, y in points]
    advance = int(round(x_max - x_min))

    pen = TTGlyphPen(None)
    pen.moveTo(points[0])
    for pt in points[1:]:
        pen.lineTo(pt)
    pen.closePath()
    star = pen.glyph()

    empty = TTGlyphPen(None).glyph()

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder([".notdef", "space", GLYPH_NAME])
    fb.setupCharacterMap({0x20: "space", GLYPH_CODEPOINT: GLYPH_NAME})
    fb.setupGlyf({".notdef": empty, "space": empty, GLYPH_NAME: star})
    fb.setupHorizontalMetrics({
        ".notdef": (UPM, 0),
        "space": (UPM, 0),
        GLYPH_NAME: (advance, 0),
    })
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({
        "familyName": FAMILY,
        "styleName": "Regular",
        "fullName": FAMILY,
        "psName": f"{FAMILY}-Regular",
        "version": "1.0",
        "copyright": "Helium starburst outline from helium.computer official app icon",
    })
    fb.setupOS2(
        sTypoAscender=800, sTypoDescender=-200, sTypoLineGap=0,
        usWinAscent=800, usWinDescent=200,
    )
    fb.setupPost()
    # Fixed timestamp so the build is byte-reproducible: menu-setup.sh uses
    # `cmp` to decide whether the installed font is stale, and a "now"
    # timestamp would make every rebuild look different.
    # (3850070400 = 2026-01-01 in head's 1904-epoch seconds.)
    fb.font["head"].created = 3850070400
    fb.font["head"].modified = 3850070400
    fb.save(OUT_TTF)
    print(f"wrote {OUT_TTF} ({os.path.getsize(OUT_TTF)} bytes), "
          f"glyph U+{GLYPH_CODEPOINT:04X} in family '{FAMILY}'")


if __name__ == "__main__":
    build()
