// Specialty-depth card — surfaces pregnancy / breastfeeding /
// pediatric / geriatric recommendations on the Result screen.
//
// Renders nothing unless at least one specialty is active for the
// current patient context. When active, it dominates visual weight
// because these subgroups are exactly where general-purpose
// switching tools fail.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import {
  specialtyLabel,
  tierLabel,
  tierTint,
  type SpecialtyAssessment,
  type SpecialtyRecommendation,
  type Specialty,
  type SpecialtyTier,
} from '../engine/specialty';
import { Chip, type ChipTone } from './Chip';
import { Icon, type IconName } from './Icon';

/** Map specialty tier → Chip tone. */
function tierTone(t: SpecialtyTier): ChipTone {
  switch (t) {
    case 'preferred':  return 'success';
    case 'acceptable': return 'info';
    case 'caution':    return 'warning';
    case 'avoid':      return 'danger';
  }
}

const SPECIALTY_ICON: Record<Specialty, IconName> = {
  pregnancy: 'heart-pulse',
  breastfeeding: 'user',
  pediatric: 'sparkles',
  geriatric: 'shield',
};

const SPECIALTY_TINT: Record<Specialty, string> = {
  pregnancy: '#ef4444',
  breastfeeding: '#a78bfa',
  pediatric: '#34d399',
  geriatric: '#f59e0b',
};

export function SpecialtyDepthCard({ assessment }: { assessment: SpecialtyAssessment }) {
  const [expanded, setExpanded] = useState(false);
  if (assessment.applicable.length === 0) return null;
  if (assessment.recommendations.length === 0) return null;

  // Sort recs by specialty for grouped display
  const grouped: Record<Specialty, SpecialtyRecommendation[]> = {
    pregnancy: [],
    breastfeeding: [],
    pediatric: [],
    geriatric: [],
  };
  for (const r of assessment.recommendations) grouped[r.specialty].push(r);

  // Hero tint — most concerning specialty / tier combination
  const worstTier = assessment.recommendations.reduce<string>((acc, r) => {
    const rank = { avoid: 0, caution: 1, acceptable: 2, preferred: 3 }[r.tier];
    const accRank = { avoid: 0, caution: 1, acceptable: 2, preferred: 3 }[acc as 'avoid' | 'caution' | 'acceptable' | 'preferred'] ?? 4;
    return rank < accRank ? r.tier : (acc as string);
  }, 'preferred' as string);
  const heroTint = tierTint(worstTier as 'avoid');
  const heroIcon = assessment.applicable[0];

  return (
    <View className={`bg-surface border ${heroTint.border} rounded-2xl mt-3 overflow-hidden`}>
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="flex-row items-center px-4 py-3 active:opacity-80"
      >
        <View
          className="w-9 h-9 rounded-xl items-center justify-center mr-3"
          style={{
            backgroundColor: `${SPECIALTY_TINT[heroIcon]}1a`,
            borderWidth: 1,
            borderColor: `${SPECIALTY_TINT[heroIcon]}33`,
          }}
        >
          <Icon name={SPECIALTY_ICON[heroIcon]} size={16} color={SPECIALTY_TINT[heroIcon]} />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Specialty considerations</Text>
          <Text className={`${heroTint.text} text-micro`} numberOfLines={2}>
            {assessment.headline}
          </Text>
        </View>
        <Icon name={expanded ? 'chevron-left' : 'chevron-right'} size={16} color="#6b7280" />
      </Pressable>

      {expanded && (
        <View className="border-t border-border">
          {assessment.applicable.map((sp) => {
            const items = grouped[sp];
            if (items.length === 0) return null;
            return (
              <View key={sp}>
                <View className="flex-row items-center px-4 py-2 bg-bg/50">
                  <View
                    className="w-1.5 h-4 rounded-sm mr-2"
                    style={{ backgroundColor: SPECIALTY_TINT[sp] }}
                  />
                  <Text className="text-text text-eyebrow uppercase tracking-widest font-bold">
                    {specialtyLabel(sp)}
                  </Text>
                </View>
                {items.map((r, i) => (
                  <RecommendationRow
                    key={`${r.drugId}-${r.specialty}-${i}`}
                    rec={r}
                    isLast={i === items.length - 1}
                  />
                ))}
              </View>
            );
          })}
          <View className="px-4 py-2 bg-bg/30 border-t border-border">
            <Text className="text-muted text-micro leading-4">
              Tiers (best → worst): preferred · acceptable · caution · avoid.
              Drawn from Maudsley 15th, NICE perinatal NG192, Beers 2023, and FDA labelling.
            </Text>
          </View>
        </View>
      )}
    </View>
  );
}

function RecommendationRow({
  rec,
  isLast,
}: {
  rec: SpecialtyRecommendation;
  isLast: boolean;
}) {
  const tint = tierTint(rec.tier);
  return (
    <View className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}>
      <View className="flex-row items-start">
        <View className="flex-1 pr-3">
          <Text className="text-text text-sm font-semibold">
            {rec.drugName ?? rec.drugId}
          </Text>
          <Text className="text-muted text-xs leading-4 mt-0.5">{rec.rationale}</Text>
          {rec.knownRisks && (
            <View className="bg-bg/60 border-l-2 border-danger rounded-r-md px-3 py-1.5 mt-2">
              <Text className="text-danger text-eyebrow uppercase tracking-widest font-bold mb-0.5">
                Known risks
              </Text>
              <Text className="text-text text-micro leading-4">{rec.knownRisks}</Text>
            </View>
          )}
          {rec.doseFactor != null && rec.doseFactor < 1 && (
            <Text className="text-muted text-micro mt-1.5">
              Dose modifier: start at <Text className="text-text font-semibold">{Math.round(rec.doseFactor * 100)}%</Text> of adult target.
            </Text>
          )}
          {rec.additionalMonitoring && rec.additionalMonitoring.length > 0 && (
            <View className="mt-1.5">
              {rec.additionalMonitoring.map((m, i) => (
                <Text key={i} className="text-muted text-micro leading-4">
                  • {m}
                </Text>
              ))}
            </View>
          )}
        </View>
        <Chip
          tone={tierTone(rec.tier)}
          size="sm"
          label={tierLabel(rec.tier)}
        />
      </View>
    </View>
  );
}
