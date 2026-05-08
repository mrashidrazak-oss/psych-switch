// Engine unit tests.
//
// Per CLAUDE.md: "Every clinical calculation must have a unit test with at
// least 3 cases including an edge case." These tests cover:
//   1. Happy path — reviewed pair at reviewed doses returns a valid plan.
//   2. Edge case — unknown drug pair returns no_rule (does NOT guess).
//   3. Edge case — known pair but doses outside the reviewed range
//      returns dose_out_of_range (does NOT linearly scale).

import {
  deriveSafetyFlags,
  generateSwitchPlan,
  getDrug,
  listAllDrugs,
  listDrugs,
} from '../switchingEngine';

describe('MAOI hard-block', () => {
  test('SSRI → moclobemide (MAOI) returns maoi_washout with 14-day washout', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'moclobemide',
      toDoseMg: 300,
    });
    expect(plan.status).toBe('maoi_washout');
    if (plan.status !== 'maoi_washout') return;
    expect(plan.direction).toBe('to_maoi');
    expect(plan.washoutDays).toBe(14);
    expect(plan.safetyFlags).toContain('maoi_washout_required_14_day');
  });

  test('fluoxetine → moclobemide enforces the 5-week (35-day) washout', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'fluoxetine',
      fromDoseMg: 20,
      toDrugId: 'moclobemide',
      toDoseMg: 300,
    });
    expect(plan.status).toBe('maoi_washout');
    if (plan.status !== 'maoi_washout') return;
    expect(plan.washoutDays).toBe(35);
    expect(plan.safetyFlags).toContain('maoi_washout_required_5_week');
    // The 14-day flag must NOT be present — the 5-week flag supersedes it.
    expect(plan.safetyFlags).not.toContain('maoi_washout_required_14_day');
  });

  test('moclobemide → SSRI returns short clearance (1 day) due to reversibility', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'moclobemide',
      fromDoseMg: 300,
      toDrugId: 'sertraline',
      toDoseMg: 100,
    });
    expect(plan.status).toBe('maoi_washout');
    if (plan.status !== 'maoi_washout') return;
    expect(plan.direction).toBe('from_maoi');
    expect(plan.washoutDays).toBe(1);
    expect(plan.safetyFlags).toContain('maoi_clearance_required');
  });

  test('MAOI hard-block runs BEFORE rule lookup (cannot be overridden by a rule)', () => {
    // Even if a future rule existed for paroxetine→moclobemide (it
    // doesn't, and shouldn't), the engine must still return a washout.
    // This test fixes the order of checks.
    const plan = generateSwitchPlan({
      fromDrugId: 'paroxetine',
      fromDoseMg: 20,
      toDrugId: 'moclobemide',
      toDoseMg: 300,
    });
    expect(plan.status).toBe('maoi_washout');
  });
});

