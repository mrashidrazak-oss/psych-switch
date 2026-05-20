// Opioid-substitution-treatment (OST) induction protocol.
//
// The COWS scale (already shipped) scores opioid-withdrawal
// severity; this engine turns the agent choice + objective
// withdrawal into a day-1 induction protocol with the safety gates
// people get wrong (precipitated withdrawal with buprenorphine,
// methadone accumulation / day-3 deaths). Summarised from the UK
// "Orange Book" (Drug misuse and dependence: clinical guidelines
// 2017), NICE, and the Maudsley 15e.

enum OstAgent {
  buprenorphine('Buprenorphine'),
  methadone('Methadone');

  const OstAgent(this.label);
  final String label;
}

class OstInput {
  const OstInput({
    required this.agent,
    required this.cowsScore,
    required this.longActingOpioidOrFentanyl,
    required this.lowTolerance,
  });

  final OstAgent agent;

  /// Latest COWS total (0–48).
  final int cowsScore;

  /// On methadone / slow-release morphine / fentanyl — higher
  /// precipitated-withdrawal + accumulation risk.
  final bool longActingOpioidOrFentanyl;

  /// Uncertain / low tolerance, older, comorbid, or polydrug — start
  /// lower.
  final bool lowTolerance;
}

class OstPlan {
  const OstPlan({
    required this.canStartNow,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  /// Safe to give the first dose now?
  final bool canStartNow;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'OST induction',
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

OstPlan buildOstPlan(OstInput i) {
  final steps = <String>[];
  final cautions = <String>[];

  if (i.agent == OstAgent.buprenorphine) {
    final ready = i.cowsScore >= 12;
    if (!ready) {
      steps.add(
        'WAIT: COWS ${i.cowsScore} — defer the first dose until '
        'objective withdrawal (COWS ≥ 12, ideally ≥ 12–13 with '
        'clear physical signs) to avoid precipitated withdrawal.',
      );
    }
    final first = i.lowTolerance ? '2 mg' : '4 mg';
    steps
      ..add('Day 1 dose 1: buprenorphine $first SL once COWS ≥ 12 '
          'with physical signs.')
      ..add('Reassess at 1–2 h: if persisting withdrawal, give a '
          'further 2–4 mg.')
      ..add('Typical day-1 total 8 mg (range 4–12 mg; up to 16 mg '
          'only if heavy use + clearly tolerated).')
      ..add('Day 2 onward: titrate by 2–4 mg/day to a maintenance '
          'dose (commonly 12–24 mg).');
    cautions
      ..add('Precipitated withdrawal risk if a full agonist is still '
          'on board — the COWS gate is the safeguard.')
      ..add('Fentanyl / long-acting opioids: higher precipitated-'
          'withdrawal risk; consider a longer wait, smaller first '
          'dose, or specialist micro-dosing induction.');
    return OstPlan(
      canStartNow: ready,
      headline: ready
          ? 'Buprenorphine — withdrawal adequate; induct now.'
          : 'Buprenorphine — NOT yet (COWS < 12). Wait for '
              'objective withdrawal.',
      steps: steps,
      cautions: cautions,
    );
  }

  // Methadone
  final day1Start = i.lowTolerance ? '10–20 mg' : '20–30 mg';
  steps
    ..add('Day 1: methadone $day1Start PO. Confirm recent illicit '
        'use; do not dose a non-tolerant or intoxicated patient.')
    ..add('If withdrawal persists 2–4 h after the first dose, a '
        'cautious supplemental 5–10 mg may be given — day-1 total '
        'should not exceed ~30 mg (40 mg only with clear high '
        'tolerance + supervision).')
    ..add('Days 2–7: increase slowly (≈ 5–10 mg every few days, '
        'max ~30 mg/week) — steady state takes ~5 days.')
    ..add('Supervised consumption during induction.');
  cautions
    ..add('METHADONE ACCUMULATES — long half-life means day-3 / '
        'early-induction deaths from delayed peak. "Start low, go '
        'slow"; warn the patient not to top up with illicit opioids '
        '/ sedatives.')
    ..add('QTc risk at higher doses + with interacting drugs — '
        'baseline ECG if risk factors.')
    ..add('Caution with concurrent benzodiazepines / alcohol / '
        'pregabalin — respiratory-depression synergy.');
  return OstPlan(
    canStartNow: true,
    headline: 'Methadone — cautious day-1 induction.',
    steps: steps,
    cautions: cautions,
  );
}
