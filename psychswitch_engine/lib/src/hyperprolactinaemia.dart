// Antipsychotic-induced hyperprolactinaemia — assessment + management.
//
// A very common, under-treated antipsychotic adverse effect with
// real long-term harms (hypogonadism, sexual dysfunction, reduced
// bone mineral density, possible breast effects). This engine bands
// the prolactin level, flags when the level is high enough that a
// prolactinoma must be excluded, and gives a stepwise management
// plan. Summarised from the Maudsley 15e and Endocrine Society /
// UK consensus guidance.

enum ProlactinBand {
  normal('Normal'),
  mild('Mildly raised'),
  moderate('Moderately raised'),
  high('Markedly raised');

  const ProlactinBand(this.label);
  final String label;
}

class HyperprolactinResult {
  const HyperprolactinResult({
    required this.band,
    required this.headline,
    required this.imagingAdvised,
    required this.steps,
    required this.cautions,
  });

  final ProlactinBand band;
  final String headline;

  /// True when the level is high enough that a pituitary tumour
  /// should be actively excluded with imaging.
  final bool imagingAdvised;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Antipsychotic hyperprolactinaemia — ${band.label}',
      headline,
      '',
      if (imagingAdvised)
        'Imaging: pituitary MRI advised — exclude prolactinoma.'
      else
        'Imaging: not mandated on level alone; image if symptoms / '
            'level out of keeping with the drug.',
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

/// [prolactin] in mIU/L. Approx conversion: 1 ng/mL ≈ 21 mIU/L.
HyperprolactinResult evaluateHyperprolactinaemia({
  double? prolactin,
  bool symptomatic = false,
}) {
  ProlactinBand band;
  if (prolactin == null || prolactin < 530) {
    band = ProlactinBand.normal;
  } else if (prolactin < 1000) {
    band = ProlactinBand.mild;
  } else if (prolactin < 2000) {
    band = ProlactinBand.moderate;
  } else {
    band = ProlactinBand.high;
  }

  final imagingAdvised = band == ProlactinBand.high;

  const sharedCautions = <String>[
    'A drug-naive baseline (or value before switching) makes '
        'attribution far easier — interpret in context.',
    'Macroprolactin and recent venepuncture stress can cause '
        'spuriously high results — confirm with a repeat / '
        'macroprolactin screen before major changes.',
    'Do not stop an effective antipsychotic abruptly for an '
        'asymptomatic mild rise — weigh relapse risk against harm.',
  ];

  switch (band) {
    case ProlactinBand.normal:
      return const HyperprolactinResult(
        band: ProlactinBand.normal,
        headline: 'Prolactin within normal limits.',
        imagingAdvised: false,
        steps: <String>[
          'No action for the level itself. Ask about galactorrhoea, '
              'menstrual change, sexual dysfunction and check the '
              'baseline was done — symptoms can precede a measured '
              'rise.',
        ],
        cautions: sharedCautions,
      );
    case ProlactinBand.mild:
      return const HyperprolactinResult(
        band: ProlactinBand.mild,
        headline:
            'Mildly raised — commonly drug-related, especially with '
            'risperidone / paliperidone / amisulpride / typicals.',
        imagingAdvised: false,
        steps: <String>[
          'Clarify cause: exclude pregnancy, hypothyroidism, renal '
              'impairment, stress sampling, and other prolactin-'
              'raising drugs.',
          'If asymptomatic: monitor, recheck, and document — '
              'routine treatment change is not always needed.',
          'If symptomatic: discuss switching to a prolactin-sparing '
              'agent (aripiprazole, quetiapine, or low-dose '
              'aripiprazole augmentation) per Maudsley.',
        ],
        cautions: sharedCautions,
      );
    case ProlactinBand.moderate:
      return const HyperprolactinResult(
        band: ProlactinBand.moderate,
        headline:
            'Moderately raised — likely drug-related but warrants '
            'active management.',
        imagingAdvised: false,
        steps: <String>[
          'Confirm with a repeat (rule out macroprolactin / stress); '
              'review symptoms and bone / gonadal consequences.',
          'Switch to a prolactin-sparing antipsychotic, or add '
              'aripiprazole augmentation, balancing relapse risk.',
          'If the level is out of keeping with the drug, symptoms '
              'are prominent, or it does not settle after change — '
              'image the pituitary and involve endocrinology.',
        ],
        cautions: sharedCautions,
      );
    case ProlactinBand.high:
      return const HyperprolactinResult(
        band: ProlactinBand.high,
        headline:
            'Markedly raised — too high to attribute to an '
            'antipsychotic without excluding a prolactinoma.',
        imagingAdvised: true,
        steps: <String>[
          'Arrange pituitary MRI and refer to endocrinology — a '
              'level this high is unusual for drug effect alone.',
          'Do not assume it is the antipsychotic; investigate in '
              'parallel with any treatment change.',
          'Manage symptomatic hypogonadism / bone health with the '
              'endocrine team; review antipsychotic choice.',
        ],
        cautions: sharedCautions,
      );
  }
}
