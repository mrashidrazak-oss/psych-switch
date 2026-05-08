// Clinical reference data for once-monthly LAI antipsychotics.
// Source: FDA-approved prescribing information from DailyMed (Feb 2025).
//   - Invega Sustenna: Janssen Pharmaceuticals, Inc.
//   - Abilify Maintena: Otsuka America Pharmaceutical, Inc.
//
// Doses for Invega Sustenna are expressed in mg equivalents (mg eq) of
// paliperidone — the convention used in Malaysian / ASEAN labelling.
// The FDA PI uses mg of paliperidone palmitate (the prodrug ester);
// conversion: multiply mg eq × 1.56 to get mg PP.
//   25 mg eq = 39 mg PP
//   50 mg eq = 78 mg PP
//   75 mg eq = 117 mg PP
//  100 mg eq = 156 mg PP
//  150 mg eq = 234 mg PP

export interface DepotInitiationStep {
  label: string;       // e.g. "Day 1", "Day 8 (±4 days)"
  doseMgEq: number;    // dose in mg eq (paliperidone) or mg (aripiprazole)
  site: string;        // injection site instruction
  notes?: string;
}

export interface MissedDoseScenario {
  condition: string;   // e.g. "4–6 weeks since last injection"
  action: string;      // what to do
  severity: 'info' | 'warning' | 'danger';
}

export interface RenalAdjustment {
  category: string;    // e.g. "Normal (CrCl ≥ 80 mL/min)"
  crcl: string;        // threshold text
  day1: string;
  day8: string;
  maintenance: string;
  max: string;
}

export interface NeedleGuide {
  site: string;
  habitus: string;
  gauge: string;
  lengthInch: string;
}

export interface DrugInteractionAdjustment {
  situation: string;
  action: string;
  severity: 'info' | 'warning' | 'danger';
}

// ── INVEGA SUSTENNA (Paliperidone Palmitate PP1M) ─────────────────────────────

