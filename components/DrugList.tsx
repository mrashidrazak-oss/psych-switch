// Tappable list of drugs.
//
// Two modes:
//   1. Plain mode (no `rankedAgainst`): grouped by clinical category
//      (antidepressant / MAOI / antipsychotic-oral / antipsychotic-LAI),
//      sorted by class then name. Used for the FROM picker on
//      SwitchScreen — the clinician usually knows which drug they're
//      switching off.
//
//   2. Smart-picker mode (`rankedAgainst` set): the to-drug list is
//      re-ordered by clinical relevance to THIS pair + THIS patient
//      context using engine/smartPicker.ts. Drugs that already have a
//      reviewed cross-titration rule float to the top; drugs that would
//      trigger an "avoid"-severity DDI or contraindication sink to the
//      bottom and pick up a tag.
//
// We never HIDE a drug in smart mode — the clinician can still pick a
// fallback, just with a clear "no reviewed rule" / "DDI" / "contra" tag.
import { Pressable, Text, View } from 'react-native';
import {
  rankDrugs,
  type RelevanceTier,
} from '../engine/smartPicker';
import type { PatientContext } from '../engine/patientContext';
import type { Drug } from '../engine/types';

export interface SmartPickerOpts {
  fromDrugId: string;
  context?: PatientContext;
  avoidAeId?: string | null;
}

