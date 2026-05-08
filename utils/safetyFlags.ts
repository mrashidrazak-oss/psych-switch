// Display strings for the safety flags emitted by the switching engine.
// Centralised here so engine logic stays free of UI copy and so the same
// strings can be reused if we add the flags to e.g. a printed handout.
//
// When you add a new flag key in the engine (`deriveSafetyFlags` or
// rule-level `safetyFlags`), add a matching entry here. Unknown keys fall
// back to a generic display in the UI.

export type SafetySeverity = 'info' | 'warning' | 'danger';

export interface FlagDisplay {
  severity: SafetySeverity;
  title: string;
  body: string;
}

export const SAFETY_FLAG_DISPLAY: Record<string, FlagDisplay> = {
  serotonin_syndrome_overlap_low: {
    severity: 'warning',
    title: 'Serotonin syndrome — low overlap risk',
    body: 'Cross-tapering two serotonergic agents creates brief overlap. Risk is low at typical doses; monitor for tremor, hyperreflexia, autonomic instability.',
  },
  serotonin_syndrome_overlap_high: {
    severity: 'danger',
    title: 'Serotonin syndrome — significant overlap risk',
    body: 'Combined serotonergic activity is substantial. Consider a washout strategy instead of cross-taper.',
  },
  discontinuation_syndrome_high: {
    severity: 'warning',
    title: 'High discontinuation syndrome risk',
    body: 'The original drug carries a high risk of discontinuation symptoms (electric-shock sensations, dizziness, irritability, insomnia). Taper slowly, warn the patient, and provide PRN advice.',
  },
  anticholinergic_rebound: {
    severity: 'warning',
    title: 'Anticholinergic rebound',
    body: 'Paroxetine has notable anticholinergic activity. Abrupt cessation may produce cholinergic rebound — nausea, sweating, agitation, GI upset. Taper gradually.',
  },
  maoi_washout_required_14_day: {
    severity: 'danger',
    title: 'MAOI washout required (14 days)',
    body: 'Stop the original antidepressant and wait 14 days with no antidepressant before starting the MAOI. Overlap risks fatal serotonin syndrome.',
  },
  maoi_washout_required_5_week: {
    severity: 'danger',
    title: 'Fluoxetine washout — 5 weeks before MAOI',
    body: 'Fluoxetine plus norfluoxetine require a full 5-week (35-day) washout before any MAOI can safely be started. This is non-negotiable.',
  },
  maoi_clearance_required: {
    severity: 'danger',
    title: 'MAOI clearance required before next drug',
    body: 'After stopping a reversible MAOI (e.g. moclobemide), wait the recommended clearance period before starting another serotonergic drug. For irreversible MAOIs the wait is 14 days.',
  },
  cholinergic_rebound: {
    severity: 'warning',
    title: 'Cholinergic rebound risk',
    body: 'Stopping a strongly anticholinergic antipsychotic (olanzapine, quetiapine) can produce cholinergic rebound — nausea, sweating, agitation, GI upset. Taper gradually rather than stopping abruptly. Brief overlap with an anticholinergic agent is occasionally needed.',
  },
  akathisia_risk_aripiprazole: {
    severity: 'warning',
    title: 'Akathisia risk on aripiprazole',
    body: 'Aripiprazole is the most frequent cause of akathisia in this drug set, particularly in patients previously stabilised on a full D2 antagonist. Counsel patient to report restlessness early. Start low; titrate against tolerability.',
  },
  prolactin_normalisation: {
    severity: 'info',
    title: 'Prolactin levels likely to normalise',
    body: 'Switching off a high-prolactin agent (risperidone, haloperidol) typically restores normal prolactin within 2-4 weeks. Counsel about possible return of menses, resolution of galactorrhoea, or change in libido.',
  },
  depot_washout_long: {
    severity: 'warning',
    title: 'Long depot washout — residual drug for weeks',
    body: 'The original LAI continues to release drug for weeks after the last injection. Residual depot must be considered when interpreting clinical changes, attributing side effects, or initiating the next agent.',
  },
  lai_initiation_oral_overlap: {
    severity: 'warning',
    title: 'LAI requires oral overlap during initiation',
    body: 'Most LAIs do not reach therapeutic levels until 2-3 weeks after the first injection. Continue the oral antipsychotic during the loading phase per the schedule. Stopping oral too early risks relapse.',
  },
  // ── Mood-stabilizer specific flags ─────────────────────────────────
  lamotrigine_cbz_induction_withdrawal_risk: {
    severity: 'danger',
    title: 'LTG rises as CBZ is withdrawn — reduce LTG dose',
    body: 'Carbamazepine is a potent UGT inducer. As CBZ is tapered, the induction effect is lost and lamotrigine levels RISE. Lamotrigine dose must be reduced in synchrony with the CBZ taper. Failure to do so risks toxic LTG levels and Stevens-Johnson syndrome.',
  },
  lamotrigine_dose_must_reduce_as_cbz_tapers: {
    severity: 'danger',
    title: 'Reduce lamotrigine progressively as CBZ is tapered',
    body: 'Follow the step-by-step schedule to reduce lamotrigine in proportion to the CBZ dose reduction. Check lamotrigine level 2 weeks after CBZ is fully stopped.',
  },
  lamotrigine_vpa_inhibition_withdrawal_risk: {
    severity: 'danger',
    title: 'LTG falls as VPA is withdrawn — increase LTG dose',
    body: 'Valproate inhibits lamotrigine glucuronidation. As valproate is tapered, inhibition is relieved and lamotrigine levels FALL. Lamotrigine dose must be increased in synchrony with the valproate taper. Failure to do so risks subtherapeutic levels and mood relapse.',
  },
  lamotrigine_dose_must_increase_as_vpa_tapers: {
    severity: 'danger',
    title: 'Increase lamotrigine progressively as VPA is tapered',
    body: 'Follow the step-by-step schedule to increase lamotrigine in proportion to the valproate dose reduction. Target monotherapy LTG dose is approximately double the co-prescribed dose with VPA.',
  },
  sjs_risk_lamotrigine: {
    severity: 'danger',
    title: 'Stevens-Johnson syndrome risk (lamotrigine)',
    body: 'Lamotrigine carries a risk of SJS / TEN (severe skin reaction). Risk is increased by rapid titration, concurrent valproate, or prior SJS. Any new rash in the first 8 weeks requires urgent assessment. Stop lamotrigine if rash is drug-related.',
  },
  valproate_teratogenicity_warning: {
    severity: 'danger',
    title: 'Valproate: mandatory teratogenicity counselling',
    body: 'Valproate has the highest teratogenic risk of any mood stabilizer. Contraindicated in women of childbearing potential without documented counselling, risk minimisation programme, and effective contraception. Confirm before stopping — ensure the patient has a safe alternative if pregnant.',
  },
  // ── Antipsychotic-specific flags ────────────────────────────────────
  metabolic_monitoring_required: {
    severity: 'warning',
    title: 'Metabolic monitoring required',
    body: 'The target antipsychotic carries a high metabolic risk (weight gain, dyslipidaemia, glucose dysregulation). Record baseline weight, fasting glucose, and fasting lipid profile before initiating. Repeat at 4, 12, and 26 weeks. Notify primary care team.',
  },
  qtc_monitoring_required: {
    severity: 'warning',
    title: 'QTc monitoring — ECG required',
    body: 'One or both drugs in this switch carry a clinically significant QTc-prolongation risk. Obtain a baseline ECG before initiating the new drug and repeat at 4–6 weeks or sooner if symptomatic. Correct hypokalaemia and hypomagnesaemia. Avoid concurrent QTc-prolonging drugs where possible.',
  },
  eps_risk_increase: {
    severity: 'warning',
    title: 'Increased EPS risk',
    body: 'The target drug carries a higher extrapyramidal risk than the current drug. Warn the patient about the possibility of stiffness, restlessness (akathisia), or dystonia, particularly in the first weeks. Have anticholinergic medication (e.g. procyclidine) available PRN. Young males switching to high-potency FGAs are at highest risk of acute dystonia.',
  },
  lurasidone_food_requirement: {
    severity: 'danger',
    title: 'Lurasidone: must be taken with food',
    body: 'Lurasidone bioavailability is approximately doubled when taken with a meal of at least 350 kcal. Taking it fasted produces subtherapeutic plasma levels. Counsel the patient explicitly to take lurasidone with their main meal every day.',
  },
  amisulpride_renal_clearance: {
    severity: 'warning',
    title: 'Amisulpride: renally excreted — adjust in renal impairment',
    body: 'Amisulpride is excreted unchanged by the kidneys. Dose reduction is required in renal impairment (eGFR <30 mL/min). Check baseline renal function before initiation and during overlap.',
  },
  lithium_rebound_mania_risk: {
    severity: 'danger',
    title: 'Lithium withdrawal — rebound mania risk',
    body: 'Abrupt or rapid lithium discontinuation carries a significant risk of rebound mania, often more severe than pre-treatment episodes. Taper over at least 4 weeks, ideally over 3 months (NICE/BAP). Monitor closely for prodromal symptoms for at least 6 months after stopping. Have a low threshold to restart or add an antipsychotic.',
  },
  carbamazepine_autoinduction: {
    severity: 'warning',
    title: 'Carbamazepine auto-induction — recheck levels at 4 weeks',
    body: 'Carbamazepine induces its own metabolism via CYP3A4. Plasma levels fall over the first 2–4 weeks of therapy as induction develops. Initial levels at 1 week will be higher than steady-state levels at 4 weeks — recheck and upward-titrate dose at 4 weeks as needed.',
  },
  carbamazepine_enzyme_reversal: {
    severity: 'warning',
    title: 'CBZ induction reversal — co-medication levels will rise',
    body: 'Carbamazepine induces CYP3A4, CYP2C9, and CYP1A2 broadly. When CBZ is stopped, induction reverses over 2–4 weeks — plasma levels of all substrate drugs (antipsychotics, anticoagulants, contraceptives, some antidepressants) will rise. Review and adjust all co-medications.',
  },
  lithium_narrow_therapeutic_index: {
    severity: 'warning',
    title: 'Lithium: narrow therapeutic index',
    body: 'Ensure baseline renal function (eGFR), TFTs, calcium, FBC, and 12-lead ECG before initiating lithium. Steady-state levels are reached in 5–7 days — check serum lithium 12 h post-dose. Target 0.6–1.0 mmol/L for maintenance; 0.8–1.0 for acute mood episodes. Counsel about dehydration risk (intercurrent illness, heat, diarrhoea) as a precipitant of toxicity.',
  },
  agomelatine_lft_monitoring: {
    severity: 'warning',
    title: 'Agomelatine: LFT monitoring required',
    body: 'Agomelatine carries a small risk of hepatotoxicity. Check LFTs at baseline and at 3, 6, 12, and 24 weeks of treatment. Stop immediately if LFTs exceed 3× ULN. Contraindicated in hepatic impairment or concurrent hepatotoxic drugs.',
  },
  vortioxetine_cyp2d6_interaction: {
    severity: 'warning',
    title: 'Vortioxetine: CYP2D6 inhibitor increases levels',
    body: 'The preceding drug (fluoxetine or paroxetine) is a potent CYP2D6 inhibitor and substantially raises vortioxetine plasma levels. Do not start vortioxetine at doses above 5 mg until CYP2D6 inhibition has cleared (allow 1–2 weeks after stopping fluoxetine/paroxetine before titrating above 10 mg). Avoid 15–20 mg doses immediately after.',
  },
  prolactin_elevation: {
    severity: 'info',
    title: 'Hyperprolactinaemia expected',
    body: 'The target drug is a full D2 antagonist with sustained prolactin elevation. Counsel about potential side effects: amenorrhoea, galactorrhoea, loss of libido, and (with prolonged elevation) reduced bone density. Check baseline prolactin if considering long-term use.',
  },
  bipolar_relapse_monitor: {
    severity: 'warning',
    title: 'Bipolar relapse risk during transition',
    body: 'Any change to a mood stabiliser carries a risk of mood episode during the transition period. Monitor for prodromal symptoms (reduced sleep, increased energy, irritability, low mood) and have a clear escalation plan agreed with the patient and carer before initiating the switch.',
  },
  lamotrigine_vpa_level_rise_on_add: {
    severity: 'danger',
    title: 'Valproate doubles lamotrigine levels — titrate carefully',
    body: 'Adding valproate to lamotrigine substantially raises lamotrigine plasma levels (approximately 2× due to UGT inhibition). When introducing valproate, lamotrigine dose must be reduced (typically halved) as valproate levels rise above 500 mg/day. Monitor for lamotrigine toxicity: dizziness, diplopia, ataxia, nausea.',
  },
};

/** Generic fallback for flag keys that don't yet have a display entry. */
export function getFlagDisplay(key: string): FlagDisplay {
  return (
    SAFETY_FLAG_DISPLAY[key] ?? {
      severity: 'warning',
      title: key,
      body: 'No display copy for this flag yet. Update utils/safetyFlags.ts.',
    }
  );
}
