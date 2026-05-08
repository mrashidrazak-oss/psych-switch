// Overlap-intensity chip — visible inline near the schedule header.
//
// Single tappable pill showing tier (low / moderate / high / severe).
// Tap → modal with the rationale, mechanism flags, and component
// breakdown.
//
// Designed to coexist with the ScaleResult banner ("schedule adapted")
// without crowding — this chip is one line, the banner can be longer.
//
// As of v0.4.8 the trigger pill and the inner mechanism flag pills
// are built on the unified Chip primitive (components/Chip.tsx).
import { useState } from 'react';
import { Modal, Pressable, ScrollView, Text, View } from 'react-native';
import {
  flagLabel,
  type OverlapAssessment,
  type OverlapTier,
} from '../engine/overlapIntensity';
import { tap as hapticTap } from '../utils/haptics';
import { Chip, type ChipTone, TONE_HEX } from './Chip';
import { Icon } from './Icon';

/** Map overlap tier → Chip tone. */
function tierTone(t: OverlapTier): ChipTone {
  switch (t) {
    case 'low':      return 'success';
    case 'moderate': return 'info';
    case 'high':     return 'warning';
    case 'severe':   return 'danger';
  }
}

export function OverlapIntensityChip({
  assessment,
}: {
  assessment: OverlapAssessment;
}) {
  const [open, setOpen] = useState(false);

  if (assessment.score === 0 && assessment.label === 'No overlap') {
    return null;
  }
  const tone = tierTone(assessment.tier);

  return (
    <>
      <Chip
        tone={tone}
        size="md"
        label={`⇆ ${assessment.label}`}
        value={`· ${assessment.score}/100`}
        onPress={() => {
          hapticTap();
          setOpen(true);
        }}
        accessibilityLabel={`Overlap intensity ${assessment.label}, ${assessment.score} out of 100. Tap for breakdown.`}
      />

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
        <View
          style={{
            flex: 1,
            backgroundColor: 'rgba(0,0,0,0.6)',
            justifyContent: 'center',
            paddingHorizontal: 24,
          }}
        >
          <View
            style={{
              backgroundColor: '#141a22',
              borderRadius: 20,
              borderWidth: 1,
              borderColor: '#1f2933',
              maxHeight: '80%',
            }}
          >
            <ScrollView contentContainerStyle={{ padding: 20 }}>
              <View className="flex-row items-center mb-3">
                <Chip tone={tone} label={assessment.label} />
                <View className="flex-1" />
                <Text
                  className={`text-2xl font-bold`}
                  style={{ color: TONE_HEX[tone], fontFamily: 'Helvetica' }}
                >
                  {assessment.score}
                </Text>
                <Text className="text-muted text-xs ml-1 mb-1 self-end">/100</Text>
                <Pressable
                  onPress={() => setOpen(false)}
                  hitSlop={10}
                  className="ml-3 p-1 active:opacity-70"
                >
                  <Icon name="check" size={16} color={TONE_HEX.neutral} />
                </Pressable>
              </View>

              <Text className="text-text text-sm leading-5 mb-3">
                {assessment.rationale}
              </Text>

              {/* Component breakdown */}
              <View className="bg-bg/60 rounded-xl p-3 mb-3">
                <Row
                  label="Day 1 from-drug"
                  value={`${Math.round(assessment.components.day1FromFraction * 100)}% of target`}
                />
                <Row
                  label="Day 1 to-drug"
                  value={`${Math.round(assessment.components.day1ToFraction * 100)}% of target`}
                />
                <Row
                  label="Co-prescribed"
                  value={`${assessment.components.overlapDays} day${assessment.components.overlapDays === 1 ? '' : 's'}`}
                />
                <Row
                  label="Mechanism multiplier"
                  value={`${assessment.components.mechanismMultiplier.toFixed(2)}×`}
                  isLast
                />
              </View>

              {assessment.flags.length > 0 && (
                <>
                  <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-2">
                    Mechanism stacking
                  </Text>
                  <View className="flex-row flex-wrap mb-3" style={{ gap: 6 }}>
                    {assessment.flags.map((f) => (
                      <Chip
                        key={f}
                        tone="warning"
                        size="sm"
                        label={flagLabel(f)}
                      />
                    ))}
                  </View>
                </>
              )}

              <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                What to do
              </Text>
              <Text className="text-text text-xs leading-4 mb-1">
                {assessment.tier === 'low' &&
                  'Standard cross-taper is appropriate. No additional caution required beyond the existing schedule.'}
                {assessment.tier === 'moderate' &&
                  'Reasonable cross-taper. Counsel patient for the standard side-effect window of both drugs during the overlap.'}
                {assessment.tier === 'high' &&
                  'Consider Conservative mode (toggle below the schedule) to reduce Day 1 from-drug by 25%, or extend the taper. Counsel for serotonin / EPS / sedation additive effects depending on flags.'}
                {assessment.tier === 'severe' &&
                  'Strongly consider Conservative mode and / or extending the taper. Verify against the primary source (Maudsley table 3.7) and document rationale if proceeding as scheduled.'}
              </Text>

              <Text className="text-muted text-eyebrow leading-4 mt-3">
                Score = (Day-1 doses × duration weight) × mechanism stacking. Maudsley 15th ch.3 explicitly allows overlap during cross-taper; this chip is a UX nudge, not a contraindication.
              </Text>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </>
  );
}

function Row({
  label,
  value,
  isLast,
}: {
  label: string;
  value: string;
  isLast?: boolean;
}) {
  return (
    <View
      className={`flex-row justify-between py-1 ${!isLast ? 'border-b border-border' : ''}`}
    >
      <Text className="text-muted text-xs">{label}</Text>
      <Text className="text-text text-xs font-mono">{value}</Text>
    </View>
  );
}
