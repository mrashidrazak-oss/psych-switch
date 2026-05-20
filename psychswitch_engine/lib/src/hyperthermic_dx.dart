// Hyperthermic-emergency differentiator.
//
// The four toxidromes that present as "hot, altered, unstable" and
// are routinely confused at 3am: neuroleptic malignant syndrome,
// serotonin syndrome, malignant catatonia, and anticholinergic
// toxicity. Tick the features present; the engine ranks the
// differentials and surfaces the distinguishing pearl + management
// for the leading one.
//
// Feature set + discriminators summarised from the Maudsley 15e,
// Boyer & Shannon (serotonin syndrome, NEJM 2005), and Fink & Taylor
// (catatonia).

class HyperthermicFeature {
  const HyperthermicFeature({
    required this.id,
    required this.label,
    required this.subtitle,
  });

  final String id;
  final String label;
  final String subtitle;
}

const List<HyperthermicFeature> kHyperthermicFeatures =
    <HyperthermicFeature>[
  // Exposures
  HyperthermicFeature(
    id: 'dopamine_antagonist',
    label: 'Dopamine antagonist exposure',
    subtitle: 'Antipsychotic started / increased, or dopaminergic '
        'agent abruptly stopped.',
  ),
  HyperthermicFeature(
    id: 'serotonergic_agent',
    label: 'Serotonergic agent exposure',
    subtitle: 'SSRI/SNRI, MAOI, tramadol, linezolid, recent dose '
        'increase or combination.',
  ),
  HyperthermicFeature(
    id: 'anticholinergic_agent',
    label: 'Anticholinergic agent exposure',
    subtitle: 'TCA, antihistamine, oxybutynin, benztropine, '
        'antipsychotic with high muscarinic load, plant / OTC.',
  ),
  HyperthermicFeature(
    id: 'psychiatric_prodrome',
    label: 'Catatonic / psychiatric prodrome',
    subtitle: 'Stupor, mutism, posturing, negativism, waxy '
        'flexibility preceding the autonomic picture.',
  ),
  // Onset
  HyperthermicFeature(
    id: 'onset_rapid',
    label: 'Rapid onset (< 24 h)',
    subtitle: 'Hours from the offending exposure.',
  ),
  HyperthermicFeature(
    id: 'onset_subacute',
    label: 'Subacute onset (days–2 weeks)',
    subtitle: 'Evolves over days after starting / increasing the '
        'drug.',
  ),
  // Neuromuscular
  HyperthermicFeature(
    id: 'lead_pipe_rigidity',
    label: 'Lead-pipe rigidity',
    subtitle: 'Generalised, uniform rigidity; bradyreflexia.',
  ),
  HyperthermicFeature(
    id: 'clonus_hyperreflexia',
    label: 'Clonus + hyperreflexia',
    subtitle: 'Lower-limb predominant; myoclonus, tremor.',
  ),
  HyperthermicFeature(
    id: 'catatonic_signs',
    label: 'Catatonic signs',
    subtitle: 'Posturing, waxy flexibility, negativism, '
        'echophenomena.',
  ),
  HyperthermicFeature(
    id: 'normal_tone',
    label: 'Normal / near-normal tone',
    subtitle: 'No rigidity or clonus despite agitation.',
  ),
  // Skin / autonomic / pupils
  HyperthermicFeature(
    id: 'diaphoresis',
    label: 'Diaphoretic, moist skin',
    subtitle: 'Sweating prominent.',
  ),
  HyperthermicFeature(
    id: 'dry_flushed_skin',
    label: 'Dry, flushed skin',
    subtitle: 'Anhidrosis; "red as a beet".',
  ),
  HyperthermicFeature(
    id: 'mydriasis',
    label: 'Mydriasis (dilated pupils)',
    subtitle: '',
  ),
  HyperthermicFeature(
    id: 'hyperactive_bowel',
    label: 'Hyperactive bowel sounds',
    subtitle: 'Diarrhoea, increased peristalsis.',
  ),
  HyperthermicFeature(
    id: 'absent_bowel_retention',
    label: 'Absent bowel sounds / urinary retention',
    subtitle: 'Ileus; "dry as a bone".',
  ),
  HyperthermicFeature(
    id: 'markedly_raised_ck',
    label: 'Markedly raised CK',
    subtitle: 'CK often in the thousands; risk of rhabdomyolysis.',
  ),
];

class HyperthermicDifferential {
  const HyperthermicDifferential({
    required this.id,
    required this.name,
    required this.tagline,
    required this.features,
    required this.discriminator,
    required this.management,
  });

  final String id;
  final String name;
  final String tagline;
  final List<String> features;
  final String discriminator;
  final String management;
}

