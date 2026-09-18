# Blue Berry — Parallax Forest Background Specs

> **Viewport:** 640×360 (base) · 1280×720 window · **Arena:** 2400×900 scrollable
> **Renderer:** GL Compatibility · **Texture Filter:** Nearest (0) · **Pixel Snap:** on
> **Last Updated:** 2026-09-06

---

## 1. Concept

Three parallax depth layers create a **2.5D forest illusion**. The camera scrolls horizontally as the player moves through an endless forest. Each layer scrolls at a different speed to simulate depth.

```
DEPTH LAYERS (front → back):

  ┌─────────────────────────────────────────────────────────┐
  │  LAYER 3 — FOREGROUND TREES                              │
  │  Closest to camera, large trunks + canopy                │
  │  Parallax Speed: 0.15 (slowest foreground)               │
  │  Scrolls at 15% of player movement                       │
  ├─────────────────────────────────────────────────────────┤
  │  LAYER 2 — MIDGROUND (PLAYER + ENEMIES ARE HERE)        │
  │  Mid-distance trees, bushes, details                     │
  │  Parallax Speed: 0.38 (existing forest layer)            │
  │  Scrolls at 38% of player movement                       │
  ├─────────────────────────────────────────────────────────┤
  │  LAYER 1 — BACKGROUND                                    │
  │  Distant treeline, mountains, fog                       │
  │  Parallax Speed: 0.08 (slowest, farthest)                │
  │  Scrolls at 8% of player movement                        │
  └─────────────────────────────────────────────────────────┘
```

---

## 2. Asset Specifications for External Art Tools (Aseprite / Photoshop)

### 2.1 General Rules

| Property | Value |
|----------|-------|
| **Base resolution** | 640×360 logical pixels |
| **Scale factor** | **2×** (import as 1280×720 for crisp pixels) |
| **Pixel grid** | Snap to **16px grid** minimum |
| **Color palette** | Limited, warm forest palette (see below) |
| **Alpha** | PNG with transparency |
| **Format** | `.png`, **Nearest** filter, **Mipmaps Off** in Godot |
| **Texture repeat** | Enable horizontal repeat for seamless scrolling |

### 2.2 Color Palette Reference

Use these as your forest palette (hex):

```
SKY:         #2E3A2E  (dark evergreen)
MOUNTAIN:    #3D4A3D  (mid distant hills)
FOREST_DARK: #1B2E1B  (deep forest)
FOREST_MID:  #2A4228  (mid forest green)
FOREST_LIGHT:#3B5E34  (light canopy)
TRUNK_DARK:  #2C1E14  (dark bark)
TRUNK_MID:   #4A3528  (mid bark)
TRUNK_LIGHT: #6B4E3A  (light bark)
CANOPY_GREEN:#1E5E2E  (canopy green)
GROUND:      #1E2E18  (forest floor)
GROUND_LINE: #2A3A22  (grass/ground line)
FOG:         #3A4A3A  (atmospheric haze)
FIREFLY:     #88CC44  #FFDD44  (accent glow)
```

### 2.3 Layer 1 — Background Distant Treeline

**Purpose:** Far mountain/treeline silhouette — slowest scroll (parallax 0.08).

| Property | Specification |
|----------|--------------|
| **Artwork size** | **1280×360 px** (2× of 640×360) — single horizontal strip |
| **Content** | Mountain silhouette + distant tree tops + fog gradient |
| **Key shapes** | Low peaks (3-5 hills), sparse tree clusters, fog bank at bottom |
| **Height coverage** | Top 60% sky, bottom 40% ground/horizon line at y=216 (of 360) |
| **Seamless** | Left edge must connect to right edge for horizontal repeat |
| **Godot import** | TextureRect, `texture_repeat=2`, `expand_mode=1` |
| **Parallax** | `parallax_sky = 0.08` |
| **Godot node** | `TextureRect` inside `Parallax` node |
| **File name** | `assets/backgrounds/bg_distant_treeline.png` |

**Art template grid** (for 1280×360 canvas at 2×):
```
    0    128    256    384    512    640    768    896   1024   1152   1280
    |-----|------|------|------|------|------|------|------|------|------|
    ├─────────────────────── SKY (y=0 to y=190) ───────────────────────┤
    │                                                                     │
    │   ○○          ◇◇◇         ○○○          ◇◇          ○○            │  Mountains
    │  ◇◇◇        ◇◇◇◇        ◇◇◇◇        ◇◇◇        ◇◇◇            │  (distant)
    │───────────────────────────────────────────────────────────────────│  y=190 horizon
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  Fog/ground
    │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  y=360
```

