// Clinical reference data for once-monthly LAI antipsychotics.
//
// Source: FDA-approved prescribing information from DailyMed (Feb 2025).
//   - Invega Sustenna: Janssen Pharmaceuticals, Inc.
//   - Abilify Maintena: Otsuka America Pharmaceutical, Inc.
//
// Doses for Invega Sustenna are expressed in mg equivalents (mg eq) of
// paliperidone — the convention used in Malaysian labelling.
// FDA PI uses mg of paliperidone palmitate (the prodrug ester);
// conversion: multiply mg eq × 1.56 to get mg PP.
//
// Dart port of engine/depotLai.ts. The three exported records — SUSTENNA,
// TRINZA, MAINTENA — are exposed as top-level `const` instances of the
// corresponding `LaiProtocol` / `TrinzaProtocol` / `MaintenaProtocol`
// classes.

// ── Shared helpers ─────────────────────────────────────────────────────

enum DepotSeverity {
  info('info'),
  warning('warning'),
  danger('danger');

  const DepotSeverity(this.jsonValue);

  final String jsonValue;

  static DepotSeverity fromJson(String value) {
    for (final s in DepotSeverity.values) {
      if (s.jsonValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'unknown DepotSeverity');
  }
}

class DepotInitiationStep {
  const DepotInitiationStep({
    required this.label,
    required this.doseMgEq,
    required this.site,
    this.notes,
  });

  /// Display label e.g. "Day 1", "Day 8 (±4 days)".
  final String label;

  /// Dose in mg eq (paliperidone) or mg (aripiprazole).
  final num doseMgEq;

  final String site;
  final String? notes;
}

class MissedDoseScenario {
  const MissedDoseScenario({
    required this.condition,
    required this.action,
    required this.severity,
  });

  final String condition;
  final String action;
  final DepotSeverity severity;
}

class PaliperidoneRenalAdjustment {
  const PaliperidoneRenalAdjustment({
    required this.category,
    required this.crcl,
    required this.day1,
    required this.day8,
    required this.maintenance,
    required this.max,
  });

  final String category;
  final String crcl;
  final String day1;
  final String day8;
  final String maintenance;
  final String max;
}

class TrinzaRenalAdjustment {
  const TrinzaRenalAdjustment({
    required this.category,
    required this.crcl,
    required this.notes,
  });

  final String category;
  final String crcl;
  final String notes;
}

class NeedleGuide {
  const NeedleGuide({
    required this.site,
    required this.habitus,
    required this.gauge,
    required this.lengthInch,
  });

  final String site;
  final String habitus;
  final String gauge;
  final String lengthInch;
}

class DrugInteractionAdjustment {
  const DrugInteractionAdjustment({
    required this.situation,
    required this.action,
    required this.severity,
  });

  final String situation;
  final String action;
  final DepotSeverity severity;
}

class StrengthEntry {
  const StrengthEntry({
    required this.mgEq,
    required this.mgPP,
    required this.volumeMl,
  });

  final num mgEq;
  final num mgPP;
  final num volumeMl;
}

class MaintenaStrengthEntry {
  const MaintenaStrengthEntry({
    required this.mgAripiprazole,
    required this.formulation,
  });

  final num mgAripiprazole;
  final String formulation;
}

class MaintenanceDoseRange {
  const MaintenanceDoseRange({
    required this.min,
    required this.max,
    this.recommended,
  });

  final num min;
  final num max;
  final num? recommended;
}

class Pp1mToTrinza {
  const Pp1mToTrinza({required this.pp1mMgEq, required this.pp3mMgEq});

  final num pp1mMgEq;
  final num pp3mMgEq;
}

class TrinzaBridgeDose {
  const TrinzaBridgeDose({
    required this.pp3mStrengthMgEq,
    required this.pp1mBridgeMgEq,
  });

  final num pp3mStrengthMgEq;
  final num pp1mBridgeMgEq;
}

class MaintenaInitiationMethod {
  const MaintenaInitiationMethod({
    required this.label,
    required this.injection,
    required this.oral,
    required this.notes,
  });

