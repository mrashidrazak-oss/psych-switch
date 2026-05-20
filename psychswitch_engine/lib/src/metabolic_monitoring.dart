// Antipsychotic metabolic-monitoring scheduler.
//
// Generates the recommended monitoring calendar from an antipsychotic
// start date, per Maudsley 15e / NICE CG178 / Lester UK adaptation.
// Baseline, week 6, week 12, then annually — each visit lists what to
// check.
//
// Pure date arithmetic; no patient identifiers, all on-device.

class MonitoringParam {
  const MonitoringParam(this.label);
  final String label;
}

const _baselineParams = <MonitoringParam>[
  MonitoringParam('Weight + BMI + waist circumference'),
  MonitoringParam('Blood pressure + pulse'),
  MonitoringParam('Fasting glucose or HbA1c'),
  MonitoringParam('Fasting lipid profile'),
  MonitoringParam('Prolactin (if symptomatic / on risperidone, '
      'amisulpride, paliperidone)'),
  MonitoringParam('U&E, LFT, FBC'),
  MonitoringParam('ECG (if cardiac risk / QTc-prolonging agent)'),
  MonitoringParam('Personal + family cardiometabolic history'),
];

const _week6Params = <MonitoringParam>[
  MonitoringParam('Weight + BMI + waist circumference'),
  MonitoringParam('Blood pressure + pulse'),
  MonitoringParam('Side-effect review (EPS, sedation, prolactin)'),
];

const _week12Params = <MonitoringParam>[
  MonitoringParam('Weight + BMI + waist circumference'),
  MonitoringParam('Blood pressure + pulse'),
  MonitoringParam('Fasting glucose or HbA1c'),
  MonitoringParam('Fasting lipid profile'),
  MonitoringParam('Prolactin (if indicated)'),
];

const _annualParams = <MonitoringParam>[
  MonitoringParam('Weight + BMI + waist circumference'),
  MonitoringParam('Blood pressure + pulse'),
  MonitoringParam('Fasting glucose or HbA1c'),
  MonitoringParam('Fasting lipid profile'),
  MonitoringParam('Prolactin (if indicated)'),
  MonitoringParam('U&E, LFT, FBC'),
  MonitoringParam('ECG (if indicated)'),
  MonitoringParam('Lifestyle + smoking + substance review'),
];

class MonitoringVisit {
  const MonitoringVisit({
    required this.label,
    required this.dueDate,
    required this.dayOffset,
    required this.params,
    required this.isOverdue,
    required this.isDueSoon,
  });

  final String label;

  /// Calendar date this visit is due.
  final DateTime dueDate;

  /// Days from the start date.
  final int dayOffset;

  final List<MonitoringParam> params;

  /// Already past due (relative to "today" passed to the builder).
  final bool isOverdue;

  /// Due within the next 14 days.
  final bool isDueSoon;
}

class MonitoringSchedule {
  const MonitoringSchedule({
    required this.startDate,
    required this.visits,
  });

  final DateTime startDate;
  final List<MonitoringVisit> visits;

  /// The next visit not yet done (first overdue, else first future).
  MonitoringVisit? get nextDue {
    for (final v in visits) {
      if (v.isOverdue || v.isDueSoon) return v;
    }
    for (final v in visits) {
      if (v.dueDate.isAfter(DateTime.now())) return v;
    }
    return null;
  }

  String clipboardSummary() {
    String d(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
    final lines = <String>[
      'Antipsychotic metabolic monitoring '
          '(start ${d(startDate)})',
      '',
      for (final v in visits)
        '${v.label} — due ${d(v.dueDate)}'
            '${v.isOverdue ? "  [OVERDUE]" : v.isDueSoon ? "  [DUE SOON]" : ""}',
    ];
    return lines.join('\n');
  }
}

DateTime _addDays(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day).add(Duration(days: n));

/// Build the schedule. [now] defaults to DateTime.now(); injectable
/// for deterministic tests. Generates baseline, wk6, wk12, then annual
/// visits up to [yearsAhead] (default 3).
MonitoringSchedule buildMonitoringSchedule({
  required DateTime startDate,
  DateTime? now,
  int yearsAhead = 3,
}) {
  final today = now ?? DateTime.now();

  MonitoringVisit mk(String label, int dayOffset,
      List<MonitoringParam> params) {
    final due = _addDays(startDate, dayOffset);
    final daysUntil = due.difference(
            DateTime(today.year, today.month, today.day))
        .inDays;
    return MonitoringVisit(
      label: label,
      dueDate: due,
      dayOffset: dayOffset,
      params: params,
      isOverdue: daysUntil < 0,
      isDueSoon: daysUntil >= 0 && daysUntil <= 14,
    );
  }

  final visits = <MonitoringVisit>[
    mk('Baseline', 0, _baselineParams),
    mk('Week 6', 42, _week6Params),
    mk('Week 12', 84, _week12Params),
  ];
  for (var y = 1; y <= yearsAhead; y++) {
    visits.add(mk('Year $y', 365 * y, _annualParams));
  }

  return MonitoringSchedule(startDate: startDate, visits: visits);
}
