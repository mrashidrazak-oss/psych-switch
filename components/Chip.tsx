// Unified chip / badge primitive.
//
// By v0.4.7 the app had grown ~9 distinct chip styles competing visually:
// EvidenceBadge, CitationChip, OverlapIntensityChip, MonitoringChips,
// SafetyFlag stripes, score tier pills, specialty tier pills, cost tier
// pills, "+N more" pills. Each was added independently with its own
// padding, font size, border radius, and tone scale. The result was
// visually noisy and made tone hierarchy (info vs warning vs danger)
// hard to read at a glance.
//
// This component is the single source of truth. Every chip in the app
// should compose from it. The 5 tones map to the existing palette:
//   neutral → muted gray (informational, no urgency)
//   info    → accent blue (factual, evidence, citations)
//   success → "to" green (good news, opt-in confirmations)
//   warning → amber       (clinically meaningful caution)
//   danger  → red         (safety-critical signals)
//
// Two variants:
//   soft    (default) — tone/10 fill + tone/30 border + tone text.
//                       The dominant style across the app.
//   outline           — transparent fill + tone/40 border + tone text.
//                       Use when you need a chip on top of a tinted
//                       surface where soft would muddy.
//
// Two sizes:
//   sm — 10–11px text, px-2 py-0.5, dense rows of many chips
//   md (default) — 11–12px text, px-2.5 py-1, standalone or 2-3 in a row
//
// Composition slots:
//   leading  — an icon name OR an arbitrary node (e.g. a filled letter dot)
//   trailing — an icon name OR an arbitrary node
//   value    — a small mono suffix (e.g. " · 12/100", " · p369")
//
// When `onPress` is provided the chip becomes a Pressable with
// accessibilityRole="button" and a tap-to-open affordance. Without it,
// the chip is a static View. accessibilityLabel falls back to label.

import { Pressable, Text, View } from 'react-native';
import { Icon, type IconName } from './Icon';

export type ChipTone = 'neutral' | 'info' | 'success' | 'warning' | 'danger';
export type ChipSize = 'sm' | 'md';
export type ChipVariant = 'soft' | 'outline';

// Tailwind class fragments per tone. Kept as strings so NativeWind's
// css-interop can pre-resolve at build time — no dynamic colour math.
const TONE_SOFT: Record<ChipTone, { bg: string; border: string; text: string }> = {
  neutral: { bg: 'bg-border',      border: 'border-border',      text: 'text-muted'   },
  info:    { bg: 'bg-accent/10',   border: 'border-accent/30',   text: 'text-accent'  },
  success: { bg: 'bg-to/10',       border: 'border-to/30',       text: 'text-to'      },
  warning: { bg: 'bg-warning/10',  border: 'border-warning/30',  text: 'text-warning' },
  danger:  { bg: 'bg-danger/10',   border: 'border-danger/30',   text: 'text-danger'  },
};

const TONE_OUTLINE: Record<ChipTone, { bg: string; border: string; text: string }> = {
  neutral: { bg: 'bg-transparent', border: 'border-border',      text: 'text-muted'   },
  info:    { bg: 'bg-transparent', border: 'border-accent/40',   text: 'text-accent'  },
  success: { bg: 'bg-transparent', border: 'border-to/40',       text: 'text-to'      },
  warning: { bg: 'bg-transparent', border: 'border-warning/40',  text: 'text-warning' },
  danger:  { bg: 'bg-transparent', border: 'border-danger/40',   text: 'text-danger'  },
};

// Tone hex map for places that need a literal colour value (e.g. icon
// stroke colour, since Icon takes a colour prop, not a className).
export const TONE_HEX: Record<ChipTone, string> = {
  neutral: '#8b949e',
  info:    '#3b82f6',
  success: '#34d399',
  warning: '#f59e0b',
  danger:  '#ef4444',
};

