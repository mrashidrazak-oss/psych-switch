// Compact schedule card — designed for use in the busy clinic summary view.
//
// Shows every schedule step as a row in a lightweight table:
//   Day | From dose | To dose | inline note (when present) | citation chip
//
// No Gantt bars, no PK simulation — just the prescribed doses at a glance.
// The component is intentionally dense; every pixel counts when you have
// a queue outside.
//
// Per-step citation chips (added in v0.3.3) point at the source backing
// each dose change. If a step doesn't carry its own citations, we fall
// back to the rule-level citation array's first entry — most reviewed
// rules come from a single Maudsley table so this is the common case.
import { Text, View } from 'react-native';
import type { Drug, ScheduleStep } from '../engine/types';
import { Chip } from './Chip';
import { CitationChip } from './CitationChip';

interface Props {
  fromDrug: Drug;
  toDrug: Drug;
  schedule: ScheduleStep[];
  /** Rule-level citations used as fallback when a step has none of its own. */
  ruleCitations?: string[];
}

export function ScheduleSummaryCard({ fromDrug, toDrug, schedule, ruleCitations }: Props) {
  const fromIsLai = fromDrug.formulation === 'lai';
  const toIsLai = toDrug.formulation === 'lai';
  const fromUnit = fromIsLai ? 'mg/inj' : 'mg';
  const toUnit = toIsLai ? 'mg/inj' : 'mg';

  return (
    <View className="bg-surface border border-border rounded-2xl overflow-hidden">
      {/* Column headers */}
      <View className="flex-row bg-border/40 px-4 py-2">
        <Text className="text-muted text-xs font-semibold w-14">DAY</Text>
        <View className="flex-1 flex-row">
          <View className="flex-1 flex-row items-center">
            <View className="w-2 h-2 rounded-full bg-from mr-1.5" />
            <Text
              className="text-muted text-xs font-semibold"
              numberOfLines={1}
            >
              {fromDrug.genericName}
            </Text>
          </View>
          <View className="flex-1 flex-row items-center">
            <View className="w-2 h-2 rounded-full bg-to mr-1.5" />
            <Text
              className="text-muted text-xs font-semibold"
              numberOfLines={1}
            >
              {toDrug.genericName}
            </Text>
          </View>
        </View>
      </View>

      {/* Step rows */}
      {schedule.map((step, index) => {
        const isLast = index === schedule.length - 1;
        const fromLabel = step.fromDoseMg === 0 ? 'stop' : `${step.fromDoseMg} ${fromUnit}`;
        const toLabel = step.toDoseMg === 0 ? '—' : `${step.toDoseMg} ${toUnit}`;
        const fromStopped = step.fromDoseMg === 0;
        const toStarted = index === 0 && step.toDoseMg > 0;

        // Per-step citation: prefer the step's own array, else the rule
        // fallback. We show only ONE chip per row to keep density manageable;
        // the full citation list still lives in the Detailed view.
        const stepCite =
          (step.citations && step.citations[0]) ||
          (ruleCitations && ruleCitations[0]) ||
          null;

        return (
          <View
            key={step.day}
            className={`px-4 py-2.5 ${!isLast ? 'border-b border-border' : ''}`}
          >
            <View className="flex-row items-center">
              {/* Day */}
              <Text className="text-text text-sm font-semibold w-14">
                Day {step.day}
              </Text>
              {/* From dose */}
              <View className="flex-1">
                <Text
                  className={`text-sm font-medium ${
                    fromStopped ? 'text-muted line-through' : 'text-text'
                  }`}
                >
                  {fromLabel}
                </Text>
              </View>
              {/* To dose */}
              <View className="flex-1">
                <Text
                  className={`text-sm font-medium ${
                    toStarted ? 'text-to font-semibold' : 'text-text'
                  }`}
                >
                  {toLabel}
                </Text>
              </View>
            </View>
            {/* Inline note — truncated to 2 lines to keep it compact */}
            {step.notes ? (
              <Text
                className="text-muted text-xs mt-1 leading-4"
                numberOfLines={2}
              >
                {step.notes}
              </Text>
            ) : null}
            {/* Per-step citation chip — single small chip backing this dose
                change. Tap to see the paraphrased source quote. */}
            {stepCite && (
              <View className="flex-row mt-1.5" style={{ gap: 4 }}>
                <CitationChip citationKey={stepCite} compact />
                {step.citations && step.citations.length > 1 && (
                  <Chip
                    tone="neutral"
                    size="sm"
                    label={`+${step.citations.length - 1}`}
                  />
                )}
              </View>
            )}
          </View>
        );
      })}
    </View>
  );
}
