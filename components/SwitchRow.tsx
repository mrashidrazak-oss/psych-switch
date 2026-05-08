// Unified boolean switch-row primitive.
//
// Replaces three near-identical hand-rolled switch toggles:
//
//   1. ToggleRow in SettingsScreen (notifications, crash reports, …)
//   2. Conservative-mode toggle on the Result screen
//   3. The benzo-tapering switch in ClozapineAncCheckerScreen
//
// All three were implemented as a Pressable with a manually-laid-out
// 10×6 (or 11×6) rounded-full track + 5×5 (or 5×5) thumb. NativeWind's
// css-interop occasionally chokes on the dynamic conditional class
// strings used to position the thumb (`items-${value ? 'end' : 'start'}`),
// so this component centralises the pattern using inline styles for
// the visual bits and Tailwind only for layout.
//
// API:
//
//   <SwitchRow
//     label="Crash reports"
//     description="Send anonymised crash data to Sentry."
//     value={settings.crashReports}
//     onChange={(v) => setSettings({ crashReports: v })}
//   />
//
// Optional `wrapped={false}` strips the outer card chrome — useful when
// the row is already inside a Banner or another card.

import { Pressable, Text, View } from 'react-native';

export interface SwitchRowProps {
  label: string;
  description?: string;
  value: boolean;
  onChange: (value: boolean) => void;
  /**
   * If true (default), the row renders inside a surface card with a
   * border. Set false when the row is already inside another card.
   */
  wrapped?: boolean;
  /** Extra Tailwind classes (margins, etc.). */
  className?: string;
  accessibilityLabel?: string;
}

const TRACK_ON = '#3b82f6';   // accent
const TRACK_OFF = '#1f2933';  // border

export function SwitchRow({
  label,
  description,
  value,
  onChange,
  wrapped = true,
  className = '',
  accessibilityLabel,
}: SwitchRowProps) {
  const containerClass = wrapped
    ? `bg-surface border border-border rounded-2xl px-4 py-3 flex-row items-center active:opacity-80 ${className}`
    : `flex-row items-center active:opacity-80 ${className}`;

  return (
    <Pressable
      onPress={() => onChange(!value)}
      accessibilityRole="switch"
      accessibilityState={{ checked: value }}
      accessibilityLabel={accessibilityLabel ?? label}
      className={containerClass}
    >
      <View className="flex-1 mr-3">
        <Text className="text-text text-sm font-semibold">{label}</Text>
        {description && (
          <Text className="text-muted text-micro mt-0.5">
            {description}
          </Text>
        )}
      </View>
      <View
        style={{
          width: 40,
          height: 24,
          borderRadius: 12,
          backgroundColor: value ? TRACK_ON : TRACK_OFF,
          padding: 2,
          flexDirection: 'row',
          justifyContent: value ? 'flex-end' : 'flex-start',
          alignItems: 'center',
        }}
      >
        <View
          style={{
            width: 20,
            height: 20,
            borderRadius: 10,
            backgroundColor: '#ffffff',
          }}
        />
      </View>
    </Pressable>
  );
}
