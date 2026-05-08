import { listAllDrugs, listDrugs } from '../switchingEngine';
import { rankDrugs } from '../smartPicker';

describe('smartPicker.rankDrugs', () => {
  const drugs = listDrugs();

  test('reviewed pairs float to "reviewed" tier', () => {
    // Olanzapine → aripiprazole is a reviewed pair.
    const ranked = rankDrugs(drugs, { fromDrugId: 'olanzapine' });
    const arip = ranked.find((r) => r.drug.id === 'aripiprazole');
    expect(arip).toBeDefined();
    expect(['reviewed', 'top']).toContain(arip!.tier);
    expect(arip!.tags).toContain('Reviewed');
  });

  test('without fromDrugId, no drug is "reviewed"', () => {
    const ranked = rankDrugs(drugs, { fromDrugId: null });
    expect(ranked.every((r) => r.tier !== 'reviewed' && r.tier !== 'top')).toBe(true);
  });

  test('lithium ranked "avoid" with severe CKD context', () => {
    const all = listAllDrugs();
    const lithium = all.find((d) => d.id === 'lithium');
    if (!lithium) return; // skip if mood stabilizer is not registered
    const ranked = rankDrugs([lithium], {
      fromDrugId: 'valproate',
      context: { renal: 'severe' },
    });
    const li = ranked.find((r) => r.drug.id === 'lithium');
    expect(li).toBeDefined();
    expect(li!.tier).toBe('avoid');
    expect(li!.blocked).toBe(true);
  });

  test('AE filter promotes switch candidates', () => {
    // Patient has weight gain on olanzapine; aripiprazole is a switch candidate.
    const ranked = rankDrugs(drugs, {
      fromDrugId: 'olanzapine',
      avoidAeId: 'weight_gain',
    });
    const arip = ranked.find((r) => r.drug.id === 'aripiprazole');
    expect(arip!.tier === 'top' || arip!.tier === 'reviewed').toBe(true);
  });

  test('AE filter demotes culprit drugs', () => {
    // If the user is fleeing weight gain, olanzapine should pick up "causes" tag.
    const ranked = rankDrugs(drugs, {
      fromDrugId: 'sertraline',
      avoidAeId: 'weight_gain',
    });
    const olz = ranked.find((r) => r.drug.id === 'olanzapine');
    expect(olz?.tags.some((t) => t.startsWith('causes'))).toBe(true);
  });

  test('result is sorted by tier rank', () => {
    const ranked = rankDrugs(drugs, { fromDrugId: 'olanzapine' });
    const tierRanks = ranked.map((r) => ({ top: 4, reviewed: 3, fallback: 2, caution: 1, avoid: 0 }[r.tier]));
    for (let i = 1; i < tierRanks.length; i++) {
      // Allow ties; just enforce non-increasing order.
      expect(tierRanks[i]).toBeLessThanOrEqual(tierRanks[i - 1]);
    }
  });
});
