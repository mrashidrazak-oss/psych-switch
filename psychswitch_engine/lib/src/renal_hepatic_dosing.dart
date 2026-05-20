// Renal & hepatic dosing reference for common psychotropics.
//
// Guidance summarised from the Maudsley 15e, the Renal Drug Handbook,
// and SmPCs. Renal bands follow eGFR (mL/min/1.73 m²); hepatic bands
// follow Child-Pugh class. Educational quick reference — confirm
// against the current product label and a renal / hepatic pharmacist
// for live decisions.

enum RenalBand {
  normal('≥ 60 — normal / mild'),
  moderate('30–59 — moderate'),
  severe('15–29 — severe'),
  dialysis('< 15 / dialysis');

  const RenalBand(this.label);
  final String label;
}

enum HepaticBand {
  mild('Child-Pugh A — mild'),
  moderate('Child-Pugh B — moderate'),
  severe('Child-Pugh C — severe');

  const HepaticBand(this.label);
  final String label;
}

class RenalHepaticEntry {
  const RenalHepaticEntry({
    required this.drugId,
    required this.drugName,
    required this.renalNormal,
    required this.renalModerate,
    required this.renalSevere,
    required this.renalDialysis,
    required this.hepaticMild,
    required this.hepaticModerate,
    required this.hepaticSevere,
  });

  final String drugId;
  final String drugName;

  final String renalNormal;
  final String renalModerate;
  final String renalSevere;
  final String renalDialysis;

  final String hepaticMild;
  final String hepaticModerate;
  final String hepaticSevere;

  String renalFor(RenalBand b) {
    switch (b) {
      case RenalBand.normal:
        return renalNormal;
      case RenalBand.moderate:
        return renalModerate;
      case RenalBand.severe:
        return renalSevere;
      case RenalBand.dialysis:
        return renalDialysis;
    }
  }

  String hepaticFor(HepaticBand b) {
    switch (b) {
      case HepaticBand.mild:
        return hepaticMild;
      case HepaticBand.moderate:
        return hepaticModerate;
      case HepaticBand.severe:
        return hepaticSevere;
    }
  }
}