export function DrugList({
  drugs,
  selectedId,
  onSelect,
  excludeId,
  rankedAgainst,
}: {
  drugs: Drug[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  excludeId?: string | null;
  /** When set, switch to smart-picker mode (relevance-ranked sections). */
  rankedAgainst?: SmartPickerOpts;
}) {
  const visible = drugs.filter((d) => d.id !== excludeId);

  if (rankedAgainst) {
    return (
      <SmartList
        drugs={visible}
        selectedId={selectedId}
        onSelect={onSelect}
        opts={rankedAgainst}
      />
    );
  }

  // ── Plain mode ─────────────────────────────────────────────────────────────
  const sections = groupDrugs(visible);

  return (
    <View>
      {sections.map((section, sectionIdx) => (
        <View key={section.id} className={sectionIdx > 0 ? 'mt-5' : ''}>
          <View className="flex-row justify-between items-center mb-2 px-1">
            <Text className="text-muted text-eyebrow uppercase tracking-widest">
              {section.label}
            </Text>
            <Text className="text-muted text-eyebrow">{section.drugs.length}</Text>
          </View>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {section.drugs.map((d, drugIdx) => {
              const isSelected = d.id === selectedId;
              const isLast = drugIdx === section.drugs.length - 1;
              return (
                <Pressable
                  key={d.id}
                  onPress={() => onSelect(d.id)}
                  className={`px-4 py-3 active:opacity-80 ${
                    !isLast ? 'border-b border-border' : ''
                  } ${isSelected ? 'bg-accent/10' : ''}`}
                  accessibilityRole="radio"
                  accessibilityState={{ selected: isSelected }}
                >
                  <View className="flex-row justify-between items-center">
                    <View className="flex-1 pr-3">
                      <Text className="text-text text-base font-semibold">
                        {d.genericName}
                      </Text>
                      <Text className="text-muted text-xs mt-0.5">
                        {drugSubtitle(d)}
                      </Text>
                    </View>
                    {isSelected ? (
                      <Text className="text-accent text-base font-semibold">✓</Text>
                    ) : null}
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

// ── Smart-picker mode ────────────────────────────────────────────────────────

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

const TIER_ROW_BG: Record<RelevanceTier, string> = {
  top:      'bg-accent/10',
  reviewed: '',
  fallback: '',
  caution:  '',
  avoid:    'opacity-60',
};

const TAG_TINT: Record<string, string> = {
  Reviewed: 'bg-to/15 text-to border-to/30',
  contra:   'bg-danger/15 text-danger border-danger/30',
  avoid:    'bg-danger/15 text-danger border-danger/30',
  caution:  'bg-warning/15 text-warning border-warning/30',
  DDI:      'bg-warning/15 text-warning border-warning/30',
};

function tagTint(tag: string): string {
  if (TAG_TINT[tag]) return TAG_TINT[tag];
  if (tag.startsWith('avoids')) return 'bg-to/15 text-to border-to/30';
  if (tag.startsWith('causes')) return 'bg-warning/15 text-warning border-warning/30';
  return 'bg-border text-muted border-border';
}

function SmartList({
  drugs,
  selectedId,
  onSelect,
  opts,
}: {
  drugs: Drug[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  opts: SmartPickerOpts;
}) {
  const ranked = rankDrugs(drugs, {
    fromDrugId: opts.fromDrugId,
    context: opts.context,
    avoidAeId: opts.avoidAeId ?? null,
  });

  // Group into sections by tier, in tier-rank order.
  const tierOrder: RelevanceTier[] = ['top', 'reviewed', 'fallback', 'caution', 'avoid'];
  const grouped: Record<RelevanceTier, typeof ranked> = {
    top: [], reviewed: [], fallback: [], caution: [], avoid: [],
  };
  for (const r of ranked) grouped[r.tier].push(r);

  return (
    <View>
      {tierOrder.map((tier, sectionIdx) => {
        const items = grouped[tier];
        if (items.length === 0) return null;
        return (
          <View key={tier} className={sectionIdx > 0 ? 'mt-5' : ''}>
            <View className="flex-row justify-between items-center mb-2 px-1">
              <Text
                className={`${TIER_HEADER_TINT[tier]} text-eyebrow uppercase tracking-widest font-bold`}
              >
                {TIER_LABEL[tier]}
              </Text>
              <Text className="text-muted text-eyebrow">{items.length}</Text>
            </View>
            <View className="bg-surface border border-border rounded-2xl overflow-hidden">
              {items.map((r, drugIdx) => {
                const isSelected = r.drug.id === selectedId;
                const isLast = drugIdx === items.length - 1;
                return (
                  <Pressable
                    key={r.drug.id}
                    onPress={() => onSelect(r.drug.id)}
                    className={`px-4 py-3 active:opacity-80 ${
                      !isLast ? 'border-b border-border' : ''
                    } ${isSelected ? 'bg-accent/10' : TIER_ROW_BG[tier]}`}
                    accessibilityRole="radio"
                    accessibilityState={{ selected: isSelected, disabled: false }}
                    accessibilityLabel={`${r.drug.genericName}. ${TIER_LABEL[tier]}.${r.tags.length ? ' Tags: ' + r.tags.join(', ') : ''}`}
                  >
                    <View className="flex-row items-start">
                      <View className="flex-1 pr-3">
                        <Text className="text-text text-base font-semibold">
                          {r.drug.genericName}
                        </Text>
                        <Text className="text-muted text-xs mt-0.5">
                          {drugSubtitle(r.drug)}
                        </Text>
                        {r.tags.length > 0 && (
                          <View className="flex-row flex-wrap mt-1.5" style={{ gap: 4 }}>
                            {r.tags.map((tag) => (
                              <View
                                key={tag}
                                className={`px-1.5 py-0.5 rounded border ${tagTint(tag)}`}
                              >
                                <Text className={`text-[9px] font-bold uppercase tracking-wider ${tagTint(tag).split(' ').find((c) => c.startsWith('text-')) ?? ''}`}>
                                  {tag}
                                </Text>
                              </View>
                            ))}
                          </View>
                        )}
                      </View>
                      {isSelected ? (
                        <Text className="text-accent text-base font-semibold">✓</Text>
                      ) : null}
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

// ── Plain-mode helpers ───────────────────────────────────────────────────────

interface Section {
  id: string;
  label: string;
  drugs: Drug[];
}

function groupDrugs(drugs: Drug[]): Section[] {
  const ad: Drug[] = [];
  const maoi: Drug[] = [];
  const apOral: Drug[] = [];
  const apLai: Drug[] = [];

  for (const d of drugs) {
    if (d.isMAOI) {
      maoi.push(d);
    } else if (d.category === 'antipsychotic' && d.formulation === 'lai') {
      apLai.push(d);
    } else if (d.category === 'antipsychotic') {
      apOral.push(d);
    } else {
      // Antidepressants — also catches drugs without an explicit category
      // field (legacy v0.1 antidepressant JSONs).
      ad.push(d);
    }
  }

  const byClassThenName = (a: Drug, b: Drug) => {
    if (a.drugClass !== b.drugClass) {
      return a.drugClass.localeCompare(b.drugClass);
    }
    return a.genericName.localeCompare(b.genericName);
  };

  ad.sort(byClassThenName);
  maoi.sort(byClassThenName);
  apOral.sort(byClassThenName);
  apLai.sort(byClassThenName);

  const sections: Section[] = [];
  if (ad.length) {
    sections.push({ id: 'antidepressant', label: 'Antidepressants', drugs: ad });
  }
  if (maoi.length) {
    sections.push({ id: 'maoi', label: 'MAOI', drugs: maoi });
  }
  if (apOral.length) {
    sections.push({
      id: 'ap-oral',
      label: 'Antipsychotics — Oral',
      drugs: apOral,
    });
  }
  if (apLai.length) {
    sections.push({
      id: 'ap-lai',
      label: 'Antipsychotics — LAI (depot)',
      drugs: apLai,
    });
  }
  return sections;
}

/**
 * The right-hand subtitle on each drug row. Antidepressants get the
 * traditional "SSRI · t½ 26 h"; LAIs get the injection interval since
 * half-life numbers measured in days are misleading for depot products
 * to a clinician scanning quickly.
 */
function drugSubtitle(d: Drug): string {
  if (d.formulation === 'lai' && d.laiDetails) {
    return `${d.drugClass} · ${d.laiDetails.injectionIntervalDays}-day depot`;
  }
  return `${d.drugClass} · t½ ${d.halfLife.meanHours} h`;
}
