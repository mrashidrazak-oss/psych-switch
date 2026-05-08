// Tailwind config — tells Tailwind which files to scan for class names.
// If you create a new folder containing components with `className=`,
// add it to the `content` array.
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.tsx',
    './screens/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      // ── Typography scale ─────────────────────────────────────────────
      // Codified in v0.4.13 to replace ad-hoc `text-[10px]` / `text-[11px]`
      // sprinkled across ~215 sites. Each token has a paired line-height so
      // line-height drift can't reintroduce the rhythm problems we just
      // cleaned up. Names are semantic, not numeric.
      //
      //   display  30 / 36   — splash heroes, big standalone numbers
      //   heading  24 / 28   — screen titles (h1)
      //   title    20 / 24   — section heroes (h2)
      //   subtitle 16 / 22   — card titles, body-lead
      //   body     14 / 20   — body default
      //   caption  12 / 16   — secondary captions, helper text
      //   micro    11 / 14   — chip labels, fine print
      //   eyebrow  10 / 14   — UPPERCASE eyebrow labels, tier tags
      //
      // Continue using stock `text-xs` / `text-sm` / `text-base` etc.
      // anywhere the meaning is purely "default size" — these tokens are
      // for places where the role is more specific than the size.
      fontSize: {
        eyebrow:  ['10px', '14px'],
        micro:    ['11px', '14px'],
        caption:  ['12px', '16px'],
        body:     ['14px', '20px'],
        subtitle: ['16px', '22px'],
        title:    ['20px', '24px'],
        heading:  ['24px', '28px'],
        display:  ['30px', '36px'],
      },
      colors: {
        // Clinical-app palette: high-contrast, dark-mode-first, no decorative
        // colour. Reds are reserved for safety warnings only.
        bg: '#0b0f14',
        surface: '#141a22',
        border: '#1f2933',
        text: '#e6edf3',
        muted: '#8b949e',
        accent: '#3b82f6',
        warning: '#f59e0b',
        danger: '#ef4444',
        from: '#60a5fa',
        to: '#34d399',
      },
    },
  },
  plugins: [],
};
