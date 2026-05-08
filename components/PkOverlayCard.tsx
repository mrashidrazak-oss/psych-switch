// Pharmacokinetic overlay — visualizes the *effective* drug level the
// patient experiences, not just what's prescribed.
//
// Why this matters: a venlafaxine taper from 150 → 0 over 14 days drops
// the prescribed dose to zero on Day 14, but the effective plasma level
// is back to baseline within 2–3 days because t½ ≈ 5h. A fluoxetine
// taper from 40 → 0 over 14 days has prescribed-zero on Day 14 but the
// effective level is still ~40% of starting on Day 28 (t½ ≈ 96 h, plus
// long-acting metabolite). This card shows that visually so the
// clinician can intuit the difference.
//
// Built on engine/pkSimulation.ts (one-compartment exponential model).
// DELIBERATELY simple — visualization-only, never use these numbers to
// dose patients.
//
// Sizing notes: react-native-svg in Expo Go does not always resolve
// width="100%" reliably. We measure the parent View's onLayout to get
// an explicit pixel width, then size the SVG accordingly. The viewBox
// matches the actual width × intrinsic chart height, no aspect-ratio
// distortion.
import { Fragment, useMemo, useState } from 'react';
import { Text, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Line, Path, Text as SvgText } from 'react-native-svg';
import {
  effectiveHalfLifeHours,
  simulateSwitch,
  type DailyPoint,
} from '../engine/pkSimulation';
import type { Drug, ScheduleStep } from '../engine/types';
import { Icon } from './Icon';

const FROM_COLOR = '#60a5fa'; // text-from
const TO_COLOR = '#34d399';   // text-to
const GRID_COLOR = '#1f2933';
const TEXT_COLOR = '#8b949e';

const CHART_HEIGHT = 200;
const PADDING = { top: 10, right: 10, bottom: 28, left: 36 };

export function PkOverlayCard({
  schedule,
  fromDrug,
  toDrug,
}: {
  schedule: ScheduleStep[];
  fromDrug: Drug;
  toDrug: Drug;
}) {
  const sim = useMemo(
    () => simulateSwitch(schedule, fromDrug, toDrug, { trailingDays: 14 }),
    [schedule, fromDrug, toDrug],
  );

  if (sim.from.length === 0) return null;

  // Y-axis normalized to actual values used in this schedule, NOT the
  // drug's clinical max. Otherwise a 5 mg taper on a drug with max 30
  // would render as a sliver at the bottom of the chart.
  const fromMax = Math.max(
    ...sim.from.map((p) => Math.max(p.prescribedDoseMg, p.effectiveLevelMg)),
    1,
  ) * 1.1; // 10% headroom
  const toMax = Math.max(
    ...sim.to.map((p) => Math.max(p.prescribedDoseMg, p.effectiveLevelMg)),
    1,
  ) * 1.1;

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-4 mt-4">
      <View className="flex-row items-center mb-1">
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="activity" size={16} color="#3b82f6" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Pharmacokinetic overlay</Text>
          <Text className="text-muted text-micro">
            Predicted effective level — visualization only, not for dosing
          </Text>
        </View>
      </View>

      <Text className="text-muted text-xs leading-4 my-2">
        Solid: simulated effective level. Dashed: prescribed dose.
        Difference reveals the half-life tail.
      </Text>

      <PkChart
        from={sim.from}
        to={sim.to}
        fromMax={fromMax}
        toMax={toMax}
        totalDays={sim.totalDays}
      />

      <View className="flex-row items-center mt-3 flex-wrap" style={{ gap: 8 }}>
        <Legend color={FROM_COLOR} label={`${fromDrug.genericName} · t½ ${Math.round(effectiveHalfLifeHours(fromDrug))} h`} />
        <Legend color={TO_COLOR}   label={`${toDrug.genericName} · t½ ${Math.round(effectiveHalfLifeHours(toDrug))} h`} />
      </View>

      <PkInsight from={sim.from} to={sim.to} fromDrug={fromDrug} toDrug={toDrug} />
    </View>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <View className="flex-row items-center">
      <View style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: color, marginRight: 6 }} />
      <Text className="text-muted text-micro">{label}</Text>
    </View>
  );
}