describe('antipsychotic auto-flag derivation', () => {
  test('olanzapine → aripiprazole flags cholinergic_rebound + akathisia + metabolic improvement direction', () => {
    const olanzapine = getDrug('olanzapine')!;
    const aripiprazole = getDrug('aripiprazole')!;
    const flags = deriveSafetyFlags(olanzapine, aripiprazole);
    expect(flags).toContain('cholinergic_rebound');
    expect(flags).toContain('akathisia_risk_aripiprazole');
    // Olanzapine is low prolactin so no normalisation flag.
    expect(flags).not.toContain('prolactin_normalisation');
  });

  test('risperidone → aripiprazole flags prolactin normalisation + akathisia', () => {
    const risperidone = getDrug('risperidone')!;
    const aripiprazole = getDrug('aripiprazole')!;
    const flags = deriveSafetyFlags(risperidone, aripiprazole);
    expect(flags).toContain('prolactin_normalisation');
    expect(flags).toContain('akathisia_risk_aripiprazole');
    // Risperidone is not anticholinergic so no cholinergic rebound.
    expect(flags).not.toContain('cholinergic_rebound');
  });

  test('haloperidol → quetiapine auto-flags qtc_additive_overlap (high + moderate)', () => {
    // haloperidol=high QTc, quetiapine=moderate QTc — worst combination in
    // the AP registry. Must always auto-flag during cross-taper.
    const haloperidol = getDrug('haloperidol')!;
    const quetiapine = getDrug('quetiapine')!;
    const flags = deriveSafetyFlags(haloperidol, quetiapine);
    expect(flags).toContain('qtc_additive_overlap');
  });

  test('haloperidol → olanzapine does NOT flag qtc_additive_overlap (olanzapine=low QTc)', () => {
    const haloperidol = getDrug('haloperidol')!;
    const olanzapine = getDrug('olanzapine')!;
    const flags = deriveSafetyFlags(haloperidol, olanzapine);
    expect(flags).not.toContain('qtc_additive_overlap');
  });

  test('switching INTO olanzapine from risperidone auto-flags metabolic_monitoring_required', () => {
    // olanzapine=very high metabolic risk; risperidone=moderate → flag fires.
    const risperidone = getDrug('risperidone')!;
    const olanzapine = getDrug('olanzapine')!;
    const flags = deriveSafetyFlags(risperidone, olanzapine);
    expect(flags).toContain('metabolic_monitoring_required');
  });

  test('switching FROM olanzapine to aripiprazole does NOT flag metabolic_monitoring_required', () => {
    // Moving AWAY from very high metabolic risk — no monitoring flag.
    const olanzapine = getDrug('olanzapine')!;
    const aripiprazole = getDrug('aripiprazole')!;
    const flags = deriveSafetyFlags(olanzapine, aripiprazole);
    expect(flags).not.toContain('metabolic_monitoring_required');
  });

  test('oral → LAI flags lai_initiation_oral_overlap', () => {
    const risperidone = getDrug('risperidone')!;
    const risperidoneLai = getDrug('risperidone-lai')!;
    const flags = deriveSafetyFlags(risperidone, risperidoneLai);
    expect(flags).toContain('lai_initiation_oral_overlap');
    expect(flags).not.toContain('depot_washout_long');
  });

  test('LAI → oral flags depot_washout_long but NOT oral overlap', () => {
    const risperidoneLai = getDrug('risperidone-lai')!;
    const aripiprazole = getDrug('aripiprazole')!;
    const flags = deriveSafetyFlags(risperidoneLai, aripiprazole);
    expect(flags).toContain('depot_washout_long');
    expect(flags).not.toContain('lai_initiation_oral_overlap');
  });

  test('LAI → LAI to a paliperidone-LAI does NOT require oral overlap (deltoid loading)', () => {
    // Paliperidone Sustenna's loading protocol (150 mg deltoid day 1,
    // 100 mg deltoid day 8) replaces the oral overlap requirement.
    const risperidoneLai = getDrug('risperidone-lai')!;
    const paliperidoneLai = getDrug('paliperidone-lai')!;
    const flags = deriveSafetyFlags(risperidoneLai, paliperidoneLai);
    expect(flags).toContain('depot_washout_long');
    expect(flags).not.toContain('lai_initiation_oral_overlap');
  });

  test('LAI → LAI to risperidone-LAI DOES require oral overlap', () => {
    const haloperidolLai = getDrug('haloperidol-lai')!;
    const risperidoneLai = getDrug('risperidone-lai')!;
    const flags = deriveSafetyFlags(haloperidolLai, risperidoneLai);
    expect(flags).toContain('depot_washout_long');
    expect(flags).toContain('lai_initiation_oral_overlap');
  });
});

describe('deriveSafetyFlags', () => {
  test('paroxetine as from-drug attaches discontinuation_syndrome_high AND anticholinergic_rebound', () => {
    const paroxetine = getDrug('paroxetine')!;
    const sertraline = getDrug('sertraline')!;
    const flags = deriveSafetyFlags(paroxetine, sertraline);
    expect(flags).toContain('discontinuation_syndrome_high');
    expect(flags).toContain('anticholinergic_rebound');
    // SSRI → SSRI also gets the overlap flag.
    expect(flags).toContain('serotonin_syndrome_overlap_low');
  });

  test('sertraline (moderate disc risk) → fluoxetine attaches only the overlap flag', () => {
    const sertraline = getDrug('sertraline')!;
    const fluoxetine = getDrug('fluoxetine')!;
    const flags = deriveSafetyFlags(sertraline, fluoxetine);
    expect(flags).not.toContain('discontinuation_syndrome_high');
    expect(flags).not.toContain('anticholinergic_rebound');
    expect(flags).toContain('serotonin_syndrome_overlap_low');
  });

  test('venlafaxine as from-drug flags very-high discontinuation risk', () => {
    const venlafaxine = getDrug('venlafaxine')!;
    const sertraline = getDrug('sertraline')!;
    const flags = deriveSafetyFlags(venlafaxine, sertraline);
    expect(flags).toContain('discontinuation_syndrome_high');
    // SNRI → SSRI is still serotonergic on both sides.
    expect(flags).toContain('serotonin_syndrome_overlap_low');
  });

  test('mirtazapine (NaSSA) is intentionally NOT flagged for serotonergic overlap', () => {
    const mirtazapine = getDrug('mirtazapine')!;
    const sertraline = getDrug('sertraline')!;
    expect(deriveSafetyFlags(mirtazapine, sertraline)).not.toContain(
      'serotonin_syndrome_overlap_low',
    );
    expect(deriveSafetyFlags(sertraline, mirtazapine)).not.toContain(
      'serotonin_syndrome_overlap_low',
    );
  });
});

