// Calendar view of the switch — day-by-day grid showing dose changes
// and monitoring milestones. Renders a month-style grid where each cell
// is one day; the cell shows "from→to mg" if a step occurs that day,
// and a small dot if monitoring is due.
//
// Width-first design — designed to render at common phone widths
// (350–430px) without horizontal scroll. Long durations spill onto
// multiple "weeks" (rows).
import { Text, View } from 'react-native';
import type { MonitoringPlan } from '../engine/monitoring';
import type { ScheduleStep } from '../engine/types';

const COLS = 7;

export function CalendarView({
  schedule,
  monitoring,
  totalDays,
}: {
  schedule: ScheduleStep[];
  monitoring?: MonitoringPlan;
  totalDays: number;
}) {
  const span = Math.max(totalDays, 28);
  const rows = Math.ceil(span / COLS);

  // Build per-day buckets
  const stepByDay = new Map<number, ScheduleStep>();
  for (const s of schedule) stepByDay.set(s.day, s);

  const monByDay = new Map<number, number>(); // day → count
  if (monitoring) {
    for (const e of monitoring.entries) {
      monByDay.set(e.dayOffset, (monByDay.get(e.dayOffset) ?? 0) + 1);
    }
  }

  const cells: { day: number }[] = [];
  for (let d = 0; d < rows * COLS; d++) cells.push({ day: d });

  return (
    <View className="bg-surface border border-border rounded-2xl px-3 py-3 mt-4">
      <View className="flex-row items-center mb-2">
        <Text className="text-text text-sm font-bold">Day-by-day calendar</Text>
        <Text className="text-muted text-micro ml-2">
          {schedule.length} dose changes · {monitoring?.entries.length ?? 0} monitoring
        </Text>
      </View>

      {/* Week labels */}
      <View className="flex-row mb-1">
        {Array.from({ length: COLS }).map((_, i) => (
          <View key={i} className="flex-1 items-center">
            <Text className="text-muted text-[9px] uppercase tracking-wider">
              {dayLabel(i)}
            </Text>
          </View>
        ))}
      </View>

      {/* Grid */}
      <View>
        {Array.from({ length: rows }).map((_, r) => (
          <View key={r} className="flex-row">
            {Array.from({ length: COLS }).map((__, c) => {
              const day = r * COLS + c;
              const step = stepByDay.get(day);
              const monCount = monByDay.get(day) ?? 0;
              const within = day <= span;
              const isMilestone = !!step;

              return (
                <View
                  key={c}
                  className={`flex-1 m-0.5 rounded-md py-1 px-1 ${
                    within ? 'bg-bg border border-border' : 'opacity-30'
                  } ${isMilestone ? 'border-accent/50' : ''}`}
                  style={{ minHeight: 38 }}
                >
                  <View className="flex-row items-center justify-between">
                    <Text className="text-muted text-[9px]">D{day}</Text>
                    {monCount > 0 && (
                      <View className="w-1.5 h-1.5 rounded-full bg-warning" />
                    )}
                  </View>
                  {step && (
                    <Text
                      className="text-text text-[9px] font-bold"
                      numberOfLines={1}
                    >
                      {step.fromDoseMg}→{step.toDoseMg}
                    </Text>
                  )}
                </View>
              );
            })}
          </View>
        ))}
      </View>

      {/* Legend */}
      <View className="flex-row items-center mt-2 flex-wrap">
        <View className="flex-row items-center mr-3">
          <View className="w-2 h-2 rounded border border-accent/50 mr-1" />
          <Text className="text-muted text-eyebrow">Dose change</Text>
        </View>
        <View className="flex-row items-center">
          <View className="w-1.5 h-1.5 rounded-full bg-warning mr-1" />
          <Text className="text-muted text-eyebrow">Monitoring due</Text>
        </View>
      </View>
    </View>
  );
}

function dayLabel(i: number): string {
  return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i] ?? '';
}