### 2.4 Layer 2 — Midground Forest (Existing + Enhanced)

**Purpose:** Mid-distance tree rows — middle scroll (parallax 0.38). This is the existing `forest_treeline.png` layer, enhanced with more detail.

| Property | Specification |
|----------|--------------|
| **Artwork size** | **1280×360 px** (2× of 640×360) — single horizontal strip |
| **Content** | Medium tree rows, underbrush, forest detail |
| **Key shapes** | Groups of 3-5 trees per cluster, medium trunks + canopies |
| **Height coverage** | Bottom 45% visible (y=198 to y=360), canopy tops at y≈160 |
| **Seamless** | Left edge connects to right edge for horizontal repeat |
| **Godot import** | `texture_repeat=2`, `expand_mode=1`, `texture_filter=0` (Nearest) |
| **Parallax** | `parallax_forest = 0.38` |
| **Godot node** | `TextureRect` inside `Parallax` node |
| **File name** | `assets/backgrounds/forest_treeline.png` *(replace existing)* |
| **Art template grid** (1280×360): | |

**Art template grid** (for 1280×360 canvas at 2×):
```
    y=0   ───────────── SKY visible above ─────────────
    y=160 ── CANOPY TOP LINE ── (trees emerge here)
    y=198 ── FOREST FLOOR LINE ── (ground/grass)
    y=360 ── BOTTOM ──
    
    Tree clusters at: 128, 320, 512, 704, 896, 1088 (x centers)
    Each cluster: 3-5 trees, varied heights (40-80px tall at 2×)
```

### 2.5 Layer 3 — Foreground Trees (NEW — Closest to Camera)

**Purpose:** Large trees/foliage that appear to be right at the edge of the viewport. Slowest scroll (parallax 0.15). Creates depth by being oversized and blurry/soft at edges.

| Property | Specification |
|----------|--------------|
| **Artwork size** | **1280×360 px** (2× of 640×360) — **TWO** strips needed |
| **Content** | Oversized tree trunks, thick canopy clumps, edge framing |
| **Key shapes** | 2-3 massive tree trunks per edge, thick canopy blobs, no ground line visible |
| **Height coverage** | Top 30% sky peek, bottom 70% tree mass. Trees extend beyond viewport |
| **Seamless** | **NOT seamless** — these are frame-specific decorative elements |
| **Godot import** | `texture_repeat=0`, `expand_mode=1`, `texture_filter=0` |
| **Parallax** | `parallax_foreground = 0.15` |
| **Godot node** | `TextureRect` inside `Parallax` node, **z_index = -50** (behind player) |
| **File name** | `assets/backgrounds/fg_trees_left.png` and `assets/backgrounds/fg_trees_right.png` |
| **Left tree specs** | 320×360 px content, positioned at screen left edge |
| **Right tree specs** | 320×360 px content, positioned at screen right edge |
| **Art template grid** (each 320×360): | |

**Left foreground tree template** (320×360 at 2×):
```
    x=0   ── LEFT EDGE ──
    ┌──────────────────────────────────────────────────────┐
    │          ○○○○                    sky peek            │
    │       ○○○○○○○○                                  ○○○  │
    │     ○○○██████○○○                        ████○○○○   │
    │    ○○████████○○○          canopy          █████○○○  │
    │   ○████████████○     ████████████      ████████○○    │
    │  ██████████████     ████████████    ████████████      │
    │  ██████████████     ████████████    ████████████      │
    │ ████▓▓▓▓▓▓████     ████████████    ████████▓▓▓▓      │
    │ ████▓▓▓▓▓▓████     ████████████    ████████▓▓▓▓      │
    │ ▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓      │
    │ ▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓      │
    │ ▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓      │
    │ ▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████▓▓▓▓▓▓    │
    │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
    └──────────────────────────────────────────────────────┘
    
    x=320 ── RIGHT EDGE (of left strip) ──
    Massive tree trunk on left, canopy extends right
    Trunk width: ~80px at 2×
    Canopy height: ~200px at 2×
```

**Right foreground tree template** (320×360 at 2×): Mirror of left, tree on right side.

---

## 3. Parallax Speed Reference

| Layer | Speed | Node | Purpose |
|-------|-------|------|---------|
| Background (distant) | **0.08** | TextureRect | Sky/mountains — barely moves |
| Foreground trees | **0.15** | TextureRect | Close trees — slow drift |
| Midground forest | **0.38** | TextureRect | Existing forest layer |
| Clouds | **0.14** | TextureRect | Atmospheric drift |
| **Player movement** | **1.0** | Camera2D | Reference speed |
| Ground (shader) | **1.0** | ColorRect | 1:1 with camera |