  final String label;
  final String injection;
  final String oral;
  final String notes;
}

// ── INVEGA SUSTENNA (PP1M) ─────────────────────────────────────────────

class SustennaProtocol {
  const SustennaProtocol({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.activeSubstance,
    required this.indication,
    required this.injectionInterval,
    required this.availableStrengths,
    required this.oralPreTreatment,
    required this.initiationSteps,
    required this.maintenanceDoseRange,
    required this.maintenanceUnit,
    required this.maintenanceWindow,
    required this.needleGuide,
    required this.injectionSiteNote,
    required this.missedDoseInitiation,
    required this.missedDoseMaintenance,
    required this.renalAdjustments,
    required this.keyWarnings,
    required this.citations,
  });

  final String id;
  final String brandName;
  final String genericName;
  final String activeSubstance;
  final String indication;
  final String injectionInterval;
  final List<StrengthEntry> availableStrengths;
  final String oralPreTreatment;
  final List<DepotInitiationStep> initiationSteps;
  final MaintenanceDoseRange maintenanceDoseRange;
  final String maintenanceUnit;
  final String maintenanceWindow;
  final List<NeedleGuide> needleGuide;
  final String injectionSiteNote;
  final List<MissedDoseScenario> missedDoseInitiation;
  final List<MissedDoseScenario> missedDoseMaintenance;
  final List<PaliperidoneRenalAdjustment> renalAdjustments;
  final List<String> keyWarnings;
  final List<String> citations;
}

const SustennaProtocol sustenna = SustennaProtocol(
  id: 'sustenna',
  brandName: 'Invega Sustenna',
  genericName: 'Paliperidone palmitate (PP1M)',
  activeSubstance: 'Paliperidone',
  indication: 'Schizophrenia · Schizoaffective disorder (adults)',
  injectionInterval: 'Once monthly (every 28 days ± 7 days)',
  availableStrengths: <StrengthEntry>[
    StrengthEntry(mgEq: 25, mgPP: 39, volumeMl: 0.25),
    StrengthEntry(mgEq: 50, mgPP: 78, volumeMl: 0.5),
    StrengthEntry(mgEq: 75, mgPP: 117, volumeMl: 0.75),
    StrengthEntry(mgEq: 100, mgPP: 156, volumeMl: 1.0),
    StrengthEntry(mgEq: 150, mgPP: 234, volumeMl: 1.5),
  ],
  oralPreTreatment:
      'Establish tolerability with oral paliperidone or oral risperidone before initiating. '
      'No minimum duration specified — tolerability must be confirmed. Patients already '
      'established on either oral agent may proceed directly to injection.',
  initiationSteps: <DepotInitiationStep>[
    DepotInitiationStep(
      label: 'Day 1',
      doseMgEq: 150,
      site: 'Deltoid ONLY',
      notes:
          'Loading dose. Deltoid administration is mandatory on Day 1 to achieve rapid therapeutic levels.',
    ),
    DepotInitiationStep(
      label: 'Day 8 (±4 days)',
      doseMgEq: 100,
      site: 'Deltoid ONLY',
      notes:
          'Second loading dose. Deltoid mandatory. May be given from Day 4 to Day 12.',
    ),
    DepotInitiationStep(
      label: 'Month 1 onward',
      doseMgEq: 75,
      site: 'Deltoid or gluteal',
      notes:
          'Recommended maintenance dose. Range 25–150 mg eq. Gluteal permitted from first maintenance dose onward. Adjust within range based on clinical response and tolerability.',
    ),
  ],
  maintenanceDoseRange:
      MaintenanceDoseRange(min: 25, recommended: 75, max: 150),
  maintenanceUnit: 'mg eq',
  maintenanceWindow: '±7 days from scheduled monthly date',
  needleGuide: <NeedleGuide>[
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Body weight < 90 kg',
      gauge: '23G',
      lengthInch: '1 inch (25 mm)',
    ),
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Body weight ≥ 90 kg',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
    NeedleGuide(
      site: 'Gluteal',
      habitus: 'All patients',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
  ],
  injectionSiteNote:
      'Deltoid: administer into the central deltoid muscle. Alternate deltoid muscles between injections. '
      'Gluteal: upper-outer quadrant of the gluteal muscle only. '
      'Day 1 and Day 8 MUST be deltoid — gluteal not permitted at initiation.',
  missedDoseInitiation: <MissedDoseScenario>[
    MissedDoseScenario(
      condition: 'Day 8 dose missed: < 4 weeks since Day 1',
      action:
          'Give 100 mg eq deltoid immediately. Then give 75 mg eq deltoid or gluteal at 5 weeks after Day 1 injection. Resume monthly thereafter.',
      severity: DepotSeverity.warning,
    ),
    MissedDoseScenario(
      condition: 'Day 8 dose missed: 4–7 weeks since Day 1',
      action:
          'Give 100 mg eq deltoid immediately. Give 100 mg eq deltoid again 1 week later. Then resume monthly schedule.',
      severity: DepotSeverity.warning,
    ),
    MissedDoseScenario(
      condition: 'Day 8 dose missed: > 7 weeks since Day 1',
      action:
          'Restart full initiation: 150 mg eq deltoid (new Day 1) → 100 mg eq deltoid (Day 8) → resume monthly.',
      severity: DepotSeverity.danger,
    ),
  ],
  missedDoseMaintenance: <MissedDoseScenario>[
    MissedDoseScenario(
      condition: '> 4 weeks to ≤ 6 weeks since last injection',
      action:
          'Administer the previously stabilised dose as soon as possible. Resume monthly schedule.',
      severity: DepotSeverity.info,
    ),
    MissedDoseScenario(
      condition: '> 6 weeks to ≤ 6 months since last injection',
      action:
          'Give previously stabilised dose in deltoid immediately. Repeat the same dose in deltoid 1 week later. Then resume monthly schedule.',
      severity: DepotSeverity.warning,
    ),
    MissedDoseScenario(
      condition: '> 6 months since last injection',
      action:
          'Restart full initiation regimen: 150 mg eq deltoid (Day 1) → 100 mg eq deltoid (Day 8) → resume monthly.',
      severity: DepotSeverity.danger,
    ),
  ],
  renalAdjustments: <PaliperidoneRenalAdjustment>[
    PaliperidoneRenalAdjustment(
      category: 'Normal renal function',
      crcl: '≥ 80 mL/min',
      day1: '150 mg eq',
      day8: '100 mg eq',
      maintenance: '75 mg eq',
      max: '150 mg eq',
    ),
    PaliperidoneRenalAdjustment(
      category: 'Mild impairment',
      crcl: '50 to < 80 mL/min',
      day1: '100 mg eq',
      day8: '75 mg eq',
      maintenance: '50 mg eq',
      max: '100 mg eq',
    ),
    PaliperidoneRenalAdjustment(
      category: 'Moderate / severe impairment',
      crcl: '< 50 mL/min',
      day1: 'CONTRAINDICATED',
      day8: 'CONTRAINDICATED',
      maintenance: 'CONTRAINDICATED',
      max: 'Not recommended',
    ),
  ],
  keyWarnings: <String>[
    'Extended exposure: paliperidone detectable in plasma up to 126 days after a single injection — ADRs and interactions persist long after discontinuation.',
    'No rapid reversal: the prolonged-release formulation cannot be removed. Overdose or serious ADRs require prolonged supportive care.',
    'QTc prolongation: avoid co-administration with other QTc-prolonging drugs.',
    'Hyperprolactinaemia: persistent; may cause amenorrhoea, galactorrhoea, gynaecomastia, reduced bone density.',
    "NMS and tardive dyskinesia: management complicated by depot's prolonged release.",
    'Orthostatic hypotension: monitor particularly at initiation.',
    'Metabolic effects: weight gain, hyperglycaemia, dyslipidaemia — baseline and monitoring required.',
  ],
  citations: <String>[
    'Invega Sustenna (paliperidone palmitate) — FDA Prescribing Information. Janssen Pharmaceuticals, Inc. DailyMed, February 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
  ],
);

// ── INVEGA TRINZA (PP3M) ────────────────────────────────────────────────

class TrinzaProtocol {
  const TrinzaProtocol({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.activeSubstance,
    required this.indication,
    required this.injectionInterval,
    required this.availableStrengths,
    required this.eligibilityCriteria,
    required this.pp1mToTrinzaConversion,
    required this.firstDoseTiming,
    required this.maintenanceDoseRange,
    required this.maintenanceUnit,
    required this.maintenanceWindow,
    required this.needleGuide,
    required this.injectionSiteNote,
    required this.missedDoseScenarios,
    required this.pp1mBridgeTable,
    required this.renalAdjustments,
    required this.pkNotes,
    required this.keyWarnings,
    required this.citations,
  });