const List<HyperthermicDifferential> kHyperthermicDifferentials =
    <HyperthermicDifferential>[
  HyperthermicDifferential(
    id: 'nms',
    name: 'Neuroleptic malignant syndrome',
    tagline: 'Dopamine block · lead-pipe rigidity · days · ↑↑CK',
    features: <String>[
      'dopamine_antagonist',
      'onset_subacute',
      'lead_pipe_rigidity',
      'diaphoresis',
      'markedly_raised_ck',
    ],
    discriminator:
        'Distinguish from serotonin syndrome by SLOW onset, '
        'lead-pipe rigidity with HYPOreflexia (not clonus), and '
        'very high CK. Bowel sounds normal / reduced.',
    management:
        'Stop the antipsychotic. Supportive care, aggressive '
        'cooling, IV fluids to protect renal function. Dantrolene '
        '1–2.5 mg/kg IV and/or bromocriptine 2.5 mg q8h for '
        'moderate–severe. ICU. Consider ECT if refractory or if '
        'malignant catatonia overlaps.',
  ),
  HyperthermicDifferential(
    id: 'serotonin',
    name: 'Serotonin syndrome',
    tagline: 'Serotonergic agent · clonus + hyperreflexia · hours',
    features: <String>[
      'serotonergic_agent',
      'onset_rapid',
      'clonus_hyperreflexia',
      'diaphoresis',
      'mydriasis',
      'hyperactive_bowel',
    ],
    discriminator:
        'Distinguish from NMS by RAPID onset, clonus / '
        'hyperreflexia (lower-limb predominant) and hyperactive '
        'bowel sounds. Hunter criteria are the reference test.',
    management:
        'Stop all serotonergic agents. Supportive care, cooling, '
        'IV fluids, benzodiazepine for agitation / rigidity. '
        'Cyproheptadine 12 mg then 2 mg q2h for moderate–severe. '
        'ICU + paralysis if temperature uncontrolled.',
  ),
  HyperthermicDifferential(
    id: 'malignant_catatonia',
    name: 'Malignant catatonia',
    tagline: 'Catatonic prodrome → autonomic storm',
    features: <String>[
      'psychiatric_prodrome',
      'catatonic_signs',
      'onset_subacute',
      'diaphoresis',
      'markedly_raised_ck',
    ],
    discriminator:
        'Catatonic signs (posturing, waxy flexibility, negativism) '
        'PRECEDE the autonomic instability. Clinically '
        'indistinguishable from NMS once florid — the history and '
        'a lorazepam challenge guide you. AVOID antipsychotics.',
    management:
        'Stop antipsychotics. Lorazepam challenge / loading is '
        'first-line; ECT is highly effective and is the treatment '
        'of choice if lorazepam-refractory or rapidly '
        'deteriorating. Supportive care + ICU.',
  ),
  HyperthermicDifferential(
    id: 'anticholinergic',
    name: 'Anticholinergic toxicity',
    tagline: 'Dry / flushed · mydriasis · ileus · normal tone',
    features: <String>[
      'anticholinergic_agent',
      'onset_rapid',
      'normal_tone',
      'dry_flushed_skin',
      'mydriasis',
      'absent_bowel_retention',
    ],
    discriminator:
        'The discriminator is the SKIN: dry and flushed (vs '
        'diaphoretic in NMS / serotonin syndrome), with absent '
        'bowel sounds, urinary retention and NORMAL tone. '
        'Mumbling delirium; CK usually normal / mildly raised.',
    management:
        'Stop the offending agent. Supportive care, cooling, '
        'benzodiazepine for agitation. Physostigmine may be used '
        'for pure central antimuscarinic delirium in a monitored '
        'setting (avoid if TCA / wide QRS — seizure / asystole '
        'risk). Toxicology input.',
  ),
];

class HyperthermicRanking {
  const HyperthermicRanking({
    required this.differential,
    required this.matches,
  });
  final HyperthermicDifferential differential;
  final int matches;
}

class HyperthermicResult {
  const HyperthermicResult({
    required this.rankings,
    required this.topId,
    required this.totalChecked,
  });

  final List<HyperthermicRanking> rankings;
  final String? topId;
  final int totalChecked;

  HyperthermicDifferential? get top {
    if (topId == null) return null;
    return kHyperthermicDifferentials.firstWhere(
      (d) => d.id == topId,
      orElse: () => kHyperthermicDifferentials.first,
    );
  }

  String clipboardSummary() {
    final t = top;
    if (t == null) {
      return 'Hyperthermic differentiator — no features ticked.';
    }
    return 'Leading differential: ${t.name}. ${t.discriminator} '
        '${t.management}';
  }
}

HyperthermicResult rankHyperthermic(Set<String> ticked) {
  final rankings = kHyperthermicDifferentials.map((d) {
    final m = d.features.where(ticked.contains).length;
    return HyperthermicRanking(differential: d, matches: m);
  }).toList()
    ..sort((a, b) => b.matches.compareTo(a.matches));

  String? topId;
  if (ticked.isNotEmpty &&
      rankings.isNotEmpty &&
      rankings.first.matches > 0) {
    topId = rankings.first.differential.id;
  }

  return HyperthermicResult(
    rankings: rankings,
    topId: topId,
    totalChecked: ticked.length,
  );
}
