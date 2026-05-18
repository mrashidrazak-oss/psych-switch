// 4AT — rapid delirium assessment.
//
// Bellelli G, Morandi A, Davis DHJ, et al. Age Ageing 2014;43:496-502.
// Free for clinical, educational and research use (the4at.com). Four
// items, ~2 minutes, no special training. Heterogeneous item scoring
// (NOT a simple Likert sum) so it gets its own engine rather than the
// generic scale model.
//
//   Item 1  Alertness                       0 / 4
//   Item 2  AMT4 (age, DOB, place, year)    0 / 1 / 2
//   Item 3  Attention (months backwards)    0 / 1 / 2
//   Item 4  Acute change / fluctuating      0 / 4
//
// Total 0-12.
//   ≥ 4  → possible delirium ± cognitive impairment
//   1-3  → possible cognitive impairment
//   0    → delirium / severe cognitive impairment unlikely

class FourAtOption {
  const FourAtOption({required this.label, required this.score});
  final String label;
  final int score;
}

class FourAtItem {
  const FourAtItem({
    required this.id,
    required this.title,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String title;
  final String prompt;
  final List<FourAtOption> options;
}

const List<FourAtItem> kFourAtItems = <FourAtItem>[
  FourAtItem(
    id: 'alertness',
    title: 'Alertness',
    prompt: 'Observe. If asleep, attempt to wake with speech or gentle '
        'touch. Rate the level of alertness.',
    options: <FourAtOption>[
      FourAtOption(label: 'Normal (fully alert, not agitated)', score: 0),
      FourAtOption(
        label: 'Mild sleepiness < 10 s after waking, then normal',
        score: 0,
      ),
      FourAtOption(
        label: 'Clearly abnormal — sleepy / agitated / hard to rouse',
        score: 4,
      ),
    ],
  ),
  FourAtItem(
    id: 'amt4',
    title: 'AMT4',
    prompt: 'Ask: age, date of birth, place (name of hospital / '
        'building), current year.',
    options: <FourAtOption>[
      FourAtOption(label: 'No mistakes', score: 0),
      FourAtOption(label: '1 mistake', score: 1),
      FourAtOption(label: '≥ 2 mistakes / untestable', score: 2),
    ],
  ),
  FourAtItem(
    id: 'attention',
    title: 'Attention',
    prompt: 'Ask the patient to recite the months of the year '
        'backwards, starting at December.',
    options: <FourAtOption>[
      FourAtOption(
        label: 'Achieves ≥ 7 months correctly',
        score: 0,
      ),
      FourAtOption(
        label: 'Starts but < 7 months / refuses to start',
        score: 1,
      ),
      FourAtOption(
        label: 'Untestable (drowsy, inattentive)',
        score: 2,
      ),
    ],
  ),
  FourAtItem(
    id: 'acute_change',
    title: 'Acute change or fluctuating course',
    prompt: 'Evidence of significant change or fluctuation in '
        'alertness, cognition, or other mental function arising over '
        'the last 2 weeks and still evident in the last 24 h.',
    options: <FourAtOption>[
      FourAtOption(label: 'No', score: 0),
      FourAtOption(label: 'Yes', score: 4),
    ],
  ),
];

class FourAtResult {
  const FourAtResult({
    required this.total,
    required this.label,
    required this.interpretation,
    required this.severity,
  });

  final int total;
  final String label;
  final String interpretation;

  /// 0 = unlikely, 1 = possible cognitive impairment, 2 = possible
  /// delirium.
  final int severity;

  String clipboardSummary() =>
      '4AT: $total / 12 — $label. $interpretation';
}

/// Score the 4AT from a map of itemId -> chosen option score.
FourAtResult scoreFourAt(Map<String, int> answers) {
  var total = 0;
  for (final item in kFourAtItems) {
    total += (answers[item.id] ?? 0);
  }
  if (total >= 4) {
    return FourAtResult(
      total: total,
      label: 'Possible delirium',
      interpretation:
          'Possible delirium ± cognitive impairment. Confirm clinically '
          '(DSM-5-TR), screen for precipitants (infection, drugs, '
          'metabolic, retention, pain), and review the medication list '
          'for deliriogenic agents.',
      severity: 2,
    );
  }
  if (total >= 1) {
    return FourAtResult(
      total: total,
      label: 'Possible cognitive impairment',
      interpretation:
          'Possible cognitive impairment. Delirium is less likely but '
          'not excluded — repeat if the clinical picture fluctuates; '
          'arrange cognitive follow-up.',
      severity: 1,
    );
  }
  return const FourAtResult(
    total: 0,
    label: 'Delirium unlikely',
    interpretation:
        'Delirium or severe cognitive impairment unlikely on this '
        'screen. Re-screen if mental state changes.',
    severity: 0,
  );
}
