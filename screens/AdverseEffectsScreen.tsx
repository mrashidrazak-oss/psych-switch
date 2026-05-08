// Adverse-effect reverse lookup.
//
// Question this answers: "Patient on drug X has problem Y — what should
// I switch to?". Filter by category, tap a problem, see culprit drugs +
// candidate switch targets + management notes.
import { useMemo, useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { Chip } from '../components/Chip';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  ADVERSE_EFFECTS,
  CATEGORY_LABELS,
  type AdverseEffect,
  type AdverseEffectCategory,
} from '../engine/adverseEffects';

const CATEGORY_ORDER: AdverseEffectCategory[] = [
  'metabolic',
  'extrapyramidal',
  'sexual',
  'sedation',
  'cardiovascular',
  'gastrointestinal',
  'hematologic',
  'cognitive',
  'discontinuation',
];

export function AdverseEffectsScreen() {
  const [selected, setSelected] = useState<AdverseEffect | null>(null);

  const grouped = useMemo(() => {
    const g: Partial<Record<AdverseEffectCategory, AdverseEffect[]>> = {};
    for (const ae of ADVERSE_EFFECTS) (g[ae.category] ??= []).push(ae);
    return g;
  }, []);

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">
        Adverse-effect lookup
      </Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        Find the cause and a candidate switch target for common problems.
      </Text>

      {/* Detail panel — sticky-ish at the top when something is selected */}
      {selected && (
        <View className="bg-surface border border-accent/40 rounded-2xl px-4 py-4 mb-4">
          <View className="flex-row items-start mb-2">
            <View className="flex-1">
              <Text className="text-muted text-eyebrow uppercase tracking-widest mb-0.5">
                {CATEGORY_LABELS[selected.category]}
              </Text>
              <Text className="text-text text-base font-bold">
                {selected.label}
              </Text>
            </View>
            <Pressable onPress={() => setSelected(null)} className="ml-2 p-1">
              <Icon name="check" size={16} color="#8b949e" />
            </Pressable>
          </View>
          <Text className="text-muted text-xs mb-3 leading-4">
            {selected.summary}
          </Text>

          {/* Culprit drugs */}
          <Text className="text-warning text-eyebrow uppercase tracking-widest font-bold mb-1">
            Common causes
          </Text>
          <View className="flex-row flex-wrap mb-3" style={{ gap: 6 }}>
            {selected.causedBy.map((d) => (
              <Chip key={d} tone="warning" size="md" label={capitalize(d)} />
            ))}
          </View>

          {/* Candidate switches */}
          <Text className="text-to text-eyebrow uppercase tracking-widest font-bold mb-1">
            Candidate switch targets
          </Text>
          <View className="flex-row flex-wrap mb-3" style={{ gap: 6 }}>
            {selected.switchCandidates.map((d) => (
              <Chip key={d} tone="success" size="md" label={capitalize(d)} />
            ))}
          </View>

          {/* Management */}
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
            Management
          </Text>
          <Text className="text-text text-sm leading-5 mb-2">
            {selected.management}
          </Text>

          {selected.citations.length > 0 && (
            <Text className="text-muted text-eyebrow mt-1">
              {selected.citations[0]}
            </Text>
          )}
        </View>
      )}

      {/* Categorised list */}
      {CATEGORY_ORDER.filter((c) => grouped[c]).map((cat) => (
        <View key={cat} className="mb-4">
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 px-1">
            {CATEGORY_LABELS[cat]}
          </Text>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {grouped[cat]!.map((ae, i, arr) => {
              const active = selected?.id === ae.id;
              return (
                <Pressable
                  key={ae.id}
                  onPress={() => setSelected(active ? null : ae)}
                  className={`px-4 py-3 active:opacity-80 ${i < arr.length - 1 ? 'border-b border-border' : ''} ${active ? 'bg-accent/10' : ''}`}
                >
                  <View className="flex-row items-center">
                    <Text className="text-text text-sm font-medium flex-1">
                      {ae.label}
                    </Text>
                    <Icon name="chevron-right" size={16} color="#6b7280" />
                  </View>
                  <Text
                    className="text-muted text-xs mt-0.5"
                    numberOfLines={1}
                  >
                    {ae.summary}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>
      ))}
    </ScreenContainer>
  );
}

function capitalize(s: string): string {
  return s.length === 0 ? s : s[0].toUpperCase() + s.slice(1);
}
