// Dose-equivalency calculator — three families on one screen.
//   • Antipsychotics    → CPZ-eq
//   • Antidepressants   → fluoxetine-eq
//   • Benzodiazepines   → diazepam-eq
//
// Flow:
//   1. Pick family (segmented control)
//   2. Pick drug + enter current dose
//   3. (Optional) pick a target drug to convert to
//   4. Card shows reference units, equivalent reference dose, and
//      converted dose if a target is chosen.
//
// Designed to be usable in 30 seconds at the bedside. No animations,
// no loading states, no modal pickers — just inline lists.
import { useMemo, useState } from 'react';
import { Pressable, Text, TextInput, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  EQUIVALENCY_FAMILIES,
  type EquivalencyEntry,
  type EquivalencyFamily,
  convertWithinFamily,
  doseInReferenceUnits,
  roundToClinicalDose,
} from '../engine/doseEquivalents';

const FAMILY_TABS: Array<{ family: EquivalencyFamily; label: string; sub: string }> = [
  { family: 'cpz',        label: 'Antipsychotics', sub: 'CPZ-eq' },
  { family: 'fluoxetine', label: 'Antidepressants', sub: 'FLX-eq' },
  { family: 'diazepam',   label: 'Benzodiazepines', sub: 'DZP-eq' },
];

