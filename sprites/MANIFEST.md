# Bollard Bash Sprite Manifest

Every visual element in the game is driven by a PNG file in this directory.
To change the look of anything, just replace the PNG — keep the same filename and
the game picks it up on next run.

## How it works

- **Snail sprites** (`snail/`) are drawn in grayscale/neutral tones and tinted
  at runtime using each player's `bollard_color` (body) and `accent_color` (shell).
  You can paint them in full color if you prefer — just set the player colors to white.
- **Arena sprites** (`arena/`) are drawn at full color and used as-is.
- Sprites are stretched to fit their target size. Pixel dimensions in the table below
  are the placeholder sizes — your replacements can be any resolution as long as the
  aspect ratio is roughly the same.

## Snail Parts — `sprites/snail/`

| File               | Size   | What it is                         | Tinted by       |
|--------------------|--------|------------------------------------|-----------------|
| `shell.png`        | 48x48  | Shell sphere (main body)           | `accent_color`  |
| `shell_spiral.png` | 48x48  | Spiral overlay on shell            | `accent_color`  |
| `body.png`         | 32x90  | Body cylinder (stretches vertically) | `bollard_color` |
| `dome.png`         | 32x18  | Dome cap on top of body            | `bollard_color` |
| `stalk.png`        |  4x16  | Eye stalk (used twice, L+R)        | `bollard_color` |
| `eye.png`          | 12x12  | Eyeball (used twice)               | not tinted      |
| `pupil.png`        |  8x8   | Pupil dot (used twice)             | not tinted      |
| `eye_highlight.png`|  6x6   | White reflection dot (used twice)  | not tinted      |
| `grab_dot.png`     | 10x10  | Red grab indicator at tip          | not tinted      |

### Snail sprite layout (local coordinates, origin at shell center)

```
         eye_highlight (white dot)
         pupil (dark dot)
    eye ---- eye          <- stalk tips, y = -(post_h + 16 + 14)
     \      /
      stalk stalk         <- from dome top downward
       dome               <- y = -post_h, width = 32
       body               <- stretches from y=0 down to y=-post_h
      [shell]             <- y=0, centered, radius ~22px
```

`post_h` ranges from 2 (fully retracted) to 90 (fully extended).
The body sprite is scaled vertically each frame to match.

## Arena Parts — `sprites/arena/`

| File              | Size    | What it is                           | Stretched to     |
|-------------------|---------|--------------------------------------|------------------|
| `ground_dirt.png` | 200x50  | Ground dirt body                     | 990x50           |
| `ground_grass.png`| 200x10  | Grass strip on top of ground         | 990x10           |
| `wall.png`        |  24x200 | Vertical wall platform (used twice)  | 20x200           |
| `platform.png`    | 180x20  | Horizontal floating platform (x2)   | 180x16           |
| `center_rock.png` |  64x64  | Center obstacle rock                 | 60x60            |
| `slime_dot.png`   |  12x12  | Slime trail dot (drawn with _draw)   | 12x12 (1:1)     |

### Arena layout (world coordinates)

```
    wall (30,300)                         wall (1250,300)
    |                                              |
    |     platform (320,330)  rock (640,190)  platform (960,330)
    |         ____            ( O )            ____
    |                                              |
    |___________  ground (640,520)  ______________|
         ~~~~~~~~~~~~ grass ~~~~~~~~~~~~
         ============= dirt =============
```

## Regenerating placeholders

If you delete a sprite and want the default back:

```
python3 scripts/generate_placeholders.py
```

## Player colors (defaults)

- **Player 1**: shell `#A06830` (warm brown), body `#B0A8C8` (light purple-gray)
- **Player 2**: shell tinted by `bollard_color = Color(0.565, 0.753, 0.792)`,
  body `accent_color = Color(0.314, 0.502, 0.314)`

These are set in `main.tscn` on the Player2 node and can be changed in the editor.
