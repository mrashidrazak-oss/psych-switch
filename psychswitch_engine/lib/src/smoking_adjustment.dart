// Smoking-status CYP1A2 dose-adjustment calculator.
//
// Polycyclic aromatic hydrocarbons in tobacco smoke (not nicotine)
// induce CYP1A2. Clozapine and olanzapine are major CYP1A2 substrates,
// so a change in smoking status changes plasma levels markedly:
//
//   • STOPPING smoking → loss of induction → levels RISE
//       clozapine ↑ up to ~50–70% over 2–4 weeks
//       olanzapine ↑ up to ~30%
//   • STARTING / resuming smoking → induction → levels FALL by a
//       similar proportion.
//
// NRT (patches / gum / vaping nicotine) does NOT induce CYP1A2 — it
// is the combustion products, so abrupt cessation on a medical ward
// (e.g. admission to a smoke-free unit) is the classic trap.
//
// Source: Maudsley 15e, Lowe & Ackman 2010, de Leon 2004.

enum SmokingChange {
  stopping('stopping'),
  starting('starting');

  const SmokingChange(this.jsonValue);
  final String jsonValue;
}

class SmokingDrug {
  const SmokingDrug({
    required this.id,
    required this.name,
    required this.stopFactor,
    required this.startFactor,
    required this.note,
  });

  final String id;
  final String name;

  /// Multiplicative change in plasma level when STOPPING smoking
  /// (e.g. 1.5 = +50%).
  final double stopFactor;

  /// Multiplicative change when STARTING smoking (e.g. 0.67 = −33%).
  final double startFactor;

  final String note;
}

const List<SmokingDrug> kSmokingDrugs = <SmokingDrug>[
  SmokingDrug(
    id: 'clozapine',
    name: 'Clozapine',
    stopFactor: 1.5,
    startFactor: 0.67,
    note: 'Highest-risk interaction. Abrupt cessation on a smoke-free '
        'ward can drive clozapine toxicity (sedation, seizures, '
        'myocarditis-mimics) within days. Check a level before / soon '
        'after the change.',
  ),
  SmokingDrug(
    id: 'olanzapine',
    name: 'Olanzapine',
    stopFactor: 1.3,
    startFactor: 0.77,
    note: 'Clinically meaningful but less dramatic than clozapine. '
        'Watch for sedation / EPS on cessation; loss of effect on '
        'resuming smoking.',
  ),
];

SmokingDrug? smokingDrugById(String id) {
  for (final d in kSmokingDrugs) {
    if (d.id == id) return d;
  }
  return null;
}

class SmokingAdjustment {
  const SmokingAdjustment({
    required this.drug,
    required this.change,
    required this.currentDoseMg,
    required this.projectedLevelFactor,
    required this.suggestedDoseMg,
    required this.headline,
    required this.action,
  });

  final SmokingDrug drug;
  final SmokingChange change;
  final double currentDoseMg;

  /// Expected multiplicative change in plasma level at the CURRENT
  /// dose if nothing is done.
  final double projectedLevelFactor;

  /// Dose that approximately restores the pre-change exposure.
  final double suggestedDoseMg;

  final String headline;
  final String action;

  String clipboardSummary() {
    final pct = ((projectedLevelFactor - 1) * 100).round();
    final dir = pct >= 0 ? '+$pct%' : '$pct%';
    return '${drug.name} ${currentDoseMg.toStringAsFixed(0)} mg — '
        'on ${change.jsonValue} smoking, level projected $dir. '
        'Suggested dose ≈ ${suggestedDoseMg.toStringAsFixed(0)} mg. '
        '$action';
  }
}

double _round5(double mg) => (mg / 5).round() * 5.0;

SmokingAdjustment computeSmokingAdjustment({
  required SmokingDrug drug,
  required SmokingChange change,
  required double currentDoseMg,
}) {
  final factor =
      change == SmokingChange.stopping ? drug.stopFactor : drug.startFactor;

  // To keep exposure stable, the dose should move inversely to the
  // level change.
  final suggested = _round5(currentDoseMg / factor)
      .clamp(0, double.infinity)
      .toDouble();

  String headline;
  String action;
  if (change == SmokingChange.stopping) {
    headline = 'Stopping smoking → CYP1A2 de-induction → level rises.';
    action =
        'Pre-empt toxicity: reduce toward the suggested dose over '
        '1–2 weeks, check a trough level before and ~1 week after the '
        'change, and counsel on sedation / seizure warning signs. '
        'NRT does NOT prevent this — it is the smoke, not the '
        'nicotine.';
  } else {
    headline = 'Starting smoking → CYP1A2 induction → level falls.';
    action =
        'Anticipate loss of efficacy: titrate up toward the suggested '
        'dose guided by response + trough levels. Re-check a level '
        '2–4 weeks after the change.';
  }

  return SmokingAdjustment(
    drug: drug,
    change: change,
    currentDoseMg: currentDoseMg,
    projectedLevelFactor: factor,
    suggestedDoseMg: suggested,
    headline: headline,
    action: action,
  );
}
