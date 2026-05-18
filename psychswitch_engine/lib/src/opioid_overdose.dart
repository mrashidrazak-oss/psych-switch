// Opioid overdose — take-home naloxone + acute reversal plan.
//
// Distinct from OST induction: this is the emergency-response and
// take-home-naloxone tool. The recurring killers are (1) failing to
// support airway/ventilation while waiting for naloxone to work and
// (2) re-narcotisation, because naloxone is shorter-acting than
// methadone / slow-release / long-acting opioids. Summarised from
// the Maudsley 15e, UK Orange Book 2017 and resuscitation guidance.

enum OverdoseSetting {
  community('Community / bystander (take-home kit)'),
  clinical('Clinical / supervised setting');

  const OverdoseSetting(this.label);
  final String label;
}

class OverdosePlan {
  const OverdosePlan({
    required this.setting,
    required this.longActing,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final OverdoseSetting setting;
  final bool longActing;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Opioid overdose — ${setting.label}'
          '${longActing ? ' · long-acting opioid' : ''}',
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

OverdosePlan buildOpioidOverdosePlan({
  OverdoseSetting setting = OverdoseSetting.community,
  bool longActingOrMethadone = false,
}) {
  final cautions = <String>[
    'RE-NARCOTISATION: naloxone wears off in ~20–90 min — shorter '
        'than most opioids — the person can re-overdose as it '
        'wears off. Never leave them alone afterwards.',
    'Use the smallest effective naloxone dose in opioid-dependent '
        'people to reverse hypoventilation WITHOUT precipitating '
        'severe acute withdrawal.',
    'Airway support and ventilation save lives while naloxone '
        'takes effect — do not delay basic resuscitation.',
  ];
  if (longActingOrMethadone) {
    cautions.insert(
      0,
      'Long-acting / methadone / slow-release overdose far '
          'outlasts naloxone — mandatory prolonged observation and '
          'often a naloxone infusion under medical care.',
    );
  }

  if (setting == OverdoseSetting.community) {
    return OverdosePlan(
      setting: setting,
      longActing: longActingOrMethadone,
      headline:
          'Bystander response with a take-home naloxone kit while '
          'waiting for the ambulance.',
      steps: <String>[
        'Call emergency services immediately; check responsiveness '
            'and breathing.',
        'Give naloxone per the kit (IM, or intranasal per device); '
            'if no response in ~2–3 min, give a further dose and '
            'repeat as supplied.',
        'Support the airway and give rescue breaths / CPR if '
            'trained; place in the recovery position if breathing.',
        'Stay until help arrives — repeated doses are often needed; '
            'symptoms can return as naloxone wears off.',
      ],
      cautions: cautions,
    );
  }

  return OverdosePlan(
    setting: setting,
    longActing: longActingOrMethadone,
    headline:
        'Supervised reversal with airway support and titrated '
        'naloxone.',
    steps: <String>[
      'A-B-C: secure airway, give high-flow oxygen and support '
          'ventilation; call the resuscitation / medical team.',
      'Titrate IV naloxone in small increments to restore '
          'adequate respiration (target ventilation, not full '
          'arousal) — repeat as needed; IM if no IV access.',
      if (longActingOrMethadone)
        'Set up a naloxone infusion and admit for prolonged '
            'monitoring — the opioid will outlast bolus naloxone.'
      else
        'Observe for an extended period for re-sedation before any '
            'discharge decision.',
      'Investigate / treat co-ingestants and complications '
          '(aspiration, hypoxic injury); document and refer to '
          'drug services with a take-home naloxone supply.',
    ],
    cautions: cautions,
  );
}
