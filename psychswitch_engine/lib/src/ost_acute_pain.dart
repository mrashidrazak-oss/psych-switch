// Acute / peri-operative pain in patients on opioid maintenance.
//
// A recurrent error is withholding the maintenance dose or
// under-treating acute pain because the patient is "on opioids".
// The principles: CONTINUE the baseline OST, treat the acute pain
// ADDITIONALLY and adequately, and account for the specific agent
// (buprenorphine's high receptor affinity; naltrexone's blockade).
// Summarised from the Maudsley 15e and UK Orange Book 2017.

enum OstAgentForPain {
  methadone('On methadone'),
  buprenorphine('On buprenorphine'),
  naltrexone('On naltrexone');

  const OstAgentForPain(this.label);
  final String label;
}

enum PainSeverity {
  mildModerate('Mild–moderate'),
  severeOrSurgical('Severe / surgical');

  const PainSeverity(this.label);
  final String label;
}

class OstPainPlan {
  const OstPainPlan({
    required this.agent,
    required this.severity,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final OstAgentForPain agent;
  final PainSeverity severity;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Acute pain on OST — ${agent.label} · ${severity.label}',
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

const _shared = <String>[
  'CONTINUE the usual maintenance dose (verify the dose/last '
      'dose with the prescriber or service) — it does NOT treat '
      'acute pain.',
  'Treat the acute pain on its own merits: maximise non-opioid '
      'multimodal analgesia (paracetamol, NSAID if safe, regional '
      '/ local techniques).',
  'Expect tolerance — effective opioid doses for breakthrough '
      'pain are often HIGHER and more frequent; review and de-'
      'escalate with a clear plan.',
  'Involve the acute pain team and the patient’s drug service '
      'early; document the plan and avoid discharge without '
      'continuity.',
];

OstPainPlan buildOstAcutePainPlan({
  OstAgentForPain agent = OstAgentForPain.methadone,
  PainSeverity severity = PainSeverity.mildModerate,
}) {
  final steps = <String>[..._shared];
  final cautions = <String>[];

  switch (agent) {
    case OstAgentForPain.methadone:
      cautions.add(
        'Methadone: watch additive sedation / QT with other '
            'agents; the maintenance dose gives little background '
            'analgesia by the time of acute pain.',
      );
      if (severity == PainSeverity.severeOrSurgical) {
        steps.add(
          'Severe/surgical: titrate full-agonist opioids to effect '
              'ON TOP of maintenance, with appropriate monitoring; '
              'consider splitting methadone to TDS for any analgesic '
              'contribution under specialist advice.',
        );
      }
    case OstAgentForPain.buprenorphine:
      cautions.add(
        'Buprenorphine has very high mu affinity — it can blunt '
            'additional full-agonist analgesia; do NOT simply stop '
            'it (loss of tolerance + relapse risk). Decide '
            'continue-vs-adjust WITH specialist input.',
      );
      if (severity == PainSeverity.severeOrSurgical) {
        steps.add(
          'Severe/surgical: options (specialist-led) include '
              'continuing buprenorphine and titrating higher-dose '
              'full agonist, using its own analgesic effect '
              '(divided dosing), or a planned peri-operative '
              'strategy agreed with anaesthesia + addiction.',
        );
      }
    case OstAgentForPain.naltrexone:
      cautions.add(
        'Naltrexone BLOCKS opioid analgesia. Oral naltrexone '
            'should be stopped ~72 h before elective procedures; '
            'depot naltrexone blockade lasts much longer — plan '
            'well ahead.',
      );
      steps
        ..add(
          'For elective pain/surgery: stop oral naltrexone in '
              'advance (≈72 h) per specialist advice; for depot, '
              'plan around the much longer blockade.',
        )
        ..add(
          'Emergency/unavoidable pain during blockade: use '
              'maximal non-opioid + regional analgesia; opioids '
              'work poorly and need very high, closely monitored '
              'doses in a critical-care setting — anaesthetics '
              'led.',
        );
  }

  return OstPainPlan(
    agent: agent,
    severity: severity,
    headline: severity == PainSeverity.severeOrSurgical
        ? 'Severe / surgical pain — specialist-led, maintenance '
            'continued, acute pain treated additionally.'
        : 'Mild–moderate pain — multimodal non-opioid first, '
            'maintenance continued.',
    steps: steps,
    cautions: cautions,
  );
}
