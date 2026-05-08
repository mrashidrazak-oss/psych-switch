// Half-life-aware Gantt visualizer.
//
// For every day in the schedule (plus a 14-day trailing window), we
// render one row showing both drugs' EFFECTIVE LEVEL — i.e. the residual
// circulating amount predicted by a one-compartment exponential model.
// This is what the original spec called for: "Uses the half-life of each
// drug to compute realistic washout."
//
// Why effective-level rather than prescribed-dose bars: the prescribed
// schedule is already in the rule's text. The clinical insight that's
// not obvious from the schedule alone is the WASHOUT TAIL — for
// fluoxetine especially, "stop on day 4" doesn't mean the drug is gone
// on day 5. The bars make this visible at a glance.
//
// The model is intentionally crude (see engine/pkSimulation.ts header).
// Visual aid only — never use these numbers to dose patients.
import { Text, View } from 'react-native';
import { simulateSwitch } from '../engine/pkSimulation';
import type { Drug, ScheduleStep } from '../engine/types';

export function GanttChart({
  fromDrug,
  toDrug,
  schedule,
}: {
  fromDrug: Drug;
  toDrug: Drug;
  schedule: ScheduleStep[];
}) {
  const sim = simulateSwitch(schedule, fromDrug, toDrug);

  // Build a lookup so we can show the prescribed dose and notes on the
  // exact rows where a schedule step lands.
  const stepByDay = new Map<number, ScheduleStep>();
  for (const s of schedule) stepByDay.set(s.day, s);

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-4">
      {/* Legend */}
      <View className="flex-row mb-3">
        <View className="flex-row items-center mr-4">
          <View className="w-3 h-3 rounded-full bg-from mr-2" />
          <Text className="text-muted text-xs">{fromDrug.genericName}</Text>
        </View>
        <View className="flex-row items-center">
          <View className="w-3 h-3 rounded-full bg-to mr-2" />
          <Text className="text-muted text-xs">{toDrug.genericName}</Text>
        </View>
      </View>

      {/* Sub-legend explaining the bars */}
      <Text className="text-muted text-xs mb-3 leading-4">
        Bars show simulated effective level (washout reflects each drug&apos;s
        half-life). Bold rows mark prescribed-dose changes from the schedule.
      </Text>

      {sim.from.map((fromPoint, i) => {
        const toPoint = sim.to[i];
        const day = fromPoint.day;
        const step = stepByDay.get(day);
        const isStepDay = step !== undefined;
        const fromPct = clampPct(fromPoint.effectiveLevelMg / fromDrug.dosing.maxDoseMg);
        const toPct = clampPct(toPoint.effectiveLevelMg / toDrug.dosing.maxDoseMg);

        return (
          <View
            key={day}
            className={`mb-2 ${isStepDay ? 'pt-2 border-t border-border' : ''}`}
          >
            <View className="flex-row items-center mb-1">
              <Text
                className={`text-xs w-12 ${
                  isStepDay ? 'text-text font-semibold' : 'text-muted'
                }`}
              >
                Day {day}
              </Text>
              {isStepDay ? (
                <Text className="text-muted text-xs flex-1">
                  {fromDrug.formulation === 'lai' || toDrug.formulation === 'lai'
                    ? `${step!.fromDoseMg}${fromDrug.formulation === 'lai' ? ' mg/inj' : ' mg'} → ${step!.toDoseMg}${toDrug.formulation === 'lai' ? ' mg/inj' : ' mg'}`
                    : `${step!.fromDoseMg} mg → ${step!.toDoseMg} mg`}
                </Text>
              ) : null}
            </View>
            <Bar pct={fromPct} colorClass="bg-from" />
            <View className="h-1" />
            <Bar pct={toPct} colorClass="bg-to" />
            {step?.notes ? (
              <Text className="text-muted text-xs mt-1 leading-4">
                {step.notes}
              </Text>
            ) : null}
          </View>
        );
      })}
    </View>
  );
}

// Theme constants used for bar colors — avoids mixing className + style
// on the same element, which trips NativeWind 4's css-interop when
// many instances (42 days × 2 bars) mount simultaneously.
const THEME = {
  border: '#1f2933',
  from: '#60a5fa',
  to: '#34d399',
} as const;

function Bar({ pct, colorClass }: { pct: number; colorClass: string }) {
  const barColor = colorClass === 'bg-from' ? THEME.from : THEME.to;
  return (
    <View
      style={{
        height: 10,
        backgroundColor: THEME.border,
        borderRadius: 999,
        overflow: 'hidden',
      }}
    >
      <View
        style={{
          height: 10,
          backgroundColor: barColor,
          borderRadius: 999,
          width: `${pct * 100}%`,
        }}
      />
    </View>
  );
}

function clampPct(n: number) {
  if (Number.isNaN(n) || n < 0) return 0;
  if (n > 1) return 1;
  return n;
}