**Formula:** `layer_speed = 1.0 / (1 + depth_factor)`
- Background (far): depth_factor ~11.5 → 0.08
- Foreground (close): depth_factor ~5.7 → 0.15
- Midground (mid): depth_factor ~1.6 → 0.38

---

## 4. Godot Node Structure

```
Background [Node2D] z_index=-100  (existing)
├── Parallax [Node2D]  (existing, handles parallax offsets)
│   ├── SkyMountains [TextureRect]  (parallax 0.08)  ← background
│   ├── Clouds [TextureRect]        (parallax 0.14)
│   ├── FG_Trees [TextureRect]      (parallax 0.15)  ← NEW foreground
│   └── Forest [TextureRect]        (parallax 0.38)  ← midground
│
├── FG_Trees_Left [TextureRect]      (parallax 0.15, z_index=-50)  ← NEW left edge
├── FG_Trees_Right [TextureRect]     (parallax 0.15, z_index=-50) ← NEW right edge
├── GroundIso [ColorRect]            (existing, shader)
└── ...
```

**Important z-ordering:**
- `z_index = -100` for Background node (behind everything)
- Foreground trees should have `z_index = -50` (between background and ground)
- Player and enemies on the ground layer (z_index = 0+)

---

## 5. How to Create Assets — Step by Step

### 5.1 In Aseprite (or Photoshop):

1. **Create canvas at 2× resolution:** 1280×360 pixels
2. **Enable pixel grid** and **snap to grid** (16px increments)
3. **Use the palette** from Section 2.2
4. **Layer structure** (bottom to top):
   - Layer 1: Sky/mountains gradient
   - Layer 2: Distant tree silhouettes
   - Layer 3: Ground/horizon line
   - Layer 4: Fog/haze effect (semi-transparent)
5. **Export as PNG** with transparency
6. **Import into Godot:**
   - Set `Texture Type → Sprite2D`
   - `Filter → Nearest` (0)
   - `Mipmaps → Off`
   - `Repeat → On` (for scrolling layers)

### 5.2 For Foreground Trees (separate left/right strips):

1. **Canvas:** 320×360 pixels (2×)
2. **Draw massive tree trunks** occupying left/right edges
3. **Canopy should extend toward center** but not overlap
4. **Add slight blur/softness** at edges (alpha gradient) for depth feel
5. **Export as PNG**, import with `Repeat → Off`
6. **Place as two separate TextureRects** on left and right edges of viewport

### 5.3 File naming convention:
```
assets/backgrounds/
├── bg_distant_treeline.png    (NEW - far mountains/trees)
├── forest_treeline.png        (EXISTING - midground, replace/enhance)
├── fg_trees_left.png          (NEW - foreground left tree)
├── fg_trees_right.png         (NEW - foreground right tree)
├── clouds.png                 (EXISTING)
├── sky_mountains.png          (EXISTING)
└── ground_iso.png             (EXISTING)
```

---

## 6. Template Scene Files

Three template `.tscn` scenes are provided for each layer. Replace placeholder textures with your created art.

See:
- `scenes/ParallaxBackground.tscn` — Full parallax scene (use or merge into existing Background.tscn)
- `scenes/ParallaxForeground.tscn` — Foreground tree layer scene
- `scenes/ParallaxMidground.tscn` — Midground forest layer scene

---

## 7. Quick Integration Checklist

- [ ] Create background art (1280×360, seamless repeat)
- [ ] Create midground art (1280×360, seamless repeat)
- [ ] Create foreground left/right art (320×360 each, non-repeat)
- [ ] Import all as PNG with Nearest filter, Mipmaps Off
- [ ] Update Background.tscn with new TextureRects
- [ ] Set parallax speeds in `background.gd` exports
- [ ] Test in game — adjust speeds until depth feels right
- [ ] Fine-tune by changing parallax values in 0.01 increments

---

## 8. Art Tips for 2.5D Depth Illusion

1. **Size = Depth:** Larger objects = closer to camera
2. **Blur/Alpha = Distance:** Distant objects should have slight alpha fade
3. **Color Saturation = Distance:** Far = muted/darker colors; near = vivid
4. **Detail = Proximity:** Close trees have visible bark texture; far trees are silhouettes
5. **Overlap = Depth:** Trees should overlap each other and the ground line
6. **Scale Variation:** Even within one layer, vary tree sizes slightly for organic feel
7. **Edge Softness:** Foreground trees should have soft alpha edges bleeding past frame
8. **No Ground Line on Foreground:** Trees should appear to grow from bottom of screen, no visible ground