// ── Chart ────────────────────────────────────────────────────────────────────

function PkChart({
  from,
  to,
  fromMax,
  toMax,
  totalDays,
}: {
  from: DailyPoint[];
  to: DailyPoint[];
  fromMax: number;
  toMax: number;
  totalDays: number;
}) {
  const [width, setWidth] = useState(0);
  const onLayout = (e: LayoutChangeEvent) => {
    const w = e.nativeEvent.layout.width;
    if (w !== width) setWidth(w);
  };

  // Render a placeholder until we know our width — keeps the layout
  // height stable so the rest of the screen doesn't reflow.
  if (width === 0) {
    return (
      <View onLayout={onLayout} style={{ width: '100%', height: CHART_HEIGHT }} />
    );
  }

  const innerW = Math.max(50, width - PADDING.left - PADDING.right);
  const innerH = CHART_HEIGHT - PADDING.top - PADDING.bottom;

  const dayToX = (day: number) =>
    PADDING.left + ((day - 1) / Math.max(1, totalDays - 1)) * innerW;
  const valueToY = (v: number, max: number) =>
    PADDING.top + innerH - (v / Math.max(1, max)) * innerH;

  const makePath = (
    pts: DailyPoint[],
    pickValue: (p: DailyPoint) => number,
    max: number,
  ) => {
    if (pts.length === 0) return '';
    return pts
      .map((p, i) =>
        `${i === 0 ? 'M' : 'L'} ${dayToX(p.day).toFixed(1)} ${valueToY(pickValue(p), max).toFixed(1)}`,
      )
      .join(' ');
  };

  const fromPrescribed = makePath(from, (p) => p.prescribedDoseMg, fromMax);
  const fromEffective  = makePath(from, (p) => p.effectiveLevelMg, fromMax);
  const toPrescribed   = makePath(to, (p) => p.prescribedDoseMg, toMax);
  const toEffective    = makePath(to, (p) => p.effectiveLevelMg, toMax);

  // Y-axis ticks at 0, 50%, 100%
  const yTicks = [0, 0.5, 1];

  // X-axis: 4 evenly spaced ticks that always include first and last day.
  // Keeps spacing predictable and stops the "last two ticks crash into
  // each other" problem the prior heuristic produced on long schedules.
  const xTicks = (() => {
    if (totalDays <= 4) {
      return Array.from({ length: totalDays }, (_, i) => i + 1);
    }
    const a = 1;
    const d = totalDays;
    const b = Math.round(1 + (totalDays - 1) * 0.33);
    const c = Math.round(1 + (totalDays - 1) * 0.67);
    return Array.from(new Set([a, b, c, d])).sort((x, y) => x - y);
  })();
  // Anchor first label to the left edge, last to the right edge, the
  // rest centered. Prevents "D1" hanging off the chart and the final
  // "D42" colliding with the right padding.
  const anchorFor = (i: number) =>
    i === 0 ? ('start' as const) : i === xTicks.length - 1 ? ('end' as const) : ('middle' as const);

  return (
    <View onLayout={onLayout} style={{ width: '100%' }}>
      <Svg width={width} height={CHART_HEIGHT}>
        {/* Background grid */}
        {yTicks.map((t, i) => {
          const y = PADDING.top + innerH - t * innerH;
          return (
            <Line
              key={`yg-${i}`}
              x1={PADDING.left}
              x2={width - PADDING.right}
              y1={y}
              y2={y}
              stroke={GRID_COLOR}
              strokeWidth={1}
              strokeDasharray={t === 0 ? undefined : '2,3'}
            />
          );
        })}

        {/* Y-axis labels — % of max */}
        {yTicks.map((t, i) => (
          <SvgText
            key={`yl-${i}`}
            x={6}
            y={PADDING.top + innerH - t * innerH + 4}
            fontSize="11"
            fill={TEXT_COLOR}
            fontFamily="Helvetica"
          >
            {`${Math.round(t * 100)}%`}
          </SvgText>
        ))}

        {/* X-axis tick marks + labels — first anchored start, last
            anchored end, middle centered. Tick mark is a short stub
            on the baseline so the eye lines the label up with the
            correct day. */}
        {xTicks.map((d, i) => {
          const x = dayToX(d);
          const yBase = PADDING.top + innerH;
          // Pull the first/last labels in by a few px so they don't
          // overshoot the chart bounds visually.
          const labelX =
            i === 0
              ? x - 1
              : i === xTicks.length - 1
                ? x + 1
                : x;
          return (
            <Fragment key={`xl-${i}`}>
              <Line
                x1={x}
                x2={x}
                y1={yBase}
                y2={yBase + 4}
                stroke={GRID_COLOR}
                strokeWidth={1}
              />
              <SvgText
                x={labelX}
                y={yBase + 16}
                fontSize="11"
                fill={TEXT_COLOR}
                textAnchor={anchorFor(i)}
                fontFamily="Helvetica"
              >
                D{d}
              </SvgText>
            </Fragment>
          );
        })}

        {/* From-drug — prescribed (dashed) + effective (solid) */}
        <Path d={fromPrescribed} stroke={FROM_COLOR} strokeWidth={1.5} strokeDasharray="4,3" fill="none" opacity={0.55} />
        <Path d={fromEffective} stroke={FROM_COLOR} strokeWidth={2.5} fill="none" />

        {/* To-drug — prescribed (dashed) + effective (solid) */}
        <Path d={toPrescribed} stroke={TO_COLOR} strokeWidth={1.5} strokeDasharray="4,3" fill="none" opacity={0.55} />
        <Path d={toEffective} stroke={TO_COLOR} strokeWidth={2.5} fill="none" />
      </Svg>
    </View>
  );
}

