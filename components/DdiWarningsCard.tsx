// DDI warnings during the cross-taper overlap window.
//
// Pulled from engine/ddi.ts. Renders one card per pattern hit, severity-
// sorted with the most serious at top.
import { Text, View } from 'react-native';
import type { DdiHit, DdiSeverity } from '../engine/ddi';
import { Icon } from './Icon';

const SEV_ORDER: Record<DdiSeverity, number> = { avoid: 3, warning: 2, caution: 1, info: 0 };

const STRIPE: Record<DdiSeverity, string> = {
  info:    'bg-accent',
  caution: 'bg-warning',
  warning: 'bg-warning',
  avoid:   'bg-danger',
};

const TEXT: Record<DdiSeverity, string> = {
  info:    'text-accent',
  caution: 'text-warning',
  warning: 'text-warning',
  avoid:   'text-danger',
};

const LABEL: Record<DdiSeverity, string> = {
  info:    'Note',
  caution: 'Caution',
  warning: 'Warning',
  avoid:   'Avoid',
};

export function DdiWarningsCard({ hits }: { hits: DdiHit[] }) {
  if (hits.length === 0) return null;
  const sorted = [...hits].sort((a, b) => SEV_ORDER[b.severity] - SEV_ORDER[a.severity]);

  return (
    <View className="mt-4">
      <View className="flex-row items-center mb-2">
        <Icon name="shield" size={14} color="#f59e0b" />
        <Text className="text-warning text-eyebrow uppercase tracking-widest font-bold ml-1.5">
          Overlap-window interactions
        </Text>
      </View>
      {sorted.map((h, i) => (
        <View
          key={i}
          className="flex-row bg-surface border border-border rounded-2xl overflow-hidden mb-2"
        >
          <View className={`w-1.5 ${STRIPE[h.severity]}`} />
          <View className="flex-1 px-4 py-3">
            <Text className={`${TEXT[h.severity]} text-eyebrow uppercase tracking-widest font-bold mb-0.5`}>
              {LABEL[h.severity]} · {h.mechanism.replace(/_/g, ' ')}
            </Text>
            <Text className="text-text text-sm leading-5 mb-1">
              {h.message}
            </Text>
            {h.mitigation && (
              <Text className="text-muted text-xs leading-4">
                <Text className="font-semibold">Mitigation: </Text>
                {h.mitigation}
              </Text>
            )}
          </View>
        </View>
      ))}
    </View>
  );
}
