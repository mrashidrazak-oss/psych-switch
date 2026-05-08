// Receptor-occupancy curve — explains why the *last* 25% of an SSRI
// taper feels harder than the first 75%.
//
// Educational: the dose-response curve for SSRI / D2 receptor occupancy
// is sigmoidal. Cutting fluoxetine 40 → 20 takes you from ~85% to ~75%
// occupancy (clinician thinks "easy halving"); cutting 5 → 2.5 takes
// you from ~50% to ~30% (huge functional drop, withdrawal experienced).
//
// Source for the shape: Sørensen A. et al. "Antidepressant withdrawal:
// hyperbolic dose tapering". (Horowitz & Taylor 2019, Lancet Psychiatry.)
//
// We deliberately do NOT bind this card to a specific drug's PK — it's
// a teaching aid that adjacent drug-class switches can reuse.
import { useState } from 'react';
import { Text, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Circle, Line, Path, Text as SvgText } from 'react-native-svg';
import type { Drug } from '../engine/types';
import { Icon } from './Icon';

const HEIGHT = 170;
const PAD = { top: 14, right: 14, bottom: 24, left: 36 };

// Drug classes that show the sigmoidal occupancy pattern relevant to
// hyperbolic-taper reasoning. We match on substring so e.g. "SGA (D2
// partial agonist)" doesn't trigger but "SSRI", "SNRI", "NaSSA",
// "Tricyclic" and "modulator" (vortioxetine) do.
const HYPERBOLIC_PATTERNS = [
  'SSRI',
  'SNRI',
  'NaSSA',
  'Tricyclic',
  'modulator',
  'SMS',
];

export function ReceptorOccupancyCard({
  drug,
  startDoseMg,
}: {
  drug: Drug;
  startDoseMg: number;
}) {
  const [width, setWidth] = useState(0);
  const onLayout = (e: LayoutChangeEvent) => {
    const w = e.nativeEvent.layout.width;
    if (w !== width) setWidth(w);
  };

  const isHyperbolic = HYPERBOLIC_PATTERNS.some((c) => drug.drugClass.includes(c));
  if (!isHyperbolic) return null;
  if (startDoseMg <= 0) return null;

  // Sigmoid model: occupancy = dose / (dose + K), where K is the dose
  // at 50% occupancy. We assume K ≈ 25% of typical target dose — this
  // matches the empirical SSRI curves in Horowitz 2019.
  const target = drug.dosing.typicalTargetRangeMg[0];
  const K = target * 0.25;
  const occupancy = (dose: number) => dose / (dose + K);

  const occStart = occupancy(startDoseMg);
  const occHalf = occupancy(startDoseMg * 0.5);
  const occQuarter = occupancy(startDoseMg * 0.25);

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-4 mt-4">
      <View className="flex-row items-center mb-2">
        <View className="w-9 h-9 rounded-xl bg-from/15 border border-from/30 items-center justify-center mr-3">
          <Icon name="activity" size={16} color="#60a5fa" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">
            Why the last 25% feels harder
          </Text>
          <Text className="text-muted text-micro">
            Receptor occupancy vs dose · {drug.genericName}
          </Text>
        </View>
      </View>

      <View onLayout={onLayout} style={{ width: '100%', height: HEIGHT }}>
        {width > 0 && (
          <OccupancySvg
            width={width}
            height={HEIGHT}
            startDoseMg={startDoseMg}
            occupancy={occupancy}
          />
        )}
      </View>

      <View className="mt-3">
        <Row label={`${drug.genericName} ${formatMg(startDoseMg)} mg`} occ={occStart} dot="#60a5fa" />
        <Row label={`Half dose (${formatMg(startDoseMg * 0.5)} mg)`} occ={occHalf} dot="#f59e0b" />
        <Row label={`Quarter dose (${formatMg(startDoseMg * 0.25)} mg)`} occ={occQuarter} dot="#ef4444" />
      </View>

      <Text className="text-muted text-micro leading-4 mt-3">
        Cutting full → half loses only{' '}
        <Text className="text-text">{((occStart - occHalf) * 100).toFixed(0)}%</Text>{' '}
        receptor occupancy. Cutting half → quarter loses{' '}
        <Text className="text-text font-bold">{((occHalf - occQuarter) * 100).toFixed(0)}%</Text>.
        That's why hyperbolic taper (smaller cuts at lower doses) reduces withdrawal —
        Horowitz &amp; Taylor 2019.
      </Text>
    </View>
  );
}

