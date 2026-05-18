// High-dose antipsychotic therapy (HDAT) — cumulative %-of-maximum.
//
// "High-dose" is defined by the CUMULATIVE percentage of the maximum
// licensed dose when ≥1 antipsychotic is used (incl. PRN + depot).
// Exceeding 100% is not absolutely contraindicated but mandates a
// documented rationale and enhanced physical monitoring. This engine
// sums the percentages and returns the HDAT status + the safeguards.
// Summarised from the Maudsley 15e and the RCPsych HDAT consensus.

class AntipsychoticMax {
  const AntipsychoticMax(this.id, this.name, this.maxDailyMg);
  final String id;
  final String name;

  /// Approximate maximum licensed adult daily dose (mg). Always
  /// confirm against the local formulary.
  final double maxDailyMg;
}

const kAntipsychoticMaxDoses = <AntipsychoticMax>[
  AntipsychoticMax('amisulpride', 'Amisulpride', 1200),
  AntipsychoticMax('aripiprazole', 'Aripiprazole', 30),
  AntipsychoticMax('chlorpromazine', 'Chlorpromazine', 1000),
  AntipsychoticMax('clozapine', 'Clozapine', 900),
  AntipsychoticMax('flupentixol', 'Flupentixol (oral)', 18),
  AntipsychoticMax('haloperidol', 'Haloperidol', 20),
  AntipsychoticMax('olanzapine', 'Olanzapine', 20),
  AntipsychoticMax('paliperidone', 'Paliperidone (oral)', 12),
  AntipsychoticMax('quetiapine', 'Quetiapine', 800),
  AntipsychoticMax('risperidone', 'Risperidone', 16),
  AntipsychoticMax('sulpiride', 'Sulpiride', 2400),
  AntipsychoticMax('zuclopenthixol', 'Zuclopenthixol (oral)', 150),
];

class HdatResult {
  const HdatResult({
    required this.totalPercent,
    required this.isHighDose,
    required this.headline,
    required this.perDrug,
    required this.safeguards,
    required this.cautions,
  });

  /// Cumulative % of maximum licensed dose across all entries.
  final double totalPercent;
  final bool isHighDose;
  final String headline;

  /// "Name: 12 mg → 60% of max" lines, in entry order.
  final List<String> perDrug;
  final List<String> safeguards;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'High-dose antipsychotic check — '
          '${totalPercent.toStringAsFixed(0)}% of maximum',
      headline,
      '',
      'Per drug:',
      for (final d in perDrug) ' · $d',
      '',
      if (isHighDose) ...<String>[
        'HDAT safeguards:',
        for (final s in safeguards) ' · $s',
        '',
      ],
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

const _cautions = <String>[
  'Percentages use approximate maximum licensed doses — always '
      'confirm against the current local formulary.',
  'Count ALL antipsychotic exposure: regular + PRN + depot/LAI '
      '(antipsychotic polypharmacy commonly tips total > 100%).',
  'High dose is not absolutely contraindicated but should be a '
      'considered, time-limited, documented decision after '
      'optimising a single agent (incl. clozapine where '
      'appropriate).',
];

const _safeguards = <String>[
  'Document the explicit rationale, target, review date and '
      'senior / MDT agreement before going above 100%.',
  'Baseline + regular ECG (QTc) and pulse, blood pressure and '
      'temperature monitoring.',
  'Increase monitoring frequency; have a clear plan to reduce '
      'back below 100% if no clear benefit.',
  'Inform the patient (and carer) of the off-licence / '
      'high-dose status and record consent discussion.',
];

/// [doses] maps an [AntipsychoticMax.id] to the total daily mg for
/// that drug (regular + PRN + depot-equivalent).
HdatResult evaluateHighDose(Map<String, double> doses) {
  final perDrug = <String>[];
  var total = 0.0;
  for (final ap in kAntipsychoticMaxDoses) {
    final mg = doses[ap.id];
    if (mg == null || mg <= 0) continue;
    final pct = mg / ap.maxDailyMg * 100;
    total += pct;
    perDrug.add(
      '${ap.name}: ${mg.toStringAsFixed(mg % 1 == 0 ? 0 : 1)} mg '
      '→ ${pct.toStringAsFixed(0)}% of max',
    );
  }

  if (perDrug.isEmpty) {
    return const HdatResult(
      totalPercent: 0,
      isHighDose: false,
      headline: 'No antipsychotic doses entered.',
      perDrug: <String>[],
      safeguards: <String>[],
      cautions: _cautions,
    );
  }

  final high = total > 100;
  return HdatResult(
    totalPercent: total,
    isHighDose: high,
    headline: high
        ? 'HIGH-DOSE antipsychotic therapy — cumulative dose '
            'exceeds 100% of maximum; apply the safeguards.'
        : 'Within the standard range (≤ 100% of maximum '
            'cumulative).',
    perDrug: perDrug,
    safeguards: high ? _safeguards : const <String>[],
    cautions: _cautions,
  );
}
