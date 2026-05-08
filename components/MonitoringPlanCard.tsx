// Full monitoring plan — a chronologically-sorted list of investigations
// and reviews driven by engine/monitoring.ts.
//
// Sits in the "Detailed" view of ResultScreen. Collapsible by category
// to keep the screen scannable.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import type { MonitoringEntry, MonitoringPlan } from '../engine/monitoring';
import { Icon } from './Icon';

const CATEGORY_LABEL = {
  lab:      'Labs',
  ecg:      'ECG',
  physical: 'Physical',
  rating:   'Rating',
  review:   'Review',
} as const;

const CATEGORY_COLOR = {
  lab:      'text-accent',
  ecg:      'text-warning',
  physical: 'text-to',
  rating:   'text-from',
  review:   'text-muted',
} as const;

export function MonitoringPlanCard({ plan }: { plan: MonitoringPlan }) {
  const [expanded, setExpanded] = useState(true);
  if (plan.entries.length === 0) return null;

  return (
    <View className="bg-surface border border-border rounded-2xl overflow-hidden mt-4">
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="flex-row items-center px-4 py-3 active:opacity-80"
      >
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="clipboard-check" size={16} color="#3b82f6" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Monitoring plan</Text>
          <Text className="text-muted text-micro">
            {plan.entries.length} item{plan.entries.length === 1 ? '' : 's'} over {plan.spanDays} days
          </Text>
        </View>
        <Icon name={expanded ? 'chevron-left' : 'chevron-right'} size={16} color="#6b7280" />
      </Pressable>

      {expanded && (
        <View className="border-t border-border">
          {plan.entries.map((e, i) => (
            <MonitoringRow
              key={`${e.label}-${e.dayOffset}-${i}`}
              entry={e}
              isLast={i === plan.entries.length - 1}
            />
          ))}
        </View>
      )}
    </View>
  );
}

function MonitoringRow({
  entry,
  isLast,
}: {
  entry: MonitoringEntry;
  isLast: boolean;
}) {
  const dayLabel = entry.dayOffset === 0 ? 'D0 (start)' : `D${entry.dayOffset}`;
  return (
    <View className={`flex-row px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}>
      <View className="w-14">
        <Text className="text-muted text-micro font-mono">{dayLabel}</Text>
      </View>
      <View className="flex-1">
        <View className="flex-row items-center mb-0.5">
          <Text className="text-text text-sm font-semibold">{entry.label}</Text>
          <Text className={`text-eyebrow uppercase tracking-wider font-bold ml-2 ${CATEGORY_COLOR[entry.category]}`}>
            {CATEGORY_LABEL[entry.category]}
          </Text>
        </View>
        <Text className="text-muted text-xs leading-4">{entry.detail}</Text>
      </View>
    </View>
  );
}
