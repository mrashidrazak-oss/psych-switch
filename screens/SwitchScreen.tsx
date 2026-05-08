// Drug cross-taper wizard — 4 single-focus steps:
//
//   1. FROM drug   (which drug is the patient on?)
//   2. FROM dose   (current dose of that drug)
//   3. TO drug     (which drug to switch to?)
//   4. TO dose     (target dose, then "Show schedule")
//
// Each step fills the whole screen. A progress bar at the top tracks
// position. A summary strip below the progress bar shows what's already
// been chosen so the user never loses context.
//
// Replacing the old single-page scroll with this wizard eliminates the
// problem of 26 drugs + 4 input groups all competing on one screen.
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { type ReactNode, useMemo, useState } from 'react';
import { Modal, Pressable, ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Banner } from '../components/Banner';
import { Chip, type ChipTone } from '../components/Chip';
import { Icon } from '../components/Icon';
import { usePatientContext } from '../engine/patientContext';
import { rankDrugs, type RelevanceTier } from '../engine/smartPicker';
import { listDrugs } from '../engine/switchingEngine';
import type { Drug, RiskLevel } from '../engine/types';
import { confirm, tap as hapticTap } from '../utils/haptics';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'Switch'>;

// ── Step metadata ─────────────────────────────────────────────────────────────
const STEP_LABELS = [
  'From drug',
  'Current dose',
  'To drug',
  'Target dose',
] as const;

// ── Drug grouping helpers ──────────────────────────────────────────────────────
interface Section {
  id: string;
  label: string;
  drugs: Drug[];
}

function groupDrugs(drugs: Drug[], excludeId?: string | null): Section[] {
  const visible = excludeId ? drugs.filter((d) => d.id !== excludeId) : drugs;

  const ad: Drug[] = [];
  const apOral: Drug[] = [];
  const apLai: Drug[] = [];
  const ms: Drug[] = [];

  for (const d of visible) {
    if (d.category === 'mood-stabilizer') {
      ms.push(d);
    } else if (d.category === 'antipsychotic' && d.formulation === 'lai') {
      apLai.push(d);
    } else if (d.category === 'antipsychotic') {
      apOral.push(d);
    } else {
      ad.push(d);
    }
  }

  const byClassThenName = (a: Drug, b: Drug) => {
    if (a.drugClass !== b.drugClass) return a.drugClass.localeCompare(b.drugClass);
    return a.genericName.localeCompare(b.genericName);
  };

  [ad, apOral, apLai, ms].forEach((arr) => arr.sort(byClassThenName));

  const sections: Section[] = [];
  if (ad.length) sections.push({ id: 'ad', label: 'Antidepressants', drugs: ad });
  if (apOral.length)
    sections.push({ id: 'ap-oral', label: 'Antipsychotics — Oral', drugs: apOral });
  if (apLai.length)
    sections.push({ id: 'ap-lai', label: 'Antipsychotics — LAI (depot)', drugs: apLai });
  if (ms.length)
    sections.push({ id: 'ms', label: 'Mood stabilizers', drugs: ms });
  return sections;
}

function drugSubtitle(d: Drug): string {
  if (d.formulation === 'lai' && d.laiDetails) {
    return `${d.drugClass} · ${d.laiDetails.injectionIntervalDays}-day depot`;
  }
  return `${d.drugClass} · t½ ${d.halfLife.meanHours}h`;
}