function OccupancySvg({
  width,
  height,
  startDoseMg,
  occupancy,
}: {
  width: number;
  height: number;
  startDoseMg: number;
  occupancy: (dose: number) => number;
}) {
  const innerW = Math.max(50, width - PAD.left - PAD.right);
  const innerH = height - PAD.top - PAD.bottom;

  const samples = 80;
  const maxX = startDoseMg * 1.2;
  const points: { x: number; y: number }[] = [];
  for (let i = 0; i <= samples; i++) {
    const dose = (i / samples) * maxX;
    const occ = occupancy(dose);
    points.push({
      x: PAD.left + (dose / maxX) * innerW,
      y: PAD.top + innerH - occ * innerH,
    });
  }

  const path = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`)
    .join(' ');

  const startX = PAD.left + (startDoseMg / maxX) * innerW;
  const startY = PAD.top + innerH - occupancy(startDoseMg) * innerH;
  const halfX = PAD.left + (startDoseMg * 0.5 / maxX) * innerW;
  const halfY = PAD.top + innerH - occupancy(startDoseMg * 0.5) * innerH;
  const quarterX = PAD.left + (startDoseMg * 0.25 / maxX) * innerW;
  const quarterY = PAD.top + innerH - occupancy(startDoseMg * 0.25) * innerH;

  return (
    <Svg width={width} height={height}>
      {[0.5, 1.0].map((p, i) => {
        const y = PAD.top + innerH - p * innerH;
        return (
          <Line
            key={`g-${i}`}
            x1={PAD.left}
            x2={width - PAD.right}
            y1={y}
            y2={y}
            stroke="#1f2933"
            strokeWidth={1}
            strokeDasharray="2,3"
          />
        );
      })}

      {[0, 0.5, 1].map((p, i) => (
        <SvgText
          key={`yl-${i}`}
          x={6}
          y={PAD.top + innerH - p * innerH + 4}
          fontSize="11"
          fill="#8b949e"
          fontFamily="Helvetica"
        >
          {`${Math.round(p * 100)}%`}
        </SvgText>
      ))}

      <SvgText x={PAD.left} y={height - 8} fontSize="11" fill="#8b949e" fontFamily="Helvetica">0</SvgText>
      <SvgText x={width - PAD.right} y={height - 8} fontSize="11" fill="#8b949e" textAnchor="end" fontFamily="Helvetica">
        {Math.round(maxX)} mg
      </SvgText>

      <Path d={path} stroke="#60a5fa" strokeWidth={2.5} fill="none" />

      <Circle cx={startX} cy={startY} r={5} fill="#60a5fa" />
      <Circle cx={halfX} cy={halfY} r={4.5} fill="#f59e0b" />
      <Circle cx={quarterX} cy={quarterY} r={4.5} fill="#ef4444" />
    </Svg>
  );
}

function Row({ label, occ, dot }: { label: string; occ: number; dot: string }) {
  return (
    <View className="flex-row items-center justify-between py-0.5">
      <View className="flex-row items-center flex-1">
        <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: dot, marginRight: 8 }} />
        <Text className="text-text text-xs">{label}</Text>
      </View>
      <Text className="text-muted text-xs font-mono">~{(occ * 100).toFixed(0)}% occupancy</Text>
    </View>
  );
}

function formatMg(n: number): string {
  if (n >= 10) return n.toFixed(0);
  if (n >= 1) return n.toFixed(1).replace(/\.0$/, '');
  return n.toFixed(2).replace(/\.?0+$/, '');
}
