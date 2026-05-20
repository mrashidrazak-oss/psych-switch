// Psychotropic-associated weight gain — stepwise management ladder.
//
// Distinct from the metabolic MONITORING schedule: this is the
// what-to-do-when-weight-climbs ladder. A sustained ≥ 7% gain from
// baseline is the recognised trigger to act. This engine grades the
// gain, factors in the agent's weight-gain risk tier, and returns
// the stepwise intervention. Summarised from the Maudsley 15e.

enum WeightGainTier {
  minimal('Minimal change'),
  emerging('Emerging gain (< 7%)'),
  significant('Significant gain (≥ 7%)'),
  marked('Marked gain (≥ 15%)');

  const WeightGainTier(this.label);
  final String label;
}

class MetabolicWeightResult {
  const MetabolicWeightResult({
    required this.tier,
    required this.percentGain,
    required this.headline,
    required this.steps,
    required this.cautions,
  });

  final WeightGainTier tier;
  final double percentGain;
  final String headline;
  final List<String> steps;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Psychotropic weight gain — ${tier.label} '
          '(${percentGain.toStringAsFixed(1)}%)',
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
  'Highest weight-gain risk: olanzapine and clozapine; '
      'intermediate: quetiapine, risperidone, paliperidone; lower: '
      'aripiprazole, lurasidone, ziprasidone, amisulpride.',
  'Never stop an effective antipsychotic abruptly for weight '
      'alone — weigh relapse risk and switch only with a plan.',
  'Screen the whole metabolic picture (glucose/HbA1c, lipids, '
      'BP, waist) — weight is one component of cardiometabolic '
      'risk.',
];

WeightGainTier _band(double pct) {
  if (pct >= 15) return WeightGainTier.marked;
  if (pct >= 7) return WeightGainTier.significant;
  if (pct >= 3) return WeightGainTier.emerging;
  return WeightGainTier.minimal;
}

MetabolicWeightResult evaluateMetabolicWeight({
  double percentGain = 0,
  bool highRiskAgent = false,
}) {
  final pct = percentGain < 0 ? 0.0 : percentGain;
  final tier = _band(pct);

  switch (tier) {
    case WeightGainTier.minimal:
      return MetabolicWeightResult(
        tier: tier,
        percentGain: pct,
        headline:
            'Little change — focus on prevention and ongoing '
            'monitoring.',
        steps: <String>[
          'Reinforce diet / physical-activity advice from the '
              'start; record weight and waist at each review.',
          if (highRiskAgent)
            'On a high-risk agent (olanzapine/clozapine): proactive '
                'lifestyle support and tighter monitoring from '
                'initiation.',
        ],
        cautions: _cautions,
      );
    case WeightGainTier.emerging:
      return MetabolicWeightResult(
        tier: tier,
        percentGain: pct,
        headline:
            'Emerging gain — intervene early before it reaches '
            'the 7% threshold.',
        steps: <String>[
          'Intensify structured lifestyle intervention (dietetics '
              '/ exercise referral where available).',
          'Review the regimen: is the dose minimised? Is a lower-'
              'risk agent appropriate if response allows?',
          'Recheck weight + metabolic panel on a defined interval.',
        ],
        cautions: _cautions,
      );
    case WeightGainTier.significant:
      return MetabolicWeightResult(
        tier: tier,
        percentGain: pct,
        headline:
            'Sustained ≥ 7% gain — the recognised trigger to '
            'escalate.',
        steps: <String>[
          'Optimise lifestyle support AND consider metformin as '
              'adjunctive pharmacological management (per Maudsley, '
              'if no contraindication).',
          'Actively consider switching to a lower weight-gain-risk '
              'antipsychotic if the illness is stable enough — '
              'plan the switch, do not stop abruptly.',
          'Full cardiometabolic review and treat components '
              '(glucose, lipids, BP) on their merits.',
        ],
        cautions: _cautions,
      );
    case WeightGainTier.marked:
      return MetabolicWeightResult(
        tier: tier,
        percentGain: pct,
        headline:
            'Marked gain — comprehensive intervention and a clear '
            'switch / specialist plan.',
        steps: <String>[
          'Combine intensive lifestyle + metformin and a planned '
              'switch to a lower-risk agent where clinically '
              'feasible.',
          'Refer for specialist weight-management input; consider '
              'GLP-1 / orlistat pathways via the appropriate '
              'service.',
          'Aggressively manage the full cardiometabolic risk and '
              'document the long-term plan and review dates.',
        ],
        cautions: _cautions,
      );
  }
}
