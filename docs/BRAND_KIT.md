# PsychSwitch Brand Kit

The design constraints we enforce so PsychSwitch always looks and
sounds like itself — across the app, the landing page, App Store
screenshots, beta-program emails, and any future surface.

---

## 1. Brand mark

Three SVG sources of truth, all in `assets/`:

| File | Use |
|------|-----|
| `brand-mark.svg` | Square icon — app icon, adaptive icon, favicon, OG card. 1024×1024. |
| `brand-wordmark.svg` | Mark stacked above wordmark — splash screen, landing hero. 1024×1280. |
| `feature-graphic.svg` | Horizontal hero — Play Store feature graphic. 1024×500. |

**Concept (v0.4.20).** Two crossing taper curves. The blue curve descends
from full dose at upper-left to zero at lower-right (the from-drug
coming off); the green curve ascends from zero at lower-left to full
dose at upper-right (the to-drug coming on). They cross in the centre —
the literal visual signature of every cross-titration the app
produces.

The four endpoint dots are dose-markers (terminal beads on the lines),
matching how the schedule cards render dose changes in the Result
screen.

The colours are pulled directly from the app palette: `from` (`#60a5fa`)
and `to` (`#34d399`) are the same identity colours used in every
schedule view. **The brand mark IS the product semantic** — clinicians
who've used the app for five minutes already recognise the colour
language.

**Constraints honoured.**
- Reads at 24px (favicon size) — the X-cross silhouette holds.
- Survives Android adaptive masking — all critical content sits within
  the 66% safe zone (the four dose-dots are at ~22% inset; the
  crossover is dead-centre).
- No gradients, no decorative ornament — same minimalism as the rest
  of the app's surface (rule from §2 below).
- Two-colour palette only. `from-blue` and `to-green` on `#0b0f14`. No
  third colour.

**History.** v0.1–v0.4.19 used a Lucide-style activity (EKG) glyph in a
single accent blue. Replaced in v0.4.20 because the EKG was generic
("any health app could use this") and didn't carry the product's
specific value proposition. The crossing-taper mark commits.

To rasterise: see `docs/ASSET_PIPELINE.md`.

---

## 2. Colours

Defined in `tailwind.config.js`:

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#0b0f14` | Background everywhere. Single dark surface, no gradients. |
| `surface` | `#141a22` | Card and elevated-surface backgrounds. |
| `border` | `#1f2933` | All borders, dividers, subtle separators. |
| `text` | `#e6edf3` | Primary text on `bg` / `surface`. |
| `muted` | `#8b949e` | Secondary text, captions, axis labels. |
| `accent` | `#3b82f6` | Interactive primary — CTAs, links, focus rings, citation chips. |
| `warning` | `#f59e0b` | Cautions. Pre-release status pill. Overdue indicators. |
| `danger` | `#ef4444` | Avoid-grade DDIs, contraindications, destructive actions. |
| `from` | `#60a5fa` | "From-drug" identity colour in schedules and crossover charts. |
| `to` | `#34d399` | "To-drug" / preferred / success identity colour. |

Rules:
- **No decorative colour.** Reds are *only* for safety warnings, never for emphasis.
- **No gradients** in clinical content. The landing page allows one diagonal accent gradient on the CTA box.
- **One accent at a time.** A screen has at most one prominent accent surface (CTA, banner, badge). Multiples flatten to neutral.

---

## 3. Typography

| Surface | Font | Weights used |
|---------|------|--------------|
| In-app | System default (iOS San Francisco / Android Roboto) | 400, 500, 600, 700, 800 |
| Landing page | Inter | 400, 500, 600, 700, 800 |
| Code / monospace (rule ids, citation locators, dose formulas) | Menlo (in-app) / JetBrains Mono (landing) | 400, 500 |

Sizing — every block of text on the Result screen falls into one of these tiers:

| Tier | Tailwind | Use |
|------|----------|-----|
| `text-2xl font-bold` | 24/28 | Screen titles |
| `text-base font-bold` | 16/24 | Card titles, section headings |
| `text-sm` | 14/20 | Body |
| `text-xs` | 12/18 | Captions, metadata |
| `text-[11px]` | 11/16 | Subtitles, hints |
| `text-[10px] uppercase tracking-widest font-bold` | 10/16 | All-caps labels and tier badges |