// Compute one short, useful clinical insight from the simulation.
function PkInsight({
  from,
  to,
  fromDrug,
  toDrug,
}: {
  from: DailyPoint[];
  to: DailyPoint[];
  fromDrug: Drug;
  toDrug: Drug;
}) {
  if (from.length === 0) return null;

  const lastFrom = from[from.length - 1];
  const startFrom = from[0].effectiveLevelMg;
  const fromTailPct = startFrom > 0 ? (lastFrom.effectiveLevelMg / startFrom) * 100 : 0;

  const day50 = from.find((p) => startFrom > 0 && p.effectiveLevelMg <= startFrom * 0.5)?.day;

  const lastToLevel = to[to.length - 1]?.effectiveLevelMg ?? 0;
  const dayTo90 = lastToLevel > 0
    ? to.find((p) => p.effectiveLevelMg >= lastToLevel * 0.9)?.day
    : undefined;

  return (
    <View className="bg-bg/50 rounded-lg px-3 py-2 mt-3">
      <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
        Clinical insight
      </Text>
      <View>
        {day50 != null && (
          <Text className="text-text text-xs leading-4 mb-0.5">
            • {fromDrug.genericName} effective level reaches 50% by{' '}
            <Text className="font-semibold">D{day50}</Text>
          </Text>
        )}
        {fromTailPct > 5 && (
          <Text className="text-text text-xs leading-4 mb-0.5">
            • {fromTailPct.toFixed(0)}% tail still present at end of schedule
            {fromTailPct > 20 ? ' — long washout, consider extending overlap' : ''}
          </Text>
        )}
        {dayTo90 != null && (
          <Text className="text-text text-xs leading-4">
            • {toDrug.genericName} reaches 90% steady-state by{' '}
            <Text className="font-semibold">D{dayTo90}</Text>
          </Text>
        )}
      </View>
    </View>
  );
}