const List<RenalHepaticEntry> kRenalHepaticTable = <RenalHepaticEntry>[
  RenalHepaticEntry(
    drugId: 'lithium',
    drugName: 'Lithium',
    renalNormal: 'Standard dosing; monitor level + U&E 6-monthly.',
    renalModerate: 'Reduce dose, increase level monitoring; lithium '
        'is renally cleared and nephrotoxic — co-manage with renal.',
    renalSevere: 'Avoid if possible; if unavoidable, low dose with '
        'frequent levels under specialist supervision.',
    renalDialysis: 'Generally avoid. Lithium is dialysable; if used, '
        'dose AFTER dialysis with post-session levels.',
    hepaticMild: 'No hepatic adjustment (not hepatically metabolised).',
    hepaticModerate: 'No hepatic adjustment.',
    hepaticSevere: 'No hepatic adjustment.',
  ),
  RenalHepaticEntry(
    drugId: 'paliperidone',
    drugName: 'Paliperidone',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Max ~6 mg/day oral; reduce LAI dose.',
    renalSevere: 'Max ~3 mg/day oral; LAI not recommended.',
    renalDialysis: 'Not recommended — predominantly renally excreted.',
    hepaticMild: 'No adjustment.',
    hepaticModerate: 'No adjustment (limited data).',
    hepaticSevere: 'Not studied — use with caution.',
  ),
  RenalHepaticEntry(
    drugId: 'amisulpride',
    drugName: 'Amisulpride',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Halve the dose; renally excreted, accumulates.',
    renalSevere: 'Reduce to one-third; consider an alternative.',
    renalDialysis: 'Avoid — not removed by dialysis.',
    hepaticMild: 'No adjustment (minimal hepatic metabolism).',
    hepaticModerate: 'No adjustment.',
    hepaticSevere: 'No adjustment.',
  ),
  RenalHepaticEntry(
    drugId: 'sulpiride',
    drugName: 'Sulpiride',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Reduce dose / extend interval (renally cleared).',
    renalSevere: 'Substantial dose reduction; consider alternative.',
    renalDialysis: 'Avoid.',
    hepaticMild: 'No adjustment.',
    hepaticModerate: 'No adjustment.',
    hepaticSevere: 'No adjustment.',
  ),
  RenalHepaticEntry(
    drugId: 'risperidone',
    drugName: 'Risperidone',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Start 0.5 mg BD, titrate slowly (active '
        'metabolite accumulates).',
    renalSevere: 'Start low, slow titration; max ~4 mg/day.',
    renalDialysis: 'Use with caution at low dose.',
    hepaticMild: 'Start 0.5 mg BD.',
    hepaticModerate: 'Start 0.5 mg BD, titrate slowly.',
    hepaticSevere: 'Low dose, slow titration; higher free fraction.',
  ),
  RenalHepaticEntry(
    drugId: 'sertraline',
    drugName: 'Sertraline',
    renalNormal: 'Standard dosing.',
    renalModerate: 'No adjustment (hepatic clearance).',
    renalSevere: 'No specific adjustment; use with caution.',
    renalDialysis: 'No specific adjustment; not dialysed.',
    hepaticMild: 'Use a lower dose or longer dosing interval.',
    hepaticModerate: 'Lower dose / extended interval; monitor.',
    hepaticSevere: 'Avoid / use with great caution — limited data.',
  ),
  RenalHepaticEntry(
    drugId: 'mirtazapine',
    drugName: 'Mirtazapine',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Clearance reduced ~30% — monitor for sedation.',
    renalSevere: 'Clearance reduced ~50% — lower dose.',
    renalDialysis: 'Lower dose; monitor.',
    hepaticMild: 'Clearance reduced — lower dose.',
    hepaticModerate: 'Lower dose; monitor.',
    hepaticSevere: 'Avoid / specialist supervision.',
  ),
  RenalHepaticEntry(
    drugId: 'venlafaxine',
    drugName: 'Venlafaxine',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Reduce dose ~25–50%.',
    renalSevere: 'Reduce dose ~50%.',
    renalDialysis: 'Reduce ~50%; give after dialysis.',
    hepaticMild: 'Reduce dose ~50%.',
    hepaticModerate: 'Reduce dose ≥ 50%.',
    hepaticSevere: 'Avoid / specialist supervision.',
  ),
  RenalHepaticEntry(
    drugId: 'valproate',
    drugName: 'Valproate',
    renalNormal: 'Standard dosing (interpret levels with caution — '
        'free fraction rises in uraemia).',
    renalModerate: 'No specific renal adjustment; monitor clinically '
        'rather than by total level.',
    renalSevere: 'Monitor free valproate where available.',
    renalDialysis: 'Free level monitoring; partially dialysed.',
    hepaticMild: 'Caution — hepatotoxic; monitor LFTs.',
    hepaticModerate: 'Avoid unless essential; intensive LFT '
        'monitoring.',
    hepaticSevere: 'Contraindicated — hepatic failure risk.',
  ),
  RenalHepaticEntry(
    drugId: 'lamotrigine',
    drugName: 'Lamotrigine',
    renalNormal: 'Standard titration.',
    renalModerate: 'No major adjustment; titrate cautiously.',
    renalSevere: 'Reduce maintenance dose; metabolite accumulates.',
    renalDialysis: 'Reduce dose; supplement may be needed post-HD.',
    hepaticMild: 'Reduce dose ~25%.',
    hepaticModerate: 'Reduce dose ~50%.',
    hepaticSevere: 'Reduce dose ~50–75%; slow titration.',
  ),
  RenalHepaticEntry(
    drugId: 'clozapine',
    drugName: 'Clozapine',
    renalNormal: 'Standard titration with mandatory FBC protocol.',
    renalModerate: 'Start low, titrate slowly; no fixed reduction.',
    renalSevere: 'Caution; specialist supervision.',
    renalDialysis: 'Significant caution; not dialysed.',
    hepaticMild: 'Start low; monitor LFTs.',
    hepaticModerate: 'Caution; LFT monitoring.',
    hepaticSevere: 'Avoid — hepatic failure / hepatitis risk.',
  ),
  RenalHepaticEntry(
    drugId: 'olanzapine',
    drugName: 'Olanzapine',
    renalNormal: 'Standard dosing.',
    renalModerate: 'No major adjustment.',
    renalSevere: 'Consider lower starting dose.',
    renalDialysis: 'Not dialysed; standard with monitoring.',
    hepaticMild: 'Consider 5 mg start.',
    hepaticModerate: 'Lower dose; monitor transaminases.',
    hepaticSevere: 'Caution; lower dose.',
  ),
  RenalHepaticEntry(
    drugId: 'haloperidol',
    drugName: 'Haloperidol',
    renalNormal: 'Standard dosing.',
    renalModerate: 'No major renal adjustment.',
    renalSevere: 'Lower dose; caution.',
    renalDialysis: 'Not dialysed; standard with caution.',
    hepaticMild: 'Lower dose.',
    hepaticModerate: 'Lower dose; monitor.',
    hepaticSevere: 'Avoid / specialist supervision.',
  ),
  RenalHepaticEntry(
    drugId: 'lorazepam',
    drugName: 'Lorazepam',
    renalNormal: 'Standard dosing.',
    renalModerate: 'No major adjustment (glucuronidated).',
    renalSevere: 'Lower dose; monitor sedation.',
    renalDialysis: 'Lower dose; partially dialysed.',
    hepaticMild: 'Preferred benzodiazepine — no oxidative '
        'metabolism.',
    hepaticModerate: 'Preferred; standard low dose.',
    hepaticSevere: 'Preferred over diazepam; still use lowest '
        'effective dose.',
  ),
  RenalHepaticEntry(
    drugId: 'oxazepam',
    drugName: 'Oxazepam',
    renalNormal: 'Standard dosing.',
    renalModerate: 'No major adjustment (glucuronidated).',
    renalSevere: 'Lower dose; monitor.',
    renalDialysis: 'Lower dose.',
    hepaticMild: 'Preferred benzodiazepine in liver disease.',
    hepaticModerate: 'Preferred; low dose.',
    hepaticSevere: 'Preferred over long-acting agents; lowest '
        'effective dose.',
  ),
  RenalHepaticEntry(
    drugId: 'gabapentin',
    drugName: 'Gabapentin',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Reduce dose by ~50% (renally excreted unchanged).',
    renalSevere: 'Reduce to ~25%; marked accumulation / sedation '
        'risk.',
    renalDialysis: 'Low dose + supplemental dose after each HD '
        'session.',
    hepaticMild: 'No adjustment (not hepatically metabolised).',
    hepaticModerate: 'No adjustment.',
    hepaticSevere: 'No adjustment.',
  ),
  RenalHepaticEntry(
    drugId: 'pregabalin',
    drugName: 'Pregabalin',
    renalNormal: 'Standard dosing.',
    renalModerate: 'Reduce dose ~50%.',
    renalSevere: 'Reduce dose ~75%.',
    renalDialysis: 'Low dose + supplemental dose post-HD.',
    hepaticMild: 'No adjustment.',
    hepaticModerate: 'No adjustment.',
    hepaticSevere: 'No adjustment.',
  ),
];

RenalHepaticEntry? renalHepaticById(String id) {
  for (final e in kRenalHepaticTable) {
    if (e.drugId == id) return e;
  }
  return null;
}
