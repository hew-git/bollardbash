#!/usr/bin/env python3
"""
Generate placeholder PNG sprites for Bollard Bash.
Run once: python3 scripts/generate_placeholders.py
Then replace any PNG with your own art (keep the same filename).

PALETTE KEY COLORS (used by the palette_swap shader):
  Body:  #FF00FF (highlight)  #CC00CC (midtone)  #990099 (shadow)
  Shell: #00FFFF (highlight)  #00CCCC (midtone)  #009999 (shadow)
Paint recolorable areas with these exact colors. Everything else stays as-is.

SPRITE STRUCTURE (side-view snail with spiral shell):
  sprites/snail/<blink|goopy|zappy>/
    shell.png        24x24  — spiral shell (rendered at 2x = 48px)
    inner_body.png   22x22  — exposed body circle when shell is tossed
    neck.png         12x4   — neck tile segment (rendered at 2x = 24x8)
    head.png         14x12  — head with eye stalks baked in (rendered at 2x)
  sprites/arena/
    tile.png         24x24  — tilemap brick for Towerfall-style levels
    platform.png     180x20 — floating platform
    ...
"""

import struct
import zlib
import os
import math


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


# Key palette colors
BODY_HI  = (255, 0, 255)    # #FF00FF
BODY_MID = (204, 0, 204)    # #CC00CC
BODY_SHA = (153, 0, 153)    # #990099
SHELL_HI  = (0, 255, 255)   # #00FFFF
SHELL_MID = (0, 204, 204)   # #00CCCC
SHELL_SHA = (0, 153, 153)   # #009999
EYE_WHITE = (255, 255, 255)
PUPIL_BLACK = (20, 15, 15)
OUTLINE = (40, 30, 40)

# Tile colors (stone brick)
TILE_HI  = (140, 130, 120)
TILE_MID = (110, 100, 92)
TILE_SHA = (80, 72, 65)
TILE_OUTLINE = (55, 48, 42)


def make_snail_shell(size=24):
    """24x24 spiral shell using shell key colors with shading."""
    cx, cy = size / 2.0, size / 2.0
    radius = size / 2.0 - 1
    raw = b""
    for y in range(size):
        raw += b"\x00"
        for x in range(size):
            dx = x - cx + 0.5
            dy = y - cy + 0.5
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= radius:
                if dist > radius - 1.2:
                    raw += bytes([*OUTLINE, 255])
                else:
                    angle = math.atan2(dy, dx)
                    spiral = (angle / math.pi + dist / radius * 3.0) % 1.0
                    shade = (dx + dy) / (radius * 2.0)
                    if spiral < 0.15:
                        raw += bytes([*SHELL_SHA, 255])
                    elif shade < -0.15:
                        raw += bytes([*SHELL_HI, 255])
                    elif shade > 0.15:
                        raw += bytes([*SHELL_SHA, 255])
                    else:
                        raw += bytes([*SHELL_MID, 255])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(size, size, raw)


def make_snail_inner_body(size=22):
    """22x22 inner body circle using BODY key colors (visible when shell is tossed)."""
    cx, cy = size / 2.0, size / 2.0
    radius = size / 2.0 - 1
    raw = b""
    for y in range(size):
        raw += b"\x00"
        for x in range(size):
            dx = x - cx + 0.5
            dy = y - cy + 0.5
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= radius:
                if dist > radius - 1.2:
                    raw += bytes([*OUTLINE, 255])
                else:
                    shade = (dx + dy) / (radius * 2.0)
                    if shade < -0.15:
                        raw += bytes([*BODY_HI, 255])
                    elif shade > 0.15:
                        raw += bytes([*BODY_SHA, 255])
                    else:
                        raw += bytes([*BODY_MID, 255])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(size, size, raw)


def make_snail_neck(width=12, height=4):
    """12x4 neck tile segment using body key colors."""
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            if y == 0 or y == height - 1:
                raw += bytes([*OUTLINE, 255])
            elif x == 0 or x == width - 1:
                raw += bytes([*OUTLINE, 255])
            else:
                if y == 1:
                    raw += bytes([*BODY_HI, 255])
                elif y == height - 2:
                    raw += bytes([*BODY_SHA, 255])
                else:
                    raw += bytes([*BODY_MID, 255])
    return _png(width, height, raw)


