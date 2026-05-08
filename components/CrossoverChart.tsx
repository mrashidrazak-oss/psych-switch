// Crossover chart — visualizes the cross-taper as two stacked area
// regions. From-drug fades down on the left; to-drug rises on the
// right. The clinician can *see* the cross-taper concept rather than
// reconstruct it from a table of doses.
//
// Heights are normalized to each drug's max-in-this-schedule (not the
// drug's clinical max), so a 5 mg taper and a 30 mg taper read with the
// same visual weight. This is a *shape* visualization, not a dose
// visualization — the schedule rows underneath carry the absolute
// numbers.
//
// Width: measured via onLayout for explicit pixel sizing (react-native-svg
// doesn't always resolve "100%" correctly in Expo Go).
import { useState } from 'react';
import { Text, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Defs, LinearGradient, Path, Stop, Line, Text as SvgText } from 'react-native-svg';
import type { ScheduleStep } from '../engine/types';

const FROM_COLOR = '#60a5fa';
const TO_COLOR = '#34d399';
const TEXT_COLOR = '#8b949e';
const GRID = '#1f2933';

const HEIGHT = 160;
const PAD = { top: 8, right: 8, bottom: 24, left: 8 };

export function CrossoverChart({
  schedule,
  totalDays,
}: {
  schedule: ScheduleStep[];
  totalDays?: number;
}) {
  const [width, setWidth] = useState(0);

  if (schedule.length < 2) return null;

  const lastDay = schedule[schedule.length - 1].day;
  const span = totalDays ?? lastDay;

  const fromMaxValue = Math.max(...schedule.map((s) => s.fromDoseMg), 1);
  const toMaxValue   = Math.max(...schedule.map((s) => s.toDoseMg), 1);

  const onLayout = (e: LayoutChangeEvent) => {
    const w = e.nativeEvent.layout.width;
    if (w !== width) setWidth(w);
  };

  return (
    <View className="bg-surface border border-border rounded-2xl px-3 py-3 mt-4">
      <View className="flex-row items-center mb-2">
        <Text className="text-text text-sm font-bold">Crossover shape</Text>
        <Text className="text-muted text-micro ml-2">
          relative dose curves over {span} days
        </Text>
      </View>

      <View onLayout={onLayout} style={{ width: '100%', height: HEIGHT }}>
        {width > 0 && (
          <CrossoverSvg
            width={width}
            height={HEIGHT}
            schedule={schedule}
            span={span}
            fromMaxValue={fromMaxValue}
            toMaxValue={toMaxValue}
          />
        )}
      </View>

      {/* Legend */}
      <View className="flex-row items-center mt-2" style={{ gap: 12 }}>
        <View className="flex-row items-center">
          <View style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: FROM_COLOR, marginRight: 6 }} />
          <Text className="text-muted text-micro">From drug (taper)</Text>
        </View>
        <View className="flex-row items-center">
          <View style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: TO_COLOR, marginRight: 6 }} />
          <Text className="text-muted text-micro">To drug (titration)</Text>
        </View>
      </View>
    </View>
  );
}

function CrossoverSvg({
  width,
  height,
  schedule,
  span,
  fromMaxValue,
  toMaxValue,
}: {
  width: number;
  height: number;
  schedule: ScheduleStep[];
  span: number;
  fromMaxValue: number;
  toMaxValue: number;
}) {
  const innerW = Math.max(50, width - PAD.left - PAD.right);
  const innerH = height - PAD.top - PAD.bottom;

  const dayToX = (day: number) =>
    PAD.left + ((day - 1) / Math.max(1, span - 1)) * innerW;
  const fromValueToY = (v: number) => PAD.top + innerH - (v / fromMaxValue) * innerH;
  const toValueToY   = (v: number) => PAD.top + innerH - (v / toMaxValue) * innerH;

  const buildArea = (
    valueOf: (s: ScheduleStep) => number,
    yOf: (v: number) => number,
  ) => {
    const x0 = dayToX(schedule[0].day);
    const xN = dayToX(schedule[schedule.length - 1].day);
    return (
      `M ${x0.toFixed(1)} ${(PAD.top + innerH).toFixed(1)} ` +
      schedule
        .map((s) => `L ${dayToX(s.day).toFixed(1)} ${yOf(valueOf(s)).toFixed(1)}`)
        .join(' ') +
      ` L ${xN.toFixed(1)} ${(PAD.top + innerH).toFixed(1)} Z`
    );
  };

  const fromArea = buildArea((s) => s.fromDoseMg, fromValueToY);
  const toArea   = buildArea((s) => s.toDoseMg, toValueToY);

  // X tick labels — start, mid, end
  const xTicks = [
    schedule[0].day,
    schedule[Math.floor(schedule.length / 2)].day,
    schedule[schedule.length - 1].day,
  ];

  return (
    <Svg width={width} height={height}>
      <Defs>
        <LinearGradient id="cxFromGrad" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor={FROM_COLOR} stopOpacity={0.55} />
          <Stop offset="100%" stopColor={FROM_COLOR} stopOpacity={0.08} />
        </LinearGradient>
        <LinearGradient id="cxToGrad" x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0%" stopColor={TO_COLOR} stopOpacity={0.55} />
          <Stop offset="100%" stopColor={TO_COLOR} stopOpacity={0.08} />
        </LinearGradient>
      </Defs>

      {/* Baseline */}
      <Line
        x1={PAD.left}
        x2={width - PAD.right}
        y1={PAD.top + innerH}
        y2={PAD.top + innerH}
        stroke={GRID}
        strokeWidth={1}
      />

      {/* Areas */}
      <Path d={fromArea} fill="url(#cxFromGrad)" stroke={FROM_COLOR} strokeWidth={2} />
      <Path d={toArea}   fill="url(#cxToGrad)"   stroke={TO_COLOR}   strokeWidth={2} />

      {/* X tick labels */}
      {xTicks.map((d, i) => (
        <SvgText
          key={`xt-${i}`}
          x={dayToX(d)}
          y={height - 8}
          fontSize="11"
          fill={TEXT_COLOR}
          textAnchor={i === 0 ? 'start' : i === xTicks.length - 1 ? 'end' : 'middle'}
          fontFamily="Helvetica"
        >
          D{d}
        </SvgText>
      ))}
    </Svg>
  );
}
