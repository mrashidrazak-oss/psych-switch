// MAOI tyramine-restricted diet & hypertensive-crisis reference.
//
// Irreversible non-selective MAOIs (phenelzine, tranylcypromine,
// isocarboxazid) and high-dose / non-transdermal selegiline block
// gut + hepatic MAO-A, so dietary tyramine escapes first-pass
// metabolism and can trigger a hypertensive crisis. Moclobemide
// (reversible MAO-A) and low-dose transdermal selegiline carry far
// less dietary risk but the same drug-interaction risk.
//
// Food classification + crisis management summarised from the
// Maudsley 15e and Gardner 1996 tyramine dataset.

enum TyramineRisk {
  avoid('Avoid'),
  caution('Caution / moderate'),
  safe('Generally safe');

  const TyramineRisk(this.label);
  final String label;
}

class FoodItem {
  const FoodItem({
    required this.name,
    required this.risk,
    required this.note,
  });

  final String name;
  final TyramineRisk risk;
  final String note;
}

const List<FoodItem> kMaoiFoods = <FoodItem>[
  // Avoid
  FoodItem(
    name: 'Aged / mature cheeses',
    risk: TyramineRisk.avoid,
    note: 'Cheddar, Stilton, Camembert, blue cheeses. Fresh cream '
        'cheese / cottage cheese / ricotta are safe.',
  ),
  FoodItem(
    name: 'Cured / fermented / dried meats',
    risk: TyramineRisk.avoid,
    note: 'Salami, pepperoni, dry sausage, aged / air-dried meats, '
        'fermented bologna.',
  ),
  FoodItem(
    name: 'Fermented soy products',
    risk: TyramineRisk.avoid,
    note: 'Soy sauce, miso, tempeh, fermented bean curd, '
        'fermented soybean paste.',
  ),
  FoodItem(
    name: 'Sauerkraut & kimchi',
    risk: TyramineRisk.avoid,
    note: 'Fermented cabbage products.',
  ),
  FoodItem(
    name: 'Tap / home-brew & some craft beer',
    risk: TyramineRisk.avoid,
    note: 'Unpasteurised / cask beer. Bottled / canned beer + most '
        'wine are caution in moderation.',
  ),
  FoodItem(
    name: 'Marmite / Vegemite / yeast extract',
    risk: TyramineRisk.avoid,
    note: 'Concentrated yeast extracts. Baked bread is safe '
        '(baking inactivates the yeast).',
  ),
  FoodItem(
    name: 'Broad (fava) bean pods',
    risk: TyramineRisk.avoid,
    note: 'Contain dopa — a pressor risk distinct from tyramine.',
  ),
  FoodItem(
    name: 'Spoiled / improperly stored food',
    risk: TyramineRisk.avoid,
    note: 'Tyramine rises with age / bacterial action — eat fresh, '
        'store cold, avoid leftovers > 24 h.',
  ),
  // Caution
  FoodItem(
    name: 'Bottled / canned beer & wine',
    risk: TyramineRisk.caution,
    note: 'Limit to ~2 units; tap / unpasteurised forms are avoid.',
  ),
  FoodItem(
    name: 'Ripe / overripe bananas & avocado',
    risk: TyramineRisk.caution,
    note: 'Fresh ripe fruit is fine; over-ripe / brown should be '
        'avoided. Banana skin is high.',
  ),
  FoodItem(
    name: 'Pasteurised light / processed cheeses',
    risk: TyramineRisk.caution,
    note: 'Processed cheese slices in small amounts are usually '
        'tolerated.',
  ),
  FoodItem(
    name: 'Soured cream / yoghurt',
    risk: TyramineRisk.caution,
    note: 'Fresh, in-date products in normal portions are low risk.',
  ),
  // Safe
  FoodItem(
    name: 'Fresh meat, poultry, fish',
    risk: TyramineRisk.safe,
    note: 'Freshly cooked and eaten promptly.',
  ),
  FoodItem(
    name: 'Fresh fruit & vegetables',
    risk: TyramineRisk.safe,
    note: 'Excluding the specific cautioned / avoided items.',
  ),
  FoodItem(
    name: 'Bread, cereals, rice, pasta',
    risk: TyramineRisk.safe,
    note: 'Baked goods are safe.',
  ),
  FoodItem(
    name: 'Fresh dairy (milk, cottage / cream cheese)',
    risk: TyramineRisk.safe,
    note: 'Non-aged dairy.',
  ),
];

/// Drugs that must be avoided with an irreversible MAOI (separate from
/// diet — the bigger killer in practice).
const List<String> kMaoiDrugCautions = <String>[
  'Indirect sympathomimetics — pseudoephedrine, phenylephrine, '
      'ephedrine (OTC cold remedies), amphetamines.',
  'Other serotonergic agents — SSRIs/SNRIs, clomipramine, '
      'tramadol, pethidine, dextromethorphan, linezolid, '
      'triptans → serotonin syndrome.',
  'Other MAOIs / RIMA — observe full washout in both directions.',
  'Local anaesthetic with adrenaline; check before any procedure.',
];

class TyramineLookup {
  const TyramineLookup({required this.query, required this.matches});
  final String query;
  final List<FoodItem> matches;
}

/// Case-insensitive substring search across food names.
TyramineLookup searchFoods(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return TyramineLookup(query: query, matches: List.of(kMaoiFoods));
  }
  return TyramineLookup(
    query: query,
    matches: kMaoiFoods
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.note.toLowerCase().contains(q))
        .toList(),
  );
}

/// Hypertensive-crisis recognition + management script.
const String kHypertensiveCrisisManagement =
    'Suspect a tyramine ("cheese") reaction with sudden severe '
    'occipital headache, hypertension, palpitations, sweating, '
    'neck stiffness ± photophobia after a suspect food. '
    'Stop the suspect food. Sit upright. Confirm BP. Treat as a '
    'hypertensive emergency: titratable agent (e.g. IV labetalol or '
    'phentolamine; oral nifedipine is no longer recommended due to '
    'overshoot). Continuous monitoring; exclude intracranial '
    'haemorrhage if focal signs. Do NOT give a beta-blocker alone if '
    'unopposed alpha effect is suspected.';