import { listRules } from '../switchingEngine';

describe('rule registry', () => {
  test('all 133 reviewed rules are registered (43 AD + 71 AP + 12 mood-stabilizer + 7 LAI-to-oral)', () => {
    const ids = listRules().map((r) => r.id).sort();
    expect(ids).toEqual([
      'agomelatine-to-escitalopram',
      'agomelatine-to-mirtazapine',
      'agomelatine-to-sertraline',
      'agomelatine-to-venlafaxine',
      'amisulpride-to-aripiprazole',
      'amisulpride-to-haloperidol',
      'amisulpride-to-lurasidone',
      'amisulpride-to-olanzapine',
      'amisulpride-to-quetiapine',
      'amisulpride-to-risperidone',
      'aripiprazole-lai-to-aripiprazole',
      'aripiprazole-lai-to-paliperidone-lai',
      'aripiprazole-to-amisulpride',
      'aripiprazole-to-aripiprazole-lai',
      'aripiprazole-to-haloperidol',
      'aripiprazole-to-lurasidone',
      'aripiprazole-to-olanzapine',
      'aripiprazole-to-quetiapine',
      'aripiprazole-to-risperidone',
      'carbamazepine-to-lamotrigine',
      'carbamazepine-to-lithium',
      'carbamazepine-to-valproate',
      'chlorpromazine-to-aripiprazole',
      'chlorpromazine-to-olanzapine',
      'chlorpromazine-to-quetiapine',
      'chlorpromazine-to-risperidone',
      'desvenlafaxine-to-escitalopram',
      'desvenlafaxine-to-mirtazapine',
      'desvenlafaxine-to-sertraline',
      'desvenlafaxine-to-venlafaxine',
      'duloxetine-to-sertraline',
      'duloxetine-to-venlafaxine',
      'escitalopram-to-agomelatine',
      'escitalopram-to-desvenlafaxine',
      'escitalopram-to-fluoxetine',
      'escitalopram-to-sertraline',
      'escitalopram-to-venlafaxine',
      'escitalopram-to-vortioxetine',
      'fluoxetine-to-escitalopram',
      'fluoxetine-to-sertraline',
      'flupenthixol-lai-to-flupenthixol',
      'fluphenazine-lai-to-fluphenazine',
      'haloperidol-lai-to-aripiprazole-lai',
      'haloperidol-lai-to-haloperidol',
      'haloperidol-lai-to-paliperidone-lai',
      'haloperidol-lai-to-risperidone-lai',
      'haloperidol-to-amisulpride',
      'haloperidol-to-aripiprazole',
      'haloperidol-to-haloperidol-lai',
      'haloperidol-to-lurasidone',
      'haloperidol-to-olanzapine',
      'haloperidol-to-paliperidone-lai',
      'haloperidol-to-quetiapine',
      'haloperidol-to-risperidone',
      'lamotrigine-to-carbamazepine',
      'lamotrigine-to-lithium',
      'lamotrigine-to-valproate',
      'lithium-to-carbamazepine',
      'lithium-to-lamotrigine',
      'lithium-to-valproate',
      'lurasidone-to-aripiprazole',
      'lurasidone-to-haloperidol',
      'lurasidone-to-olanzapine',
      'lurasidone-to-quetiapine',
      'lurasidone-to-risperidone',
      'mirtazapine-to-agomelatine',
      'mirtazapine-to-desvenlafaxine',
      'mirtazapine-to-escitalopram',
      'mirtazapine-to-sertraline',
      'mirtazapine-to-vortioxetine',
      'olanzapine-to-amisulpride',
      'olanzapine-to-aripiprazole',
      'olanzapine-to-aripiprazole-lai',
      'olanzapine-to-haloperidol',
      'olanzapine-to-lurasidone',
      'olanzapine-to-paliperidone-lai',
      'olanzapine-to-quetiapine',
      'olanzapine-to-risperidone',
      'paliperidone-lai-to-aripiprazole-lai',
      'paliperidone-lai-to-paliperidone',
      'paroxetine-to-escitalopram',
      'paroxetine-to-fluoxetine',
      'paroxetine-to-sertraline',
      'quetiapine-to-amisulpride',
      'quetiapine-to-aripiprazole',
      'quetiapine-to-aripiprazole-lai',
      'quetiapine-to-haloperidol',
      'quetiapine-to-lurasidone',
      'quetiapine-to-olanzapine',
      'quetiapine-to-paliperidone-lai',
      'quetiapine-to-risperidone',
      'risperidone-lai-to-aripiprazole',
      'risperidone-lai-to-aripiprazole-lai',
      'risperidone-lai-to-paliperidone-lai',
      'risperidone-lai-to-risperidone',
      'risperidone-to-amisulpride',
      'risperidone-to-aripiprazole',
      'risperidone-to-aripiprazole-lai',
      'risperidone-to-haloperidol',
      'risperidone-to-lurasidone',
      'risperidone-to-olanzapine',
      'risperidone-to-paliperidone-lai',
      'risperidone-to-quetiapine',
      'risperidone-to-risperidone-lai',
      'sertraline-to-agomelatine',
      'sertraline-to-desvenlafaxine',
      'sertraline-to-duloxetine',
      'sertraline-to-escitalopram',
      'sertraline-to-fluoxetine',
      'sertraline-to-venlafaxine',
      'sertraline-to-vortioxetine',
      'sulpiride-to-aripiprazole',
      'sulpiride-to-olanzapine',
      'sulpiride-to-quetiapine',
      'sulpiride-to-risperidone',
      'trifluoperazine-to-aripiprazole',
      'trifluoperazine-to-olanzapine',
      'trifluoperazine-to-quetiapine',
      'trifluoperazine-to-risperidone',
      'valproate-to-carbamazepine',
      'valproate-to-lamotrigine',
      'valproate-to-lithium',
      'venlafaxine-to-agomelatine',
      'venlafaxine-to-desvenlafaxine',
      'venlafaxine-to-duloxetine',
      'venlafaxine-to-mirtazapine',
      'venlafaxine-to-sertraline',
      'venlafaxine-to-vortioxetine',
      'vortioxetine-to-escitalopram',
      'vortioxetine-to-mirtazapine',
      'vortioxetine-to-sertraline',
      'vortioxetine-to-venlafaxine',
      'zuclopenthixol-lai-to-zuclopenthixol',
    ]);
  });

  test('every rule carries at least 2 citations (per content guideline)', () => {
    for (const rule of listRules()) {
      expect(rule.citations.length).toBeGreaterThanOrEqual(2);
    }
  });

  test('every registered rule generates an ok plan at its reviewed reference doses', () => {
    // Parameterised smoke test: every rule, when called with its own
    // reference doses, must yield status 'ok' with a non-empty schedule
    // ending in fromDoseMg=0. Catches schedule typos, dose mismatches,
    // and registry/JSON drift in one assertion loop.
    for (const rule of listRules()) {
      const plan = generateSwitchPlan({
        fromDrugId: rule.fromDrugId,
        fromDoseMg: rule.doseRatios.fromCurrentDoseMg,
        toDrugId: rule.toDrugId,
        toDoseMg: rule.doseRatios.toTargetDoseMg,
      });
      expect(plan.status).toBe('ok');
      if (plan.status !== 'ok') continue;
      expect(plan.schedule.length).toBeGreaterThan(0);
      const last = plan.schedule[plan.schedule.length - 1];
      expect(last.fromDoseMg).toBe(0);
    }
  });

  test('every registered ORAL-drug dose in every schedule matches a real increment', () => {
    // Catches the kind of bug where a schedule says "paroxetine 5 mg"
    // but paroxetine is only available as 10/20/30 mg tablets in
    // Malaysia. The check is skipped for LAI entries — for depots, the
    // schedule's dose value represents continuous residual exposure
    // (a number on a continuum), not a discrete prescribed injection.
    for (const rule of listRules()) {
      const fromDrug = getDrug(rule.fromDrugId);
      const toDrug = getDrug(rule.toDrugId);
      expect(fromDrug).toBeDefined();
      expect(toDrug).toBeDefined();
      const checkDose = (drug: typeof fromDrug, dose: number) => {
        if (!drug || drug.formulation === 'lai') return true;
        return new Set([0, ...drug.dosing.increments]).has(dose);
      };
      for (const step of rule.schedule) {
        expect(checkDose(fromDrug, step.fromDoseMg)).toBe(true);
        expect(checkDose(toDrug, step.toDoseMg)).toBe(true);
      }
    }
  });
});