  final String id;
  final String brandName;
  final String genericName;
  final String activeSubstance;
  final String indication;
  final String injectionInterval;
  final List<StrengthEntry> availableStrengths;
  final List<String> eligibilityCriteria;
  final List<Pp1mToTrinza> pp1mToTrinzaConversion;
  final String firstDoseTiming;
  final MaintenanceDoseRange maintenanceDoseRange;
  final String maintenanceUnit;
  final String maintenanceWindow;
  final List<NeedleGuide> needleGuide;
  final String injectionSiteNote;
  final List<MissedDoseScenario> missedDoseScenarios;
  final List<TrinzaBridgeDose> pp1mBridgeTable;
  final List<TrinzaRenalAdjustment> renalAdjustments;
  final List<String> pkNotes;
  final List<String> keyWarnings;
  final List<String> citations;
}

const TrinzaProtocol trinza = TrinzaProtocol(
  id: 'trinza',
  brandName: 'Invega Trinza',
  genericName: 'Paliperidone palmitate (PP3M)',
  activeSubstance: 'Paliperidone',
  indication:
      'Schizophrenia (adults) — maintenance after ≥ 4 months stable on PP1M',
  injectionInterval: 'Once every 3 months (±2 weeks window)',
  availableStrengths: <StrengthEntry>[
    StrengthEntry(mgEq: 175, mgPP: 273, volumeMl: 0.875),
    StrengthEntry(mgEq: 263, mgPP: 410, volumeMl: 1.315),
    StrengthEntry(mgEq: 350, mgPP: 546, volumeMl: 1.75),
    StrengthEntry(mgEq: 525, mgPP: 819, volumeMl: 2.625),
  ],
  eligibilityCriteria: <String>[
    'Patient must be adequately treated with PP1M (Invega Sustenna) for ≥ 4 months.',
    'The last two consecutive PP1M injections must be the SAME strength before conversion.',
    'PP1M 25 mg eq (39 mg PP) dose has NOT been studied with PP3M — do not switch from 25 mg eq.',
    'Clinically stable on PP1M at time of conversion.',
  ],
  pp1mToTrinzaConversion: <Pp1mToTrinza>[
    Pp1mToTrinza(pp1mMgEq: 50, pp3mMgEq: 175),
    Pp1mToTrinza(pp1mMgEq: 75, pp3mMgEq: 263),
    Pp1mToTrinza(pp1mMgEq: 100, pp3mMgEq: 350),
    Pp1mToTrinza(pp1mMgEq: 150, pp3mMgEq: 525),
  ],
  firstDoseTiming:
      'Give the first Trinza injection where and when the next Invega Sustenna '
      '(PP1M) dose would have been due. A ±7-day window applies.',
  maintenanceDoseRange: MaintenanceDoseRange(min: 175, max: 525),
  maintenanceUnit: 'mg eq',
  maintenanceWindow: '±2 weeks from scheduled quarterly date',
  needleGuide: <NeedleGuide>[
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Body weight < 90 kg',
      gauge: '22G',
      lengthInch: '1 inch (25 mm)',
    ),
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Body weight ≥ 90 kg',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
    NeedleGuide(
      site: 'Gluteal',
      habitus: 'All patients',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
  ],
  injectionSiteNote:
      'Use TRINZA-specific needles — do NOT use Invega Sustenna needles. '
      'Shake the syringe vigorously for at least 15 seconds within 5 minutes of administration to ensure uniform suspension. '
      'Deltoid or gluteal site is equally acceptable. Alternate deltoid sites between injections.',
  missedDoseScenarios: <MissedDoseScenario>[
    MissedDoseScenario(
      condition: '> 3.5 months to < 4 months since last PP3M injection',
      action:
          'Give Trinza (PP3M) injection immediately at the previously stabilised dose. Resume the every-3-month schedule.',
      severity: DepotSeverity.warning,
    ),
    MissedDoseScenario(
      condition: '4 months to ≤ 9 months since last PP3M injection',
      action:
          'Do NOT give PP3M yet. Give Invega Sustenna (PP1M) as a bridge: inject the corresponding PP1M dose (see bridge table below) on Day 1 and again on Day 8. Then re-establish on PP1M for ≥ 4 months with the last two doses the same strength before resuming PP3M.',
      severity: DepotSeverity.danger,
    ),
    MissedDoseScenario(
      condition: '> 9 months since last PP3M injection',
      action:
          'Full PP1M reinitiation required: 150 mg eq deltoid on Day 1, 100 mg eq deltoid on Day 8, then monthly maintenance. Stabilise for ≥ 4 months with last two consecutive doses the same strength before transitioning back to PP3M.',
      severity: DepotSeverity.danger,
    ),
  ],
  pp1mBridgeTable: <TrinzaBridgeDose>[
    TrinzaBridgeDose(pp3mStrengthMgEq: 175, pp1mBridgeMgEq: 50),
    TrinzaBridgeDose(pp3mStrengthMgEq: 263, pp1mBridgeMgEq: 75),
    TrinzaBridgeDose(pp3mStrengthMgEq: 350, pp1mBridgeMgEq: 100),
    // FDA PI: 156 mg PP (= 100 mg eq), NOT 234 mg PP — see errata.
    TrinzaBridgeDose(pp3mStrengthMgEq: 525, pp1mBridgeMgEq: 100),
  ],
  renalAdjustments: <TrinzaRenalAdjustment>[
    TrinzaRenalAdjustment(
      category: 'Normal renal function',
      crcl: '≥ 80 mL/min',
      notes:
          'Standard PP3M dose following standard PP1M → PP3M conversion table.',
    ),
    TrinzaRenalAdjustment(
      category: 'Mild renal impairment',
      crcl: '50 to < 80 mL/min',
      notes:
          'Must first be established and stabilised on PP1M using the mild-impairment protocol (Day 1: 100 mg eq, Day 8: 75 mg eq, maintenance: 50 mg eq). Once stable, may transition to PP3M using the conversion table from the mild PP1M maintenance dose.',
    ),
    TrinzaRenalAdjustment(
      category: 'Moderate / severe renal impairment',
      crcl: '< 50 mL/min',
      notes:
          'NOT RECOMMENDED. Same contraindication as PP1M — paliperidone is primarily renally cleared and will accumulate. Do not initiate or continue.',
    ),
  ],
  pkNotes: <String>[
    'Apparent t½: 84–95 days after a single PP3M injection.',
    'Steady-state reached after ≥ 4 months of quarterly dosing.',
    'Paliperidone is renally eliminated — no significant hepatic metabolism.',
    'Paliperidone is 9-OH-risperidone (the active metabolite of risperidone); PP3M pharmacology is identical to oral paliperidone and PP1M, only the release rate differs.',
  ],
  keyWarnings: <String>[
    'PP3M is not appropriate for initial treatment — patient must be stable on PP1M (Invega Sustenna) for ≥ 4 months first.',
    'Last TWO consecutive PP1M doses must be the SAME strength before switching — different last two doses means conversion dose is uncertain.',
    'Very long t½ (~84–95 days): adverse effects and drug interactions may persist for months after last injection.',
    'Shake vigorously ≥ 15 seconds — inadequate shaking results in underdose from incomplete suspension.',
    'Use Trinza-specific needles — NOT interchangeable with Invega Sustenna needles.',
    'Renal impairment (CrCl < 50 mL/min): NOT recommended — same restriction as PP1M.',
    'Prolactinaemia, QTc prolongation, metabolic effects, NMS, tardive dyskinesia: same risk profile as PP1M with the added complexity of even longer duration of action.',
  ],
  citations: <String>[
    'Invega Trinza (paliperidone palmitate) — FDA Prescribing Information. Janssen Pharmaceuticals, Inc. DailyMed, 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
    'Berwaerts J et al. J Clin Psychiatry 2015;76:1–13 (PP3M pivotal trial).',
  ],
);

// ── ABILIFY MAINTENA ────────────────────────────────────────────────────

class MaintenaInitiationMethods {
  const MaintenaInitiationMethods({
    required this.fourteenDay,
    required this.oneDay,
  });

