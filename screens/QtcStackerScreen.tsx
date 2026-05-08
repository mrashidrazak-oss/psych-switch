// QTc stacker — select all current medications and get an aggregate
// QTc risk assessment with recommendations.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  assessQtcRisk,
  getQtcData,
  listQtcDrugs,
} from '../engine/qtcStacker';
import type { OverallRisk, QtcDrugEntry } from '../engine/qtcStacker';

const CATEGORY_ORDER = [
  'antipsychotic',
  'antidepressant',
  'mood-stabilizer',
  'antibiotic',
  'other',
] as const;

const CATEGORY_LABEL: Record<string, string> = {
  antipsychotic: 'Antipsychotics',
  antidepressant: 'Antidepressants',
  'mood-stabilizer': 'Mood stabilizers',
  antibiotic: 'Antibiotics',
  other: 'Other (antiemetics, opioids)',
};

const QTC_BADGE_COLOR: Record<string, string> = {
  known: 'bg-danger',
  conditional: 'bg-warning',
  possible: 'bg-accent',
  low: 'bg-border',
};

const QTC_TEXT_COLOR: Record<string, string> = {
  known: 'text-danger',
  conditional: 'text-warning',
  possible: 'text-accent',
  low: 'text-muted',
};

const RISK_COLOR: Record<OverallRisk, string> = {
  none: 'text-to',
  low: 'text-to',
  moderate: 'text-warning',
  high: 'text-danger',
  very_high: 'text-danger',
};

const RISK_STRIPE: Record<OverallRisk, string> = {
  none: 'bg-to',
  low: 'bg-to',
  moderate: 'bg-warning',
  high: 'bg-danger',
  very_high: 'bg-danger',
};

const RISK_LABEL: Record<OverallRisk, string> = {
  none: 'No significant QTc risk',
  low: 'Low QTc risk',
  moderate: 'Moderate QTc risk — ECG recommended',
  high: 'HIGH QTc risk — ECG REQUIRED',
  very_high: 'VERY HIGH QTc risk — cardiology input',
};

export function QtcStackerScreen() {
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [showResult, setShowResult] = useState(false);

  const allDrugs = listQtcDrugs();
  const data = getQtcData();
  const assessment = assessQtcRisk([...selected]);

  const toggleDrug = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
    setShowResult(false);
  };

  const drugsGrouped: Record<string, QtcDrugEntry[]> = {};
  for (const d of allDrugs) {
    if (!drugsGrouped[d.category]) drugsGrouped[d.category] = [];
    drugsGrouped[d.category].push(d);
  }

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">QTc stacker</Text>
      <Text className="text-muted text-sm mb-2">
        Select all current medications. Tap 'Assess' to get the aggregate
        QTc risk and recommendations.
      </Text>

      {/* Risk legend */}
      <View className="flex-row gap-2 mb-4 flex-wrap">
        {(['known', 'conditional', 'possible', 'low'] as const).map((cat) => (
          <View key={cat} className="flex-row items-center gap-1">
            <View className={`w-2 h-2 rounded-full ${QTC_BADGE_COLOR[cat]}`} />
            <Text className={`text-xs capitalize ${QTC_TEXT_COLOR[cat]}`}>
              {cat}
            </Text>
          </View>
        ))}
      </View>

      {/* Drug checklist by category */}
      {CATEGORY_ORDER.map((cat) => {
        const drugs = drugsGrouped[cat];
        if (!drugs || drugs.length === 0) return null;
        return (
          <View key={cat} className="mb-4">
            <Text className="text-muted text-xs uppercase tracking-widest mb-2">
              {CATEGORY_LABEL[cat] ?? cat}
            </Text>
            <View className="bg-surface border border-border rounded-2xl overflow-hidden">
              {drugs.map((drug, i) => {
                const isSelected = selected.has(drug.id);
                const isLast = i === drugs.length - 1;
                return (
                  <Pressable
                    key={drug.id}
                    onPress={() => toggleDrug(drug.id)}
                    className={`flex-row items-center px-4 py-3 active:opacity-80 ${
                      !isLast ? 'border-b border-border' : ''
                    } ${isSelected ? 'bg-accent/10' : ''}`}
                  >
                    {/* Checkbox */}
                    <View
                      className={`w-5 h-5 rounded mr-3 items-center justify-center border ${
                        isSelected
                          ? 'bg-accent border-accent'
                          : 'border-border'
                      }`}
                    >
                      {isSelected && (
                        <Text className="text-white text-xs font-bold leading-none">
                          ✓
                        </Text>
                      )}
                    </View>
                    {/* Drug name */}
                    <Text className="text-text text-sm flex-1">
                      {drug.name}
                    </Text>
                    {/* Risk badge */}
                    <View
                      className={`px-2 py-0.5 rounded-full ${QTC_BADGE_COLOR[drug.qtcCategory]} opacity-80`}
                    >
                      <Text className="text-white text-eyebrow font-semibold capitalize">
                        {drug.qtcCategory}
                      </Text>
                    </View>
                  </Pressable>
                );
              })}
            </View>
          </View>
        );
      })}

      {/* Assess button */}
      <Pressable
        onPress={() => setShowResult(true)}
        disabled={selected.size === 0}
        className={`rounded-2xl py-4 mb-6 ${
          selected.size === 0 ? 'bg-border' : 'bg-accent active:opacity-80'
        }`}
      >
        <Text
          className={`text-center text-base font-semibold ${
            selected.size === 0 ? 'text-muted' : 'text-white'
          }`}
        >
          Assess QTc risk ({selected.size} drug{selected.size !== 1 ? 's' : ''})
        </Text>
      </Pressable>

      {/* Result */}
      {showResult && selected.size > 0 && (
        <>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
            <View className="flex-row">
              <View className={`w-2 ${RISK_STRIPE[assessment.overallRisk]}`} />
              <View className="flex-1 px-4 py-4">
                <Text
                  className={`text-base font-bold mb-1 ${RISK_COLOR[assessment.overallRisk]}`}
                >
                  {RISK_LABEL[assessment.overallRisk]}
                </Text>
                <Text className="text-muted text-xs mb-3">
                  {assessment.summary}
                </Text>

                {/* Recommendations */}
                <Text className="text-muted text-xs uppercase tracking-wider mb-2">
                  Recommendations
                </Text>
                {assessment.recommendations.map((r, i) => (
                  <Text key={i} className="text-text text-sm leading-5 mb-1">
                    • {r}
                  </Text>
                ))}
              </View>
            </View>
          </View>

          {/* Per-drug notes for selected drugs with conditional+ risk */}
          {assessment.selectedDrugs
            .filter((d) => d.qtcCategory !== 'low')
            .map((d) => (
              <View
                key={d.id}
                className="flex-row bg-surface border border-border rounded-2xl overflow-hidden mb-2"
              >
                <View className={`w-1.5 ${QTC_BADGE_COLOR[d.qtcCategory]}`} />
                <View className="flex-1 px-4 py-3">
                  <Text className="text-text text-sm font-semibold mb-1">
                    {d.name}
                    <Text className={`text-xs font-normal ml-1 ${QTC_TEXT_COLOR[d.qtcCategory]}`}>
                      {' '}({d.qtcCategory})
                    </Text>
                  </Text>
                  <Text className="text-muted text-xs leading-4">{d.notes}</Text>
                </View>
              </View>
            ))}
        </>
      )}

      {/* Source note */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Data source
        </Text>
        {data.citations.slice(0, 2).map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {data.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}