const SIZE_LAYOUT: Record<ChipSize, { padding: string; text: string; iconSize: number }> = {
  sm: { padding: 'px-2 py-0.5',   text: 'text-eyebrow', iconSize: 10 },
  md: { padding: 'px-2.5 py-1',   text: 'text-micro',   iconSize: 12 },
};

export interface ChipProps {
  label: string;
  tone?: ChipTone;
  size?: ChipSize;
  variant?: ChipVariant;
  leadingIcon?: IconName;
  trailingIcon?: IconName;
  /** Slot for arbitrary leading content (e.g. a filled letter dot). Wins over `leadingIcon`. */
  leading?: React.ReactNode;
  /** Slot for arbitrary trailing content. Wins over `trailingIcon`. */
  trailing?: React.ReactNode;
  /** Small mono suffix appended after the label, e.g. " · 12/100". */
  value?: string;
  /** Make the chip a Pressable. */
  onPress?: () => void;
  /** Defaults to `label` (or `${label}, ${value}`). */
  accessibilityLabel?: string;
  /** Forward extra Tailwind classes for layout (margins, etc.). */
  className?: string;
}

export function Chip({
  label,
  tone = 'neutral',
  size = 'md',
  variant = 'soft',
  leadingIcon,
  trailingIcon,
  leading,
  trailing,
  value,
  onPress,
  accessibilityLabel,
  className = '',
}: ChipProps) {
  const tint = variant === 'soft' ? TONE_SOFT[tone] : TONE_OUTLINE[tone];
  const { padding, text, iconSize } = SIZE_LAYOUT[size];
  const toneHex = TONE_HEX[tone];

  const containerClass = `flex-row items-center rounded-full border ${tint.bg} ${tint.border} ${padding} ${onPress ? 'active:opacity-80' : ''} ${className}`;

  const content = (
    <>
      {leading ?? (leadingIcon && (
        <View className="mr-1">
          <Icon name={leadingIcon} size={iconSize} color={toneHex} />
        </View>
      ))}
      <Text className={`${tint.text} ${text} font-semibold`} numberOfLines={1}>
        {label}
      </Text>
      {value !== undefined && (
        <Text className={`${tint.text} ${text} font-mono ml-1`} numberOfLines={1}>
          {value}
        </Text>
      )}
      {trailing ?? (trailingIcon && (
        <View className="ml-1">
          <Icon name={trailingIcon} size={iconSize} color={toneHex} />
        </View>
      ))}
    </>
  );

  const a11y = accessibilityLabel ?? (value ? `${label}, ${value}` : label);

  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        accessibilityRole="button"
        accessibilityLabel={a11y}
        className={containerClass}
      >
        {content}
      </Pressable>
    );
  }

  return (
    <View accessibilityLabel={a11y} className={containerClass}>
      {content}
    </View>
  );
}

/**
 * A small filled circular prefix (e.g. an evidence-grade letter "A").
 * Designed to drop into Chip's `leading` slot.
 */
export function ChipDot({
  text,
  tone,
  size = 'md',
}: {
  text: string;
  tone: ChipTone;
  size?: ChipSize;
}) {
  const dim = size === 'sm' ? 'w-3.5 h-3.5' : 'w-4 h-4';
  const txt = size === 'sm' ? 'text-[9px]' : 'text-eyebrow';
  // Use the tone's /20 fill — slightly stronger than the chip body so it pops.
  const bg = {
    neutral: 'bg-muted/30',
    info:    'bg-accent/30',
    success: 'bg-to/30',
    warning: 'bg-warning/30',
    danger:  'bg-danger/30',
  }[tone];
  const txtColor = {
    neutral: 'text-text',
    info:    'text-accent',
    success: 'text-to',
    warning: 'text-warning',
    danger:  'text-danger',
  }[tone];
  return (
    <View className={`${dim} rounded-full items-center justify-center mr-1 ${bg}`}>
      <Text className={`${txtColor} font-bold ${txt}`}>{text}</Text>
    </View>
  );
}
