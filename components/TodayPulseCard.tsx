// Today's pulse card — Home-screen widget showing what monitoring is
// due across all saved cases. Three tiers (overdue / today / soon)
// surfaced as a collapsible card.
//
// Renders nothing at all when no saved case has any pulse in the next
// 14 days — keeps the home dashboard quiet for clinicians who haven't
// saved anything or whose cases are stable.
import { useMemo, useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import {
  computeCasePulses,
  pulseCountsByTier,
  tierColor,
  tierLabel,
  type CasePulse,
} from '../engine/casePulse';
import type { SavedCase } from '../engine/caseManager';
import { tap as hapticTap } from '../utils/haptics';
import { Icon } from './Icon';

const MAX_VISIBLE = 5;

export function TodayPulseCard({
  cases,
  onPulsePress,
}: {
  cases: SavedCase[];
  onPulsePress?: (pulse: CasePulse) => void;
}) {
  const pulses = useMemo(() => computeCasePulses(cases), [cases]);
  const counts = useMemo(() => pulseCountsByTier(pulses), [pulses]);
  const [expanded, setExpanded] = useState(false);

  if (pulses.length === 0) return null;

  // Headline composition — only mention tiers that have at least one
  // entry. Keeps the line readable on phones.
  const segments: string[] = [];
  if (counts.overdue) segments.push(`${counts.overdue} overdue`);
  if (counts.today) segments.push(`${counts.today} today`);
  if (counts.soon) segments.push(`${counts.soon} this week`);
  const headline = segments.join(' · ');

  // Pick a hero tint — show overdue red if any, else amber, else blue.
  const heroTier = counts.overdue ? 'overdue' : counts.today ? 'today' : 'soon';
  const heroColor = tierColor(heroTier);

  const visible = expanded ? pulses : pulses.slice(0, MAX_VISIBLE);
  const hidden = pulses.length - visible.length;

  return (
    <View className="bg-surface border border-border rounded-2xl mt-3 overflow-hidden">
      <Pressable
        onPress={() => {
          hapticTap();
          setExpanded((e) => !e);
        }}
        className="flex-row items-center px-4 py-3 active:opacity-80"
      >
        <View
          className={`w-9 h-9 rounded-xl items-center justify-center mr-3 ${heroColor.dot.replace('bg-', 'bg-')}/15 border ${heroColor.dot.replace('bg-', 'border-')}/30`}
          style={{ borderWidth: 1 }}
        >
          <Icon
            name="heart-pulse"
            size={16}
            color={heroTier === 'overdue' ? '#ef4444' : heroTier === 'today' ? '#f59e0b' : '#3b82f6'}
          />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Today's pulse</Text>
          <Text className={`text-micro ${heroColor.text}`}>{headline}</Text>
        </View>
        <Icon
          name={expanded ? 'chevron-left' : 'chevron-right'}
          size={16}
          color="#6b7280"
        />
      </Pressable>

      {/* Always render the first row even when collapsed if there's
          something overdue — so the clinician can see the most urgent
          action without having to expand. */}
      {!expanded && counts.overdue > 0 && (
        <View className="border-t border-border">
          <PulseRow pulse={pulses[0]} isLast onPress={() => onPulsePress?.(pulses[0])} />
        </View>
      )}

      {expanded && (
        <View className="border-t border-border">
          {visible.map((p, i) => (
            <PulseRow
              key={`${p.caseId}-${p.dayOffset}-${p.entry.label}-${i}`}
              pulse={p}
              isLast={i === visible.length - 1 && hidden === 0}
              onPress={() => onPulsePress?.(p)}
            />
          ))}
          {hidden > 0 && (
            <View className="px-4 py-2.5 bg-bg/50">
              <Text className="text-muted text-micro text-center">
                +{hidden} more — open Saved cases for the full schedule.
              </Text>
            </View>
          )}
        </View>
      )}
    </View>
  );
}

function PulseRow({
  pulse,
  isLast,
  onPress,
}: {
  pulse: CasePulse;
  isLast: boolean;
  onPress: () => void;
}) {
  const c = tierColor(pulse.tier);
  const dayText =
    pulse.daysFromNow === 0
      ? 'today'
      : pulse.daysFromNow === 1
        ? 'tomorrow'
        : pulse.daysFromNow === -1
          ? 'yesterday'
          : pulse.daysFromNow > 0
            ? `in ${pulse.daysFromNow}d`
            : `${Math.abs(pulse.daysFromNow)}d ago`;

  return (
    <Pressable
      onPress={onPress}
      className={`flex-row items-center px-4 py-3 active:opacity-80 ${!isLast ? 'border-b border-border' : ''}`}
    >
      <View className={`w-1.5 h-1.5 rounded-full ${c.dot} mr-3`} />
      <View className="flex-1 pr-2">
        <Text className="text-text text-sm font-medium" numberOfLines={1}>
          {pulse.entry.label}
        </Text>
        <Text className="text-muted text-micro" numberOfLines={1}>
          {pulse.caseLabel} · D{pulse.dayOffset} · {dayText}
        </Text>
      </View>
      <Text className={`text-eyebrow uppercase tracking-wider font-bold ${c.text}`}>
        {tierLabel(pulse.tier)}
      </Text>
      <Icon name="chevron-right" size={14} color="#6b7280" />
    </Pressable>
  );
}
