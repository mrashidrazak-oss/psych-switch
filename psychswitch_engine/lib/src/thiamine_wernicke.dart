// Wernicke's encephalopathy — thiamine prophylaxis vs treatment.
//
// The single commonest avoidable error in addictions psychiatry:
// oral thiamine is inadequately absorbed in active / malnourished
// drinkers, and glucose given before thiamine can precipitate
// Wernicke's. This engine maps the clinical scenario to the right
// route + dose. Summarised from the Maudsley 15e, NICE CG100,
// Royal College of Physicians, and EFNS guidance.

enum ThiamineScenario {
  prophylaxisLowRisk('Prophylaxis — low risk'),
  prophylaxisHighRisk('Prophylaxis — high risk'),
  suspectedWernicke('Suspected / established Wernicke\'s');

  const ThiamineScenario(this.label);
  final String label;
}

class ThiaminePlan {
  const ThiaminePlan({
    required this.scenario,
    required this.headline,
    required this.regimen,
    required this.keyPoints,
  });

  final ThiamineScenario scenario;
  final String headline;
  final String regimen;
  final List<String> keyPoints;

  String clipboardSummary() {
    final lines = <String>[
      'Thiamine / Wernicke plan — ${scenario.label}',
      headline,
      '',
      'Regimen: $regimen',
      '',
      'Key points:',
      for (final k in keyPoints) ' · $k',
    ];
    return lines.join('\n');
  }
}

const _glucoseRule =
    'Give thiamine BEFORE any IV glucose / carbohydrate load — '
    'glucose without thiamine can precipitate Wernicke\'s.';

const _magnesiumRule =
    'Correct magnesium — it is a cofactor; thiamine is ineffective '
    'in hypomagnesaemia.';

ThiaminePlan buildThiaminePlan(ThiamineScenario s) {
  switch (s) {
    case ThiamineScenario.prophylaxisLowRisk:
      return const ThiaminePlan(
        scenario: ThiamineScenario.prophylaxisLowRisk,
        headline: 'Well, eating, uncomplicated dependence.',
        regimen:
            'Oral thiamine 100 mg TDS (some guidelines 200–300 mg/day) '
            'for the duration of detox and while drinking continues.',
        keyPoints: <String>[
          'Oral is acceptable ONLY if the patient is well-nourished, '
              'eating, not vomiting, and not in significant '
              'withdrawal.',
          _glucoseRule,
          'Escalate to parenteral immediately if any Wernicke '
              'feature, poor intake, or vomiting develops.',
        ],
      );
    case ThiamineScenario.prophylaxisHighRisk:
      return const ThiaminePlan(
        scenario: ThiamineScenario.prophylaxisHighRisk,
        headline:
            'Malnourished / poor diet / vomiting / decompensated / '
            'inpatient detox.',
        regimen:
            'Parenteral B-vitamins — e.g. Pabrinex IV high-potency '
            'ONE pair OD–BD for 3–5 days, then high-dose oral '
            'thiamine (≥ 100 mg TDS) thereafter.',
        keyPoints: <String>[
          'Oral absorption is unreliable in active / malnourished '
              'drinkers — do not rely on oral for prophylaxis here.',
          _glucoseRule,
          _magnesiumRule,
          'Have anaphylaxis facilities available for IV pairs '
              '(rare; give over ~30 min).',
        ],
      );
    case ThiamineScenario.suspectedWernicke:
      return const ThiaminePlan(
        scenario: ThiamineScenario.suspectedWernicke,
        headline:
            'Treat empirically — the classic triad (confusion, '
            'ataxia, ophthalmoplegia) is often INCOMPLETE; treat on '
            'suspicion.',
        regimen:
            'Parenteral B-vitamins — e.g. Pabrinex IV high-potency '
            'TWO pairs TDS for ≥ 3–5 days (continue while improving), '
            'then ONE pair OD for a further 3–5 days, then high-dose '
            'oral thiamine. Manage in a setting able to give IV '
            'safely.',
        keyPoints: <String>[
          'Do not wait for the full triad or for confirmatory '
              'imaging — under-treatment risks Korsakoff syndrome.',
          _glucoseRule,
          _magnesiumRule,
          'Reassess neurology daily; ophthalmoplegia often responds '
              'within hours, ataxia / confusion over days.',
        ],
      );
  }
}