// ── Main screen ────────────────────────────────────────────────────────────────
export function SwitchScreen({ navigation }: Props) {
  // Hidden from the cross-titration picker as of v0.4.15 pending further
  // research:
  //   • Mood stabilizers — switching matrix needs more clinical
  //     validation (lithium serum-level pacing, lamotrigine titration vs
  //     SJS risk, valproate teratogenicity in switching scenarios).
  //   • LAI / depot antipsychotics — initiation overlap with oral, missed-dose
  //     algorithms and depot tail kinetics are protocol-specific and live in
  //     dedicated module screens (Sustenna / Maintena / Trinza). Stuffing
  //     them into a generic cross-taper picker would mislead.
  //
  // Both classes remain registered in the drug database (engine still has
  // their profiles, rules and tests) — they're just filtered out of *this*
  // surface. The dedicated modules on Home are the right entry point.
  const drugs = useMemo(
    () =>
      listDrugs().filter(
        (d) => d.category !== 'mood-stabilizer' && d.formulation !== 'lai',
      ),
    [],
  );
  const insets = useSafeAreaInsets();
  const { ctx } = usePatientContext();

  const [step, setStep] = useState<1 | 2 | 3 | 4>(1);
  const [fromDrugId, setFromDrugId] = useState<string | null>(null);
  const [fromDoseMg, setFromDoseMg] = useState<number | null>(null);
  const [toDrugId, setToDrugId] = useState<string | null>(null);
  const [toDoseMg, setToDoseMg] = useState<number | null>(null);
  const [profileDrug, setProfileDrug] = useState<Drug | null>(null);

  const fromDrug = drugs.find((d) => d.id === fromDrugId) ?? null;
  const toDrug = drugs.find((d) => d.id === toDrugId) ?? null;

  const goBack = () => {
    if (step === 1) {
      navigation.goBack();
    } else {
      setStep((s) => (s - 1) as 1 | 2 | 3 | 4);
    }
  };

  const onSubmit = () => {
    if (!fromDrugId || fromDoseMg === null || !toDrugId || toDoseMg === null)
      return;
    confirm();
    navigation.navigate('Result', {
      fromDrugId,
      fromDoseMg,
      toDrugId,
      toDoseMg,
    });
  };

  return (
    <View className="flex-1 bg-bg">
      {/* ── Progress bar + summary ──────────────────────────────────── */}
      <View className="px-5 pt-3 pb-4 border-b border-border bg-bg">
        <ProgressBar step={step} />

        {/* Context summary — visible from step 2 onward */}
        {(fromDrug || toDrug) && (
          <View className="flex-row items-center mt-3 flex-wrap">
            <SummaryChip
              label={fromDrug?.genericName ?? '—'}
              dimmed={!fromDrug}
            />
            {fromDoseMg !== null && (
              <SummaryChip label={`${fromDoseMg} mg`} dimmed={false} small />
            )}
            <Text className="text-muted mx-2 text-sm">→</Text>
            <SummaryChip
              label={toDrug?.genericName ?? '?'}
              dimmed={!toDrug}
            />
            {toDoseMg !== null && (
              <SummaryChip label={`${toDoseMg} mg`} dimmed={false} small />
            )}
          </View>
        )}
      </View>

      {/* ── Step question heading ────────────────────────────────────── */}
      <View className="px-5 pt-5 pb-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Step {step} of 4
        </Text>
        <Text className="text-text text-xl font-bold">
          {stepQuestion(step, fromDrug, toDrug)}
        </Text>
      </View>

      {/* ── Step content (scrollable) ────────────────────────────────── */}
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 24 }}
        keyboardShouldPersistTaps="handled"
      >
        {step === 1 && (
          <DrugPicker
            drugs={drugs}
            selectedId={fromDrugId}
            onSelect={(id) => {
              hapticTap();
              setFromDrugId(id);
              // Reset downstream selections when from-drug changes.
              setFromDoseMg(null);
              if (id === toDrugId) {
                setToDrugId(null);
                setToDoseMg(null);
              }
              setStep(2);
            }}
            onInfo={setProfileDrug}
          />
        )}

        {step === 2 && fromDrug && (
          <DosePicker
            drug={fromDrug}
            selectedDose={fromDoseMg}
            onSelect={(dose) => {
              hapticTap();
              setFromDoseMg(dose);
              setStep(3);
            }}
          />
        )}

        {step === 3 && (
          <DrugPicker
            drugs={drugs}
            selectedId={toDrugId}
            excludeId={fromDrugId}
            onSelect={(id) => {
              hapticTap();
              setToDrugId(id);
              setToDoseMg(null);
              setStep(4);
            }}
            onInfo={setProfileDrug}
            rankAgainst={fromDrugId ? { fromDrugId, ctx } : undefined}
          />
        )}

        {step === 4 && toDrug && (
          <DosePicker
            drug={toDrug}
            selectedDose={toDoseMg}
            onSelect={(d) => { hapticTap(); setToDoseMg(d); }}
          />
        )}
      </ScrollView>

      {/* ── Bottom action bar ──────────────────────────────────────────
          The bar reserves a stable height across all 4 steps so the layout
          doesn't shift when the user navigates back/forward. Step 4 reveals
          the primary CTA inline; all other steps fill the slot with a Back
          link occupying the same visual mass. */}
      <View
        className="px-5 pt-3 border-t border-border bg-bg"
        style={{ paddingBottom: Math.max(insets.bottom, 12) }}
      >
        {step === 4 ? (
          <View className="flex-row gap-3">
            {/* Back as a square 56px tile */}
            <Pressable
              onPress={goBack}
              className="w-14 h-14 rounded-2xl bg-surface border border-border items-center justify-center active:opacity-70"
            >
              <Icon name="chevron-left" size={20} color="#8b949e" />
            </Pressable>
            {/* CTA fills the rest */}
            <Pressable
              onPress={onSubmit}
              disabled={toDoseMg === null}
              className={`flex-1 h-14 rounded-2xl flex-row items-center justify-center ${
                toDoseMg !== null ? 'bg-accent active:opacity-80' : 'bg-border'
              }`}
            >
              <Text
                className={`text-center text-base font-semibold mr-2 ${
                  toDoseMg !== null ? 'text-white' : 'text-muted'
                }`}
              >
                Show switching schedule
              </Text>
              <Icon
                name="arrow-right"
                size={18}
                color={toDoseMg !== null ? '#ffffff' : '#8b949e'}
              />
            </Pressable>
          </View>
        ) : (
          <Pressable
            onPress={goBack}
            className="flex-row items-center justify-center h-14 rounded-2xl bg-surface border border-border active:opacity-70"
          >
            <Icon name="chevron-left" size={18} color="#8b949e" />
            <Text className="text-muted text-sm font-medium ml-1.5">
              {step === 1 ? 'Back to home' : 'Previous step'}
            </Text>
          </Pressable>
        )}
      </View>

      {/* Drug profile bottom sheet */}
      <DrugProfileModal
        drug={profileDrug}
        onClose={() => setProfileDrug(null)}
      />
    </View>
  );
}

