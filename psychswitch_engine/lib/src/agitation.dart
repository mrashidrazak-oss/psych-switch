// Agitation management algorithm.
//
// Maps clinical severity + context (psychotic vs non-psychotic, '
// alcohol-withdrawal, elderly, pregnant) to a stepwise recommendation
// for verbal de-escalation → oral PRN → IM rapid tranquillisation.
//
// Reference: Maudsley 15e, NICE NG10 (Violence and aggression),
// Royal College of Psychiatrists RT guidance.

enum AgitationSeverity {
  mild('mild'),
  moderate('moderate'),
  severe('severe');

  const AgitationSeverity(this.jsonValue);
  final String jsonValue;
}

String agitationSeverityLabel(AgitationSeverity s) {
  switch (s) {
    case AgitationSeverity.mild:
      return 'Mild';
    case AgitationSeverity.moderate:
      return 'Moderate';
    case AgitationSeverity.severe:
      return 'Severe';
  }
}

class AgitationContext {
  const AgitationContext({
    required this.severity,
    required this.psychotic,
    required this.alcoholOrBenzoWithdrawal,
    required this.elderly,
    required this.pregnant,
    required this.refusingOral,
  });

  final AgitationSeverity severity;
  final bool psychotic;
  final bool alcoholOrBenzoWithdrawal;
  final bool elderly;
  final bool pregnant;
  final bool refusingOral;
}

class AgitationPlan {
  const AgitationPlan({
    required this.context,
    required this.firstLine,
    required this.secondLine,
    required this.cautions,
  });

  final AgitationContext context;

