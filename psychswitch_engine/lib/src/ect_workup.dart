// ECT work-up & peri-treatment checklist.
//
// Structured pre-ECT preparation and the medication review that
// trips people up. Summarised from the Maudsley 15e, RCPsych ECT
// Handbook (Waite & Easton), and NICE TA59.
//
// The checklist is grouped; an item is "satisfied" when ticked. The
// engine reports completion + the outstanding list + a clipboard
// summary. Drug-interaction notes are surfaced as their own group so
// they are reviewed explicitly, not buried.

class EctItem {
  const EctItem({
    required this.id,
    required this.label,
    required this.detail,
  });

  final String id;
  final String label;
  final String detail;
}

class EctGroup {
  const EctGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<EctItem> items;
}

const List<EctGroup> kEctGroups = <EctGroup>[
  EctGroup(
    title: 'Consent & indication',
    items: <EctItem>[
      EctItem(
        id: 'indication',
        label: 'Clear indication documented',
        detail: 'Severe / treatment-resistant depression, '
            'catatonia, prolonged or severe mania, high suicide risk '
            'needing rapid response, or patient preference.',
      ),
      EctItem(
        id: 'consent',
        label: 'Valid consent OR statutory authority',
        detail: 'Capacitous written consent, or — if lacking '
            'capacity — the relevant Mental Health Act authority + '
            'second opinion. Re-confirm capacity periodically through '
            'the course.',
      ),
      EctItem(
        id: 'second_opinion',
        label: 'Second opinion where required',
        detail: 'Required for detained / incapacitous patients per '
            'local legislation (e.g. MHA 2001 s.77 second '
            'psychiatrist + Board authority).',
      ),
    ],
  ),
  EctGroup(
    title: 'Pre-anaesthetic',
    items: <EctItem>[
      EctItem(
        id: 'anaesthetic_review',
        label: 'Anaesthetic assessment complete',
        detail: 'ASA grade, airway, cardiac / respiratory risk, '
            'previous anaesthetic problems.',
      ),
      EctItem(
        id: 'fasting',
        label: 'Fasting confirmed',
        detail: 'Nil by mouth ≥ 6 h solids, ≥ 2 h clear fluids. '
            'Withhold morning oral hypoglycaemics; plan diabetic '
            'management.',
      ),
      EctItem(
        id: 'investigations',
        label: 'Baseline investigations reviewed',
        detail: 'FBC, U&E, glucose; ECG (and CXR / echo if '
            'cardiac history). Pregnancy test if indicated.',
      ),
      EctItem(
        id: 'dental',
        label: 'Dental / airway check',
        detail: 'Loose teeth, dentures, crowns documented; bite '
            'block plan. Remove dentures before each treatment.',
      ),
      EctItem(
        id: 'anticoagulation',
        label: 'Anticoagulation reviewed',
        detail: 'ECT is generally safe on stable anticoagulation; '
            'confirm therapeutic-range INR / DOAC plan with the '
            'anaesthetist rather than stopping reflexively.',
      ),
    ],
  ),
  EctGroup(
    title: 'Medication review',
    items: <EctItem>[
      EctItem(
        id: 'lithium',
        label: 'Lithium — reduce / hold + level',
        detail: 'Increases risk of prolonged seizures, post-ictal '
            'delirium and neurotoxicity. Consider holding the night '
            'before and on treatment mornings; aim level at the '
            'lower end; check a level.',
      ),
      EctItem(
        id: 'benzo_anticonvulsant',
        label: 'Benzodiazepines / anticonvulsants minimised',
        detail: 'Raise seizure threshold and shorten seizures. '
            'Minimise / withhold pre-treatment where clinically '
            'safe; flumazenil is occasionally used by anaesthetics.',
      ),
      EctItem(
        id: 'clozapine_bupropion',
        label: 'Seizure-threshold-lowering agents noted',
        detail: 'Clozapine, bupropion, high-dose antipsychotics — '
            'risk of prolonged / tardive seizures. Document and '
            'inform the anaesthetist.',
      ),
      EctItem(
        id: 'theophylline',
        label: 'Theophylline / aminophylline flagged',
        detail: 'Markedly increases status-epilepticus risk — '
            'review necessity and levels with the medical team.',
      ),
      EctItem(
        id: 'maoi',
        label: 'MAOI interaction considered',
        detail: 'ECT can be given on MAOIs but coordinate with '
            'anaesthetics — avoid indirect sympathomimetics; use '
            'direct agents for hypotension.',
      ),
    ],
  ),
  EctGroup(
    title: 'During the course',
    items: <EctItem>[
      EctItem(
        id: 'cognitive_monitoring',
        label: 'Cognitive monitoring scheduled',
        detail: 'Baseline + every ~3-4 treatments (orientation, '
            'autobiographical memory). Switch bilateral → unilateral '
            'or reduce frequency if cognitive impairment emerges.',
      ),
      EctItem(
        id: 'response_monitoring',
        label: 'Response monitoring scheduled',
        detail: 'Track a depression / target-symptom scale each '
            'week; review continuation after ~6-12 treatments.',
      ),
      EctItem(
        id: 'seizure_adequacy',
        label: 'Seizure adequacy reviewed each session',
        detail: 'EEG seizure ≥ ~15 s; restimulate if missed / '
            'inadequate. Review stimulus dosing and caffeine / '
            'hyperventilation augmentation if persistently short.',
      ),
    ],
  ),
];

class EctResult {
  const EctResult({
    required this.totalItems,
    required this.satisfied,
    required this.outstanding,
  });

  final int totalItems;
  final int satisfied;

  /// Labels of unticked items, in group order.
  final List<String> outstanding;

  bool get isComplete => satisfied == totalItems;
  double get fraction =>
      totalItems == 0 ? 0 : satisfied / totalItems;

  String clipboardSummary() {
    final lines = <String>[
      'ECT work-up: $satisfied / $totalItems items complete'
          '${isComplete ? "  — READY" : ""}',
    ];
    if (!isComplete) {
      lines
        ..add('')
        ..add('Outstanding:')
        ..addAll(outstanding.map((o) => ' · $o'));
    }
    return lines.join('\n');
  }
}

EctResult evaluateEct(Set<String> ticked) {
  var total = 0;
  var done = 0;
  final outstanding = <String>[];
  for (final g in kEctGroups) {
    for (final it in g.items) {
      total++;
      if (ticked.contains(it.id)) {
        done++;
      } else {
        outstanding.add(it.label);
      }
    }
  }
  return EctResult(
    totalItems: total,
    satisfied: done,
    outstanding: outstanding,
  );
}
