// Patient-context warnings card. Shows engine-flagged dose adjustments,
// contraindications and "do this differently" notes pulled from the
// patient context register.
//
// If the user hasn't filled in any context, render a soft prompt instead
// of disappearing entirely — that prompt is the nudge to capture context
// for safer decisions.
//
// As of v0.4.10 every state renders via the unified <Banner> primitive.
import { Pressable, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { ContextWarning } from '../engine/patientContext';
import type { RootStackParamList } from '../utils/navigation';
import { Banner, type BannerTone } from './Banner';
import { Icon } from './Icon';

function severityTone(s: ContextWarning['severity']): BannerTone {
  switch (s) {
    case 'info':    return 'info';
    case 'warning': return 'warning';
    case 'danger':  return 'danger';
  }
}

function severityEyebrow(s: ContextWarning['severity'], drugId?: string): string {
  const base = s === 'danger' ? 'Avoid' : s === 'warning' ? 'Caution' : 'Note';
  return drugId ? `${base} · ${drugId}` : base;
}

export function ContextWarningsCard({
  warnings,
  hasContext,
}: {
  warnings: ContextWarning[];
  hasContext: boolean;
}) {
  const nav = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  if (!hasContext) {
    return (
      <Pressable
        onPress={() => nav.navigate('PatientContext')}
        className="mt-3 active:opacity-80"
      >
        <Banner
          tone="neutral"
          eyebrow="Patient context"
          trailing={<Icon name="chevron-right" size={18} color="#6b7280" />}
        >
          <Text className="text-text text-sm leading-5">
            Add age, renal/hepatic function, pregnancy, comorbidities to
            activate context warnings.
          </Text>
        </Banner>
      </Pressable>
    );
  }

  if (warnings.length === 0) {
    return (
      <Banner
        tone="success"
        eyebrow="Context applied"
        className="mt-3"
      >
        <Text className="text-text text-xs">
          No context-driven warnings for this pair. Engine still applied
          renal / hepatic / pregnancy filters silently.
        </Text>
      </Banner>
    );
  }

  return (
    <View className="mt-3">
      {warnings.map((w, i) => (
        <Banner
          key={i}
          tone={severityTone(w.severity)}
          eyebrow={severityEyebrow(w.severity, w.drugId)}
          body={w.message}
          className="mb-2"
        />
      ))}
    </View>
  );
}