  /// Verbal + first medication recommendation.
  final List<String> firstLine;
  final List<String> secondLine;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Agitation management — '
          '${agitationSeverityLabel(context.severity)}',
      '',
      'First-line:',
      for (final f in firstLine) ' · $f',
      '',
      'Second-line if inadequate:',
      for (final s in secondLine) ' · $s',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

AgitationPlan buildAgitationPlan(AgitationContext ctx) {
  final first = <String>[];
  final second = <String>[];
  final cautions = <String>[];

  first.add(
    'Verbal de-escalation — calm tone, low stimulation room, '
    'orient to surroundings, identify trigger, offer choices.',
  );
  first.add(
    'Offer food / drink / phone if appropriate; address basic needs.',
  );

  // Alcohol / benzo withdrawal — benzo-only path
  if (ctx.alcoholOrBenzoWithdrawal) {
    cautions.add(
      'Suspected withdrawal — avoid antipsychotics (lower seizure '
      'threshold). Treat the withdrawal directly.',
    );
    if (ctx.severity == AgitationSeverity.mild) {
      first.add('Diazepam 10 mg PO; reassess after 1 hour.');
    } else if (ctx.severity == AgitationSeverity.moderate) {
      first.add('Diazepam 20 mg PO; CIWA-driven titration.');
      second.add('Lorazepam 2 mg IM if PO refused.');
    } else {
      first.add(
        'Lorazepam 4 mg IM (or 2 mg IV with monitoring); '
        'CIWA-driven loading.',
      );
      second.add('Repeat lorazepam after 30 minutes if needed.');
    }
    cautions.add('Add thiamine 100 mg IV / IM before glucose.');
    return AgitationPlan(
      context: ctx,
      firstLine: first,
      secondLine: second,
      cautions: cautions,
    );
  }

  // Elderly — start low, avoid benzos and high-potency D2
  if (ctx.elderly) {
    cautions.add(
      'Elderly — START LOW, go slow. Avoid lorazepam-haloperidol '
      'combo. Halve adult doses.',
    );
    if (ctx.severity == AgitationSeverity.mild) {
      first.add('Quetiapine 12.5–25 mg PO or olanzapine 2.5 mg PO.');
    } else if (ctx.severity == AgitationSeverity.moderate) {
      first.add(
        'Olanzapine 2.5–5 mg PO or quetiapine 25 mg PO. Lorazepam '
        '0.5 mg PO as adjunct only.',
      );
      if (ctx.refusingOral) {
        second.add('Olanzapine 2.5 mg IM (NOT with parenteral benzo).');
      }
    } else {
      first.add(
        'Olanzapine 2.5–5 mg IM OR haloperidol 0.5–1 mg IM '
        '(consider ECG, exclude QTc-prolongers).',
      );
      second.add(
        'Lorazepam 0.5–1 mg IM (only if PO refused — caution with '
        'respiratory depression).',
      );
    }
    return AgitationPlan(
      context: ctx,
      firstLine: first,
      secondLine: second,
      cautions: cautions,
    );
  }

  // Pregnancy
  if (ctx.pregnant) {
    cautions.add(
      'Pregnancy — preferred agents are haloperidol or olanzapine; '
      'avoid benzodiazepines in the third trimester unless absolutely '
      'necessary.',
    );
    if (ctx.severity == AgitationSeverity.mild) {
      first.add('Olanzapine 5–10 mg PO.');
    } else if (ctx.severity == AgitationSeverity.moderate) {
      first.add('Olanzapine 10 mg PO; haloperidol 2.5–5 mg PO option.');
      second.add('Olanzapine 5 mg IM if PO refused.');
    } else {
      first.add(
        'Haloperidol 5 mg IM (most data in pregnancy) OR olanzapine '
        '5 mg IM. ECG monitoring.',
      );
      second.add(
        'Repeat after 30 min if needed. Avoid promethazine in 3rd '
        'trimester.',
      );
    }
    return AgitationPlan(
      context: ctx,
      firstLine: first,
      secondLine: second,
      cautions: cautions,
    );
  }

  // General adult
  if (ctx.severity == AgitationSeverity.mild) {
    if (ctx.psychotic) {
      first.add('Offer their usual oral antipsychotic if due.');
      first.add('Lorazepam 1–2 mg PO PRN.');
    } else {
      first.add('Lorazepam 1–2 mg PO PRN, or diazepam 5–10 mg PO.');
    }
    return AgitationPlan(
      context: ctx,
      firstLine: first,
      secondLine: second,
      cautions: cautions,
    );
  }

  if (ctx.severity == AgitationSeverity.moderate) {
    if (ctx.psychotic) {
      first.add(
        'Olanzapine 10 mg PO + lorazepam 1–2 mg PO (separate by '
        '≥ 1 hour from IM olanzapine if used).',
      );
      if (ctx.refusingOral) {
        second.add(
          'IM olanzapine 10 mg ALONE (NOT with parenteral benzo — '
          'respiratory depression risk).',
        );
        second.add('OR IM haloperidol 5 mg + IM promethazine 25 mg.');
      } else {
        second.add('IM haloperidol 5 mg + IM promethazine 25 mg if PO inadequate.');
      }
    } else {
      first.add('Lorazepam 2 mg PO; repeat after 60 min if needed.');
      second.add('Lorazepam 2 mg IM if PO refused.');
    }
    cautions.add(
      'Watch for respiratory depression with benzodiazepines — have '
      'flumazenil + oxygen available.',
    );
    return AgitationPlan(
      context: ctx,
      firstLine: first,
      secondLine: second,
      cautions: cautions,
    );
  }

  // Severe
  if (ctx.psychotic) {
    first.add(
      'IM haloperidol 5 mg + IM promethazine 25 mg (preferred RT '
      'combo per NICE NG10).',
    );
    first.add(
      'OR IM olanzapine 10 mg ALONE (do NOT combine with parenteral '
      'benzodiazepine within 1 hour).',
    );
    second.add(
      'IM aripiprazole 9.75 mg (avoid if QT-prolongation concerns).',
    );
  } else {
    first.add('Lorazepam 4 mg IM (or 2 mg IV with monitoring).');
    second.add(
      'IM haloperidol 5 mg + IM promethazine 25 mg if benzo '
      'inadequate.',
    );
  }
  cautions.addAll(<String>[
    'ECG before IV haloperidol (QTc).',
    'Have flumazenil + naloxone available.',
    'Restraint only with adequate staffing; document indication, '
    'duration, monitoring.',
    'Side-effects post-RT: monitor airway, BP, sats × 15 min × 1 h.',
  ]);

  return AgitationPlan(
    context: ctx,
    firstLine: first,
    secondLine: second,
    cautions: cautions,
  );
}