describe('paroxetine → sertraline rule (high-stakes taper)', () => {
  test('returns ok plan and merges in profile-driven flags from paroxetine', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'paroxetine',
      fromDoseMg: 20,
      toDrugId: 'sertraline',
      toDoseMg: 100,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    // Profile-derived flags must surface even though the JSON's
    // `safetyFlags` array is empty — that's the whole point of derivation.
    expect(plan.safetyFlags).toContain('discontinuation_syndrome_high');
    expect(plan.safetyFlags).toContain('anticholinergic_rebound');
    expect(plan.safetyFlags).toContain('serotonin_syndrome_overlap_low');
  });
});

describe('drug registry', () => {
  test('listDrugs() returns 31 visible drugs (11 ADs + 11 oral APs + 5 LAIs + 4 mood stabilizers)', () => {
    // Hidden drugs (3 MAOIs + 2 hidden LAIs + 4 new oral FGA/paliperidone = 9) must NOT appear here.
    // getDrug() still finds them — see hidden-drug tests below.
    const ids = listDrugs().map((d) => d.id).sort();
    expect(ids).toEqual([
      'agomelatine',
      'amisulpride',
      'aripiprazole',
      'aripiprazole-lai',
      'carbamazepine',
      'chlorpromazine',
      'clozapine',
      'desvenlafaxine',
      'duloxetine',
      'escitalopram',
      'fluoxetine',
      'flupenthixol-lai',
      'fluphenazine-lai',
      'fluvoxamine',
      'haloperidol',
      'lamotrigine',
      'lithium',
      'lurasidone',
      'mirtazapine',
      'olanzapine',
      'paliperidone-lai',
      'paroxetine',
      'quetiapine',
      'risperidone',
      'sertraline',
      'sulpiride',
      'trifluoperazine',
      'valproate',
      'venlafaxine',
      'vortioxetine',
      'zuclopenthixol-lai',
    ]);
  });

  test('listAllDrugs() returns all 40 drugs including the 9 hidden ones', () => {
    const all = listAllDrugs();
    expect(all).toHaveLength(40);
    const hiddenIds = all.filter((d) => d.hidden).map((d) => d.id).sort();
    expect(hiddenIds).toEqual([
      'flupenthixol',
      'fluphenazine',
      'haloperidol-lai',
      'moclobemide',
      'paliperidone',
      'phenelzine',
      'risperidone-lai',
      'tranylcypromine',
      'zuclopenthixol',
    ]);
  });

  test('hidden drugs are NOT in listDrugs() but ARE accessible via getDrug()', () => {
    for (const id of ['moclobemide', 'phenelzine', 'tranylcypromine', 'haloperidol-lai', 'risperidone-lai']) {
      expect(listDrugs().find((d) => d.id === id)).toBeUndefined();
      expect(getDrug(id)).toBeDefined();
    }
  });

  test('phenelzine and tranylcypromine are tagged as irreversible MAOIs with 14-day clearance', () => {
    for (const id of ['phenelzine', 'tranylcypromine']) {
      const d = getDrug(id);
      expect(d).toBeDefined();
      expect(d!.isMAOI).toBe(true);
      expect(d!.maoiClearanceDays).toBe(14);
    }
  });

  test('all 7 LAI entries carry formulation=lai and laiDetails (5 visible + 2 hidden)', () => {
    const laiIds = [
      'risperidone-lai',
      'paliperidone-lai',
      'aripiprazole-lai',
      'haloperidol-lai',
      'zuclopenthixol-lai',
      'flupenthixol-lai',
      'fluphenazine-lai',
    ];
    for (const id of laiIds) {
      const d = getDrug(id);
      expect(d).toBeDefined();
      expect(d!.formulation).toBe('lai');
      expect(d!.laiDetails).toBeDefined();
      expect(d!.laiDetails!.injectionIntervalDays).toBeGreaterThan(0);
      expect(typeof d!.laiDetails!.needsOralOverlap).toBe('boolean');
    }
  });

  test('antipsychotics are all tagged category=antipsychotic and carry profile fields', () => {
    const apIds = ['olanzapine', 'risperidone', 'quetiapine', 'aripiprazole', 'haloperidol'];
    for (const id of apIds) {
      const d = getDrug(id);
      expect(d).toBeDefined();
      expect(d!.category).toBe('antipsychotic');
      // Antipsychotic-specific risk fields must be present.
      expect(d!.epsRisk).toBeDefined();
      expect(d!.metabolicRisk).toBeDefined();
      expect(d!.prolactinRisk).toBeDefined();
      expect(d!.qtcRisk).toBeDefined();
      expect(d!.sedation).toBeDefined();
      expect(d!.lai).toBeDefined();
    }
  });

  test('antidepressants are NOT typed as antipsychotic (defensive)', () => {
    const adIds = ['sertraline', 'fluoxetine', 'venlafaxine', 'mirtazapine', 'moclobemide'];
    for (const id of adIds) {
      const d = getDrug(id);
      expect(d!.category).not.toBe('antipsychotic');
    }
  });

  test('moclobemide is correctly tagged as MAOI with 1-day clearance', () => {
    const m = getDrug('moclobemide');
    expect(m).toBeDefined();
    expect(m!.isMAOI).toBe(true);
    expect(m!.maoiClearanceDays).toBe(1);
  });

  test('fluoxetine MAOI washout is the special 5-week rule, not 14 days', () => {
    const f = getDrug('fluoxetine');
    expect(f).toBeDefined();
    // Per Maudsley: 5 weeks (35 days) off fluoxetine before any MAOI,
    // because of norfluoxetine's long half-life. This is the canonical
    // edge case that distinguishes fluoxetine from every other SSRI.
    expect(f!.maoiWashout?.daysOffBeforeMAOI).toBe(35);
  });
});

