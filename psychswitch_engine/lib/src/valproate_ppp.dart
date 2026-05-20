// Valproate Pregnancy Prevention Programme (PPP) — prescribing gate.
//
// Valproate exposure in pregnancy carries ~10% risk of major
// congenital malformation and ~30–40% risk of neurodevelopmental
// disorder. Regulators (MHRA and equivalents) require a formal
// Pregnancy Prevention Programme before valproate is used in any
// person able to become pregnant. This engine turns the PPP
// checklist into a clear prescribing verdict + the outstanding
// requirements. Summarised from the Maudsley 15e and MHRA valproate
// safety guidance.

enum ValproateVerdict {
  notApplicable('PPP not applicable'),
  permitted('May prescribe — PPP conditions met'),
  conditional('Only if PPP conditions completed'),
  avoid('Do NOT prescribe valproate');

  const ValproateVerdict(this.label);
  final String label;
}

class ValproatePppInput {
  const ValproatePppInput({
    this.childbearingPotential = true,
    this.pregnant = false,
    this.forBipolar = true,
    this.noEffectiveAlternative = false,
    this.highlyEffectiveContraception = false,
    this.annualRiskAcknowledgement = false,
    this.specialistReview = false,
  });

  /// Able to become pregnant (not the case if e.g. post-menopausal
  /// or permanently sterilised — clinician judgement).
  final bool childbearingPotential;
  final bool pregnant;

  /// Indication: bipolar (true) vs epilepsy (false). Bipolar has a
  /// stricter bar — effective alternatives almost always exist.
  final bool forBipolar;
  final bool noEffectiveAlternative;
  final bool highlyEffectiveContraception;
  final bool annualRiskAcknowledgement;
  final bool specialistReview;
}

class ValproatePppResult {
  const ValproatePppResult({
    required this.verdict,
    required this.headline,
    required this.outstanding,
    required this.actions,
    required this.cautions,
  });

  final ValproateVerdict verdict;
  final String headline;

  /// PPP requirements not yet satisfied.
  final List<String> outstanding;
  final List<String> actions;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Valproate PPP — ${verdict.label}',
      headline,
      '',
      if (outstanding.isNotEmpty) ...<String>[
        'Outstanding PPP requirements:',
        for (final o in outstanding) ' · $o',
        '',
      ],
      'Actions:',
      for (final a in actions) ' · $a',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _cautions = <String>[
  'Risk in pregnancy: ~10% major congenital malformation, '
      '~30–40% neurodevelopmental disorder — among the highest of '
      'any commonly used drug.',
  'The PPP includes an annual specialist review and a signed '
      'Risk Acknowledgement Form; supply should be in original '
      'packaging with the warning and patient card.',
  'Never stop valproate abruptly in someone established on it '
      '(seizure / relapse risk) — plan any switch with the '
      'specialist.',
];

ValproatePppResult evaluateValproatePpp(ValproatePppInput i) {
  if (!i.childbearingPotential) {
    return const ValproatePppResult(
      verdict: ValproateVerdict.notApplicable,
      headline:
          'Not of childbearing potential — the PPP gate does not '
          'apply, but document the basis for that judgement.',
      outstanding: <String>[],
      actions: <String>[
        'Record why childbearing potential does not apply and '
            'review if circumstances change.',
        'Still counsel on general adverse effects and monitoring.',
      ],
      cautions: _cautions,
    );
  }

  if (i.pregnant) {
    return ValproatePppResult(
      verdict: ValproateVerdict.avoid,
      headline:
          'Pregnant — valproate is contraindicated unless there is '
          'genuinely no alternative for severe epilepsy under '
          'specialist care; never for bipolar.',
      outstanding: const <String>[],
      actions: <String>[
        if (i.forBipolar)
          'Do not use valproate for bipolar in pregnancy — switch '
              'planning with the specialist as an urgent priority.'
        else
          'Specialist (neurology/obstetric) decision only, with '
              'fully informed consent if truly no alternative.',
        'Refer for specialist counselling and fetal medicine '
            'input; ensure high-dose folate already in place.',
      ],
      cautions: _cautions,
    );
  }

  final outstanding = <String>[
    if (!i.specialistReview)
      'Annual specialist review of continued need not done.',
    if (!i.noEffectiveAlternative)
      'No documented confirmation that effective alternatives '
          'have been tried / are unsuitable.',
    if (!i.highlyEffectiveContraception)
      'Highly effective contraception not confirmed in place.',
    if (!i.annualRiskAcknowledgement)
      'Signed annual Risk Acknowledgement Form not completed.',
  ];

  // Bipolar with an available alternative → should not use at all.
  if (i.forBipolar && !i.noEffectiveAlternative) {
    return ValproatePppResult(
      verdict: ValproateVerdict.avoid,
      headline:
          'Bipolar indication with effective alternatives available '
          '— valproate should not be started / continued in someone '
          'able to become pregnant.',
      outstanding: outstanding,
      actions: const <String>[
        'Choose a non-valproate mood stabiliser; plan any switch '
            'from existing valproate with the specialist.',
        'Document the discussion and the alternative chosen.',
      ],
      cautions: _cautions,
    );
  }

  if (outstanding.isEmpty) {
    return ValproatePppResult(
      verdict: ValproateVerdict.permitted,
      headline:
          'All PPP conditions met — valproate may be used at the '
          'lowest effective dose with ongoing annual review.',
      outstanding: const <String>[],
      actions: const <String>[
        'Prescribe the lowest effective dose; dispense in '
            'original pack with warning label + patient card.',
        'Diarise the next annual specialist review and Risk '
            'Acknowledgement Form renewal.',
        'Re-counsel and reassess immediately if pregnancy is '
            'planned or suspected.',
      ],
      cautions: _cautions,
    );
  }

  return ValproatePppResult(
    verdict: ValproateVerdict.conditional,
    headline:
        'Childbearing potential — valproate only if every PPP '
        'requirement below is completed first.',
    outstanding: outstanding,
    actions: const <String>[
      'Complete all outstanding PPP requirements before '
          'prescribing / continuing.',
      'If they cannot be met, use a non-valproate alternative.',
      'Counsel on the malformation + neurodevelopmental risks and '
          'document understanding.',
    ],
    cautions: _cautions,
  );
}