// ── Subcomponents ──────────────────────────────────────────────────────────────

function stepQuestion(
  step: 1 | 2 | 3 | 4,
  fromDrug: Drug | null,
  toDrug: Drug | null,
): string {
  switch (step) {
    case 1:
      return 'Which drug is the patient currently on?';
    case 2:
      return `Current dose of ${fromDrug?.genericName ?? '…'}?`;
    case 3:
      return 'Which drug to switch to?';
    case 4:
      return `Target dose of ${toDrug?.genericName ?? '…'}?`;
  }
}

// Progress bar: 4 connected segments with numbered nodes. Completed steps
// are accent-filled with a check; the current step is accent-ringed; future
// steps are muted. The step label under the row tells the user exactly
// what they're being asked.
function ProgressBar({ step }: { step: 1 | 2 | 3 | 4 }) {
  return (
    <View>
      <View className="flex-row items-center">
        {([1, 2, 3, 4] as const).map((s, idx) => {
          const isCurrent = s === step;
          const isDone = s < step;
          return (
            <View key={s} className="flex-row items-center flex-1">
              {/* Node */}
              <View
                className={`w-6 h-6 rounded-full items-center justify-center ${
                  isDone
                    ? 'bg-accent'
                    : isCurrent
                      ? 'bg-accent/15 border-2 border-accent'
                      : 'bg-surface border border-border'
                }`}
              >
                {isDone ? (
                  <Icon name="check" size={12} color="#ffffff" strokeWidth={3} />
                ) : (
                  <Text
                    className={`text-micro font-bold ${
                      isCurrent ? 'text-accent' : 'text-muted'
                    }`}
                  >
                    {s}
                  </Text>
                )}
              </View>
              {/* Connector */}
              {idx < 3 && (
                <View
                  className={`flex-1 h-[2px] mx-1.5 rounded-full ${
                    isDone ? 'bg-accent' : 'bg-border'
                  }`}
                />
              )}
            </View>
          );
        })}
      </View>
      <Text className="text-muted text-micro mt-2 font-medium">
        Step {step} of 4 · {STEP_LABELS[step - 1]}
      </Text>
    </View>
  );
}

