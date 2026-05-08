// Ramadan mode — drug-by-drug timing guidance for Ramadan fasting.
// Groups by drug class and shows recommended dosing window (Suhoor /
// Iftar / flexible) with per-drug special notes.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import guidanceData from '../content/ramadan/guidance.json';

type DrugGuidance = {
  id: string;
  name: string;
  dosing: string;
  recommendation: string;
  rationale: string;
  specialNote: string;
};

const TIMING_LABEL: Record<string, string> = {
  suhoor: 'Suhoor',
  iftar: 'Iftar',
  suhoor_or_iftar: 'Suhoor or Iftar',
  suhoor_and_iftar: 'Suhoor + Iftar (BD)',
  iftar_or_suhoor_and_iftar: 'Iftar (OD) or Suhoor + Iftar',
  suhoor_and_iftar_or_iftar: 'Suhoor + Iftar or Iftar (XR)',
  od_mr: 'Flexible (MR)',
  bd_or_od_xr: 'Suhoor + Iftar or Iftar (XR)',
  discuss_with_team: 'Discuss with team',
};

const TIMING_COLOR: Record<string, string> = {
  suhoor: 'bg-accent',
  iftar: 'bg-warning',
  suhoor_or_iftar: 'bg-to',
  suhoor_and_iftar: 'bg-accent',
  iftar_or_suhoor_and_iftar: 'bg-warning',
  suhoor_and_iftar_or_iftar: 'bg-accent',
  od_mr: 'bg-border',
  bd_or_od_xr: 'bg-accent',
  discuss_with_team: 'bg-danger',
};

// Group drugs by simple category inferred from drugId
const DRUG_GROUPS: { label: string; ids: string[] }[] = [
  {
    label: 'Antidepressants',
    ids: [
      'fluoxetine',
      'sertraline',
      'escitalopram',
      'paroxetine',
      'fluvoxamine',
      'venlafaxine',
      'duloxetine',
      'mirtazapine',
    ],
  },
  {
    label: 'Antipsychotics',
    ids: [
      'olanzapine',
      'quetiapine',
      'risperidone',
      'aripiprazole',
      'haloperidol',
      'clozapine',
    ],
  },
  {
    label: 'Mood stabilizers',
    ids: ['lithium', 'valproate', 'lamotrigine', 'carbamazepine'],
  },
];

export function RamadanModeScreen() {
  const [expanded, setExpanded] = useState<string | null>(null);
  const drugs = guidanceData.drugs as DrugGuidance[];

  const drugsById: Record<string, DrugGuidance> = {};
  for (const d of drugs) drugsById[d.id] = d;

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">Ramadan mode</Text>
      <Text className="text-muted text-sm mb-2">
        Dose-timing guidance for fasting patients. Malaysia fast: ~13–14h.
      </Text>

      {/* Timing key */}
      <View className="flex-row gap-3 mb-4 flex-wrap">
        <TimingPill label="Suhoor" color="bg-accent" />
        <TimingPill label="Iftar" color="bg-warning" />
        <TimingPill label="Flexible" color="bg-to" />
        <TimingPill label="⚠ Discuss" color="bg-danger" />
      </View>

      {/* General principles collapsible */}
      <Pressable
        onPress={() => setExpanded(expanded === '__principles__' ? null : '__principles__')}
        className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4 active:opacity-80"
      >
        <View className="flex-row items-center justify-between">
          <Text className="text-text text-sm font-semibold">
            General prescribing principles
          </Text>
          <Text className="text-muted text-lg">
            {expanded === '__principles__' ? '−' : '+'}
          </Text>
        </View>
        {expanded === '__principles__' && (
          <View className="mt-3">
            {guidanceData.generalPrinciples.map((p, i) => (
              <Text key={i} className="text-muted text-xs leading-5 mb-2">
                • {p}
              </Text>
            ))}
          </View>
        )}
      </Pressable>

      {/* Drug groups */}
      {DRUG_GROUPS.map((group) => (
        <View key={group.label} className="mb-4">
          <Text className="text-muted text-xs uppercase tracking-widest mb-2">
            {group.label}
          </Text>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {group.ids.map((id, i) => {
              const drug = drugsById[id];
              if (!drug) return null;
              const isExpanded = expanded === id;
              const isLast = i === group.ids.length - 1;
              const timingBg = TIMING_COLOR[drug.recommendation] ?? 'bg-border';
              const timingText =
                TIMING_LABEL[drug.recommendation] ?? drug.recommendation;

              return (
                <View key={id}>
                  <Pressable
                    onPress={() => setExpanded(isExpanded ? null : id)}
                    className={`px-4 py-3 active:opacity-80 ${
                      !isLast && !isExpanded ? 'border-b border-border' : ''
                    }`}
                  >
                    <View className="flex-row items-center">
                      <View className="flex-1">
                        <Text className="text-text text-sm font-semibold">
                          {drug.name}
                        </Text>
                        <Text className="text-muted text-xs">
                          {drug.dosing.replace(/_/g, ' ')}
                        </Text>
                      </View>
                      <View className={`rounded-full px-2.5 py-1 ${timingBg} opacity-90 ml-2`}>
                        <Text className="text-white text-eyebrow font-semibold">
                          {timingText}
                        </Text>
                      </View>
                      <Text className="text-muted ml-2">{isExpanded ? '−' : '+'}</Text>
                    </View>

                    {isExpanded && (
                      <View className="mt-3">
                        <View className="bg-bg rounded-xl px-3 py-2 mb-2">
                          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
                            Rationale
                          </Text>
                          <Text className="text-text text-xs leading-4">
                            {drug.rationale}
                          </Text>
                        </View>
                        {drug.specialNote && (
                          <View
                            className={`rounded-xl px-3 py-2 ${
                              drug.id === 'lithium' || drug.id === 'clozapine'
                                ? 'bg-danger/10 border border-danger/30'
                                : 'bg-bg'
                            }`}
                          >
                            <Text className="text-muted text-xs uppercase tracking-wider mb-1">
                              Note
                            </Text>
                            <Text
                              className={`text-xs leading-4 ${
                                drug.id === 'lithium' || drug.id === 'clozapine'
                                  ? 'text-danger'
                                  : 'text-text'
                              }`}
                            >
                              {drug.specialNote}
                            </Text>
                          </View>
                        )}
                      </View>
                    )}
                  </Pressable>
                  {!isLast && !isExpanded && null}
                  {(isExpanded || !isLast) && (
                    <View
                      className={`h-px bg-border ${isExpanded && !isLast ? 'mt-3' : ''}`}
                    />
                  )}
                </View>
              );
            })}
          </View>
        </View>
      ))}

      {/* Citations */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {guidanceData.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {guidanceData.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function TimingPill({ label, color }: { label: string; color: string }) {
  return (
    <View className={`flex-row items-center gap-1 rounded-full px-2 py-1 ${color} opacity-80`}>
      <Text className="text-white text-xs font-semibold">{label}</Text>
    </View>
  );
}