describe('generateSwitchPlan', () => {
  test('returns reviewed schedule for sertraline 100mg → escitalopram 10mg', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'escitalopram',
      toDoseMg: 10,
    });

    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return; // narrow for TS
    expect(plan.schedule.length).toBeGreaterThan(0);
    expect(plan.schedule[0].day).toBe(1);
    // Final step must end with the from-drug fully discontinued.
    const lastStep = plan.schedule[plan.schedule.length - 1];
    expect(lastStep.fromDoseMg).toBe(0);
    // Spec mandates >= 2 citations on every switching rule.
    expect(plan.citations.length).toBeGreaterThanOrEqual(2);
  });

  test('returns maudsley_guidance for an AD pair without a specific reviewed rule', () => {
    // Phase D: when no specific rule exists for an antidepressant pair,
    // engine consults the Maudsley 15th strategy matrix instead of giving
    // a bare no_rule. sertraline → mirtazapine has no specific rule but
    // the matrix has a class-level entry (ssri_other → mirtazapine).
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'mirtazapine',
      toDoseMg: 30,
    });
    expect(plan.status).toBe('maudsley_guidance');
    if (plan.status !== 'maudsley_guidance') return;
    expect(plan.guidance.strategy).toBe('cross_taper_cautiously');
    expect(plan.guidance.headline.length).toBeGreaterThan(0);
    expect(plan.guidance.citations.length).toBeGreaterThanOrEqual(1);
  });

  test('returns maudsley_guidance (cross-category) for AP → MS — never bare no_rule for valid drug pairs', () => {
    // AP↔MS has no specific rule and no Maudsley matrix entry, but the
    // cross-category fallback synthesises guidance from drug categories.
    const plan = generateSwitchPlan({
      fromDrugId: 'olanzapine',
      fromDoseMg: 10,
      toDrugId: 'lithium',
      toDoseMg: 800,
    });
    expect(plan.status).toBe('maudsley_guidance');
    if (plan.status !== 'maudsley_guidance') return;
    expect(plan.guidance.strategy).toBe('cross_taper_cautiously');
  });

  test('returns no_rule only for unregistered drug IDs', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'not-a-real-drug',
      fromDoseMg: 10,
      toDrugId: 'sertraline',
      toDoseMg: 100,
    });
    expect(plan.status).toBe('no_rule');
  });

  test('lithium → valproate returns ok (specific reviewed rule now exists)', () => {
    // Previously returned maudsley_guidance. A specific cross-taper rule now
    // exists (lithium-to-valproate) so the engine returns ok at reference doses.
    const plan = generateSwitchPlan({
      fromDrugId: 'lithium',
      fromDoseMg: 1000,
      toDrugId: 'valproate',
      toDoseMg: 1500,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    expect(plan.schedule.length).toBeGreaterThan(0);
    expect(plan.schedule[plan.schedule.length - 1]!.fromDoseMg).toBe(0);
  });

  test('valproate → carbamazepine returns ok (specific reviewed rule now exists — PK interaction)', () => {
    // Previously returned maudsley_guidance. A specific cross-taper rule now
    // exists (valproate-to-carbamazepine) with CBZ-epoxide toxicity notes.
    const plan = generateSwitchPlan({
      fromDrugId: 'valproate',
      fromDoseMg: 1500,
      toDrugId: 'carbamazepine',
      toDoseMg: 800,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    expect(plan.schedule.length).toBeGreaterThan(0);
    expect(plan.schedule[plan.schedule.length - 1]!.fromDoseMg).toBe(0);
  });

  test('lamotrigine → valproate returns ok (specific reviewed rule now exists — VPA doubles LTG levels)', () => {
    // Previously returned maudsley_guidance. A specific cross-taper rule now
    // exists (lamotrigine-to-valproate) with the CRITICAL LTG dose halving note.
    const plan = generateSwitchPlan({
      fromDrugId: 'lamotrigine',
      fromDoseMg: 200,
      toDrugId: 'valproate',
      toDoseMg: 1500,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    expect(plan.schedule.length).toBeGreaterThan(0);
    expect(plan.schedule[plan.schedule.length - 1]!.fromDoseMg).toBe(0);
  });

  test('dose mismatch returns ok with dosesMatchReference=false (not dose_out_of_range)', () => {
    // Phase D: engine no longer rejects dose mismatches. It returns the
    // reviewed reference schedule with a flag so the UI can render a
    // "reference doses — adapt proportionally" banner.
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 200, // higher than reviewed 100mg reference
      toDrugId: 'escitalopram',
      toDoseMg: 10,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    expect(plan.dosesMatchReference).toBe(false);
    expect(plan.inputDoses.fromMg).toBe(200);
    expect(plan.rule.doseRatios.fromCurrentDoseMg).toBe(100);
  });

  test('dose match returns ok with dosesMatchReference=true', () => {
    const plan = generateSwitchPlan({
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'escitalopram',
      toDoseMg: 10,
    });
    expect(plan.status).toBe('ok');
    if (plan.status !== 'ok') return;
    expect(plan.dosesMatchReference).toBe(true);
  });
});

describe('Full picker coverage — no bare no_rule for any valid visible pair', () => {
  test('every visible drug pair returns ok, maudsley_guidance, maoi_washout, or clozapine_redirect — never no_rule', () => {
    const drugs = listDrugs();
    const noRulePairs: string[] = [];

    for (const from of drugs) {
      for (const to of drugs) {
        if (from.id === to.id) continue;
        const plan = generateSwitchPlan({
          fromDrugId: from.id,
          toDrugId: to.id,
          fromDoseMg: from.dosing.startingDoseMg,
          toDoseMg: to.dosing.startingDoseMg,
        });
        if (plan.status === 'no_rule') {
          noRulePairs.push(`${from.id} → ${to.id}`);
        }
      }
    }

    if (noRulePairs.length > 0) {
      console.error('Pairs with no_rule:\n' + noRulePairs.join('\n'));
    }
    expect(noRulePairs).toHaveLength(0);
  });
});
