# Asset Pipeline

How to turn the SVG sources in `assets/` into the PNGs Expo + the
App Store + the Play Store + the landing page need. Three SVG
sources, ~7 PNG outputs.

---

## Source SVGs

| File | Purpose |
|------|---------|
| `assets/brand-mark.svg` | The icon mark with dark tile background — square, 1024×1024 |
| `assets/brand-mark-adaptive.svg` | Android adaptive-icon foreground — transparent BG, content within 66% safe zone, 1024×1024 |
| `assets/brand-wordmark.svg` | Mark stacked above the wordmark — 1024×1280 |
| `assets/feature-graphic.svg` | Horizontal hero — 1024×500 |

All three reference the same crossing-taper geometry; tweaking any
one means tweaking the matching paths in the others. See
`docs/BRAND_KIT.md` §1 for the design rationale.

## Required outputs

| File | Size | Source | Used by |
|------|------|--------|---------|
| `assets/icon.png` | 1024×1024 | brand-mark.svg | iOS app icon (Expo auto-derives all sizes). |
| `assets/adaptive-icon.png` | 1024×1024 | brand-mark.svg | Android adaptive icon foreground. |
| `assets/favicon.png` | 192×192 | brand-mark.svg | Web favicon (Expo Web). |
| `assets/splash.png` | 1284×2778 | brand-wordmark.svg | iOS Pro Max splash. Centred on `#0b0f14`. |
| `assets/feature-graphic.png` | 1024×500 | feature-graphic.svg | Play Store feature graphic. No alpha. |
| `docs/landing/og-image.png` | 1200×630 | brand-wordmark.svg | OpenGraph card for the landing page. |

---

## Recipe — using `rsvg-convert` (recommended)

```bash
brew install librsvg imagemagick

cd /Users/rashidrazak/Desktop/psych-switch/assets

# ── App icon family — direct rasterisation ─────────────────────────
rsvg-convert -w 1024 -h 1024 brand-mark.svg > icon.png
rsvg-convert -w 1024 -h 1024 brand-mark-adaptive.svg > adaptive-icon.png   # transparent BG
rsvg-convert -w 192  -h 192  brand-mark.svg > favicon.png

# ── Play Store feature graphic — direct, then strip alpha ──────────
rsvg-convert -w 1024 -h 500 feature-graphic.svg > feature-graphic.png
magick feature-graphic.png -background '#0b0f14' -alpha remove feature-graphic.png

# ── Splash (iPhone Pro Max, 1284×2778) ─────────────────────────────
# Render the wordmark composition at native 1024×1280, then composite
# onto a centred portrait canvas matching the iPhone Pro Max splash
# resolution.
rsvg-convert -w 1024 -h 1280 brand-wordmark.svg > /tmp/psw-wordmark.png
magick -size 1284x2778 xc:'#0b0f14' \
  \( /tmp/psw-wordmark.png -resize 900x \) \
  -gravity center -composite \
  splash.png
rm /tmp/psw-wordmark.png

# ── OpenGraph card for the landing page (1200×630) ─────────────────
rsvg-convert -w 1200 -h 1500 brand-wordmark.svg > /tmp/psw-wordmark-og.png
magick -size 1200x630 xc:'#0b0f14' \
  \( /tmp/psw-wordmark-og.png -resize 480x \) \
  -gravity center -composite \
  ../docs/landing/og-image.png
rm /tmp/psw-wordmark-og.png
```

Verify every PNG:

```bash
file assets/icon.png assets/adaptive-icon.png assets/favicon.png \
     assets/splash.png assets/feature-graphic.png \
     docs/landing/og-image.png
# Each should match the size in the table above.
```

---

## Recipe — using Inkscape (if rsvg-convert isn't installed)

```bash
inkscape brand-mark.svg --export-type=png --export-filename=icon.png --export-width=1024
```

## Quick rasterise — macOS-only fallback (no installs)

If `librsvg` and `imagemagick` aren't installed and you only need the
icon family in a hurry, macOS's QuickLook can produce square
thumbnails:

```bash
qlmanage -t -s 1024 -o /tmp/ assets/brand-mark.svg
cp /tmp/brand-mark.svg.png assets/icon.png
cp /tmp/brand-mark.svg.png assets/adaptive-icon.png
qlmanage -t -s 192 -o /tmp/ assets/brand-mark.svg
cp /tmp/brand-mark.svg.png assets/favicon.png
```

Caveats:
- `qlmanage` flattens transparency to white. Use the tiled
  `brand-mark.svg` (not `brand-mark-adaptive.svg`) for adaptive-icon
  this way — Android's `backgroundColor: '#0b0f14'` will still composite
  correctly because the tile is the same colour, but you lose the
  proper transparent foreground a real adaptive icon expects.
- `qlmanage` only does square outputs, so this path can't generate
  splash.png, feature-graphic.png, or og-image.png. Install librsvg +
  imagemagick when you need those.

---

## Recipe — using Figma (manual fallback)

1. Drag `brand-mark.svg` into a Figma frame.
2. Set the frame to 1024×1024 with background `#0b0f14`.
3. Export as PNG @1x for `icon.png` / `adaptive-icon.png`.
4. Resize the frame to 192×192 for `favicon.png`.
5. For splash, use a 1242×2436 frame with the SVG at 600×600 centred.
6. For OG, use a 1200×630 frame with the SVG at 360×360 centred.

---

## After the pipeline runs

1. Verify the icon shows correctly in `pnpm start` (it appears in the
   Expo Go QR card and on Simulator).
2. Bump `app.json` version if you want this to ship in the next OTA.
3. Commit `assets/icon.png`, `adaptive-icon.png`, `favicon.png`,
   `splash.png` together with a message like:
   `chore(assets): rasterise brand mark for v0.5 launch`.

The SVG is the source of truth. If you tweak `brand-mark.svg`,
re-run the recipe — don't hand-edit the PNGs.

---

## Why we don't auto-build this

Expo's prebuild can technically generate icons on every build, but
that requires committing build configuration that's brittle across
SDK upgrades. A one-shot manual run, committed to git, is more
reliable for a small project. Re-run only when the brand changes.
