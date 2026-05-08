// Lithium tapering & discontinuation guidance screen.
//
// Per Maudsley 15th edition (Bipolar disorder, pp.331–333). Stopping
// lithium without a slow hyperbolic taper carries a sevenfold increase
// in relapse risk vs the untreated disorder. This screen shows:
//   - Why slow tapering matters (with the relapse-risk numbers)
//   - The Maudsley 15 specific reduction regimen (Box 2.3)
//   - Withdrawal effects table (physical + psychological)
//   - Practical tapering principles
//   - What to do if symptoms emerge
import { Text, View } from 'react-native';
import { Banner } from '../components/Banner';
import { ScreenContainer } from '../components/ScreenContainer';
import { getLithiumTapering } from '../engine/moodStabilizerTapering';

export function LithiumTaperingScreen() {
  const data = getLithiumTapering();

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        {data.title}
      </Text>
      <Text className="text-muted text-sm mb-4">
        Slow hyperbolic taper. Maudsley 15 — Box 2.3.
      </Text>

      {/* Why this matters card */}
      <Banner
        tone="warning"
        eyebrow="Why slow tapering matters"
        body={data.rationale}
        className="mb-4"
      />

      {/* Maudsley regimen — the key clinical content */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Maudsley 15 reduction regimen (Box 2.3)
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {data.tapering.maudsleyRegimen.steps.map((step, i) => {
          const isLast = i === data.tapering.maudsleyRegimen.steps.length - 1;
          return (
            <View
              key={step.phase}
              className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="flex-row items-baseline justify-between mb-1">
                <Text className="text-text text-sm font-semibold">
                  {step.phase}
                </Text>
                <Text className="text-accent text-sm font-bold">
                  −{step.stepDoseMg} mg {step.interval}
                </Text>
              </View>
              <Text className="text-muted text-xs leading-4">{step.notes}</Text>
            </View>
          );
        })}
      </View>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Total duration
        </Text>
        <Text className="text-text text-sm leading-5">
          {data.tapering.maudsleyRegimen.totalDurationNote}
        </Text>
      </View>

      {/* Hyperbolic principle */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Hyperbolic tapering principle
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-text text-sm leading-5 mb-3">
          {data.tapering.principle}
        </Text>
        <View className="bg-bg rounded-xl px-3 py-2 mb-2">
          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
            Initial reduction
          </Text>
          <Text className="text-text text-sm">
            {data.tapering.initialReduction}
          </Text>
        </View>
        <View className="bg-bg rounded-xl px-3 py-2 mb-2">
          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
            Rapid vs gradual
          </Text>
          <Text className="text-text text-sm leading-5">
            {data.tapering.rapidVsGradual}
          </Text>
        </View>
        <View className="bg-bg rounded-xl px-3 py-2">
          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
            Final pre-stop dose
          </Text>
          <Text className="text-text text-sm leading-5">
            {data.tapering.minimumDoseBeforeStop}
          </Text>
        </View>
      </View>

      {/* Withdrawal effects */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Withdrawal effects
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs leading-4 mb-3">
          {data.withdrawalEffects.rationale}
        </Text>
        <View className="flex-row gap-3">
          <View className="flex-1 bg-bg rounded-xl px-3 py-2">
            <Text className="text-muted text-xs uppercase tracking-wider mb-1">
              Physical
            </Text>
            {data.withdrawalEffects.physical.map((sym) => (
              <Text key={sym} className="text-text text-xs leading-5">
                • {sym}
              </Text>
            ))}
          </View>
          <View className="flex-1 bg-bg rounded-xl px-3 py-2">
            <Text className="text-muted text-xs uppercase tracking-wider mb-1">
              Psychological
            </Text>
            {data.withdrawalEffects.psychological.map((sym) => (
              <Text key={sym} className="text-text text-xs leading-5">
                • {sym}
              </Text>
            ))}
          </View>
        </View>
      </View>

      {/* When to consider */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        When to consider stopping
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        {data.whenToConsiderStopping.map((item, i) => (
          <Text
            key={i}
            className={`text-text text-sm leading-5 ${i < data.whenToConsiderStopping.length - 1 ? 'mb-2' : ''}`}
          >
            • {item}
          </Text>
        ))}
      </View>

      {/* Monitoring during taper */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Monitoring during the taper
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        {data.monitoringDuringTaper.map((item, i) => (
          <Text
            key={i}
            className={`text-text text-sm leading-5 ${i < data.monitoringDuringTaper.length - 1 ? 'mb-2' : ''}`}
          >
            • {item}
          </Text>
        ))}
      </View>

      {/* If symptoms emerge */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        If symptoms emerge
      </Text>
      <Banner tone="warning" hideEyebrow className="mb-4">
        {data.ifSymptomsEmerge.map((item, i) => (
          <Text
            key={i}
            className={`text-text text-sm leading-5 ${i < data.ifSymptomsEmerge.length - 1 ? 'mb-2' : ''}`}
          >
            • {item}
          </Text>
        ))}
      </Banner>

      {/* Never do this */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Never do this
      </Text>
      <Banner tone="danger" hideEyebrow className="mb-4">
        {data.neverDoThis.map((item, i) => (
          <Text
            key={i}
            className={`text-text text-sm leading-5 ${i < data.neverDoThis.length - 1 ? 'mb-2' : ''}`}
          >
            ✕ {item}
          </Text>
        ))}
      </Banner>

      {/* Other mood stabilizers */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Valproate · Lamotrigine · Carbamazepine
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-text text-sm leading-5">
          {data.otherMoodStabilizers}
        </Text>
      </View>

      {/* Citations */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {data.citations.map((c, i) => (
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
