// Unified segmented-control primitive.
//
// By v0.4.10 we had four near-identical segmented pills:
//
//   1. ViewToggle (Result screen)              — Summary / Detailed
//   2. TaperSpeedToggle (Result screen)        — Faster / Standard / Slower (with sublabels + warning accent)
//   3. Segmented helper (SettingsScreen)       — generic 2-segment
//   4. ResultTabs (Result screen)              — already on its own primitive (icon + label tabs); kept distinct because tabs carry icons and live in a different position in the screen hierarchy.
//
// (1)–(3) all reduced to the same pattern: a horizontal row, a pill
// track background, an active-pill fill, label text, optional sublabel
// underneath, optional accent colour for "this option is non-default".
// This component is the shared base.
//
// API:
//
//   <SegmentedControl
//     label="Taper speed"                 // optional uppercase label above the row
//     options={[                          // each option carries a key, label, optional sublabel + accent
//       { value: 'faster',   label: 'Faster',   sublabel: '−25%', accent: true  },
//       { value: 'standard', label: 'Standard', sublabel: 'Maudsley default'    },
//       { value: 'slower',   label: 'Slower',   sublabel: '+50%', accent: true  },
//     ]}
//     value={speed}
//     onChange={setSpeed}
//   />
//
// Sized for inline use inside a card; flex-1 so each segment fills evenly.

import { Pressable, Text, View } from 'react-native';

export interface SegmentedOption<T extends string | number> {
  value: T;
  label: string;
  /** Optional smaller line under the label (e.g. "−25%", "Maudsley default"). */
  sublabel?: string;
  /**
   * If true, label is rendered in the warning amber instead of the
   * neutral text colour when active. Use to flag "non-default" or
   * "outside reviewed" choices (e.g. faster/slower tapers).
   */
  accent?: boolean;
}

export interface SegmentedControlProps<T extends string | number> {
  options: ReadonlyArray<SegmentedOption<T>>;
  value: T;
  onChange: (value: T) => void;
  /** Optional uppercase label rendered above the row. */
  label?: string;
  /** Forward extra Tailwind classes for layout (margins, etc.). */
  className?: string;
}

// Theme constants — kept as plain hex/string so NativeWind 4's
// css-interop never has to resolve dynamic conditional class strings,
// which has been a source of intermittent crashes in dev.
const THEME = {
  track: 'rgba(31, 41, 51, 0.4)', // border @ 40%
  activePill: '#141a22',           // surface
  activeText: '#e6edf3',           // text
  inactiveText: '#8b949e',         // muted
  warning: '#f59e0b',              // warning
} as const;

export function SegmentedControl<T extends string | number>({
  options,
  value,
  onChange,
  label,
  className = '',
}: SegmentedControlProps<T>) {
  return (
    <View className={className}>
      {label && (
        <Text
          style={{
            color: THEME.inactiveText,
            fontSize: 11,
            fontWeight: '600',
            letterSpacing: 1,
            textTransform: 'uppercase',
            marginBottom: 6,
          }}
        >
          {label}
        </Text>
      )}
      <View
        style={{
          flexDirection: 'row',
          backgroundColor: THEME.track,
          borderRadius: 12,
          padding: 4,
        }}
      >
        {options.map((opt) => {
          const isActive = value === opt.value;
          const accentTint = opt.accent && isActive;
          return (
            <Pressable
              key={String(opt.value)}
              onPress={() => onChange(opt.value)}
              accessibilityRole="button"
              accessibilityState={{ selected: isActive }}
              accessibilityLabel={
                opt.sublabel ? `${opt.label}, ${opt.sublabel}` : opt.label
              }
              style={{
                flex: 1,
                paddingVertical: 8,
                paddingHorizontal: 4,
                borderRadius: 8,
                alignItems: 'center',
                backgroundColor: isActive ? THEME.activePill : 'transparent',
              }}
            >
              <Text
                style={{
                  fontSize: 13,
                  fontWeight: '600',
                  color: accentTint
                    ? THEME.warning
                    : isActive
                      ? THEME.activeText
                      : THEME.inactiveText,
                }}
              >
                {opt.label}
              </Text>
              {opt.sublabel && (
                <Text
                  style={{
                    fontSize: 10,
                    color: THEME.inactiveText,
                    marginTop: 1,
                  }}
                >
                  {opt.sublabel}
                </Text>
              )}
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}