Avoid font sizes outside these tiers — a new size should be a deliberate addition to the kit, not a one-off.

---

## 4. Voice

Three audiences, three registers:

### To clinicians (default — most of the app)
- **Direct, terse, citation-anchored.** Maudsley-style rather than marketing-style.
- Use clinical abbreviations freely (FBC, ECG, eGFR) — link them to the glossary if non-obvious.
- Quantify when possible. "30–40% major malformation rate" beats "high risk".
- Refer to the engine's outputs by their proper names (PsychSwitch Score, evidence grade, citation chip).

### To patients (counselling card, patient handouts)
- **Plain language.** No clinical abbreviations without a translation.
- Calm imperatives. *"Take olanzapine 15 mg at bedtime."*
- Always close with "If you notice X, call your clinic" — patient agency over passive instruction.
- Never use the word "drug". Use "medication".

### To everyone (landing page, store listing)
- **Confident, factual, not salesy.** "Reviewed cross-titration schedules, cited to the page" beats "the smartest psychiatric prescribing app".
- Numbers carry weight: tests passing, rules reviewed, citations resolved.
- Never claim diagnostic capability or replace clinical judgement.

---

## 5. Iconography

`components/Icon.tsx` — 30+ Lucide-style stroke icons, all rendered via `react-native-svg`.

Rules:
- **Stroke-only**, never filled.
- `strokeWidth = 1.75` default, `2.5` for primary actions.
- Size: 14 (inline), 16 (default body), 18 (CTA), 20+ (hero).
- Colour: matches the surrounding tier — accent for primary, muted for secondary, danger/warning for safety.

When you need a new icon, add it to `Icon.tsx` rather than importing a new library. Keeps the bundle small and the visual language consistent.

---

## 6. Motion

- **Reliability over polish.** The earlier `AnimatedReveal` mass-fade-in was removed because it intermittently left content invisible in Expo Go.
- Keep animation strictly additive — never gate visibility on a successful animation start.
- Allowed: button-press scale (`active:opacity-80`), modal cross-fade (built into RN), pulse loaders for skeletons, score-ring fill on first render.
- Avoid: physics, page transitions, scroll-driven animation, anything that requires `useNativeDriver: false`.

---

## 7. Spacing

NativeWind / Tailwind defaults. Common tokens:

- `gap-3` / `mb-3` (12px) for related-element spacing.
- `mt-4` / `gap-4` (16px) for cards under each other.
- `mt-6` / `mt-7` (24/28px) for major section breaks.
- `px-4 py-3` is the canonical card padding.
- Row padding inside cards: `px-4 py-3`. Reduce to `py-2.5` when rows are dense (schedule, glossary).

---

## 8. Naming

- **PsychSwitch** — one word, capital P + S. Never "Psych Switch" or "psychswitch" except in URLs and identifiers.
- **PsychSwitch edition** — only in the app name and store listing. In conversation just "PsychSwitch".
- **Rules** are referenced by id (`olanzapine-to-aripiprazole`) in technical content and as `From → To` (`Olanzapine → Aripiprazole`) in display.
- **Drug ids** are kebab-case lowercase, matching the JSON file names.
- **Citation keys** are snake_case lowercase with version markers (e.g. `maudsley15_ch3_p369_table_3_7`).

---

## 9. Things we don't do

- We don't use emoji in clinical content. (Emoji in marketing copy is OK.)
- We don't use bright reds for non-safety content.
- We don't use multi-coloured logos / icons / gradients in icon tiles.
- We don't use shadows except on primary CTAs (`shadowOpacity: 0.20–0.25`, `shadowRadius: 10–12`, `shadowColor: var(--accent)`).
- We don't use rounded corners larger than `rounded-2xl` (16px) outside hero sections.
- We don't centre-align body text in the app. Centred text is reserved for empty states and CTAs.

---

This kit is a contract. Diverging from it is fine if it serves a clearer clinical purpose — but it's a deliberate decision, not a default.
