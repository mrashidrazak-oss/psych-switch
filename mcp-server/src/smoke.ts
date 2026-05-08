// Smoke test — calls every handler with realistic inputs and asserts
// it returns something sane. Not exhaustive — covers happy paths and
// shape of returned data so we catch regressions when the engine
// changes shape under us.
//
// Run with:  pnpm test
//
// Exits non-zero on any failure so CI / `eas build` hooks can fail
// loud. Output is intentionally chatty so a manual run is also a
// useful sanity check while debugging.

import { handlers, type HandlerName } from './handlers';

interface Check {
  name: HandlerName;
  args: Record<string, unknown>;
  /** Asserts on the result. Throws on failure. */
  expect: (result: unknown) => void;
}

const CHECKS: Check[] = [
  {
    name: 'psychswitch_list_drugs',
    args: {},
    expect: (r) => {
      const arr = r as Array<{ id: string }>;
      assert(Array.isArray(arr), 'drugs is array');
      assert(arr.length >= 30, `drugs.length >= 30 (got ${arr.length})`);
      assert(arr.every((d) => typeof d.id === 'string'), 'every drug has an id');
    },
  },
  {
    name: 'psychswitch_list_drugs',
    args: { category: 'antidepressant' },
    expect: (r) => {
      const arr = r as Array<{ category: string }>;
      assert(arr.every((d) => d.category === 'antidepressant'), 'all antidepressants');
    },
  },
  {
    name: 'psychswitch_get_drug',
    args: { id: 'aripiprazole' },
    expect: (r) => {
      const d = r as { id: string; genericName: string };
      assert(d.id === 'aripiprazole', 'returns aripiprazole');
      assert(d.genericName === 'Aripiprazole', 'has genericName');
    },
  },
  {
    name: 'psychswitch_list_rules',
    args: {},
    expect: (r) => {
      const arr = r as Array<{ id: string }>;
      assert(Array.isArray(arr), 'rules is array');
      assert(arr.length > 100, `rules.length > 100 (got ${arr.length})`);
    },
  },
  {
    name: 'psychswitch_list_rules',
    args: { fromDrugId: 'olanzapine' },
    expect: (r) => {
      const arr = r as Array<{ fromDrugId: string }>;
      assert(arr.every((rule) => rule.fromDrugId === 'olanzapine'), 'filtered by from');
      assert(arr.length > 0, 'has at least one olanzapine rule');
    },
  },
  {
    name: 'psychswitch_generate_plan',
    args: {
      fromDrugId: 'olanzapine',
      fromDoseMg: 20,
      toDrugId: 'aripiprazole',
      toDoseMg: 15,
    },
    expect: (r) => {
      const env = r as { plan: { status: string }; score?: { total: number; band: string } };
      assert(env.plan.status === 'ok', `plan ok (got ${env.plan.status})`);
      assert(env.score != null, 'has score');
      assert(env.score!.total >= 0 && env.score!.total <= 100, 'score 0-100');
    },
  },
  {
    name: 'psychswitch_generate_plan',
    args: {
      fromDrugId: 'olanzapine',
      fromDoseMg: 30,        // != reference 20 → adapted
      toDrugId: 'aripiprazole',
      toDoseMg: 20,
    },
    expect: (r) => {
      const env = r as { adaptedFromReviewed?: boolean };
      assert(env.adaptedFromReviewed === true, 'schedule adapted');
    },
  },
  {
    name: 'psychswitch_generate_plan',
    args: {
      fromDrugId: 'olanzapine',
      fromDoseMg: 20,
      toDrugId: 'aripiprazole',
      toDoseMg: 15,
      patientContext: { renal: 'severe' },
    },
    expect: (r) => {
      const env = r as { contextWarnings?: unknown[] };
      assert(Array.isArray(env.contextWarnings), 'context warnings array');
    },
  },
  {
    name: 'psychswitch_scale_schedule',
    args: {
      fromDrugId: 'olanzapine',
      fromDoseMg: 30,
      toDrugId: 'aripiprazole',
      toDoseMg: 20,
    },
    expect: (r) => {
      const out = r as { adapted: boolean; schedule: unknown };
      assert(out.adapted === true, 'adapted true');
      assert(out.schedule != null, 'has schedule');
    },
  },
  {
    name: 'psychswitch_dose_equivalent',
    args: {
      family: 'cpz',
      fromDrugId: 'olanzapine',
      fromDoseMg: 5,
      toDrugId: 'aripiprazole',
    },
    expect: (r) => {
      const c = r as { to: { doseMg: number } };
      assert(typeof c.to.doseMg === 'number', 'has converted dose');
      // 5 mg olanzapine ≈ 100 mg CPZ ≈ 7.5 mg aripiprazole per Leucht 2016
      assert(c.to.doseMg > 0, 'positive');
    },
  },
  {
    name: 'psychswitch_predict_ae',
    args: { toDrugId: 'aripiprazole', fromDrugId: 'olanzapine' },
    expect: (r) => {
      const p = r as { predictions: unknown[] };
      assert(Array.isArray(p.predictions), 'predictions array');
      assert(p.predictions.length > 0, 'non-empty');
    },
  },
  {
    name: 'psychswitch_check_ddi',
    args: { drugIds: ['fluoxetine', 'phenelzine'] },
    expect: (r) => {
      const hits = r as Array<{ severity: string }>;
      assert(Array.isArray(hits), 'array');
      assert(hits.some((h) => h.severity === 'avoid'), 'SSRI+MAOI flagged avoid');
    },
  },
  {
    name: 'psychswitch_compute_score',
    args: {
      fromDrugId: 'olanzapine',
      fromDoseMg: 20,
      toDrugId: 'aripiprazole',
      toDoseMg: 15,
    },
    expect: (r) => {
      const s = r as { total: number; band: string };
      assert(s.total >= 0 && s.total <= 100, 'score 0-100');
      assert(['excellent', 'good', 'caution', 'poor'].includes(s.band), 'valid band');
    },
  },
  {
    name: 'psychswitch_search',
    args: { query: 'olanz' },
    expect: (r) => {
      const hits = r as Array<{ kind: string }>;
      assert(Array.isArray(hits), 'array');
      assert(hits.length > 0, 'has hits');
    },
  },
  {
    name: 'psychswitch_lookup_glossary',
    args: { term: 'qtc' },
    expect: (r) => {
      const e = r as { definition: string };
      assert(typeof e.definition === 'string', 'has definition');
      assert(e.definition.length > 0, 'non-empty');
    },
  },
  {
    name: 'psychswitch_get_citation',
    args: { key: 'maudsley15_ch3_p369_table_3_7' },
    expect: (r) => {
      const c = r as { source: string; reference: string };
      assert(c.source === 'Maudsley15', 'Maudsley source');
      assert(c.reference.length > 0, 'has reference');
    },
  },
  {
    name: 'psychswitch_context_warnings',
    args: { drugId: 'lithium', patientContext: { renal: 'severe' } },
    expect: (r) => {
      const arr = r as Array<{ severity: string }>;
      assert(Array.isArray(arr), 'array');
      assert(arr.some((w) => w.severity === 'danger'), 'lithium + severe CKD = danger');
    },
  },
  {
    name: 'psychswitch_assess_specialty',
    args: {
      fromDrugId: 'sertraline',
      toDrugId: 'paroxetine',
      patientContext: { pregnant: true, trimester: 1 },
    },
    expect: (r) => {
      const a = r as { applicable: string[]; recommendations: Array<{ tier: string; drugId: string }> };
      assert(a.applicable.includes('pregnancy'), 'pregnancy applicable');
      const paroxRec = a.recommendations.find((rec) => rec.drugId === 'paroxetine');
      assert(paroxRec?.tier === 'avoid', 'paroxetine 1st trimester = avoid');
    },
  },
  {
    name: 'psychswitch_assess_specialty',
    args: {
      fromDrugId: 'sertraline',
      toDrugId: 'mirtazapine',
      patientContext: { ageYears: 78 },
    },
    expect: (r) => {
      const a = r as { applicable: string[]; recommendations: Array<{ doseFactor?: number }> };
      assert(a.applicable.includes('geriatric'), 'geriatric applicable');
      assert(a.recommendations.some((rec) => rec.doseFactor != null && rec.doseFactor < 1), 'geriatric dose factor');
    },
  },
  {
    name: 'psychswitch_list_errata',
    args: {},
    expect: (r) => {
      const arr = r as Array<{ id: string; dateISO: string }>;
      assert(Array.isArray(arr), 'array');
      assert(arr.length > 0, 'has entries');
      assert(arr[0].dateISO.length >= 10, 'first entry has dateISO');
    },
  },
  {
    name: 'psychswitch_list_errata',
    args: { sinceVersion: '0.3.0' },
    expect: (r) => {
      const arr = r as Array<{ appVersion: string }>;
      // Every entry should be from 0.3.0 onward (parsed loosely)
      assert(arr.every((e) => parseFloat(e.appVersion) >= 0.3), 'all post-0.3');
    },
  },
  {
    name: 'psychswitch_quantitative_ae',
    args: { drugId: 'olanzapine' },
    expect: (r) => {
      const out = r as { drugId: string; effects: Array<{ formatted: string }> };
      assert(out.drugId === 'olanzapine', 'returns drug id');
      assert(out.effects.length > 0, 'has at least one effect');
      assert(out.effects.every((e) => typeof e.formatted === 'string'), 'all formatted');
    },
  },
  {
    name: 'psychswitch_cost',
    args: { drugIds: ['fluoxetine', 'agomelatine'] },
    expect: (r) => {
      const out = r as { entries: Array<{ entry: { tier: string } | null }>; deltaMyr?: number };
      assert(out.entries.length === 2, 'two entries');
      assert(out.entries[0].entry?.tier === 'subsidised', 'fluoxetine subsidised');
      assert(typeof out.deltaMyr === 'number', 'delta computed');
      assert(out.deltaMyr! > 0, 'agomelatine pricier than fluoxetine');
    },
  },
  {
    name: 'psychswitch_overlap_intensity',
    args: {
      fromDrugId: 'sertraline',
      fromDoseMg: 100,
      toDrugId: 'escitalopram',
      toDoseMg: 10,
    },
    expect: (r) => {
      const a = r as { tier?: string; flags?: string[]; score?: number };
      assert(typeof a.tier === 'string', 'has tier');
      assert(Array.isArray(a.flags), 'has flags array');
      assert(a.flags!.includes('serotonergic_stacking'), 'serotonergic_stacking flagged');
      assert(typeof a.score === 'number', 'has score');
    },
  },
];

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(`Assertion failed: ${msg}`);
}

async function main(): Promise<void> {
  let pass = 0;
  let fail = 0;
  for (const c of CHECKS) {
    process.stdout.write(`  ${c.name} ... `);
    try {
      const handler = handlers[c.name];
      if (!handler) throw new Error(`No handler for ${c.name}`);
      const result = await handler(c.args);
      c.expect(result);
      console.log('✓');
      pass++;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.log(`✗  ${msg}`);
      fail++;
    }
  }
  console.log(`\n${pass} passed, ${fail} failed (${CHECKS.length} total)`);
  if (fail > 0) process.exit(1);
}

main().catch((err) => {
  console.error('Smoke test runner crashed:', err);
  process.exit(1);
});
