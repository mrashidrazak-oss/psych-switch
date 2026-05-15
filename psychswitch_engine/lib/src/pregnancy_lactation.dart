// Pregnancy + lactation safety atlas.
//
// Per-drug safety guidance for the OB-psych question — "Can my
// patient stay on this in pregnancy / breastfeeding?". The FDA
// retired the A/B/C/D/X letter categories in 2015 (PLLR), so this
// engine uses three semantic tiers per axis:
//
//   • preferred   — first-line evidence is reassuring
//   • use_with_caution — relative risk requires discussion + monitoring
//   • avoid       — significant absolute risk; specialist input first
//
// Content is summarised from:
//   • Maudsley 15th ed. — perinatal psychotropics chapter
//   • LactMed (NIH)
//   • UK Teratology Information Service (UKTIS)
//   • Stahl, Prescriber's Guide, 7e
//
// Recommendations are CLINICAL SUMMARIES, not personalised advice.
// Specialist OB-psych review remains the standard for live decisions.

enum PerinatalTier {
  preferred('preferred'),
  cautious('use_with_caution'),
  avoid('avoid'),
  unknown('unknown');

  const PerinatalTier(this.jsonValue);
  final String jsonValue;
}

String tierLabel(PerinatalTier t) {
  switch (t) {
    case PerinatalTier.preferred:
      return 'Preferred';
    case PerinatalTier.cautious:
      return 'Use with caution';
    case PerinatalTier.avoid:
      return 'Avoid';
    case PerinatalTier.unknown:
      return 'No clear guidance';
  }
}

/// One drug's perinatal profile.
class PerinatalProfile {
  const PerinatalProfile({
    required this.drugId,
    required this.drugName,
    required this.pregnancyTier,
    required this.pregnancyNote,
    required this.lactationTier,
    required this.lactationNote,
    required this.sources,
  });

  /// Registry drug id (matches `Drug.id`).
  final String drugId;
  final String drugName;

  final PerinatalTier pregnancyTier;
  final String pregnancyNote;

  final PerinatalTier lactationTier;
  final String lactationNote;

  /// Sources line (e.g. "Maudsley 15e · LactMed").
  final String sources;
}

