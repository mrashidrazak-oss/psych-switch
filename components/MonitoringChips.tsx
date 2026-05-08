// Monitoring chips — a compact at-a-glance strip summarising the rule's
// `safetyFlags` array. Sits between the strategy rationale and the
// schedule, giving clinicians a quick visual census of "what monitoring
// does this switch require?" without having to read every full
// SafetyFlag card.
//
// The full SafetyFlag cards remain (clinical detail must not be hidden);
// these chips are an additional layer of legibility, not a replacement.
//
// As of v0.4.8 these are simply rows of the unified Chip primitive.
import { Text, View } from 'react-native';
import { getFlagDisplay, type SafetySeverity } from '../utils/safetyFlags';
import { Chip, type ChipTone } from './Chip';

// Map flag keys to short clinical labels and a relevant glyph. Keys that
// aren't in this table fall back to the flag display title.
const FLAG_SHORT_LABEL: Record<string, string> = {
  qtc_monitoring_required: 'ECG / QTc',
  metabolic_monitoring_required: 'Metabolic',
  eps_risk_increase: 'EPS',
  prolactin_elevation: 'Prolactin',
  prolactin_normalisation: 'Prolactin ↓',
  amisulpride_renal_clearance: 'Renal',
  lurasidone_food_requirement: 'With food',
  agomelatine_lft_monitoring: 'LFTs',
  lithium_narrow_therapeutic_index: 'Li level',
  lithium_rebound_mania_risk: 'Mania risk',
  carbamazepine_autoinduction: 'CBZ levels',
  carbamazepine_enzyme_reversal: 'Co-meds ↑',
  sjs_risk_lamotrigine: 'SJS risk',
  valproate_teratogenicity_warning: 'Teratogenic',
  bipolar_relapse_monitor: 'Mood watch',
  vortioxetine_cyp2d6_interaction: 'CYP2D6',
  akathisia_risk_aripiprazole: 'Akathisia',
  cholinergic_rebound: 'Anti-Ach rebound',
  anticholinergic_rebound: 'Anti-Ach rebound',
  discontinuation_syndrome_high: 'Disc. syndrome',
  serotonin_syndrome_overlap_low: '5-HT overlap',
  serotonin_syndrome_overlap_high: '5-HT overlap',
  depot_washout_long: 'Depot tail',
  lai_initiation_oral_overlap: 'Oral overlap',
  lamotrigine_vpa_level_rise_on_add: 'LTG ↑ on VPA',
  lamotrigine_cbz_induction_withdrawal_risk: 'LTG ↑ off CBZ',
  lamotrigine_vpa_inhibition_withdrawal_risk: 'LTG ↓ off VPA',
  lamotrigine_dose_must_reduce_as_cbz_tapers: 'Reduce LTG',
  lamotrigine_dose_must_increase_as_vpa_tapers: 'Increase LTG',
};

/** Map SafetySeverity → ChipTone. */
function severityTone(s: SafetySeverity): ChipTone {
  switch (s) {
    case 'info':    return 'info';
    case 'warning': return 'warning';
    case 'danger':  return 'danger';
  }
}

export function MonitoringChips({ flags }: { flags: string[] }) {
  if (flags.length === 0) return null;

  return (
    <View className="mb-3">
      <Text className="text-muted text-xs uppercase tracking-wider mb-2">
        At-a-glance monitoring
      </Text>
      <View className="flex-row flex-wrap" style={{ gap: 6 }}>
        {flags.map((key) => {
          const display = getFlagDisplay(key);
          const label = FLAG_SHORT_LABEL[key] ?? display.title;
          return (
            <Chip
              key={key}
              tone={severityTone(display.severity)}
              size="md"
              label={label}
            />
          );
        })}
      </View>
    </View>
  );
}
