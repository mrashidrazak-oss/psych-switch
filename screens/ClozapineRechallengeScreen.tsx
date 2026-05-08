// Clozapine re-challenge / interruption-restart wizard.
//
// User enters how long the patient has been off clozapine (days + hours).
// The engine looks up the appropriate restart tier and returns the correct
// strategy: continue at dose / halve and retitrate / restart from 25 mg /
// full re-initiation from 12.5 mg.
import { useState } from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { Banner } from '../components/Banner';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  classifyInterruption,
  getRechallengeRules,
} from '../engine/clozapine';
import type { RechallengeTier } from '../engine/clozapine';

const SEVERITY_STRIPE = {
  info: 'bg-accent',
  warning: 'bg-warning',
  danger: 'bg-danger',
} as const;

const SEVERITY_BADGE = {
  info: 'text-accent',
  warning: 'text-warning',
  danger: 'text-danger',
} as const;

export function ClozapineRechallengeScreen() {
  const [days, setDays] = useState(0);
  const [hours, setHours] = useState(0);
  const [result, setResult] = useState<RechallengeTier | null>(null);
  const rules = getRechallengeRules();

  const totalHours = days * 24 + hours;

  const handleClassify = () => {
    setResult(classifyInterruption({ days, hours }));
  };

  const resetResult = () => setResult(null);

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        Interruption restart
      </Text>
      <Text className="text-muted text-sm mb-6">
        How long has the patient been without clozapine? The correct restart
        strategy depends entirely on the gap duration.
      </Text>

      {/* Duration selector */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-widest mb-3">
          Time since last dose
        </Text>
        <DurationRow
          label="Days"
          value={days}
          onDecrement={() => { setDays(Math.max(0, days - 1)); resetResult(); }}
          onIncrement={() => { setDays(days + 1); resetResult(); }}
        />
        <View className="h-px bg-border my-3" />
        <DurationRow
          label="Hours"
          value={hours}
          onDecrement={() => { setHours(Math.max(0, hours - 1)); resetResult(); }}
          onIncrement={() => { setHours(Math.min(23, hours + 1)); resetResult(); }}
        />
        {totalHours > 0 && (
          <Text className="text-muted text-xs mt-3">
            Total gap: {days > 0 ? `${days}d ` : ''}{hours > 0 ? `${hours}h` : ''}
            {' '}({totalHours} hours)
          </Text>
        )}
      </View>

      {/* Classify button */}
      <TouchableOpacity
        onPress={handleClassify}
        disabled={totalHours === 0}
        className={`rounded-2xl py-4 mb-6 ${totalHours === 0 ? 'bg-border' : 'bg-accent active:opacity-80'}`}
        activeOpacity={0.8}
      >
        <Text className={`text-center text-base font-semibold ${totalHours === 0 ? 'text-muted' : 'text-white'}`}>
          Get restart guidance
        </Text>
      </TouchableOpacity>

      {/* Result */}
      {result && (
        <>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
            <View className="flex-row">
              <View className={`w-2 ${SEVERITY_STRIPE[result.severity]}`} />
              <View className="flex-1 px-4 py-4">
                <Text
                  className={`text-xs uppercase tracking-widest mb-1 font-semibold ${SEVERITY_BADGE[result.severity]}`}
                >
                  {result.severity} — gap {result.label}
                </Text>
                <Text className="text-text text-base font-bold mb-2">
                  {result.heading}
                </Text>
                <Text className="text-muted text-sm leading-5 mb-3">
                  {result.guidance}
                </Text>

                <View className="bg-bg rounded-xl px-3 py-3 mb-3">
                  <Text className="text-muted text-xs uppercase tracking-wider mb-1">
                    Restart instruction
                  </Text>
                  <Text className="text-text text-sm leading-5">
                    {result.restartInstruction}
                  </Text>
                </View>

                <View className="bg-bg rounded-xl px-3 py-3 mb-3">
                  <Text className="text-muted text-xs uppercase tracking-wider mb-1">
                    Monitoring
                  </Text>
                  <Text className="text-text text-sm leading-5">
                    {result.monitoringNote}
                  </Text>
                </View>

                {result.warningSignsToWatch.length > 0 && (
                  <View className="bg-bg rounded-xl px-3 py-3">
                    <Text className="text-muted text-xs uppercase tracking-wider mb-1">
                      Watch for
                    </Text>
                    {result.warningSignsToWatch.map((w) => (
                      <Text key={w} className="text-text text-sm">
                        • {w}
                      </Text>
                    ))}
                  </View>
                )}
              </View>
            </View>
          </View>

          {result.retitrationRequired && (
            <Banner
              tone="danger"
              variant="outline"
              eyebrow="Retitration required"
              body="Use the Titration schedule in this app for the step-by-step inpatient protocol. Do NOT restart at the previous maintenance dose."
              className="mb-4"
            />
          )}
        </>
      )}

      {/* Absolute contraindications */}
      <Text className="text-muted text-xs uppercase tracking-widest mt-4 mb-2">
        Absolute contraindications to rechallenge
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        {rules.absoluteContraindications.map((c, i) => (
          <Text
            key={c}
            className={`text-text text-sm leading-5 ${i < rules.absoluteContraindications.length - 1 ? 'mb-2' : ''}`}
          >
            • {c}
          </Text>
        ))}
      </View>

      {/* Citations */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {rules.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {rules.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function DurationRow({
  label,
  value,
  onDecrement,
  onIncrement,
}: {
  label: string;
  value: number;
  onDecrement: () => void;
  onIncrement: () => void;
}) {
  return (
    <View className="flex-row items-center">
      <Text className="text-text text-sm font-semibold flex-1">{label}</Text>
      <TouchableOpacity
        onPress={onDecrement}
        disabled={value === 0}
        className={`w-10 h-10 rounded-full items-center justify-center ${
          value === 0 ? 'bg-border' : 'bg-accent active:opacity-80'
        }`}
        activeOpacity={0.8}
      >
        <Text
          className={`text-xl font-bold leading-none ${value === 0 ? 'text-muted' : 'text-white'}`}
        >
          −
        </Text>
      </TouchableOpacity>
      <Text className="text-text text-lg font-semibold w-12 text-center">
        {value}
      </Text>
      <TouchableOpacity
        onPress={onIncrement}
        className="w-10 h-10 rounded-full bg-accent items-center justify-center active:opacity-80"
        activeOpacity={0.8}
      >
        <Text className="text-white text-xl font-bold leading-none">+</Text>
      </TouchableOpacity>
    </View>
  );
}