  final MaintenaInitiationMethod fourteenDay;
  final MaintenaInitiationMethod oneDay;
}

class MaintenaProtocol {
  const MaintenaProtocol({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.activeSubstance,
    required this.indication,
    required this.injectionInterval,
    required this.availableStrengths,
    required this.oralPreTreatment,
    required this.initiationMethods,
    required this.initiationSteps,
    required this.maintenanceDoseRange,
    required this.maintenanceUnit,
    required this.maintenanceWindow,
    required this.needleGuide,
    required this.injectionSiteNote,
    required this.missedDoseSecondThird,
    required this.missedDoseFourthOnward,
    required this.drugInteractions,
    required this.renalNote,
    required this.hepaticNote,
    required this.pkNotes,
    required this.keyWarnings,
    required this.citations,
  });

  final String id;
  final String brandName;
  final String genericName;
  final String activeSubstance;
  final String indication;
  final String injectionInterval;
  final List<MaintenaStrengthEntry> availableStrengths;
  final String oralPreTreatment;
  final MaintenaInitiationMethods initiationMethods;
  final List<DepotInitiationStep> initiationSteps;
  final MaintenanceDoseRange maintenanceDoseRange;
  final String maintenanceUnit;
  final String maintenanceWindow;
  final List<NeedleGuide> needleGuide;
  final String injectionSiteNote;
  final List<MissedDoseScenario> missedDoseSecondThird;
  final List<MissedDoseScenario> missedDoseFourthOnward;
  final List<DrugInteractionAdjustment> drugInteractions;
  final String renalNote;
  final String hepaticNote;
  final List<String> pkNotes;
  final List<String> keyWarnings;
  final List<String> citations;
}

const MaintenaProtocol maintena = MaintenaProtocol(
  id: 'maintena',
  brandName: 'Abilify Maintena',
  genericName: 'Aripiprazole monohydrate (extended-release)',
  activeSubstance: 'Aripiprazole',
  indication:
      'Schizophrenia · Bipolar I disorder maintenance monotherapy (adults)',
  injectionInterval:
      'Once monthly (no sooner than 26 days after prior injection)',
  availableStrengths: <MaintenaStrengthEntry>[
    MaintenaStrengthEntry(
      mgAripiprazole: 300,
      formulation: 'Single-dose vial (lyophilised) or prefilled syringe',
    ),
    MaintenaStrengthEntry(
      mgAripiprazole: 400,
      formulation: 'Single-dose vial (lyophilised) or prefilled syringe',
    ),
  ],
  oralPreTreatment:
      'Must establish tolerability with oral aripiprazole before initiating in patients naive to aripiprazole. '
      'Two initiation methods — see below.',
  initiationMethods: MaintenaInitiationMethods(
    fourteenDay: MaintenaInitiationMethod(
      label: '14-day oral overlap (standard)',
      injection: '400 mg IM on Day 1',
      oral: 'Oral aripiprazole 10–20 mg daily for 14 consecutive days',
      notes:
          'Give the 400 mg injection and start oral on the same day. Continue oral for 14 days only — do not extend. Alternatively, if patient is already stabilised on another oral antipsychotic, that agent may be continued for the 14-day period instead.',
    ),
    oneDay: MaintenaInitiationMethod(
      label: '1-day initiation (two injections)',
      injection:
          '800 mg total: two separate 400 mg IM injections into two different sites simultaneously',
      oral: 'Oral aripiprazole 20 mg on Day 1 only (single dose)',
      notes:
          'The two injections must be given into two different muscles (deltoid + gluteal, or two gluteal sites — not same muscle twice). This method establishes therapeutic levels faster but requires two injections at once.',
    ),
  ),
  initiationSteps: <DepotInitiationStep>[
    DepotInitiationStep(
      label: 'Day 1',
      doseMgEq: 400,
      site: 'Deltoid or gluteal',
      notes:
          '14-day method: single 400 mg + oral aripiprazole 10–20 mg/day for 14 days. 1-day method: 400 mg × 2 sites + oral 20 mg once only.',
    ),
    DepotInitiationStep(
      label: 'Month 1 onward',
      doseMgEq: 400,
      site: 'Deltoid or gluteal',
      notes:
          'Standard maintenance dose. Reduce to 300 mg if tolerability issues or CYP2D6 poor metaboliser.',
    ),
  ],
  maintenanceDoseRange:
      MaintenanceDoseRange(min: 300, recommended: 400, max: 400),
  maintenanceUnit: 'mg',
  maintenanceWindow: 'No sooner than 26 days after prior injection',
  needleGuide: <NeedleGuide>[
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Non-obese',
      gauge: '23G',
      lengthInch: '1 inch (25 mm)',
    ),
    NeedleGuide(
      site: 'Deltoid',
      habitus: 'Obese',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
    NeedleGuide(
      site: 'Gluteal',
      habitus: 'Non-obese',
      gauge: '22G',
      lengthInch: '1.5 inch (38 mm)',
    ),
    NeedleGuide(
      site: 'Gluteal',
      habitus: 'Obese',
      gauge: '21G',
      lengthInch: '2 inch (51 mm)',
    ),
  ],
  injectionSiteNote:
      'Deltoid or gluteal equally acceptable from Day 1. Do NOT massage the injection site after administration — can alter release kinetics. No post-injection observation period required (unlike olanzapine pamoate).',
  missedDoseSecondThird: <MissedDoseScenario>[
    MissedDoseScenario(
      condition:
          '> 4 weeks to < 5 weeks since last injection (2nd or 3rd dose)',
      action:
          'Administer injection as soon as possible. Resume monthly schedule.',
      severity: DepotSeverity.info,
    ),
    MissedDoseScenario(
      condition: '≥ 5 weeks since last injection (2nd or 3rd dose)',
      action:
          'Restart treatment using either the 14-day or 1-day initiation protocol.',
      severity: DepotSeverity.danger,
    ),
  ],
  missedDoseFourthOnward: <MissedDoseScenario>[
    MissedDoseScenario(
      condition:
          '> 4 weeks to < 6 weeks since last injection (4th dose onward)',
      action:
          'Administer injection as soon as possible. Resume monthly schedule.',
      severity: DepotSeverity.info,
    ),
    MissedDoseScenario(
      condition: '≥ 6 weeks since last injection (4th dose onward)',
      action:
          'Restart treatment using either the 14-day or 1-day initiation protocol.',
      severity: DepotSeverity.danger,
    ),
  ],
  drugInteractions: <DrugInteractionAdjustment>[
    DrugInteractionAdjustment(
      situation: 'CYP2D6 poor metaboliser',
      action: 'Reduce to 300 mg monthly.',
      severity: DepotSeverity.warning,
    ),
    DrugInteractionAdjustment(
      situation:
          'Strong CYP2D6 inhibitor (> 14 days) — e.g. fluoxetine, paroxetine',
      action: 'Reduce to 300 mg monthly.',
      severity: DepotSeverity.warning,
    ),
    DrugInteractionAdjustment(
      situation:
          'Strong CYP3A4 inhibitor (> 14 days) — e.g. itraconazole, clarithromycin',
      action: 'Reduce to 300 mg monthly.',
      severity: DepotSeverity.warning,
    ),
    DrugInteractionAdjustment(
      situation: 'Strong CYP2D6 AND CYP3A4 inhibitor combined',
      action:
          'Avoid combination. If unavoidable, use with caution — exposure substantially increased. Consider oral aripiprazole instead.',
      severity: DepotSeverity.danger,
    ),
    DrugInteractionAdjustment(
      situation:
          'Strong CYP3A4 inducer (> 14 days) — e.g. carbamazepine, rifampicin',
      action:
          'AVOID concomitant use for > 14 days. No adequate dose alternative — exposure reduced too substantially for reliable therapeutic effect.',
      severity: DepotSeverity.danger,
    ),
  ],
  renalNote: 'No dose adjustment required for renal impairment (FDA PI).',
  hepaticNote: 'No dose adjustment required for hepatic impairment (FDA PI).',
  pkNotes: <String>[
    'Single-dose apparent t½: ~17.8 days (deltoid) / ~21 days (gluteal).',
    'Steady-state t½ after multiple gluteal doses: 29.9–46.5 days (dose-dependent).',
    'No post-injection observation period required (no PIOS documented, unlike olanzapine pamoate).',
  ],
  keyWarnings: <String>[
    'Extended half-life (~30–46 days at steady state): adverse effects persist well after discontinuation — prolonged supportive management may be needed.',
    'Do NOT massage the injection site — can alter release kinetics.',
    'Akathisia: most common neurological adverse reaction — counsel patients before initiation.',
    'Metabolic effects: weight gain (most common ADR), hyperglycaemia, dyslipidaemia — baseline and monitoring required.',
    'Orthostatic hypotension: monitor at initiation.',
    'NMS and tardive dyskinesia: management complicated by extended release.',
    'Carbamazepine interaction: avoid co-prescription for > 14 days — substantially lowers aripiprazole levels without adequate dose solution.',
  ],
  citations: <String>[
    'Abilify Maintena (aripiprazole) — FDA Prescribing Information. Otsuka America Pharmaceutical, Inc. DailyMed, 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
  ],
);