def make_snail_head(width=14, height=12):
    """14x12 head with eye stalks baked in, using body key colors."""
    raw = b""
    cx = width / 2.0
    head_cy = 8.0
    head_rx = 6.0
    head_ry = 4.0
    stalk_l_x = 4
    stalk_r_x = 9
    eye_l_x = 4
    eye_r_x = 9

    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            dx = x - cx + 0.5
            hdy = y - head_cy
            in_head = (dx / head_rx) ** 2 + (hdy / head_ry) ** 2 <= 1.0
            in_head_outline = (dx / (head_rx + 0.8)) ** 2 + (hdy / (head_ry + 0.8)) ** 2 <= 1.0
            in_stalk = y >= 1 and y <= 6 and (x == stalk_l_x or x == stalk_r_x)
            in_eye = y >= 0 and y <= 1 and (abs(x - eye_l_x) <= 1 or abs(x - eye_r_x) <= 1)
            is_pupil = y == 0 and (x == eye_l_x or x == eye_r_x)

            if is_pupil:
                raw += bytes([*PUPIL_BLACK, 255])
            elif in_eye:
                raw += bytes([*EYE_WHITE, 255])
            elif in_stalk:
                raw += bytes([*BODY_MID, 255])
            elif in_head and not in_head_outline:
                shade = (dx + hdy) / (head_rx * 2.0)
                if shade < -0.15:
                    raw += bytes([*BODY_HI, 255])
                elif shade > 0.15:
                    raw += bytes([*BODY_SHA, 255])
                else:
                    raw += bytes([*BODY_MID, 255])
            elif in_head_outline and not in_head:
                raw += bytes([*OUTLINE, 255])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(width, height, raw)


def make_tile(size=24):
    """24x24 stone brick tile for Towerfall-style maps."""
    raw = b""
    # Brick pattern: horizontal mortar at y=11,12 and vertical mortar varies by row
    for y in range(size):
        raw += b"\x00"
        for x in range(size):
            # Mortar lines (dark gaps between bricks)
            is_h_mortar = y == 0 or y == size - 1 or y == 11 or y == 12
            # Vertical mortar offset by row half
            if y <= 11:
                is_v_mortar = x == 0 or x == size - 1
            else:
                is_v_mortar = x == 11 or x == 12
            if x == 0 or x == size - 1 or y == 0 or y == size - 1:
                # Outer edge
                raw += bytes([*TILE_OUTLINE, 255])
            elif is_h_mortar or is_v_mortar:
                raw += bytes([*TILE_SHA, 255])
            else:
                # Brick interior with subtle shading
                bx = x % 12
                by = y % 12
                if bx <= 1 or by <= 1:
                    raw += bytes([*TILE_HI, 255])
                elif bx >= 10 or by >= 10:
                    raw += bytes([*TILE_SHA, 255])
                else:
                    raw += bytes([*TILE_MID, 255])
    return _png(size, size, raw)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "sprites")

sprites = {
    # ── PER-CHARACTER SPRITES (use key colors for recoloring) ──
    # Blink
    "snail/blink/shell.png":      lambda: make_snail_shell(24),
    "snail/blink/inner_body.png": lambda: make_snail_inner_body(22),
    "snail/blink/neck.png":       lambda: make_snail_neck(12, 4),
    "snail/blink/head.png":       lambda: make_snail_head(14, 12),
    # Goopy
    "snail/goopy/shell.png":      lambda: make_snail_shell(24),
    "snail/goopy/inner_body.png": lambda: make_snail_inner_body(22),
    "snail/goopy/neck.png":       lambda: make_snail_neck(12, 4),
    "snail/goopy/head.png":       lambda: make_snail_head(14, 12),
    # Zappy
    "snail/zappy/shell.png":      lambda: make_snail_shell(24),
    "snail/zappy/inner_body.png": lambda: make_snail_inner_body(22),
    "snail/zappy/neck.png":       lambda: make_snail_neck(12, 4),
    "snail/zappy/head.png":       lambda: make_snail_head(14, 12),

    # ── ARENA PARTS ──
    "arena/tile.png":           lambda: make_tile(24),
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
