// Clozapine titration display. Per Maudsley 15th edition, the schedule
// depends on sex × smoker status (driven by CYP1A2 activity). Two toggles:
//   - Sex (Female / Male)
//   - Smoker (Smoker / Non-smoker)
// Each combination yields a different 20-day schedule with a different
// maintenance target (225 / 250 / 300 / 375 mg/day).
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { Banner } from '../components/Banner';
import { ScreenContainer } from '../components/ScreenContainer';
import { getTitration, type TitrationSex } from '../engine/clozapine';

export function ClozapineInitiationScreen() {
  const [sex, setSex] = useState<TitrationSex>('female');
  const [smoker, setSmoker] = useState<boolean>(false);
  const protocol = getTitration({ sex, smoker });

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        Clozapine titration
      </Text>
      <Text className="text-muted text-sm mb-4">
        Maudsley 15th edition — schedule depends on sex × smoking status
        (CYP1A2 pharmacokinetics).
      </Text>

      {/* Variant toggles */}
      <View className="mb-4">
        <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
          Patient sex
        </Text>
        <View className="flex-row bg-surface border border-border rounded-2xl p-1 mb-3">
          <SegTab label="Female" active={sex === 'female'} onPress={() => setSex('female')} />
          <SegTab label="Male" active={sex === 'male'} onPress={() => setSex('male')} />
        </View>
        <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
          Smoking status
        </Text>
        <View className="flex-row bg-surface border border-border rounded-2xl p-1">
          <SegTab label="Non-smoker" active={!smoker} onPress={() => setSmoker(false)} />
          <SegTab label="Smoker" active={smoker} onPress={() => setSmoker(true)} />
        </View>
      </View>

      {/* Target dose summary */}
      <Banner tone="info" hideEyebrow className="mb-4">
        <View className="flex-row items-baseline justify-between mb-1">
          <Text className="text-text text-base font-semibold">
            Target maintenance
          </Text>
          <Text className="text-accent text-2xl font-bold">
            {protocol.targetDoseMg} mg/day
          </Text>
        </View>
        <Text className="text-muted text-xs">
          {protocol.totalDays}-day twice-daily titration. Reached on day{' '}
          {protocol.steps[protocol.steps.length - 1].day}.
        </Text>
      </Banner>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Why this schedule
        </Text>
        <Text className="text-text text-sm leading-5">{protocol.rationale}</Text>
      </View>

      {/* Schedule */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Daily schedule
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row px-4 py-2 bg-bg/40 border-b border-border">
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-12">
            Day
          </Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-16 text-right">
            AM (mg)
          </Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-16 text-right">
            PM (mg)
          </Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-16 text-right">
            Total
          </Text>
        </View>
        {protocol.steps.map((step, i) => {
          const isLast = i === protocol.steps.length - 1;
          const isTargetReached = step.totalMg === protocol.targetDoseMg;
          return (
            <View
              key={step.day}
              className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''} ${isTargetReached ? 'bg-accent/10' : ''}`}
            >
              <View className="flex-row items-center">
                <Text className="text-text text-sm font-semibold w-12">
                  {step.day}
                </Text>
                <Text className="text-text text-sm w-16 text-right tabular-nums">
                  {step.morningMg === 0 ? '—' : step.morningMg}
                </Text>
                <Text className="text-text text-sm w-16 text-right tabular-nums">
                  {step.eveningMg}
                </Text>
                <Text
                  className={`text-sm w-16 text-right font-semibold tabular-nums ${isTargetReached ? 'text-accent' : 'text-text'}`}
                >
                  {step.totalMg}
                </Text>
              </View>
              {step.notes ? (
                <Text className="text-muted text-xs leading-4 mt-1">
                  {step.notes}
                </Text>
              ) : null}
            </View>
          );
        })}
      </View>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Beyond day {protocol.totalDays}
        </Text>
        <Text className="text-text text-sm leading-5">
          {protocol.postTitrationGuidance}
        </Text>
      </View>

      <View className="bg-surface border-2 border-danger rounded-2xl px-4 py-3 mb-4">
        <Text className="text-danger text-xs uppercase tracking-widest mb-1">
          Missed-dose rule
        </Text>
        <Text className="text-text text-sm leading-5">
          {protocol.missedDoseRule}
        </Text>
      </View>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {protocol.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {protocol.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function SegTab({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      className={`flex-1 py-2 rounded-xl active:opacity-80 ${active ? 'bg-accent' : ''}`}
    >
      <Text
        className={`text-center text-sm font-semibold ${active ? 'text-white' : 'text-muted'}`}
      >
        {label}
      </Text>
    </Pressable>
  );
}