export const SUSTENNA = {
  id: 'sustenna',
  brandName: 'Invega Sustenna',
  genericName: 'Paliperidone palmitate (PP1M)',
  activeSubstance: 'Paliperidone',
  indication: 'Schizophrenia · Schizoaffective disorder (adults)',
  injectionInterval: 'Once monthly (every 28 days ± 7 days)',

  availableStrengths: [
    { mgEq: 25, mgPP: 39, volumeMl: 0.25 },
    { mgEq: 50, mgPP: 78, volumeMl: 0.5 },
    { mgEq: 75, mgPP: 117, volumeMl: 0.75 },
    { mgEq: 100, mgPP: 156, volumeMl: 1.0 },
    { mgEq: 150, mgPP: 234, volumeMl: 1.5 },
  ],

  oralPreTreatment:
    'Establish tolerability with oral paliperidone or oral risperidone before initiating. ' +
    'No minimum duration specified — tolerability must be confirmed. Patients already ' +
    'established on either oral agent may proceed directly to injection.',

  initiationSteps: [
    {
      label: 'Day 1',
      doseMgEq: 150,
      site: 'Deltoid ONLY',
      notes: 'Loading dose. Deltoid administration is mandatory on Day 1 to achieve rapid therapeutic levels.',
    },
    {
      label: 'Day 8 (±4 days)',
      doseMgEq: 100,
      site: 'Deltoid ONLY',
      notes: 'Second loading dose. Deltoid mandatory. May be given from Day 4 to Day 12.',
    },
    {
      label: 'Month 1 onward',
      doseMgEq: 75,
      site: 'Deltoid or gluteal',
      notes: 'Recommended maintenance dose. Range 25–150 mg eq. Gluteal permitted from first maintenance dose onward. Adjust within range based on clinical response and tolerability.',
    },
  ] as DepotInitiationStep[],

  maintenanceDoseRange: { min: 25, recommended: 75, max: 150 },
  maintenanceUnit: 'mg eq',
  maintenanceWindow: '±7 days from scheduled monthly date',

  needleGuide: [
    { site: 'Deltoid', habitus: 'Body weight < 90 kg', gauge: '23G', lengthInch: '1 inch (25 mm)' },
    { site: 'Deltoid', habitus: 'Body weight ≥ 90 kg', gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
    { site: 'Gluteal', habitus: 'All patients', gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
  ] as NeedleGuide[],

  injectionSiteNote:
    'Deltoid: administer into the central deltoid muscle. Alternate deltoid muscles between injections. ' +
    'Gluteal: upper-outer quadrant of the gluteal muscle only. ' +
    'Day 1 and Day 8 MUST be deltoid — gluteal not permitted at initiation.',

  missedDoseInitiation: [
    {
      condition: 'Day 8 dose missed: < 4 weeks since Day 1',
      action: 'Give 100 mg eq deltoid immediately. Then give 75 mg eq deltoid or gluteal at 5 weeks after Day 1 injection. Resume monthly thereafter.',
      severity: 'warning',
    },
    {
      condition: 'Day 8 dose missed: 4–7 weeks since Day 1',
      action: 'Give 100 mg eq deltoid immediately. Give 100 mg eq deltoid again 1 week later. Then resume monthly schedule.',
      severity: 'warning',
    },
    {
      condition: 'Day 8 dose missed: > 7 weeks since Day 1',
      action: 'Restart full initiation: 150 mg eq deltoid (new Day 1) → 100 mg eq deltoid (Day 8) → resume monthly.',
      severity: 'danger',
    },
  ] as MissedDoseScenario[],

  missedDoseMaintenance: [
    {
      condition: '> 4 weeks to ≤ 6 weeks since last injection',
      action: 'Administer the previously stabilised dose as soon as possible. Resume monthly schedule.',
      severity: 'info',
    },
    {
      condition: '> 6 weeks to ≤ 6 months since last injection',
      action: 'Give previously stabilised dose in deltoid immediately. Repeat the same dose in deltoid 1 week later. Then resume monthly schedule.',
      severity: 'warning',
    },
    {
      condition: '> 6 months since last injection',
      action: 'Restart full initiation regimen: 150 mg eq deltoid (Day 1) → 100 mg eq deltoid (Day 8) → resume monthly.',
      severity: 'danger',
    },
  ] as MissedDoseScenario[],

  renalAdjustments: [
    {
      category: 'Normal renal function',
      crcl: '≥ 80 mL/min',
      day1: '150 mg eq',
      day8: '100 mg eq',
      maintenance: '75 mg eq',
      max: '150 mg eq',
    },
    {
      category: 'Mild impairment',
      crcl: '50 to < 80 mL/min',
      day1: '100 mg eq',
      day8: '75 mg eq',
      maintenance: '50 mg eq',
      max: '100 mg eq',
    },
    {
      category: 'Moderate / severe impairment',
      crcl: '< 50 mL/min',
      day1: 'CONTRAINDICATED',
      day8: 'CONTRAINDICATED',
      maintenance: 'CONTRAINDICATED',
      max: 'Not recommended',
    },
  ] as RenalAdjustment[],

  keyWarnings: [
    'Extended exposure: paliperidone detectable in plasma up to 126 days after a single injection — ADRs and interactions persist long after discontinuation.',
    'No rapid reversal: the prolonged-release formulation cannot be removed. Overdose or serious ADRs require prolonged supportive care.',
    'QTc prolongation: avoid co-administration with other QTc-prolonging drugs.',
    'Hyperprolactinaemia: persistent; may cause amenorrhoea, galactorrhoea, gynaecomastia, reduced bone density.',
    'NMS and tardive dyskinesia: management complicated by depot\'s prolonged release.',
    'Orthostatic hypotension: monitor particularly at initiation.',
    'Metabolic effects: weight gain, hyperglycaemia, dyslipidaemia — baseline and monitoring required.',
  ],

  citations: [
    'Invega Sustenna (paliperidone palmitate) — FDA Prescribing Information. Janssen Pharmaceuticals, Inc. DailyMed, February 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
  ],
} as const;

// ── INVEGA TRINZA (Paliperidone Palmitate PP3M) ───────────────────────────────

export interface TrinzaBridgeDose {
  pp3mStrengthMgEq: number;   // PP3M dose patient was on
  pp1mBridgeMgEq: number;     // PP1M dose to give on Day 1 and Day 8 of bridge
}

export const TRINZA = {
  id: 'trinza',
  brandName: 'Invega Trinza',
  genericName: 'Paliperidone palmitate (PP3M)',
  activeSubstance: 'Paliperidone',
  indication: 'Schizophrenia (adults) — maintenance after ≥ 4 months stable on PP1M',
  injectionInterval: 'Once every 3 months (±2 weeks window)',

  // All 4 strengths in mg eq (paliperidone) — FDA PI uses mg PP
  // mg eq × 1.56 = mg PP (same conversion as PP1M)
  availableStrengths: [
    { mgEq: 175, mgPP: 273, volumeMl: 0.875 },
    { mgEq: 263, mgPP: 410, volumeMl: 1.315 },
    { mgEq: 350, mgPP: 546, volumeMl: 1.75  },
    { mgEq: 525, mgPP: 819, volumeMl: 2.625 },
  ],

  // Eligibility criteria before switching from PP1M to PP3M
  eligibilityCriteria: [
    'Patient must be adequately treated with PP1M (Invega Sustenna) for ≥ 4 months.',
    'The last two consecutive PP1M injections must be the SAME strength before conversion.',
    'PP1M 25 mg eq (39 mg PP) dose has NOT been studied with PP3M — do not switch from 25 mg eq.',
    'Clinically stable on PP1M at time of conversion.',
  ],

  // PP1M → PP3M dose conversion table
  pp1mToTrinzaConversion: [
    { pp1mMgEq: 50,  pp3mMgEq: 175 },
    { pp1mMgEq: 75,  pp3mMgEq: 263 },
    { pp1mMgEq: 100, pp3mMgEq: 350 },
    { pp1mMgEq: 150, pp3mMgEq: 525 },
  ] as { pp1mMgEq: number; pp3mMgEq: number }[],

  // When to give first PP3M dose
  firstDoseTiming:
    'Give the first Trinza injection where and when the next Invega Sustenna ' +
    '(PP1M) dose would have been due. A ±7-day window applies.',

  maintenanceDoseRange: { min: 175, max: 525 },
  maintenanceUnit: 'mg eq',
  maintenanceWindow: '±2 weeks from scheduled quarterly date',

  // Needle selection — PP3M uses its own needles (NOT interchangeable with Sustenna)
  needleGuide: [
    { site: 'Deltoid', habitus: 'Body weight < 90 kg', gauge: '22G', lengthInch: '1 inch (25 mm)' },
    { site: 'Deltoid', habitus: 'Body weight ≥ 90 kg', gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
    { site: 'Gluteal', habitus: 'All patients',        gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
  ] as NeedleGuide[],

  injectionSiteNote:
    'Use TRINZA-specific needles — do NOT use Invega Sustenna needles. ' +
    'Shake the syringe vigorously for at least 15 seconds within 5 minutes of administration to ensure uniform suspension. ' +
    'Deltoid or gluteal site is equally acceptable. Alternate deltoid sites between injections.',

  // Missed dose — 3-tier algorithm
  missedDoseScenarios: [
    {
      condition: '> 3.5 months to < 4 months since last PP3M injection',
      action: 'Give Trinza (PP3M) injection immediately at the previously stabilised dose. Resume the every-3-month schedule.',
      severity: 'warning' as const,
    },
    {
      condition: '4 months to ≤ 9 months since last PP3M injection',
      action: 'Do NOT give PP3M yet. Give Invega Sustenna (PP1M) as a bridge: inject the corresponding PP1M dose (see bridge table below) on Day 1 and again on Day 8. Then re-establish on PP1M for ≥ 4 months with the last two doses the same strength before resuming PP3M.',
      severity: 'danger' as const,
    },
    {
      condition: '> 9 months since last PP3M injection',
      action: 'Full PP1M reinitiation required: 150 mg eq deltoid on Day 1, 100 mg eq deltoid on Day 8, then monthly maintenance. Stabilise for ≥ 4 months with last two consecutive doses the same strength before transitioning back to PP3M.',
      severity: 'danger' as const,
    },
  ] as MissedDoseScenario[],

  // PP1M bridge doses for the 4–9 month missed-dose window
  pp1mBridgeTable: [
    { pp3mStrengthMgEq: 175, pp1mBridgeMgEq: 50  },
    { pp3mStrengthMgEq: 263, pp1mBridgeMgEq: 75  },
    { pp3mStrengthMgEq: 350, pp1mBridgeMgEq: 100 },
    { pp3mStrengthMgEq: 525, pp1mBridgeMgEq: 100 }, // FDA PI: 156 mg PP (= 100 mg eq), NOT 234 mg PP
  ] as TrinzaBridgeDose[],

  // Renal — same restrictions as PP1M (paliperidone is renally cleared)
  renalAdjustments: [
    {
      category: 'Normal renal function',
      crcl: '≥ 80 mL/min',
      notes: 'Standard PP3M dose following standard PP1M → PP3M conversion table.',
    },
    {
      category: 'Mild renal impairment',
      crcl: '50 to < 80 mL/min',
      notes: 'Must first be established and stabilised on PP1M using the mild-impairment protocol (Day 1: 100 mg eq, Day 8: 75 mg eq, maintenance: 50 mg eq). Once stable, may transition to PP3M using the conversion table from the mild PP1M maintenance dose.',
    },
    {
      category: 'Moderate / severe renal impairment',
      crcl: '< 50 mL/min',
      notes: 'NOT RECOMMENDED. Same contraindication as PP1M — paliperidone is primarily renally cleared and will accumulate. Do not initiate or continue.',
    },
  ] as { category: string; crcl: string; notes: string }[],

  pkNotes: [
    'Apparent t½: 84–95 days after a single PP3M injection.',
    'Steady-state reached after ≥ 4 months of quarterly dosing.',
    'Paliperidone is renally eliminated — no significant hepatic metabolism.',
    'Paliperidone is 9-OH-risperidone (the active metabolite of risperidone); PP3M pharmacology is identical to oral paliperidone and PP1M, only the release rate differs.',
  ],

  keyWarnings: [
    'PP3M is not appropriate for initial treatment — patient must be stable on PP1M (Invega Sustenna) for ≥ 4 months first.',
    'Last TWO consecutive PP1M doses must be the SAME strength before switching — different last two doses means conversion dose is uncertain.',
    'Very long t½ (~84–95 days): adverse effects and drug interactions may persist for months after last injection.',
    'Shake vigorously ≥ 15 seconds — inadequate shaking results in underdose from incomplete suspension.',
    'Use Trinza-specific needles — NOT interchangeable with Invega Sustenna needles.',
    'Renal impairment (CrCl < 50 mL/min): NOT recommended — same restriction as PP1M.',
    'Prolactinaemia, QTc prolongation, metabolic effects, NMS, tardive dyskinesia: same risk profile as PP1M with the added complexity of even longer duration of action.',
  ],

  citations: [
    'Invega Trinza (paliperidone palmitate) — FDA Prescribing Information. Janssen Pharmaceuticals, Inc. DailyMed, 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
    'Berwaerts J et al. J Clin Psychiatry 2015;76:1–13 (PP3M pivotal trial).',
  ],
} as const;

// ── ABILIFY MAINTENA (Aripiprazole Monohydrate ER) ────────────────────────────

export const MAINTENA = {
  id: 'maintena',
  brandName: 'Abilify Maintena',
  genericName: 'Aripiprazole monohydrate (extended-release)',
  activeSubstance: 'Aripiprazole',
  indication: 'Schizophrenia · Bipolar I disorder maintenance monotherapy (adults)',
  injectionInterval: 'Once monthly (no sooner than 26 days after prior injection)',

  availableStrengths: [
    { mgAripiprazole: 300, formulation: 'Single-dose vial (lyophilised) or prefilled syringe' },
    { mgAripiprazole: 400, formulation: 'Single-dose vial (lyophilised) or prefilled syringe' },
  ],

  oralPreTreatment:
    'Must establish tolerability with oral aripiprazole before initiating in patients naive to aripiprazole. ' +
    'Two initiation methods — see below.',

  initiationMethods: {
    fourteenDay: {
      label: '14-day oral overlap (standard)',
      injection: '400 mg IM on Day 1',
      oral: 'Oral aripiprazole 10–20 mg daily for 14 consecutive days',
      notes:
        'Give the 400 mg injection and start oral on the same day. Continue oral for 14 days only — do not extend. Alternatively, if patient is already stabilised on another oral antipsychotic, that agent may be continued for the 14-day period instead.',
    },
    oneDay: {
      label: '1-day initiation (two injections)',
      injection: '800 mg total: two separate 400 mg IM injections into two different sites simultaneously',
      oral: 'Oral aripiprazole 20 mg on Day 1 only (single dose)',
      notes:
        'The two injections must be given into two different muscles (deltoid + gluteal, or two gluteal sites — not same muscle twice). This method establishes therapeutic levels faster but requires two injections at once.',
    },
  },

  initiationSteps: [
    {
      label: 'Day 1',
      doseMgEq: 400,
      site: 'Deltoid or gluteal',
      notes: '14-day method: single 400 mg + oral aripiprazole 10–20 mg/day for 14 days. 1-day method: 400 mg × 2 sites + oral 20 mg once only.',
    },
    {
      label: 'Month 1 onward',
      doseMgEq: 400,
      site: 'Deltoid or gluteal',
      notes: 'Standard maintenance dose. Reduce to 300 mg if tolerability issues or CYP2D6 poor metaboliser.',
    },
  ] as DepotInitiationStep[],

  maintenanceDoseRange: { min: 300, recommended: 400, max: 400 },
  maintenanceUnit: 'mg',
  maintenanceWindow: 'No sooner than 26 days after prior injection',

  needleGuide: [
    { site: 'Deltoid', habitus: 'Non-obese', gauge: '23G', lengthInch: '1 inch (25 mm)' },
    { site: 'Deltoid', habitus: 'Obese', gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
    { site: 'Gluteal', habitus: 'Non-obese', gauge: '22G', lengthInch: '1.5 inch (38 mm)' },
    { site: 'Gluteal', habitus: 'Obese', gauge: '21G', lengthInch: '2 inch (51 mm)' },
  ] as NeedleGuide[],

  injectionSiteNote:
    'Deltoid or gluteal equally acceptable from Day 1. Do NOT massage the injection site after administration — can alter release kinetics. No post-injection observation period required (unlike olanzapine pamoate).',

  missedDoseSecondThird: [
    {
      condition: '> 4 weeks to < 5 weeks since last injection (2nd or 3rd dose)',
      action: 'Administer injection as soon as possible. Resume monthly schedule.',
      severity: 'info',
    },
    {
      condition: '≥ 5 weeks since last injection (2nd or 3rd dose)',
      action: 'Restart treatment using either the 14-day or 1-day initiation protocol.',
      severity: 'danger',
    },
  ] as MissedDoseScenario[],

  missedDoseFourthOnward: [
    {
      condition: '> 4 weeks to < 6 weeks since last injection (4th dose onward)',
      action: 'Administer injection as soon as possible. Resume monthly schedule.',
      severity: 'info',
    },
    {
      condition: '≥ 6 weeks since last injection (4th dose onward)',
      action: 'Restart treatment using either the 14-day or 1-day initiation protocol.',
      severity: 'danger',
    },
  ] as MissedDoseScenario[],

  drugInteractions: [
    {
      situation: 'CYP2D6 poor metaboliser',
      action: 'Reduce to 300 mg monthly.',
      severity: 'warning',
    },
    {
      situation: 'Strong CYP2D6 inhibitor (> 14 days) — e.g. fluoxetine, paroxetine',
      action: 'Reduce to 300 mg monthly.',
      severity: 'warning',
    },
    {
      situation: 'Strong CYP3A4 inhibitor (> 14 days) — e.g. itraconazole, clarithromycin',
      action: 'Reduce to 300 mg monthly.',
      severity: 'warning',
    },
    {
      situation: 'Strong CYP2D6 AND CYP3A4 inhibitor combined',
      action: 'Avoid combination. If unavoidable, use with caution — exposure substantially increased. Consider oral aripiprazole instead.',
      severity: 'danger',
    },
    {
      situation: 'Strong CYP3A4 inducer (> 14 days) — e.g. carbamazepine, rifampicin',
      action: 'AVOID concomitant use for > 14 days. No adequate dose alternative — exposure reduced too substantially for reliable therapeutic effect.',
      severity: 'danger',
    },
  ] as DrugInteractionAdjustment[],

  renalNote: 'No dose adjustment required for renal impairment (FDA PI).',
  hepaticNote: 'No dose adjustment required for hepatic impairment (FDA PI).',

  pkNotes: [
    'Single-dose apparent t½: ~17.8 days (deltoid) / ~21 days (gluteal).',
    'Steady-state t½ after multiple gluteal doses: 29.9–46.5 days (dose-dependent).',
    'No post-injection observation period required (no PIOS documented, unlike olanzapine pamoate).',
  ],

  keyWarnings: [
    'Extended half-life (~30–46 days at steady state): adverse effects persist well after discontinuation — prolonged supportive management may be needed.',
    'Do NOT massage the injection site — can alter release kinetics.',
    'Akathisia: most common neurological adverse reaction — counsel patients before initiation.',
    'Metabolic effects: weight gain (most common ADR), hyperglycaemia, dyslipidaemia — baseline and monitoring required.',
    'Orthostatic hypotension: monitor at initiation.',
    'NMS and tardive dyskinesia: management complicated by extended release.',
    'Carbamazepine interaction: avoid co-prescription for > 14 days — substantially lowers aripiprazole levels without adequate dose solution.',
  ],

  citations: [
    'Abilify Maintena (aripiprazole) — FDA Prescribing Information. Otsuka America Pharmaceutical, Inc. DailyMed, 2025.',
    'Maudsley 15th edition — LAI antipsychotics, Chapter 1.',
  ],
} as const;