const List<PerinatalProfile> kPerinatalAtlas = <PerinatalProfile>[
  // ── SSRIs ──────────────────────────────────────────────────────────
  PerinatalProfile(
    drugId: 'sertraline',
    drugName: 'Sertraline',
    pregnancyTier: PerinatalTier.preferred,
    pregnancyNote:
        'First-line SSRI in pregnancy across all trimesters. Most '
        'reassuring teratogenicity data; transient neonatal adaptation '
        'syndrome possible with third-trimester exposure but generally '
        'self-limiting.',
    lactationTier: PerinatalTier.preferred,
    lactationNote:
        'Low relative infant dose (~0.5%). Largest body of LactMed '
        'data of any SSRI; preferred during breastfeeding.',
    sources: 'Maudsley 15e · LactMed · UKTIS',
  ),
  PerinatalProfile(
    drugId: 'fluoxetine',
    drugName: 'Fluoxetine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Reasonable choice but long half-life means persistence into '
        'neonatal period; small increase in cardiac malformation '
        'signal in some registries. Continue if effective; do not '
        'switch in pregnancy purely for safety reasons.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Higher relative infant dose than sertraline (~5-10%); active '
        'metabolite norfluoxetine accumulates. Acceptable but monitor '
        'infant for irritability / poor feeding.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'paroxetine',
    drugName: 'Paroxetine',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'Associated with a small absolute increase in cardiac '
        'malformations (especially RVOT) with first-trimester '
        'exposure. Marked neonatal discontinuation syndrome with '
        'third-trimester exposure.',
    lactationTier: PerinatalTier.preferred,
    lactationNote:
        'Low relative infant dose; one of the preferred SSRIs in '
        'lactation when initiating post-partum.',
    sources: 'Maudsley 15e · UKTIS',
  ),
  PerinatalProfile(
    drugId: 'escitalopram',
    drugName: 'Escitalopram',
    pregnancyTier: PerinatalTier.preferred,
    pregnancyNote:
        'No teratogenic signal in pooled registries; preferred '
        'alternative if sertraline isn\'t tolerated.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Acceptable; relative infant dose ~5%. Less data than '
        'sertraline.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'fluvoxamine',
    drugName: 'Fluvoxamine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Less data than other SSRIs; reasonable to continue if '
        'effective, otherwise switch to sertraline.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Limited data; acceptable with monitoring.',
    sources: 'LactMed',
  ),
  PerinatalProfile(
    drugId: 'citalopram',
    drugName: 'Citalopram',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Comparable to escitalopram; observed mild cardiac signal '
        'in registries.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Relative infant dose ~5%. Acceptable, less preferred than '
        'sertraline.',
    sources: 'Maudsley 15e · LactMed',
  ),

  // ── SNRIs ──────────────────────────────────────────────────────────
  PerinatalProfile(
    drugId: 'venlafaxine',
    drugName: 'Venlafaxine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'No major teratogen signal but neonatal adaptation syndrome '
        '(irritability, feeding difficulties) more prominent than '
        'with SSRIs.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Relative infant dose ~7%. Acceptable; monitor infant.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'duloxetine',
    drugName: 'Duloxetine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote: 'Limited data; no clear teratogenic signal.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Limited data; relative infant dose < 1%.',
    sources: 'LactMed',
  ),

  // ── Other antidepressants ─────────────────────────────────────────
  PerinatalProfile(
    drugId: 'mirtazapine',
    drugName: 'Mirtazapine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'No major teratogenic signal; sometimes preferred when sleep '
        'and weight gain are clinically desirable.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose ~2%. Acceptable.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'moclobemide',
    drugName: 'Moclobemide',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'Insufficient human data; theoretical concern about '
        'serotonergic interactions during labour.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Limited data; transfer reported to be low.',
    sources: 'UKTIS',
  ),

  // ── Antipsychotics ────────────────────────────────────────────────
  PerinatalProfile(
    drugId: 'olanzapine',
    drugName: 'Olanzapine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'No clear teratogenic signal; weigh against maternal weight '
        'gain, gestational diabetes risk. Continue if effective for '
        'severe illness.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Relative infant dose ~1%. Acceptable; monitor infant for '
        'sedation.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'quetiapine',
    drugName: 'Quetiapine',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Lowest placental transfer of the common atypicals; reasonable '
        'choice when continuation is necessary.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose < 1%. Acceptable.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'risperidone',
    drugName: 'Risperidone',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Limited data but no clear teratogenic signal. Watch '
        'hyperprolactinaemia in mother.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose ~3%. Acceptable.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'aripiprazole',
    drugName: 'Aripiprazole',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Limited human data; no clear teratogenic signal so far.',
    lactationTier: PerinatalTier.avoid,
    lactationNote:
        'May suppress lactation via D2 partial agonism / reduced '
        'prolactin. Consider alternatives if breastfeeding is the '
        'priority.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'haloperidol',
    drugName: 'Haloperidol',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Extensive historical use without clear teratogenic signal; '
        'reasonable in severe psychotic illness.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose ~2%. Acceptable.',
    sources: 'Maudsley 15e',
  ),
  PerinatalProfile(
    drugId: 'clozapine',
    drugName: 'Clozapine',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'Risk of neonatal floppy-infant syndrome, agranulocytosis '
        'concerns, gestational diabetes. If irreplaceable for '
        'treatment-resistant illness, continue with specialist '
        'oversight.',
    lactationTier: PerinatalTier.avoid,
    lactationNote:
        'Concentrates in milk; case reports of agranulocytosis and '
        'sedation in infants. Generally not recommended.',
    sources: 'Maudsley 15e · LactMed',
  ),

  // ── Mood stabilisers ──────────────────────────────────────────────
  PerinatalProfile(
    drugId: 'lithium',
    drugName: 'Lithium',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Small absolute increase in Ebstein\'s anomaly with '
        'first-trimester exposure (~0.6% vs ~0.1% baseline). For many '
        'severe bipolar patients the benefit outweighs the risk; '
        'monitor levels more frequently and dose-adjust through '
        'pregnancy. Hold around delivery to avoid neonatal toxicity.',
    lactationTier: PerinatalTier.avoid,
    lactationNote:
        'Variable but significant transfer with serum levels in '
        'infants up to 50% of maternal. Generally avoid; if continued, '
        'monitor infant serum lithium, TSH, and renal function.',
    sources: 'Maudsley 15e · UKTIS · LactMed',
  ),
  PerinatalProfile(
    drugId: 'lamotrigine',
    drugName: 'Lamotrigine',
    pregnancyTier: PerinatalTier.preferred,
    pregnancyNote:
        'Preferred mood stabiliser in pregnancy. No clear teratogenic '
        'signal at psychiatric doses. Levels fall ~40% by 32 weeks — '
        'monitor and dose-adjust.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Relative infant dose 9-18%. Monitor infant for rash and '
        'measure levels if symptomatic.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'valproate',
    drugName: 'Valproate',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'STRONGLY AVOID. Neural-tube defects (1-2%), cardiac, '
        'craniofacial malformations; mean IQ reduction of 7-10 points '
        'in exposed children. Pregnancy-prevention programme is '
        'mandatory.',
    lactationTier: PerinatalTier.cautious,
    lactationNote:
        'Low relative infant dose (<5%), acceptable if maternal use '
        'is unavoidable.',
    sources: 'Maudsley 15e · UKTIS · MHRA',
  ),
  PerinatalProfile(
    drugId: 'carbamazepine',
    drugName: 'Carbamazepine',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'Neural-tube defects (~1%), cardiac, craniofacial '
        'malformations. Less teratogenic than valproate but still '
        'avoid where possible.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose 3-5%. Monitor infant LFTs.',
    sources: 'Maudsley 15e · UKTIS',
  ),

  // ── Benzodiazepines / Z-drugs ────────────────────────────────────
  PerinatalProfile(
    drugId: 'diazepam',
    drugName: 'Diazepam',
    pregnancyTier: PerinatalTier.avoid,
    pregnancyNote:
        'Cleft-lip signal in older studies; floppy-infant syndrome '
        'and neonatal withdrawal with regular third-trimester use.',
    lactationTier: PerinatalTier.avoid,
    lactationNote:
        'Long half-life metabolites accumulate in infants. '
        'Short-acting alternatives (lorazepam) preferred.',
    sources: 'Maudsley 15e · LactMed',
  ),
  PerinatalProfile(
    drugId: 'lorazepam',
    drugName: 'Lorazepam',
    pregnancyTier: PerinatalTier.cautious,
    pregnancyNote:
        'Short-acting, no active metabolites. Brief courses '
        'reasonable; avoid sustained use in third trimester.',
    lactationTier: PerinatalTier.cautious,
    lactationNote: 'Relative infant dose ~2%. Acceptable short-term.',
    sources: 'Maudsley 15e · LactMed',
  ),
];

/// Get the profile for a drug id. Null when no entry is curated.
PerinatalProfile? perinatalProfileFor(String drugId) {
  for (final p in kPerinatalAtlas) {
    if (p.drugId == drugId) return p;
  }
  return null;
}
