#!/usr/bin/env python3
"""
Red Grid Link — screenshot frame compositor.

Takes raw device PNGs from screenshots/<device>/ and produces App Store
ready images in screenshots/<device>/framed/. Each framed image is:

  +----------------------------------------------------+
  | [tactical caption bar: 22% height]                 |
  |   HEADLINE TEXT                                    |
  |   subheadline                                      |
  +----------------------------------------------------+
  |                                                    |
  |   [actual device screenshot shrunk to 78% height]  |
  |                                                    |
  +----------------------------------------------------+

Output dimensions match the raw source exactly so Apple's auto-scaling
and device-class validation both pass:

  iPhone 6.9"    1320 × 2868   (iPhone 17 Pro Max)
  iPad 13"       2064 × 2752   (iPad Pro M5)

Uses only Pillow (installed via `pip install --user pillow`).

Usage:
  python3 tools/screenshots/frame.py
  python3 tools/screenshots/frame.py iphone_17_pro_max
  python3 tools/screenshots/frame.py ipad_pro_13_m5
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[2]
SCREENSHOTS_DIR = REPO_ROOT / "screenshots"

# Tactical palette (from lib/core/theme/tactical_colors.dart red theme)
BG = (10, 0, 0)           # #0A0000
CARD = (13, 0, 0)          # #0D0000
BORDER = (102, 0, 0)       # #660000
TEXT = (187, 0, 0)         # #BB0000
TEXT2 = (204, 68, 68)      # #CC4444
ACCENT = (221, 34, 34)     # #DD2222

# Caption bar takes 22% of total height
CAPTION_BAR_FRAC = 0.22

# Captions per screenshot name
# Max ~40 chars for headline to stay readable on listing thumbnails
CAPTIONS = {
    "01_map_team": (
        "YOUR TEAM. ONE MAP.",
        "Encrypted Bluetooth team sync — no cell towers",
    ),
    "02_grid_mgrs": (
        "MGRS PRECISION NAVIGATION",
        "Live 10-digit grid, 1-meter precision",
    ),
    "03_field_link": (
        "FIELD LINK — ZERO INFRASTRUCTURE",
        "AES-256-GCM + ECDH P-256 key exchange",
    ),
    "04_tools": (
        "11 TACTICAL TOOLS",
        "Dead reckoning, resection, coord converter + 8 more",
    ),
    "05_themes": (
        "4 TACTICAL DISPLAY THEMES",
        "Red Light, NVG Green, Day White, Blue Force",
    ),
    "06_nvg_green_theme": (
        "NIGHT VISION READY",
        "NVG Green theme — night observation device compatible",
    ),
    "07_blue_force_theme": (
        "BLUE FORCE DISPLAY",
        "Blue-force tracker color scheme for C2 environments",
    ),
    "08_day_white_theme": (
        "HIGH-VISIBILITY DAY MODE",
        "Day White theme — full contrast in direct sunlight",
    ),
}


def find_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    """Find a monospace font on macOS, preferring bold for headlines."""
    candidates_bold = [
        "/System/Library/Fonts/SFNSMono.ttf",
        "/System/Library/Fonts/Supplemental/Menlo.ttc",
        "/System/Library/Fonts/Monaco.ttf",
        "/Library/Fonts/Menlo.ttc",
    ]
    candidates_regular = candidates_bold
    paths = candidates_bold if bold else candidates_regular
    for path in paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def draw_caption_bar(
    canvas: Image.Image, headline: str, subheadline: str, bar_height: int
) -> None:
    """Draws the tactical caption bar on top of canvas."""
    draw = ImageDraw.Draw(canvas, "RGBA")
    w = canvas.width

    # Fill caption area with near-black
    draw.rectangle((0, 0, w, bar_height), fill=BG)

    # Bottom border stripe (1px of TEXT color, subtle)
    draw.line((0, bar_height - 2, w, bar_height - 2), fill=BORDER, width=2)

    # Top corners accent (small tactical marks)
    corner_len = int(w * 0.04)
    corner_thick = max(2, int(w * 0.003))
    for cx in (int(w * 0.05), int(w * 0.95) - corner_len):
        draw.rectangle(
            (cx, int(bar_height * 0.15), cx + corner_len, int(bar_height * 0.15) + corner_thick),
            fill=ACCENT,
        )

    # Headline: bold, accent color, letter-spaced feel via spacing between chars
    headline_size = int(bar_height * 0.28)
    sub_size = int(bar_height * 0.13)

    head_font = find_font(headline_size, bold=True)
    sub_font = find_font(sub_size)

    # Center headline
    bbox = draw.textbbox((0, 0), headline, font=head_font)
    head_w = bbox[2] - bbox[0]
    head_h = bbox[3] - bbox[1]
    head_x = (w - head_w) // 2
    head_y = int(bar_height * 0.35)
    draw.text((head_x, head_y), headline, font=head_font, fill=ACCENT)

    # Subheadline below
    sub_bbox = draw.textbbox((0, 0), subheadline, font=sub_font)
    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = (w - sub_w) // 2
    sub_y = head_y + head_h + int(bar_height * 0.06)
    draw.text((sub_x, sub_y), subheadline, font=sub_font, fill=TEXT2)


def compose_framed(raw_path: Path, out_path: Path) -> None:
    """Produces a final App Store frame for the raw capture at raw_path."""
    name = raw_path.stem
    caption = CAPTIONS.get(name)
    if caption is None:
        print(f"  SKIP {name} — no caption defined")
        return

    raw = Image.open(raw_path).convert("RGB")
    full_w, full_h = raw.size

    # Canvas dimensions match the raw source so Apple's device-class
    # validation passes.
    canvas = Image.new("RGB", (full_w, full_h), BG)

    bar_height = int(full_h * CAPTION_BAR_FRAC)
    screenshot_height = full_h - bar_height

    # Scale raw screenshot to fit the remaining area, centered
    raw_aspect = full_w / full_h
    screenshot_aspect = full_w / screenshot_height
    if raw_aspect > screenshot_aspect:
        # Raw is wider — scale by width
        new_w = full_w
        new_h = int(full_w / raw_aspect)
    else:
        new_h = screenshot_height
        new_w = int(screenshot_height * raw_aspect)
    scaled = raw.resize((new_w, new_h), Image.LANCZOS)

    paste_x = (full_w - new_w) // 2
    paste_y = bar_height + (screenshot_height - new_h) // 2
    canvas.paste(scaled, (paste_x, paste_y))

    draw_caption_bar(canvas, caption[0], caption[1], bar_height)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, "PNG", optimize=True)
    print(f"  ✓ {out_path.name}  ({full_w}x{full_h})")


def process_device(device: str) -> None:
    src_dir = SCREENSHOTS_DIR / device
    dst_dir = SCREENSHOTS_DIR / device / "framed"
    if not src_dir.exists():
        print(f"No raw screenshots in {src_dir}")
        return
    raws = sorted(src_dir.glob("*.png"))
    if not raws:
        print(f"No PNGs found in {src_dir}")
        return
    print(f"\n=== {device} ===")
    for raw in raws:
        if raw.parent.name == "framed":
            continue
        out = dst_dir / raw.name
        compose_framed(raw, out)


def main() -> int:
    targets = sys.argv[1:] if len(sys.argv) > 1 else [
        "iphone_17_pro_max",
        "ipad_pro_13_m5",
    ]
    for device in targets:
        process_device(device)
    return 0


if __name__ == "__main__":
    sys.exit(main())
