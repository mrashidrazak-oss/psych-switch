// Unified banner / call-out primitive.
//
// Companion to <Chip> (v0.4.9). By v0.4.8 we had at least 5 banner
// shapes scattered across the app:
//
//   1. Stripe-left  — `flex-row bg-surface border border-border rounded-2xl
//                      overflow-hidden` + `<View className="w-1.5 bg-X" />`
//                      + content. The dominant style. Used by SafetyFlag,
//                      adapted-schedule, no-scale, taper-speed warning,
//                      indicative-schedule, washout, clozapine-redirect.
//   2. Outline      — `bg-surface border border-{tone} rounded-2xl` (no
//                      stripe). Used as a softer accent banner.
//   3. Soft fill    — `bg-{tone}/15 border border-{tone}/30 rounded-2xl`.
//                      Used inside Toast, error states, and a couple of
//                      specialty cards.
//   4. Inset quote  — `bg-bg/60 border-l-2 border-{tone} rounded-r-md`.
//                      Used for paraphrased citation excerpts. Distinct
//                      enough from a banner to keep separate; we'll leave
//                      that pattern alone.
//   5. SafetyFlag    — pattern (1) with a fixed eyebrow → title → body
//                      structure.
//
// This component covers patterns 1, 2 and 3. The API:
//
//   <Banner
//     tone="warning"          // neutral | info | success | warning | danger
//     variant="stripe"        // stripe (default) | outline | soft
//     eyebrow="Caution"       // optional uppercase tag (auto-set from tone if omitted in stripe variant)
//     title="..."             // optional bold title
//     body="..."              // optional muted body text
//     trailing={<Pressable />} // optional right-side slot (e.g. an action button)
//   >
//     {children}              // optional arbitrary content under the title/body
//   </Banner>
//
// Tone scale matches Chip's so the two compose visually:
//   neutral  — gray, generic information
//   info     — accent blue
//   success  — to-green
//   warning  — amber
//   danger   — red

import { Text, View } from 'react-native';

export type BannerTone = 'neutral' | 'info' | 'success' | 'warning' | 'danger';
export type BannerVariant = 'stripe' | 'outline' | 'soft';

const STRIPE_BAR: Record<BannerTone, string> = {
  neutral: 'bg-muted',
  info:    'bg-accent',
  success: 'bg-to',
  warning: 'bg-warning',
  danger:  'bg-danger',
};

const OUTLINE_BORDER: Record<BannerTone, string> = {
  neutral: 'border-border',
  info:    'border-accent',
  success: 'border-to',
  warning: 'border-warning',
  danger:  'border-danger',
};

const SOFT_TINT: Record<BannerTone, { bg: string; border: string }> = {
  neutral: { bg: 'bg-border',     border: 'border-border'      },
  info:    { bg: 'bg-accent/10',  border: 'border-accent/30'   },
  success: { bg: 'bg-to/10',      border: 'border-to/30'       },
  warning: { bg: 'bg-warning/10', border: 'border-warning/30'  },
  danger:  { bg: 'bg-danger/10',  border: 'border-danger/30'   },
};

const TONE_TEXT: Record<BannerTone, string> = {
  neutral: 'text-muted',
  info:    'text-accent',
  success: 'text-to',
  warning: 'text-warning',
  danger:  'text-danger',
};

/** Default eyebrow label per tone (used by stripe variant when no eyebrow is passed). */
const DEFAULT_EYEBROW: Record<BannerTone, string> = {
  neutral: 'Note',
  info:    'Note',
  success: 'OK',
  warning: 'Caution',
  danger:  'Warning',
};

export interface BannerProps {
  tone?: BannerTone;
  variant?: BannerVariant;
  eyebrow?: string;
  /** Set false to suppress the auto eyebrow on stripe variant. */
  hideEyebrow?: boolean;
  title?: string;
  body?: string;
  /** Right-side slot (e.g. an action Pressable). Stripe + outline only. */
  trailing?: React.ReactNode;
  /** Extra layout classes (margins, etc.). */
  className?: string;
  children?: React.ReactNode;
}

export function Banner({
  tone = 'warning',
  variant = 'stripe',
  eyebrow,
  hideEyebrow,
  title,
  body,
  trailing,
  className = '',
  children,
}: BannerProps) {
  const eyebrowText = eyebrow ?? DEFAULT_EYEBROW[tone];
  const eyebrowColor = TONE_TEXT[tone];

  if (variant === 'stripe') {
    return (
      <View
        className={`flex-row bg-surface border border-border rounded-2xl overflow-hidden ${className}`}
      >
        <View className={`w-1.5 ${STRIPE_BAR[tone]}`} />
        <View className="flex-1 px-4 py-3">
          <BannerContent
            eyebrow={hideEyebrow ? undefined : eyebrowText}
            eyebrowColor={eyebrowColor}
            title={title}
            body={body}
            trailing={trailing}
          >
            {children}
          </BannerContent>
        </View>
      </View>
    );
  }

  if (variant === 'outline') {
    return (
      <View
        className={`bg-surface border ${OUTLINE_BORDER[tone]} rounded-2xl px-4 py-3 ${className}`}
      >
        <BannerContent
          eyebrow={hideEyebrow ? undefined : eyebrow}
          eyebrowColor={eyebrowColor}
          title={title}
          body={body}
          trailing={trailing}
        >
          {children}
        </BannerContent>
      </View>
    );
  }

  // soft
  const tint = SOFT_TINT[tone];
  return (
    <View
      className={`${tint.bg} border ${tint.border} rounded-2xl px-4 py-3 ${className}`}
    >
      <BannerContent
        eyebrow={hideEyebrow ? undefined : eyebrow}
        eyebrowColor={eyebrowColor}
        title={title}
        body={body}
        trailing={trailing}
      >
        {children}
      </BannerContent>
    </View>
  );
}

function BannerContent({
  eyebrow,
  eyebrowColor,
  title,
  body,
  trailing,
  children,
}: {
  eyebrow?: string;
  eyebrowColor: string;
  title?: string;
  body?: string;
  trailing?: React.ReactNode;
  children?: React.ReactNode;
}) {
  return (
    <>
      {(eyebrow || trailing) && (
        <View className="flex-row items-center mb-1">
          {eyebrow && (
            <Text
              className={`${eyebrowColor} text-xs uppercase tracking-widest font-semibold flex-1`}
            >
              {eyebrow}
            </Text>
          )}
          {!eyebrow && <View className="flex-1" />}
          {trailing}
        </View>
      )}
      {title && (
        <Text className="text-text text-base font-semibold mb-1">{title}</Text>
      )}
      {body && <Text className="text-muted text-sm leading-5">{body}</Text>}
      {children}
    </>
  );
}