function SummaryChip({
  label,
  dimmed,
  small,
}: {
  label: string;
  dimmed: boolean;
  small?: boolean;
}) {
  // Migrated to the unified Chip primitive in v0.4.14. Two states:
  //   • dimmed → neutral tone (placeholder slot, e.g. "From drug")
  //   • active → info tone   (filled slot, e.g. "Olanzapine 20 mg")
  return (
    <Chip
      tone={dimmed ? 'neutral' : 'info'}
      size={small ? 'sm' : 'md'}
      label={label}
      className="mr-1 mb-1"
    />
  );
}

// Full-screen drug list with category sections.
//
// When `rankAgainst` is set (i.e. on the to-drug step where we know the
// from-drug), the picker switches into smart mode: drugs are re-grouped
// by clinical relevance tier (★ best fit / reviewed / fallback / caution
// / avoid) and each row gets short tags that explain WHY the engine
// ranked it that way.
function DrugPicker({
  drugs,
  selectedId,
  onSelect,
  excludeId,
  onInfo,
  rankAgainst,
}: {
  drugs: Drug[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  excludeId?: string | null;
  onInfo?: (drug: Drug) => void;
  rankAgainst?: { fromDrugId: string; ctx: import('../engine/patientContext').PatientContext };
}) {
  // Smart-picker mode — relevance tiers replace category sections.
  if (rankAgainst) {
    const visible = excludeId ? drugs.filter((d) => d.id !== excludeId) : drugs;
    return (
      <SmartDrugPicker
        drugs={visible}
        selectedId={selectedId}
        onSelect={onSelect}
        onInfo={onInfo}
        opts={rankAgainst}
      />
    );
  }

  // Plain mode — category sections.
  const sections = groupDrugs(drugs, excludeId);

  return (
    <View>
      {sections.map((section, idx) => (
        <View key={section.id} className={idx > 0 ? 'mt-5' : ''}>
          <View className="flex-row justify-between items-center mb-2 px-1">
            <Text className="text-muted text-eyebrow uppercase tracking-widest">
              {section.label}
            </Text>
            <Text className="text-muted text-eyebrow">{section.drugs.length}</Text>
          </View>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {section.drugs.map((d, di) => {
              const isSelected = d.id === selectedId;
              const isLast = di === section.drugs.length - 1;
              return (
                <Pressable
                  key={d.id}
                  onPress={() => onSelect(d.id)}
                  className={`px-4 py-3.5 active:opacity-80 ${
                    !isLast ? 'border-b border-border' : ''
                  } ${isSelected ? 'bg-accent/10' : ''}`}
                >
                  <View className="flex-row items-center">
                    {/* Selection ring */}
                    <View
                      className={`w-5 h-5 rounded-full border-2 mr-3 items-center justify-center shrink-0 ${
                        isSelected ? 'border-accent bg-accent' : 'border-border'
                      }`}
                    >
                      {isSelected && (
                        <View className="w-2 h-2 rounded-full bg-white" />
                      )}
                    </View>
                    {/* Drug name + subtitle */}
                    <View className="flex-1">
                      <Text className="text-text text-base font-semibold leading-tight">
                        {d.genericName}
                      </Text>
                      <Text className="text-muted text-xs mt-0.5">
                        {drugSubtitle(d)}
                      </Text>
                    </View>
                    {/* Info button — separate Pressable so it doesn't trigger onSelect */}
                    {onInfo && (
                      <Pressable
                        onPress={() => onInfo(d)}
                        hitSlop={10}
                        className="w-8 h-8 rounded-full bg-bg border border-border items-center justify-center ml-2 shrink-0 active:opacity-70"
                      >
                        <Icon name="info" size={14} color="#8b949e" />
                      </Pressable>
                    )}
                  </View>
                </Pressable>
              );
            })}
          </View>
        </View>
      ))}
    </View>
  );
}

// ── Smart-picker variant ───────────────────────────────────────────────────
// Reuses the same row visual language but groups by tier and surfaces tags.

const TIER_LABEL: Record<RelevanceTier, string> = {
  top:      '★ Best fit',
  reviewed: 'Reviewed pair',
  fallback: 'Maudsley fallback',
  caution:  'Use with caution',
  avoid:    'Avoid',
};
const TIER_HEADER_TINT: Record<RelevanceTier, string> = {
  top:      'text-warning',
  reviewed: 'text-to',
  fallback: 'text-muted',
  caution:  'text-warning',
  avoid:    'text-danger',
};

function SmartDrugPicker({
  drugs,
  selectedId,
  onSelect,
  onInfo,
  opts,
}: {
  drugs: Drug[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onInfo?: (drug: Drug) => void;
  opts: { fromDrugId: string; ctx: import('../engine/patientContext').PatientContext };
}) {
  const ranked = useMemo(
    () => rankDrugs(drugs, { fromDrugId: opts.fromDrugId, context: opts.ctx }),
    [drugs, opts.fromDrugId, opts.ctx],
  );

  const tierOrder: RelevanceTier[] = ['top', 'reviewed', 'fallback', 'caution', 'avoid'];
  const grouped: Record<RelevanceTier, typeof ranked> = {
    top: [], reviewed: [], fallback: [], caution: [], avoid: [],
  };
  for (const r of ranked) grouped[r.tier].push(r);

  return (
    <View>
      {/* Hint — explain the new ordering */}
      <Banner tone="info" variant="outline" hideEyebrow className="mb-3">
        <View className="flex-row items-center">
          <Icon name="sparkles" size={14} color="#3b82f6" />
          <Text className="text-text text-xs ml-2 flex-1">
            Ordered by clinical relevance — reviewed pairs first, contraindications last.
          </Text>
        </View>
      </Banner>

      {tierOrder.map((tier, idx) => {
        const items = grouped[tier];
        if (items.length === 0) return null;
        return (
          <View key={tier} className={idx > 0 ? 'mt-5' : ''}>
            <View className="flex-row justify-between items-center mb-2 px-1">
              <Text className={`${TIER_HEADER_TINT[tier]} text-eyebrow uppercase tracking-widest font-bold`}>
                {TIER_LABEL[tier]}
              </Text>
              <Text className="text-muted text-eyebrow">{items.length}</Text>
            </View>
            <View className="bg-surface border border-border rounded-2xl overflow-hidden">
              {items.map((r, di) => {
                const isSelected = r.drug.id === selectedId;
                const isLast = di === items.length - 1;
                return (
                  <Pressable
                    key={r.drug.id}
                    onPress={() => onSelect(r.drug.id)}
                    className={`px-4 py-3.5 active:opacity-80 ${!isLast ? 'border-b border-border' : ''} ${isSelected ? 'bg-accent/10' : ''} ${tier === 'avoid' ? 'opacity-60' : ''}`}
                  >
                    <View className="flex-row items-center">
                      <View
                        className={`w-5 h-5 rounded-full border-2 mr-3 items-center justify-center shrink-0 ${
                          isSelected ? 'border-accent bg-accent' : 'border-border'
                        }`}
                      >
                        {isSelected && <View className="w-2 h-2 rounded-full bg-white" />}
                      </View>
                      <View className="flex-1">
                        <Text className="text-text text-base font-semibold leading-tight">
                          {r.drug.genericName}
                        </Text>
                        <Text className="text-muted text-xs mt-0.5">
                          {drugSubtitle(r.drug)}
                        </Text>
                        {r.tags.length > 0 && (
                          <View className="flex-row flex-wrap mt-1.5" style={{ gap: 4 }}>
                            {r.tags.map((tag) => (
                              <SmartTag key={tag} tag={tag} />
                            ))}
                          </View>
                        )}
                      </View>
                      {onInfo && (
                        <Pressable
                          onPress={() => onInfo(r.drug)}
                          hitSlop={10}
                          className="w-8 h-8 rounded-full bg-bg border border-border items-center justify-center ml-2 shrink-0 active:opacity-70"
                        >
                          <Icon name="info" size={14} color="#8b949e" />
                        </Pressable>
                      )}
                    </View>
                  </Pressable>
                );
              })}
            </View>
          </View>
        );
      })}
    </View>
  );
}

function SmartTag({ tag }: { tag: string }) {
  let bg = 'bg-border';
  let border = 'border-border';
  let text = 'text-muted';
  if (tag === 'Reviewed') {
    bg = 'bg-to/15'; border = 'border-to/30'; text = 'text-to';
  } else if (tag === 'contra' || tag === 'avoid') {
    bg = 'bg-danger/15'; border = 'border-danger/30'; text = 'text-danger';
  } else if (tag === 'caution' || tag === 'DDI' || tag.startsWith('causes')) {
    bg = 'bg-warning/15'; border = 'border-warning/30'; text = 'text-warning';
  } else if (tag.startsWith('avoids')) {
    bg = 'bg-to/15'; border = 'border-to/30'; text = 'text-to';
  }
  return (
    <View className={`px-1.5 py-0.5 rounded border ${bg} ${border}`}>
      <Text className={`text-[9px] font-bold uppercase tracking-wider ${text}`}>{tag}</Text>
    </View>
  );
}

// Large tappable dose tiles — easier to tap than the old small chips.
// LAI-aware: depot doses are per-injection, not per-day.
function DosePicker({
  drug,
  selectedDose,
  onSelect,
}: {
  drug: Drug;
  selectedDose: number | null;
  onSelect: (dose: number) => void;
}) {
  const isLai = drug.formulation === 'lai';
  const doseUnit = isLai ? 'mg/inj' : 'mg';
  const rangeUnit = isLai
    ? `per injection · every ${drug.laiDetails?.injectionIntervalDays ?? '?'} days`
    : 'mg/day';

  return (
    <View>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs">
          Typical range · {rangeUnit}
        </Text>
        <Text className="text-text text-sm font-semibold">
          {drug.dosing.typicalTargetRangeMg[0]}–
          {drug.dosing.typicalTargetRangeMg[1]} mg
        </Text>
        {isLai && drug.laiDetails?.initiationProtocol && (
          <Text className="text-muted text-xs mt-1 leading-4">
            {drug.laiDetails.initiationProtocol}
          </Text>
        )}
      </View>

      <View className="flex-row flex-wrap">
        {drug.dosing.increments.map((dose) => {
          const isSelected = dose === selectedDose;
          const isTypical =
            dose >= drug.dosing.typicalTargetRangeMg[0] &&
            dose <= drug.dosing.typicalTargetRangeMg[1];
          return (
            <Pressable
              key={dose}
              onPress={() => onSelect(dose)}
              className={`mr-3 mb-3 rounded-2xl items-center justify-center active:opacity-80 ${
                isSelected
                  ? 'bg-accent border-2 border-accent'
                  : isTypical
                    ? 'bg-surface border-2 border-accent/30'
                    : 'bg-surface border border-border'
              }`}
              style={{ width: 88, height: 72 }}
            >
              <Text
                className={`text-xl font-bold ${
                  isSelected ? 'text-white' : 'text-text'
                }`}
              >
                {dose}
              </Text>
              <Text
                className={`text-eyebrow mt-0.5 ${
                  isSelected ? 'text-white/80' : 'text-muted'
                }`}
              >
                {doseUnit}
              </Text>
              {isTypical && !isSelected && (
                <Text className="text-[9px] text-accent mt-0.5 font-medium">
                  typical
                </Text>
              )}
            </Pressable>
          );
        })}
      </View>

      <Text className="text-muted text-xs mt-2 leading-4">
        {drug.formulationNotes}
      </Text>
    </View>
  );
}

// ── Drug profile bottom sheet ──────────────────────────────────────────────────
//
// Rendered via React Native Modal (transparent + slide-up animation).
// Structural containers use pure `style` props to avoid NativeWind className+style
// mixing. All inner content uses pure `className`.

/**
 * Map a clinical risk level to a Chip tone.
 *
 * Pre-v0.4.14 the "high" tier used a bespoke `orange-400` colour wedged
 * between warning amber and danger red. Collapsing it into warning
 * loses no clinical signal because the label "high" still distinguishes
 * it visually from "moderate" — and we get a 1:1 mapping with our
 * tone palette.
 */
function riskTone(level: RiskLevel): ChipTone {
  switch (level) {
    case 'low':       return 'success';
    case 'moderate':  return 'info';
    case 'high':      return 'warning';
    case 'very high': return 'danger';
  }
}

function RiskPill({ label, level }: { label: string; level: RiskLevel }) {
  return (
    <Chip
      tone={riskTone(level)}
      size="md"
      label={`${label} · ${level}`}
    />
  );
}

function ProfileSection({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <View className="mb-5">
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        {title}
      </Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        {children}
      </View>
    </View>
  );
}

function ProfileRow({ label, value }: { label: string; value: string }) {
  return (
    <View className="flex-row justify-between items-start py-1 gap-3">
      <Text className="text-muted text-xs w-28 shrink-0 leading-4">{label}</Text>
      <Text className="text-text text-xs flex-1 text-right leading-4">{value}</Text>
    </View>
  );
}

function DrugProfileModal({
  drug,
  onClose,
}: {
  drug: Drug | null;
  onClose: () => void;
}) {
  const insets = useSafeAreaInsets();

  if (!drug) return null;

  const hasRiskData =
    drug.qtcRisk ??
    drug.epsRisk ??
    drug.sedation ??
    drug.metabolicRisk ??
    drug.prolactinRisk ??
    drug.discontinuationSyndromeRisk;

  const categoryLabel =
    drug.category === 'antidepressant'
      ? 'Antidepressant'
      : drug.category === 'antipsychotic'
        ? 'Antipsychotic'
        : drug.category === 'mood-stabilizer'
          ? 'Mood stabilizer'
          : null;

  return (
    <Modal
      visible
      animationType="slide"
      transparent
      onRequestClose={onClose}
      statusBarTranslucent
    >
      {/* Dimmed full-screen backdrop — pure style, no className */}
      <View
        style={{
          flex: 1,
          backgroundColor: 'rgba(0,0,0,0.6)',
          justifyContent: 'flex-end',
        }}
      >
        {/* Tap-to-dismiss area occupies the top portion */}
        <Pressable
          style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }}
          onPress={onClose}
        />

        {/* Sheet container — pure style for bg/radius/height */}
        <View
          style={{
            backgroundColor: '#141a22',
            borderTopLeftRadius: 24,
            borderTopRightRadius: 24,
            maxHeight: '88%',
            overflow: 'hidden',
          }}
        >
          {/* Drag handle */}
          <View className="items-center pt-3 pb-1">
            <View className="w-10 h-1 rounded-full bg-border" />
          </View>

          {/* Header row */}
          <View className="flex-row items-start justify-between px-5 pt-3 pb-4 border-b border-border">
            <View className="flex-1 pr-3">
              <Text className="text-text text-xl font-bold leading-snug">
                {drug.genericName}
              </Text>
              <View className="flex-row flex-wrap items-center mt-1.5 gap-1.5">
                <Chip tone="info"    size="md" label={drug.drugClass} />
                {categoryLabel && (
                  <Chip tone="neutral" size="md" label={categoryLabel} />
                )}
              </View>
            </View>
            <Pressable
              onPress={onClose}
              className="w-8 h-8 rounded-full bg-border items-center justify-center mt-0.5 active:opacity-70"
            >
              <Text className="text-muted text-sm font-bold">✕</Text>
            </Pressable>
          </View>

          {/* Scrollable content */}
          <ScrollView
            contentContainerStyle={{
              padding: 20,
              paddingBottom: Math.max(insets.bottom + 16, 32),
            }}
            showsVerticalScrollIndicator={false}
          >
            {/* ── LAI depot details (LAI drugs only, shown first) ─ */}
            {drug.formulation === 'lai' && drug.laiDetails ? (
              <ProfileSection title="Depot details">
                <ProfileRow
                  label="Injection interval"
                  value={`Every ${drug.laiDetails.injectionIntervalDays} days`}
                />
                <ProfileRow
                  label="Oral overlap"
                  value={
                    drug.laiDetails.needsOralOverlap
                      ? `Required · ${drug.laiDetails.oralOverlapDurationDays ?? '?'} days`
                      : 'Not required'
                  }
                />
                <Text className="text-muted text-xs mt-2 leading-4">
                  {drug.laiDetails.initiationProtocol}
                </Text>
              </ProfileSection>
            ) : null}

            {/* ── Pharmacokinetics ────────────────────────────── */}
            <ProfileSection title="Pharmacokinetics">
              <ProfileRow
                label="Half-life"
                value={`${drug.halfLife.meanHours}h mean · range ${drug.halfLife.rangeHours[0]}–${drug.halfLife.rangeHours[1]}h`}
              />
              {drug.halfLife.notes ? (
                <Text className="text-muted text-xs mt-1 leading-4">
                  {drug.halfLife.notes}
                </Text>
              ) : null}
              {drug.activeMetabolite.clinicallySignificant &&
              drug.activeMetabolite.name ? (
                <ProfileRow
                  label="Active metabolite"
                  value={
                    drug.activeMetabolite.halfLifeHours
                      ? `${drug.activeMetabolite.name} · t½ ${drug.activeMetabolite.halfLifeHours}h`
                      : drug.activeMetabolite.name
                  }
                />
              ) : null}
              {drug.activeMetabolite.notes ? (
                <Text className="text-muted text-xs mt-1 leading-4">
                  {drug.activeMetabolite.notes}
                </Text>
              ) : null}
              {drug.reboundPsychosisRisk ? (
                <>
                  <ProfileRow
                    label="Rebound psychosis"
                    value={drug.reboundPsychosisRisk.score}
                  />
                  <Text className="text-muted text-xs mt-1 leading-4">
                    {drug.reboundPsychosisRisk.notes}
                  </Text>
                </>
              ) : null}
            </ProfileSection>

            {/* ── CYP interactions ────────────────────────────── */}
            {(drug.cypInteractions.substrateOf.length > 0 ||
              drug.cypInteractions.inhibitorOf.length > 0) ? (
              <ProfileSection title="CYP interactions">
                {drug.cypInteractions.substrateOf.length > 0 ? (
                  <ProfileRow
                    label="Substrate of"
                    value={drug.cypInteractions.substrateOf.join(', ')}
                  />
                ) : null}
                {drug.cypInteractions.inhibitorOf.length > 0 ? (
                  <ProfileRow
                    label="Inhibits"
                    value={drug.cypInteractions.inhibitorOf.join(', ')}
                  />
                ) : null}
                <Text className="text-muted text-xs mt-1.5 leading-4">
                  {drug.cypInteractions.switchingRelevance}
                </Text>
              </ProfileSection>
            ) : null}

            {/* ── Risk profile ─────────────────────────────────── */}
            {hasRiskData ? (
              <ProfileSection title="Risk profile">
                <View className="flex-row flex-wrap gap-2">
                  {drug.qtcRisk ? (
                    <RiskPill label="QTc" level={drug.qtcRisk} />
                  ) : null}
                  {drug.epsRisk ? (
                    <RiskPill label="EPS" level={drug.epsRisk} />
                  ) : null}
                  {drug.sedation ? (
                    <RiskPill label="Sedation" level={drug.sedation} />
                  ) : null}
                  {drug.metabolicRisk ? (
                    <RiskPill label="Metabolic" level={drug.metabolicRisk.score} />
                  ) : null}
                  {drug.prolactinRisk ? (
                    <RiskPill label="Prolactin" level={drug.prolactinRisk} />
                  ) : null}
                  {drug.discontinuationSyndromeRisk ? (
                    <RiskPill
                      label="Disc. syndrome"
                      level={drug.discontinuationSyndromeRisk.score}
                    />
                  ) : null}
                </View>
                {drug.metabolicRisk?.notes ? (
                  <Text className="text-muted text-xs mt-2 leading-4">
                    {drug.metabolicRisk.notes}
                  </Text>
                ) : null}
                {drug.discontinuationSyndromeRisk?.notes ? (
                  <Text className="text-muted text-xs mt-2 leading-4">
                    {drug.discontinuationSyndromeRisk.notes}
                  </Text>
                ) : null}
              </ProfileSection>
            ) : null}

            {/* ── Dosing ──────────────────────────────────────── */}
            <ProfileSection title="Dosing">
              <ProfileRow
                label="Typical range"
                value={`${drug.dosing.typicalTargetRangeMg[0]}–${drug.dosing.typicalTargetRangeMg[1]} mg`}
              />
              <ProfileRow
                label="Max dose"
                value={`${drug.dosing.maxDoseMg} mg`}
              />
              <ProfileRow
                label="Available strengths"
                value={drug.dosing.increments.join(', ') + ' mg'}
              />
            </ProfileSection>

            {/* ── Malaysian brands ────────────────────────────── */}
            {drug.malaysianBrandNames.length > 0 ? (
              <ProfileSection title="Malaysian brands">
                <Text className="text-text text-sm leading-5">
                  {drug.malaysianBrandNames.join(' · ')}
                </Text>
              </ProfileSection>
            ) : null}

            {/* ── Prescribing notes ────────────────────────────── */}
            {drug.formulationNotes ? (
              <ProfileSection title="Prescribing notes">
                <Text className="text-muted text-sm leading-5">
                  {drug.formulationNotes}
                </Text>
              </ProfileSection>
            ) : null}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}
