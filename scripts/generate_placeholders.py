#!/usr/bin/env python3
"""
Generate placeholder PNG sprites for Bollard Bash.
Run once: python3 scripts/generate_placeholders.py
Then replace any PNG with your own art (keep the same filename).

PALETTE KEY COLORS (used by the palette_swap shader):
  Body:  #FF00FF (highlight)  #CC00CC (midtone)  #990099 (shadow)
  Shell: #00FFFF (highlight)  #00CCCC (midtone)  #009999 (shadow)
Paint recolorable areas with these exact colors. Everything else stays as-is.

SPRITE STRUCTURE:
  sprites/snail/shared/    — shared by all characters (eyes, stalks)
  sprites/snail/blink/     — Blink character sprites
  sprites/snail/goopy/     — Goopy character sprites
  sprites/snail/zappy/     — Zappy character sprites
  sprites/arena/           — arena elements
"""

import struct
import zlib
import os


def _chunk(chunk_type, data):
    c = chunk_type + data
    crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
    return struct.pack(">I", len(data)) + c + crc


def _png(width, height, pixels):
    """Build a PNG from raw RGBA pixel bytes."""
    header = b"\x89PNG\r\n\x1a\n"
    ihdr = _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    idat = _chunk(b"IDAT", zlib.compress(pixels))
    iend = _chunk(b"IEND", b"")
    return header + ihdr + idat + iend


def make_flat_rect(width, height, r, g, b, a=255):
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            raw += bytes([r, g, b, a])
    return _png(width, height, raw)


def make_flat_circle(size, r, g, b, a=255):
    cx, cy = size / 2.0, size / 2.0
    radius = size / 2.0 - 1
    raw = b""
    for y in range(size):
        raw += b"\x00"
        for x in range(size):
            dx = x - cx + 0.5
            dy = y - cy + 0.5
            if (dx * dx + dy * dy) ** 0.5 <= radius:
                raw += bytes([r, g, b, a])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(size, size, raw)


def make_flat_dome(width, height, r, g, b):
    cx = width / 2.0
    radius = width / 2.0 - 1
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            dx = x - cx + 0.5
            dy = (height - 1 - y)
            if (dx * dx + dy * dy) ** 0.5 <= radius:
                raw += bytes([r, g, b, 255])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(width, height, raw)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "sprites")

# Key palette midtone colors for placeholders
BODY_MID = (204, 0, 204)   # #CC00CC
SHELL_MID = (0, 204, 204)  # #00CCCC

sprites = {
    # ── SHARED SNAIL PARTS ──
    "snail/shared/eye.png":            lambda: make_flat_circle(12, 230, 200, 48),
    "snail/shared/pupil.png":          lambda: make_flat_circle(8, 20, 15, 15),
    "snail/shared/eye_highlight.png":  lambda: make_flat_circle(6, 255, 255, 255),
    "snail/shared/stalk.png":          lambda: make_flat_rect(4, 24, *BODY_MID),

    # ── PER-CHARACTER SPRITES (use key colors for recoloring) ──
    # Blink
    "snail/blink/shell.png":          lambda: make_flat_circle(44, *SHELL_MID),
    "snail/blink/shell_spiral.png":   lambda: make_flat_circle(44, *SHELL_MID, 100),
    "snail/blink/body.png":           lambda: make_flat_rect(32, 8, *BODY_MID),
    "snail/blink/dome.png":           lambda: make_flat_dome(32, 16, *BODY_MID),
    # Goopy
    "snail/goopy/shell.png":          lambda: make_flat_circle(44, *SHELL_MID),
    "snail/goopy/shell_spiral.png":   lambda: make_flat_circle(44, *SHELL_MID, 100),
    "snail/goopy/body.png":           lambda: make_flat_rect(32, 8, *BODY_MID),
    "snail/goopy/dome.png":           lambda: make_flat_dome(32, 16, *BODY_MID),
    # Zappy
    "snail/zappy/shell.png":          lambda: make_flat_circle(44, *SHELL_MID),
    "snail/zappy/shell_spiral.png":   lambda: make_flat_circle(44, *SHELL_MID, 100),
    "snail/zappy/body.png":           lambda: make_flat_rect(32, 8, *BODY_MID),
    "snail/zappy/dome.png":           lambda: make_flat_dome(32, 16, *BODY_MID),

    # ── ARENA PARTS (full color, not tinted) ──
    "arena/ground_dirt.png":    lambda: make_flat_rect(200, 50, 107, 77, 56),
    "arena/ground_grass.png":   lambda: make_flat_rect(200, 10, 115, 174, 82),
    "arena/wall.png":           lambda: make_flat_rect(24, 200, 128, 107, 92),
    "arena/platform.png":       lambda: make_flat_rect(180, 20, 112, 82, 61),
    "arena/center_rock.png":    lambda: make_flat_circle(64, 128, 112, 97),
    "arena/slime_dot.png":      lambda: make_flat_circle(12, 180, 220, 120, 160),
}

for path, gen_fn in sprites.items():
    full = os.path.join(SPRITES, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    data = gen_fn()
    with open(full, "wb") as f:
        f.write(data)
    print(f"  Created {path}")

print(f"\nDone! {len(sprites)} placeholder sprites in sprites/")
print("Replace any PNG with your own art (keep the same filename).")
print("\nUse these key colors for recolorable areas:")
print("  Body:  #FF00FF (highlight)  #CC00CC (midtone)  #990099 (shadow)")
print("  Shell: #00FFFF (highlight)  #00CCCC (midtone)  #009999 (shadow)")
