#!/usr/bin/env python3
"""
Generate placeholder PNG sprites for Bollard Bash.
Run once: python3 scripts/generate_placeholders.py
Then replace any PNG in sprites/ with your own art.
"""

import struct
import zlib
import os

def make_png(width, height, r, g, b, a=255):
    """Create a minimal RGBA PNG as bytes."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack(">I", len(data)) + c + crc

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    raw = b""
    for y in range(height):
        raw += b"\x00"  # filter: none
        for x in range(width):
            raw += bytes([r, g, b, a])

    idat = chunk(b"IDAT", zlib.compress(raw))
    iend = chunk(b"IEND", b"")
    return header + ihdr + idat + iend


def make_circle_png(size, r, g, b, a=255):
    """Create a circular sprite with transparency outside."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack(">I", len(data)) + c + crc

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))

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
                # Simple shading: lighter top-left, darker bottom-right
                shade = max(0.0, min(1.0, 1.0 - dist / radius * 0.3))
                angle_shade = max(0.7, 1.0 + (-dx - dy) / (radius * 2) * 0.4)
                sr = min(255, int(r * shade * angle_shade))
                sg = min(255, int(g * shade * angle_shade))
                sb = min(255, int(b * shade * angle_shade))
                raw += bytes([sr, sg, sb, a])
            else:
                raw += bytes([0, 0, 0, 0])

    idat = chunk(b"IDAT", zlib.compress(raw))
    iend = chunk(b"IEND", b"")
    return header + ihdr + idat + iend


def make_dome_png(width, height, r, g, b):
    """Create a dome/semicircle sprite."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack(">I", len(data)) + c + crc

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    cx = width / 2.0
    radius = width / 2.0 - 1

    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            dx = x - cx + 0.5
            dy = y  # dome: bottom is flat, top is curved
            dist = (dx * dx + dy * dy) ** 0.5
            if dist <= radius and y <= radius:
                shade = max(0.7, 1.0 + (-dx - dy) / (radius * 2) * 0.3)
                sr = min(255, int(r * shade))
                sg = min(255, int(g * shade))
                sb = min(255, int(b * shade))
                raw += bytes([sr, sg, sb, 255])
            else:
                raw += bytes([0, 0, 0, 0])

    idat = chunk(b"IDAT", zlib.compress(raw))
    iend = chunk(b"IEND", b"")
    return header + ihdr + idat + iend


def make_rect_png(width, height, r, g, b, a=255):
    """Create a shaded rectangle sprite (3D cylinder look)."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack(">I", len(data)) + c + crc

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            # Horizontal shading: lighter in center-left, darker at edges
            t = x / max(width - 1, 1)
            # bell curve peaking at ~0.35 (light from top-left)
            shade = 0.75 + 0.35 * max(0, 1.0 - ((t - 0.35) * 3.0) ** 2)
            sr = min(255, int(r * shade))
            sg = min(255, int(g * shade))
            sb = min(255, int(b * shade))
            raw += bytes([sr, sg, sb, a])

    idat = chunk(b"IDAT", zlib.compress(raw))
    iend = chunk(b"IEND", b"")
    return header + ihdr + idat + iend


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "sprites")

sprites = {
    # ── SNAIL PARTS (grayscale/neutral, tinted by code with modulate) ──
    "snail/shell.png":          lambda: make_circle_png(48, 200, 200, 200),
    "snail/shell_spiral.png":   lambda: make_circle_png(48, 160, 160, 160, 120),  # overlay
    "snail/body.png":           lambda: make_rect_png(32, 90, 200, 200, 200),
    "snail/dome.png":           lambda: make_dome_png(32, 18, 200, 200, 200),
    "snail/eye.png":            lambda: make_circle_png(12, 230, 200, 48),   # yellow
    "snail/pupil.png":          lambda: make_circle_png(8, 20, 15, 15),      # near-black
    "snail/eye_highlight.png":  lambda: make_circle_png(6, 255, 255, 255),   # white dot
    "snail/stalk.png":          lambda: make_rect_png(4, 16, 180, 180, 180),
    "snail/grab_dot.png":       lambda: make_circle_png(10, 220, 50, 40),    # red

    # ── ARENA PARTS (full color, not tinted) ──
    "arena/ground_dirt.png":    lambda: make_rect_png(200, 50, 107, 77, 56),
    "arena/ground_grass.png":   lambda: make_rect_png(200, 10, 115, 174, 82),
    "arena/wall.png":           lambda: make_rect_png(24, 200, 128, 107, 92),
    "arena/platform.png":       lambda: make_rect_png(180, 20, 112, 82, 61),
    "arena/center_rock.png":    lambda: make_circle_png(64, 128, 112, 97),
    "arena/slime_dot.png":      lambda: make_circle_png(12, 180, 220, 120, 160),
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
