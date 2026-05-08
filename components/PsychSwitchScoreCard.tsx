// PsychSwitch Score card.
//
// Single big number (0–100) with a color-banded ring around it, the
// short headline, and an expandable breakdown showing how each
// component contributed (or deducted from) the score.
//
// Visible at the top of the Result screen so the clinician can see
// "is this a good fit for this patient" before reading the schedule.
// Tap → expand → see exactly which components hurt / helped.
import { useState } from 'react';
import { Pressable, Text, View, type LayoutChangeEvent } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import {
  bandColor,
  bandLabel,
  type PsychSwitchScore,
  type ScoreBand,
  type ScoreComponent,
} from '../engine/psychSwitchScore';
import { Icon } from './Icon';

const RING_HEIGHT = 96;
const RING_STROKE = 8;

export function PsychSwitchScoreCard({ score }: { score: PsychSwitchScore }) {
  const [expanded, setExpanded] = useState(false);
  const tint = bandColor(score.band);
  const tintHex = bandToHex(score.band);

  return (
    <View className={`bg-surface border ${tint.border} rounded-2xl mt-3 overflow-hidden`}>
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="flex-row items-center px-4 py-4 active:opacity-80"
      >
        <ScoreRing total={score.total} hex={tintHex} />
        <View className="flex-1 ml-4">
          <Text className={`${tint.text} text-eyebrow uppercase tracking-widest font-bold mb-0.5`}>
            PsychSwitch Score
          </Text>
          <Text className="text-text text-base font-bold">
            {bandLabel(score.band)}
          </Text>
          <Text className="text-muted text-micro mt-0.5" numberOfLines={2}>
            {score.headline}
          </Text>
        </View>
        <Icon
          name={expanded ? 'chevron-left' : 'chevron-right'}
          size={16}
          color="#6b7280"
        />
      </Pressable>

      {expanded && (
        <View className={`border-t ${tint.border}`}>
          <ComponentRow label="Evidence"          value={score.components.evidence} />
          <ComponentRow label="AE alignment"     value={score.components.aeAlignment} />
          <ComponentRow label="Patient context"  value={score.components.contextSafety} />
          <ComponentRow label="DDI safety"       value={score.components.ddiSafety} />
          <ComponentRow label="Dose fidelity"    value={score.components.doseFidelity} />
          <View className="px-4 py-2 border-t border-border bg-bg/50">
            <Text className="text-muted text-micro leading-4">
              Score starts at 100 and subtracts penalties from each component.
              Surfacing this number doesn't replace clinical judgement — it
              summarises what the engine already knows so you can spot
              issues at a glance.
            </Text>
          </View>
        </View>
      )}
    </View>
  );
}

// ── Ring ─────────────────────────────────────────────────────────────────────

function ScoreRing({ total, hex }: { total: number; hex: string }) {
  const [size, setSize] = useState(RING_HEIGHT);
  const onLayout = (e: LayoutChangeEvent) => {
    const h = e.nativeEvent.layout.height;
    if (h && h !== size) setSize(h);
  };

  const r = (size - RING_STROKE) / 2;
  const cx = size / 2;
  const cy = size / 2;
  const C = 2 * Math.PI * r;
  const filled = (Math.max(0, Math.min(100, total)) / 100) * C;

  return (
    <View
      onLayout={onLayout}
      style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}
    >
      <Svg width={size} height={size}>
        {/* Track */}
        <Circle
          cx={cx}
          cy={cy}
          r={r}
          stroke="#1f2933"
          strokeWidth={RING_STROKE}
          fill="none"
        />
        {/* Fill — start from top (rotate -90deg) */}
        <Circle
          cx={cx}
          cy={cy}
          r={r}
          stroke={hex}
          strokeWidth={RING_STROKE}
          strokeLinecap="round"
          fill="none"
          strokeDasharray={`${filled} ${C - filled}`}
          strokeDashoffset={C / 4}
          transform={`rotate(-90 ${cx} ${cy})`}
        />
      </Svg>
      <View
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          alignItems: 'center',
          justifyContent: 'center',
        }}
        pointerEvents="none"
      >
        <Text className="text-text text-2xl font-bold" style={{ fontFamily: 'Helvetica' }}>
          {total}
        </Text>
        <Text className="text-muted text-[9px] uppercase tracking-widest">/ 100</Text>
      </View>
    </View>
  );
}

function bandToHex(b: ScoreBand): string {
  switch (b) {
    case 'excellent': return '#34d399';
    case 'good': return '#3b82f6';
    case 'caution': return '#f59e0b';
    case 'poor': return '#ef4444';
  }
}

// ── Component row ────────────────────────────────────────────────────────────

function ComponentRow({
  label,
  value,
}: {
  label: string;
  value: ScoreComponent;
}) {
  const sign = value.delta === 0 ? '0' : value.delta > 0 ? `+${value.delta}` : `${value.delta}`;
  const tint =
    value.delta < 0
      ? value.delta <= -20
        ? 'text-danger'
        : value.delta <= -10
          ? 'text-warning'
          : 'text-muted'
      : value.delta > 0
        ? 'text-to'
        : 'text-muted';
  return (
    <View className="flex-row items-start px-4 py-2.5 border-b border-border">
      <View className="w-32">
        <Text className="text-text text-xs font-semibold">{label}</Text>
        <Text className={`${tint} text-xs font-mono mt-0.5`}>{sign}</Text>
      </View>
      <View className="flex-1">
        <Text className="text-muted text-xs leading-4">{value.note}</Text>
      </View>
    </View>
  );
}
