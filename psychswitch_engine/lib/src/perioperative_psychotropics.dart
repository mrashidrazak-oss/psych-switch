// Perioperative management of psychotropics.
//
// "Stop everything before surgery" is a common and harmful default —
// abrupt discontinuation causes relapse, discontinuation syndromes
// and withdrawal. Most psychotropics are continued; a few need
// specific planning. This engine gives a per-class continue / adjust
// / specific-plan recommendation. Summarised from the Maudsley 15e
// and standard perioperative guidance — coordinate with anaesthesia.

enum PeriopClass {
  lithium('Lithium'),
  maoi('MAOI (irreversible)'),
  clozapine('Clozapine'),
  ssriSnri('SSRI / SNRI'),
  tca('Tricyclic antidepressant'),
  antipsychoticOther('Other antipsychotic'),
  valproateCarbamazepine('Valproate / carbamazepine'),
  benzodiazepine('Benzodiazepine'),
  stimulant('Stimulant');

  const PeriopClass(this.label);
  final String label;
}

enum PeriopStance {
  continueDrug('Continue'),
  planAdjust('Continue with a specific plan'),
  specialist('Specialist decision required');

  const PeriopStance(this.label);
  final String label;
}

class PeriopResult {
  const PeriopResult({
    required this.drugClass,
    required this.stance,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final PeriopClass drugClass;
  final PeriopStance stance;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Perioperative — ${drugClass.label} · ${stance.label}',
      headline,
      '',
      'Steps:',
      for (final s in steps) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _cautions = <String>[
  'Default is to CONTINUE psychotropics — abrupt stops cause '
      'relapse, discontinuation syndromes and withdrawal.',
  'Always agree the plan with the anaesthetist / surgical team '
      'in advance and document it; account for nil-by-mouth and '
      'the post-op route.',
  'Watch perioperative interactions: serotonergic drugs '
      '(tramadol/pethidine/methylene blue), QT-prolonging agents, '
      'and fluid/renal shifts affecting lithium.',
];

PeriopResult buildPeriopPlan(PeriopClass c) {
  switch (c) {
    case PeriopClass.lithium:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Continue for minor surgery; for major surgery hold '
            '~24–72 h before and watch fluids / renal function.',
        steps: const <String>[
          'Minor / day-case with normal renal function and good '
              'hydration: usually continue.',
          'Major surgery / large fluid shifts: omit on the day '
              '(commonly ~24–72 h before per local protocol), '
              'maintain hydration, monitor U&E and lithium level, '
              'restart when eating/drinking and stable.',
          'Avoid NSAIDs and watch ACE-I/diuretics — they raise '
              'lithium levels perioperatively.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.maoi:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.specialist,
        headline:
            'Do NOT stop reflexively — but anaesthesia must be '
            'planned around it (avoid pethidine / indirect '
            'sympathomimetics).',
        steps: const <String>[
          'Liaise early with psychiatry + anaesthesia; an "MAOI-'
              'safe" anaesthetic technique is usually preferable to '
              'stopping (washout ≈ 2 weeks risks relapse).',
          'Avoid pethidine, indirect-acting sympathomimetics and '
              'other contraindicated agents; flag clearly in the '
              'notes / drug chart.',
          'Only consider a planned washout for high-risk surgery '
              'after a specialist risk–benefit decision.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.clozapine:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Continue where possible — abrupt cessation risks '
            'rapid relapse and rebound; plan short interruptions '
            'carefully.',
        steps: const <String>[
          'Continue up to surgery if feasible; for nil-by-mouth, '
              'plan continuity and avoid gaps > ~48 h (re-titration '
              'rule applies if missed longer).',
          'Maintain FBC monitoring; watch additive sedation, '
              'hypotension and ileus risk perioperatively.',
          'If an interruption is unavoidable, agree a restart / '
              're-titration plan with the clozapine service.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.ssriSnri:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Generally continue; weigh a small bleeding-risk '
            'increase against relapse / discontinuation.',
        steps: const <String>[
          'Usually continue — routine stopping is not '
              'recommended; abrupt cessation risks discontinuation '
              'symptoms.',
          'For high-bleeding-risk surgery, discuss individually '
              'with the surgical team; consider gastroprotection if '
              'combined with NSAIDs.',
          'Avoid serotonergic perioperative agents (tramadol, '
              'pethidine, methylene blue).',
        ],
        cautions: _cautions,
      );
    case PeriopClass.tca:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Usually continue; flag anticholinergic, orthostatic '
            'and QT / arrhythmia considerations to anaesthesia.',
        steps: const <String>[
          'Continue in most cases; abrupt withdrawal causes a '
              'discontinuation syndrome.',
          'Inform anaesthesia: potential arrhythmia / QT, '
              'orthostatic hypotension and additive anticholinergic '
              'effects.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.antipsychoticOther:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.continueDrug,
        headline:
            'Continue — stopping risks relapse; note sedation, '
            'hypotension and QT.',
        steps: const <String>[
          'Continue through the perioperative period; plan the '
              'route if nil-by-mouth (depot timing, or short-term '
              'alternative formulation).',
          'Flag QT-prolonging potential and additive sedation / '
              'hypotension to anaesthesia.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.valproateCarbamazepine:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Continue (especially if used for epilepsy) — do not '
            'interrupt; plan the route.',
        steps: const <String>[
          'Continue without interruption; missing doses risks '
              'seizures / mood relapse.',
          'Plan parenteral / NG continuity if prolonged '
              'nil-by-mouth; be aware of enzyme effects '
              '(carbamazepine) and haematological / hepatic '
              'considerations.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.benzodiazepine:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.continueDrug,
        headline:
            'Continue maintenance — abrupt withdrawal can cause '
            'seizures; note additive respiratory depression.',
        steps: const <String>[
          'Continue the usual dose to avoid withdrawal; inform '
              'anaesthesia for additive sedation / respiratory '
              'depression and dosing of perioperative sedatives.',
          'Re-establish the regular dose promptly post-op.',
        ],
        cautions: _cautions,
      );
    case PeriopClass.stimulant:
      return PeriopResult(
        drugClass: c,
        stance: PeriopStance.planAdjust,
        headline:
            'Often withheld on the morning of major surgery '
            '(haemodynamic interaction) — decide with anaesthesia.',
        steps: const <String>[
          'For minor procedures usually continue; for major '
              'surgery many teams omit the day-of dose due to '
              'cardiovascular / anaesthetic interactions.',
          'Agree the plan with anaesthesia and restart promptly '
              'afterwards.',
        ],
        cautions: _cautions,
      );
  }
}
