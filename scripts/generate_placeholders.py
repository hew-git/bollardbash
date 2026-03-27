#!/usr/bin/env python3
"""
Generate placeholder PNG sprites for Bollard Bash.
Run once: python3 scripts/generate_placeholders.py
Then replace any PNG in sprites/ with your own art.
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
    """Solid flat-color rectangle."""
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            raw += bytes([r, g, b, a])
    return _png(width, height, raw)


def make_flat_circle(size, r, g, b, a=255):
    """Solid flat-color circle with transparent outside."""
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
    """Flat dome: semicircle on top, flat bottom edge. Curves upward."""
    cx = width / 2.0
    radius = width / 2.0 - 1
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            dx = x - cx + 0.5
            # y=0 is top of image, y=height-1 is bottom (flat edge)
            # Distance from bottom-center: dome curves up from the bottom
            dy = (height - 1 - y)
            if (dx * dx + dy * dy) ** 0.5 <= radius:
                raw += bytes([r, g, b, 255])
            else:
                raw += bytes([0, 0, 0, 0])
    return _png(width, height, raw)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "sprites")

sprites = {
    # ── SNAIL PARTS (neutral gray, tinted by code with self_modulate) ──
    "snail/shell.png":          lambda: make_flat_circle(48, 200, 200, 200),
    "snail/shell_spiral.png":   lambda: make_flat_circle(48, 140, 140, 140, 100),
    "snail/body.png":           lambda: make_flat_rect(32, 90, 200, 200, 200),
    "snail/dome.png":           lambda: make_flat_dome(32, 18, 200, 200, 200),
    "snail/eye.png":            lambda: make_flat_circle(12, 230, 200, 48),
    "snail/pupil.png":          lambda: make_flat_circle(8, 20, 15, 15),
    "snail/eye_highlight.png":  lambda: make_flat_circle(6, 255, 255, 255),
    "snail/stalk.png":          lambda: make_flat_rect(4, 16, 180, 180, 180),
    "snail/grab_dot.png":       lambda: make_flat_circle(10, 220, 50, 40),

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