---

*Specs for artists and developers. Use as template for all parallax forest assets.*

---

## 9. As-Built Notes (2026-09-18, procedural base art)

The PNGs below were (re)built procedurally from this spec's palette so the
long 2400px arena scrolls without seams. They are intended as **bases to
hand-tweak**, not final art.

| File | Size | Seam | Content |
|------|------|------|---------|
| `bg_distant_treeline.png` | 1280×360, opaque | period 1280 | dusk gradient, 2 sine ridges, uneven treetop band + lone pines, stars, birds, fog |
| `forest_treeline.png` | 512×128, RGBA | period 512 | 15 irregular back pines, 6 blob-canopy trees + trunks, bushes, grass fringe, opaque soil anchor strip, fireflies |
| `ground_iso.png` | 256×256, RGBA | periods 256 x + y | mottled soil, 120 grass tufts, pebbles, clover, twigs, grain (no sky, no objects) |
| `fg_trees_left/right.png` | 640×360, RGBA | one whole tree per 640 tile; bands offset 320 | left = broadleaf (~200px tall), right = pine (~150px tall); trunks run off the tile bottom so they grow from behind the ground plane; transparent gaps ~140px so trees interleave A-gap-B-gap across the world bands |
| `sky_mountains.png`, `clouds.png` | unchanged | — | kept as spare art (synthwave sky no longer wired) |

**Wiring (differs from §4 where noted):**
- `Background.tscn` `SkyMountains` texture is now `bg_distant_treeline.png`.
- The horizon is a **fixed world line** (`world y ≈ -90`, ground shader `horizon = 0.115`): walking up moves toward it, walking down moves away. The `Background` node follows the camera in **X only** — never glue it to full `cam_pos` or the horizon sticks to the screen.
- Scroll rects are sized **viewport (640) + one tile period**: Sky 1920×616, Clouds 896, Forest 1152 (rect y `-150..-22`, treetops above the ridge, bases tucked behind the ground plane). Ground rect `-160..450` so the floor reaches the lowest camera.
- `background.gd` wraps drift **centered** in `(-period/2, period/2]` via `_centered_wrap()` against `SKY/CLOUD/FOREST_TILE` consts. Plain `fposmod(cam*f, rect.size.x)` opens edge gaps once the camera roams the long arena — do not revert to it.
- Foreground strips are a **world-anchored near layer** (`parallax_foreground = 0.7`): two 3000px bands (`-1500..1500` + `-1180..1820`, i.e. half-tile offset) with repeat on, drifting at 0.7× and riding 180px above the camera so full canopies sit ON the ridge with trunks behind it. Do NOT pin them to the camera — pinning glues them next to the centered player and they read as attached to it.
- The ridge is kept **thin**: ground-shader haze `smoothstep(0.0, 0.08, gy)` plus an 8px `HorizonGlow` kiss (`alpha 0.1`) on the line. Widening either turns the horizon into a fog band.

## 10. Hand-Editing Guide (Clip Studio Paint)

Source working file: `assets/backgrounds/blueberry_backgound.clip`. Keep it —
export finished strips as PNG from it.

1. **Canvas:** keep the exact pixel sizes in §9 (CSP `cm`/`px` 1:1, no scaling on export).
2. **Seam rule (scrolling layers only):** the leftmost column must continue the rightmost column. In CSP: `Layer → Move layer` Trick — duplicate the layer, offset the copy by exactly half the canvas width (`Edit → Transform → Move layer`, X = W/2), paint out the new center seam, then offset back by W/2. Repeat vertically for `ground_iso.png` (offset Y = H/2 too).
3. **What to vary:** cluster spacing (never even), tree heights/lean, canopy blob overlap, bark streaks, firefly/mushroom/grass accents. What NOT to draw: skies or lone hero objects inside `ground_iso.png` (it tiles 2.6× through a shader — anything recognizable repeats), geometry grids, uniform spike rows.
4. **Foreground strips:** keep the outer/bottom edges opaque (trunks grow off-screen) and the inner edge dissolved — erase with a scatter/dither brush, never a hard vertical line.
5. **Export:** PNG, no resize, no color-profile conversion. In Godot keep import `compress/mode=0` (lossless), `mipmaps off`, Nearest filter (per-node `texture_filter=0` + project default).
6. **After replacing a PNG:** run `godot --headless --path . --import`, then walk the full arena in-game and watch both screen edges for seams or gaps.