export function EquivalencyScreen() {
  const [family, setFamily] = useState<EquivalencyFamily>('cpz');
  const [fromId, setFromId] = useState<string | null>(null);
  const [toId, setToId] = useState<string | null>(null);
  const [doseStr, setDoseStr] = useState('');

  const meta = EQUIVALENCY_FAMILIES[family];
  const fromDoseMg = parseFloat(doseStr);
  const validDose = !isNaN(fromDoseMg) && fromDoseMg > 0;

  const fromEntry = useMemo(
    () => meta.entries.find((e) => e.id === fromId) ?? null,
    [meta, fromId],
  );
  const toEntry = useMemo(
    () => meta.entries.find((e) => e.id === toId) ?? null,
    [meta, toId],
  );

  const refResult = useMemo(() => {
    if (!validDose || !fromId) return null;
    return doseInReferenceUnits(family, fromId, fromDoseMg);
  }, [family, fromId, fromDoseMg, validDose]);

  const convResult = useMemo(() => {
    if (!validDose || !fromId || !toId || fromId === toId) return null;
    return convertWithinFamily(family, fromId, fromDoseMg, toId);
  }, [family, fromId, toId, fromDoseMg, validDose]);

  // Sort entries: non-specialist first, alphabetic within group
  const sortedEntries = useMemo(() => {
    return [...meta.entries].sort((a, b) => {
      if (!!a.specialist !== !!b.specialist) return a.specialist ? 1 : -1;
      return a.genericName.localeCompare(b.genericName);
    });
  }, [meta]);

  const switchFamily = (f: EquivalencyFamily) => {
    setFamily(f);
    setFromId(null);
    setToId(null);
    setDoseStr('');
  };

  return (
    <ScreenContainer>
      {/* ── Hero ────────────────────────────────────────────────── */}
      <View className="mb-4">
        <Text className="text-text text-2xl font-bold mb-1">
          Dose equivalents
        </Text>
        <Text className="text-muted text-sm leading-5">
          For orientation only. Equivalent dose ≠ equivalent efficacy or
          tolerability. Always titrate to clinical effect.
        </Text>
      </View>

      {/* ── Family tabs ─────────────────────────────────────────── */}
      <View className="flex-row bg-surface border border-border rounded-2xl p-1 mb-4">
        {FAMILY_TABS.map((t) => {
          const active = t.family === family;
          return (
            <Pressable
              key={t.family}
              onPress={() => switchFamily(t.family)}
              className={`flex-1 px-2 py-2 rounded-xl ${active ? 'bg-accent' : ''}`}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              accessibilityLabel={`${t.label} ${t.sub}`}
            >
              <Text
                className={`text-center text-xs font-semibold ${active ? 'text-white' : 'text-text'}`}
              >
                {t.label}
              </Text>
              <Text
                className={`text-center text-eyebrow ${active ? 'text-white/80' : 'text-muted'}`}
              >
                {t.sub}
              </Text>
            </Pressable>
          );
        })}
      </View>

      {/* ── Reference card ──────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4 flex-row items-center">
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="beaker" size={16} color="#3b82f6" />
        </View>
        <View className="flex-1">
          <Text className="text-muted text-eyebrow uppercase tracking-widest">
            Reference
          </Text>
          <Text className="text-text text-sm font-semibold">
            {meta.reference.name} {meta.reference.mg} mg = 1 {meta.shortLabel}
          </Text>
        </View>
      </View>

      {/* ── From drug ───────────────────────────────────────────── */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 px-1">
        Current drug
      </Text>
      <DrugPicker
        entries={sortedEntries}
        selectedId={fromId}
        onSelect={(id) => {
          setFromId(id);
          if (toId === id) setToId(null);
        }}
      />

      {/* ── Dose input ──────────────────────────────────────────── */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mt-4 mb-2 px-1">
        Current dose (mg/day)
      </Text>
      <View className="flex-row items-center bg-surface border border-border rounded-2xl px-4 py-3">
        <TextInput
          value={doseStr}
          onChangeText={setDoseStr}
          keyboardType="decimal-pad"
          placeholder={fromEntry ? `e.g. ${fromEntry.equivalentMg}` : 'e.g. 100'}
          placeholderTextColor="#6b7280"
          className="flex-1 text-text text-base"
          accessibilityLabel="Current dose in milligrams per day"
        />
        <Text className="text-muted text-sm ml-2">mg/day</Text>
      </View>

      {/* ── Result ──────────────────────────────────────────────── */}
      {refResult && fromEntry && (
        <View className="bg-accent/10 border border-accent/30 rounded-2xl px-4 py-4 mt-4">
          <Text className="text-accent text-eyebrow uppercase tracking-widest font-bold mb-2">
            Reference equivalent
          </Text>
          <Text className="text-text text-base leading-5">
            {fromEntry.genericName} {formatMg(fromDoseMg)} mg/day{'\n'}
            ≈ <Text className="font-bold">{refResult.refUnits.toFixed(2)} {meta.shortLabel}</Text>
            {'\n'}
            ≈ {meta.reference.name}{' '}
            <Text className="font-bold">{formatMg(refResult.referenceDoseMg)} mg/day</Text>
          </Text>
        </View>
      )}

      {/* ── Convert to ──────────────────────────────────────────── */}
      {fromId && validDose && (
        <>
          <Text className="text-muted text-eyebrow uppercase tracking-widest mt-4 mb-2 px-1">
            Convert to
          </Text>
          <DrugPicker
            entries={sortedEntries.filter((e) => e.id !== fromId)}
            selectedId={toId}
            onSelect={setToId}
          />
        </>
      )}

      {convResult && fromEntry && toEntry && (
        <View className="bg-to/10 border border-to/30 rounded-2xl px-4 py-4 mt-4">
          <Text className="text-to text-eyebrow uppercase tracking-widest font-bold mb-2">
            Conversion
          </Text>
          <Text className="text-text text-base leading-6">
            {fromEntry.genericName} {formatMg(fromDoseMg)} mg{'\n'}
            ≈ {toEntry.genericName}{' '}
            <Text className="font-bold">
              {formatMg(roundToClinicalDose(convResult.toDoseMg))} mg/day
            </Text>{' '}
            <Text className="text-muted text-xs">
              (raw {formatMg(convResult.toDoseMg, 2)} mg)
            </Text>
          </Text>
          {toEntry.notes && (
            <Text className="text-muted text-xs mt-2 leading-4">
              {toEntry.notes}
            </Text>
          )}
        </View>
      )}

      {/* ── Limitations panel ───────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-5">
        <Text className="text-warning text-eyebrow uppercase tracking-widest font-bold mb-2">
          Limitations
        </Text>
        {meta.limitations.map((l, i) => (
          <Text key={i} className="text-muted text-xs leading-4 mb-1">
            • {l}
          </Text>
        ))}
      </View>

      {/* ── Citation ────────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-3">
        <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
          Sources
        </Text>
        {meta.citations.map((c, i) => (
          <Text key={i} className="text-text text-xs leading-4 mb-1">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-eyebrow mt-2">
          Last reviewed: {meta.lastReviewedISO}
        </Text>
      </View>
    </ScreenContainer>
  );
}

// ── DrugPicker — inline list, dense rows, single-tap select ─────────────────

function DrugPicker({
  entries,
  selectedId,
  onSelect,
}: {
  entries: EquivalencyEntry[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}) {
  return (
    <View className="bg-surface border border-border rounded-2xl overflow-hidden">
      {entries.map((e, i) => {
        const active = e.id === selectedId;
        const isLast = i === entries.length - 1;
        return (
          <Pressable
            key={e.id}
            onPress={() => onSelect(e.id)}
            className={`flex-row items-center px-4 py-3 active:opacity-80 ${
              !isLast ? 'border-b border-border' : ''
            } ${active ? 'bg-accent/10' : ''}`}
            accessibilityRole="radio"
            accessibilityState={{ selected: active }}
          >
            <View
              className={`w-4 h-4 rounded-full mr-3 border ${active ? 'bg-accent border-accent' : 'border-border'}`}
            />
            <View className="flex-1">
              <Text className="text-text text-sm font-medium">
                {e.genericName}
                {e.specialist && (
                  <Text className="text-muted text-eyebrow font-normal"> · approx</Text>
                )}
              </Text>
              {e.notes && (
                <Text className="text-muted text-micro leading-4 mt-0.5" numberOfLines={1}>
                  {e.notes}
                </Text>
              )}
            </View>
            <Text className="text-muted text-xs ml-2">
              {formatMg(e.equivalentMg)} mg
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function formatMg(n: number, decimals = 1): string {
  if (n === 0) return '0';
  if (n >= 10) return n.toFixed(0);
  if (n >= 1) return n.toFixed(decimals).replace(/\.?0+$/, '');
  return n.toFixed(2).replace(/\.?0+$/, '');
}
