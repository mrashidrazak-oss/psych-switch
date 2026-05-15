// Columbia-Suicide Severity Rating Scale (C-SSRS) — recent-screener
// adaptation.
//
// The C-SSRS is the most widely-used standardised suicide-risk
// instrument. It separates IDEATION (level 1–5), INTENSITY of ideation,
// and BEHAVIOUR (any-lifetime, last 3 months). The full instrument is
// in the public domain (Posner et al., 2011 — Columbia/NIMH).
//
// This engine surfaces the structure clinicians need at the bedside:
//   • Ideation severity level (1 → 5)
//   • Has there been any suicidal behaviour?
//   • Combined "risk tier" (Low / Moderate / High) plus a one-line
//     verdict + recommended next action.
//
// IDEATION LEVEL (highest reached in the look-back window):
//   1 — Wish to be dead
//   2 — Non-specific active suicidal thoughts
//   3 — Suicidal thoughts with method (no plan, no intent)
//   4 — Suicidal intent (no specific plan)
//   5 — Suicidal intent with specific plan
//
// RISK TIER (Columbia triage 2016):
//   • High      — ideation level 4 or 5, OR any behaviour in the last
//                 3 months
//   • Moderate  — ideation level 2 or 3 within the last month, OR
//                 any-lifetime behaviour
//   • Low       — ideation level 1 only, no behaviour
//   • None      — no ideation and no behaviour reported
//
// THIS IS DECISION SUPPORT, NOT A DECISION. Any positive screen
// requires a clinical interview — the engine's verdict is a starting
// point, not a discharge.

enum CssrsTier {
  none('none'),
  low('low'),
  moderate('moderate'),
  high('high');

  const CssrsTier(this.jsonValue);
  final String jsonValue;
}

class CssrsItem {
  const CssrsItem({
    required this.id,
    required this.level,
    required this.prompt,
    required this.note,
  });

  final String id;

  /// 1–5, anchors the severity ladder.
  final int level;
  final String prompt;
  final String note;
}

/// Input to the engine — all booleans the clinician has captured.
class CssrsInput {
  const CssrsInput({
    required this.highestIdeationLevel,
    required this.ideationLastMonth,
    required this.behaviourLifetime,
    required this.behaviourLast3Months,
  });

  /// Highest ideation level reached. 0 = no ideation, 1–5 per scale.
  final int highestIdeationLevel;

  /// Was any of that ideation present in the last month?
  final bool ideationLastMonth;

  /// Any-lifetime self-injurious behaviour with at least some intent
  /// to die (actual / interrupted / aborted / preparatory).
  final bool behaviourLifetime;

  /// Same behaviour categories — within the last 3 months.
  final bool behaviourLast3Months;
}

class CssrsResult {
  const CssrsResult({
    required this.tier,
    required this.tierLabel,
    required this.headline,
    required this.recommendation,
    required this.input,
  });

  final CssrsTier tier;
  final String tierLabel;
  final String headline;

  /// Top-line action item the clinician can paste into the note.
  final String recommendation;

  final CssrsInput input;

  String clipboardSummary() {
    final lvl = input.highestIdeationLevel == 0
        ? 'no current ideation'
        : 'ideation level ${input.highestIdeationLevel}';
    final beh = input.behaviourLast3Months
        ? 'behaviour within last 3 months'
        : (input.behaviourLifetime
            ? 'any-lifetime behaviour'
            : 'no reported behaviour');
    return 'C-SSRS: $tierLabel risk — $lvl; $beh. $recommendation';
  }
}

CssrsResult evaluateCssrs(CssrsInput input) {
  final lvl = input.highestIdeationLevel;
  final behaviourRecent = input.behaviourLast3Months;
  final behaviourEver = input.behaviourLifetime || behaviourRecent;

  if (lvl == 0 && !behaviourEver) {
    return CssrsResult(
      tier: CssrsTier.none,
      tierLabel: 'No reported risk',
      headline: 'Patient denies suicidal ideation and behaviour.',
      recommendation:
          'Document negative screen. Reassess at next visit and on any '
          'clinical deterioration.',
      input: input,
    );
  }

  if (lvl >= 4 || behaviourRecent) {
    return CssrsResult(
      tier: CssrsTier.high,
      tierLabel: 'High',
      headline: 'High suicide risk — immediate intervention indicated.',
      recommendation:
          'Do not leave alone. Means restriction, urgent psychiatric '
          'review / admission consideration, collateral history, '
          'safety plan, follow-up within 24-72 hours.',
      input: input,
    );
  }

  if ((lvl >= 2 && input.ideationLastMonth) || behaviourEver) {
    return CssrsResult(
      tier: CssrsTier.moderate,
      tierLabel: 'Moderate',
      headline: 'Moderate suicide risk — same-day review indicated.',
      recommendation:
          'Complete Stanley-Brown safety plan. Means restriction. '
          'Outpatient follow-up within 1 week. Document precipitants, '
          'protective factors, and patient-named supports.',
      input: input,
    );
  }

  return CssrsResult(
    tier: CssrsTier.low,
    tierLabel: 'Low',
    headline: 'Low suicide risk — supportive monitoring.',
    recommendation:
        'Reassess at next visit. Provide crisis-hotline information. '
        'Document protective factors + reasons for living.',
    input: input,
  );
}

/// The five ideation prompts in level order. UI renders these as a
/// 5-step ladder so the clinician picks the HIGHEST level reached.
const List<CssrsItem> kCssrsIdeationLadder = <CssrsItem>[
  CssrsItem(
    id: 'cssrs_lvl1',
    level: 1,
    prompt: 'Wish to be dead',
    note: 'Has the patient wished they were dead or could go to sleep '
        'and not wake up?',
  ),
  CssrsItem(
    id: 'cssrs_lvl2',
    level: 2,
    prompt: 'Non-specific active suicidal thoughts',
    note: 'Actual thoughts of killing themselves, without thoughts of '
        'ways to do so.',
  ),
  CssrsItem(
    id: 'cssrs_lvl3',
    level: 3,
    prompt: 'Suicidal thoughts with method',
    note: 'Thinking about a method (but not a plan with details of '
        'time, place, etc.); no intent to act on those thoughts.',
  ),
  CssrsItem(
    id: 'cssrs_lvl4',
    level: 4,
    prompt: 'Suicidal intent without specific plan',
    note: 'Active suicidal thoughts of killing oneself and report has '
        'some intent to act on such thoughts, as opposed to "I have '
        'the thoughts but I definitely will not do anything".',
  ),
  CssrsItem(
    id: 'cssrs_lvl5',
    level: 5,
    prompt: 'Suicidal intent with specific plan',
    note: 'Thoughts of killing oneself with details of plan fully or '
        'partially worked out, and patient has some intent to carry '
        'it out.',
  ),
];
