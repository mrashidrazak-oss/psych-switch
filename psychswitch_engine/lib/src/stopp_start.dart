// STOPP / START — geriatric psychiatry deprescribing aid.
//
// "Screening Tool of Older Persons' Prescriptions" (STOPP) and
// "Screening Tool to Alert to Right Treatment" (START) — O'Mahony
// et al., 2015 (v2) — surface the deprescribing / initiation prompts
// most relevant to a psychiatrist managing a patient aged ≥ 65.
//
// Only the psychiatry-relevant rules are surfaced here; the full
// STOPP/START toolset contains > 100 rules across all of medicine.
//
// Each rule maps to one or more drug ids in the registry. When the
// caller passes a regimen, `applyStoppStart` returns the matching
// rules so the UI can render an actionable list.

enum RuleKind {
  stopp('stopp'),
  start('start');

  const RuleKind(this.jsonValue);
  final String jsonValue;
}

class StoppRule {
  const StoppRule({
    required this.id,
    required this.kind,
    required this.title,
    required this.rationale,
    required this.drugIds,
    this.classMatch,
  });

  final String id;
  final RuleKind kind;
  final String title;

  /// Short clinical reasoning shown in the card.
  final String rationale;

  /// Drug ids that trigger this rule.
  final List<String> drugIds;

  /// Optional class-level match (any drug whose drugClass contains
  /// this substring triggers the rule). Used when listing every TCA
  /// or every long-acting benzo would be tedious.
  final String? classMatch;
}

/// Match result for one rule against the regimen.
class StoppMatch {
  const StoppMatch({
    required this.rule,
    required this.matchedDrugIds,
  });

  final StoppRule rule;
  final List<String> matchedDrugIds;
}

const List<StoppRule> kStoppStartRules = <StoppRule>[
  // ── STOPP — deprescribe in the elderly ──────────────────────────
  StoppRule(
    id: 'stopp_long_benzo',
    kind: RuleKind.stopp,
    title: 'Avoid long-acting benzodiazepines in older adults',
    rationale:
        'Long-acting benzos (diazepam, clonazepam) double the fall + '
        'fracture rate and worsen cognition. Switch to a short-acting '
        'agent for brief use or taper completely.',
    drugIds: <String>['diazepam', 'clonazepam', 'chlordiazepoxide'],
  ),
  StoppRule(
    id: 'stopp_benzo_chronic',
    kind: RuleKind.stopp,
    title: 'Avoid benzodiazepines for ≥ 4 weeks of continuous use',
    rationale:
        'Tolerance to anxiolytic / hypnotic effect develops within '
        'days-weeks; ongoing risk of falls, cognitive impairment, '
        'dependence. Taper using diazepam equivalents over 2–3 months.',
    drugIds: <String>[
      'diazepam',
      'lorazepam',
      'clonazepam',
      'alprazolam',
      'chlordiazepoxide',
    ],
  ),
  StoppRule(
    id: 'stopp_tca_anticholinergic',
    kind: RuleKind.stopp,
    title: 'Avoid tricyclic antidepressants as first-line in older adults',
    rationale:
        'High anticholinergic burden (delirium, urinary retention, '
        'falls) + orthostatic hypotension + arrhythmogenic. Prefer an '
        'SSRI / SNRI unless TCA-specific indication.',
    drugIds: <String>[
      'amitriptyline',
      'nortriptyline',
      'imipramine',
      'clomipramine',
      'doxepin',
    ],
  ),
  StoppRule(
    id: 'stopp_first_gen_antipsychotic',
    kind: RuleKind.stopp,
    title: 'Avoid first-generation antipsychotics for chronic use',
    rationale:
        'Higher EPS / TD risk; in dementia-related psychosis carries '
        'a black-box mortality warning. Use only for the briefest '
        'period at the lowest effective dose.',
    drugIds: <String>['haloperidol', 'chlorpromazine', 'thioridazine'],
  ),
  StoppRule(
    id: 'stopp_anticholinergic_psychotropic',
    kind: RuleKind.stopp,
    title: 'Avoid highly anticholinergic psychotropics',
    rationale:
        'Cumulative anticholinergic burden (ACB ≥ 3) drives delirium, '
        'cognitive decline, falls. Includes promethazine, '
        'hydroxyzine, oxybutynin, and the anti-EPS adjuncts '
        'procyclidine / trihexyphenidyl.',
    drugIds: <String>[
      'promethazine',
      'hydroxyzine',
      'oxybutynin',
      'procyclidine',
      'trihexyphenidyl',
      'benztropine',
    ],
  ),
  StoppRule(
    id: 'stopp_zdrugs',
    kind: RuleKind.stopp,
    title: 'Avoid Z-drugs for chronic insomnia in older adults',
    rationale:
        'Zolpidem / zopiclone increase fall + fracture rates; complex '
        'sleep behaviours documented. Limit to short-term, occasional '
        'use only.',
    drugIds: <String>['zolpidem', 'zopiclone'],
  ),
  StoppRule(
    id: 'stopp_paroxetine',
    kind: RuleKind.stopp,
    title: 'Avoid paroxetine as first-line SSRI in older adults',
    rationale:
        'Most anticholinergic of the SSRIs + significant '
        'discontinuation syndrome on missed doses. Prefer sertraline '
        'or escitalopram.',
    drugIds: <String>['paroxetine'],
  ),
  StoppRule(
    id: 'stopp_anticholinergic_for_eps',
    kind: RuleKind.stopp,
    title: 'Avoid anticholinergic anti-EPS adjuncts prophylactically',
    rationale:
        'In older adults the cognitive cost usually outweighs the EPS '
        'benefit. Consider antipsychotic dose reduction or switching '
        'to a low-EPS agent (quetiapine, olanzapine, aripiprazole) '
        'first.',
    drugIds: <String>['procyclidine', 'trihexyphenidyl', 'benztropine'],
  ),

  // ── START — initiate if appropriate ─────────────────────────────
  StoppRule(
    id: 'start_ssri_for_persistent_depression',
    kind: RuleKind.start,
    title: 'Consider an SSRI for persistent depressive symptoms',
    rationale:
        'Untreated depression in older adults is associated with '
        'cognitive decline + functional loss. Start sertraline / '
        'escitalopram at half the adult initial dose.',
    drugIds: <String>[],
    classMatch: 'antidepressant',
  ),
  StoppRule(
    id: 'start_cholinesterase_inhibitor',
    kind: RuleKind.start,
    title: 'Consider a cholinesterase inhibitor in mild–moderate '
        'Alzheimer-type dementia',
    rationale:
        'Donepezil / rivastigmine / galantamine confer modest cognitive '
        'benefit and may delay institutionalisation. Out of registry '
        'scope today but mark for discussion in shared care.',
    drugIds: <String>[],
  ),
];

/// Return every rule that applies given the regimen drug ids.
List<StoppMatch> applyStoppStart(List<String> regimenDrugIds) {
  final ids = regimenDrugIds.toSet();
  final out = <StoppMatch>[];
  for (final r in kStoppStartRules) {
    final matched = r.drugIds.where(ids.contains).toList();
    if (matched.isNotEmpty) {
      out.add(StoppMatch(rule: r, matchedDrugIds: matched));
    }
  }
  return out;
}
