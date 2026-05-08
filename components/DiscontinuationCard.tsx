// Discontinuation-syndrome banner for the from-drug.
//
// Renders only when severity >= moderate. Shows the expected symptoms,
// the strategy (e.g. "bridge to fluoxetine"), and the relevant half-life.
import { Text, View } from 'react-native';
import type { DiscontinuationFlag } from '../engine/discontinuation';
import { Icon } from './Icon';

const STRIPE = {
  low: 'bg-to',
  moderate: 'bg-warning',
  high: 'bg-warning',
  very_high: 'bg-danger',
} as const;

const TEXT = {
  low: 'text-to',
  moderate: 'text-warning',
  high: 'text-warning',
  very_high: 'text-danger',
} as const;

const LABEL = {
  low: 'Low',
  moderate: 'Moderate',
  high: 'High',
  very_high: 'Very high',
} as const;

export function DiscontinuationCard({
  flag,
  drugDisplayName,
}: {
  flag: DiscontinuationFlag;
  drugDisplayName: string;
}) {
  // Hide low-risk noise — only show when there's a clinical action required.
  if (flag.severity === 'low') return null;

  return (
    <View className="flex-row bg-surface border border-border rounded-2xl overflow-hidden mt-3">
      <View className={`w-1.5 ${STRIPE[flag.severity]}`} />
      <View className="flex-1 px-4 py-3">
        <View className="flex-row items-center mb-1.5">
          <Icon name="info" size={14} color="#f59e0b" />
          <Text className={`${TEXT[flag.severity]} text-eyebrow uppercase tracking-widest font-bold ml-1.5`}>
            Stopping {drugDisplayName} · {LABEL[flag.severity]} risk
          </Text>
        </View>
        <Text className="text-text text-sm leading-5 mb-2">
          {flag.symptoms}
        </Text>
        <Text className="text-muted text-xs leading-4">
          <Text className="text-text font-semibold">Strategy: </Text>
          {flag.strategy}
        </Text>
        {flag.halfLifeHours != null && (
          <Text className="text-muted text-eyebrow mt-1">
            t½ ≈ {flag.halfLifeHours} h
          </Text>
        )}
      </View>
    </View>
  );
}
