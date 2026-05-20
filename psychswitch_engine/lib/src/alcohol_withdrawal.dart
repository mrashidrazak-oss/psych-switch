// Alcohol-withdrawal regimen builder.
//
// The CIWA-Ar scale (already shipped) scores severity; this engine
// turns severity + patient factors into a concrete benzodiazepine
// regimen, drug choice, thiamine plan, and monitoring cadence.
// Summarised from the Maudsley 15e, NICE CG100/CG115, and SIGN 74.

enum WithdrawalSeverity {
  lowRisk('Low risk'),
  moderate('Moderate'),
  severe('Severe / complicated');

  const WithdrawalSeverity(this.label);
  final String label;
}

class AlcoholWithdrawalInput {
  const AlcoholWithdrawalInput({
    required this.severity,
    required this.hepaticImpairment,
    required this.elderlyOrFrail,
    required this.seizureOrDtHistory,
    required this.outpatient,
  });

  final WithdrawalSeverity severity;

  /// Significant liver disease → prefer a non-oxidised benzo.
  final bool hepaticImpairment;
  final bool elderlyOrFrail;
  final bool seizureOrDtHistory;

  /// Community/outpatient detox vs inpatient.
  final bool outpatient;
}

class AlcoholWithdrawalPlan {
  const AlcoholWithdrawalPlan({
    required this.benzoChoice,
    required this.regimen,
    required this.thiamine,
    required this.monitoring,
    required this.escalation,
    required this.cautions,
  });

  final String benzoChoice;
  final List<String> regimen;
  final String thiamine;
  final String monitoring;
  final String escalation;
  final List<String> cautions;

  String clipboardSummary() {
    final lines = <String>[
      'Alcohol-withdrawal regimen',
      'Benzodiazepine: $benzoChoice',
      '',
      'Regimen:',
      for (final r in regimen) ' · $r',
      '',
      'Thiamine: $thiamine',
      'Monitoring: $monitoring',
      'Escalation: $escalation',
      '',
      'Cautions:',
      for (final c in cautions) ' · $c',
    ];
    return lines.join('\n');
  }
}

AlcoholWithdrawalPlan buildAlcoholWithdrawalPlan(
    AlcoholWithdrawalInput i) {
  // Drug choice: chlordiazepoxide is standard; switch to lorazepam
  // (glucuronidated, no active metabolites) in significant hepatic
  // impairment or marked frailty.
  final useLorazepam = i.hepaticImpairment || i.elderlyOrFrail;
  final benzo = useLorazepam
      ? 'Lorazepam (no oxidative metabolism — safer in hepatic '
          'impairment / frailty)'
      : 'Chlordiazepoxide (long-acting, self-tapering)';

  final regimen = <String>[];
  final cautions = <String>[];

  // Symptom-triggered is preferred where CIWA-Ar can be reliably
  // scored by trained staff; fixed-schedule for community detox or
  // where monitoring is limited.
  if (i.outpatient) {
    regimen.add(
      'Community detox: FIXED reducing schedule (symptom-triggered '
      'needs reliable CIWA-Ar scoring).',
    );
    if (useLorazepam) {
      regimen.add(
        'Lorazepam ~2 mg QDS day 1–2, then taper over 5–7 days '
        '(individualise to intake / severity).',
      );
    } else {
      regimen.add(
        'Chlordiazepoxide e.g. 20–30 mg QDS day 1–2, reducing over '
        '5–7 days (lower for ↓intake / elderly).',
      );
    }
    cautions.add(
      'Do NOT offer community detox if severe dependence, history of '
      'withdrawal seizures / DTs, significant comorbidity, or no '
      'support — admit instead.',
    );
  } else {
    regimen.add(
      'Inpatient: SYMPTOM-TRIGGERED dosing against CIWA-Ar is '
      'first-line where staff can score reliably; otherwise a '
      'front-loaded then tapering fixed schedule.',
    );
    switch (i.severity) {
      case WithdrawalSeverity.lowRisk:
        regimen.add(useLorazepam
            ? 'Lorazepam 1–2 mg PRN for CIWA-Ar ≥ 8; reassess hourly.'
            : 'Chlordiazepoxide 10–20 mg PRN for CIWA-Ar ≥ 8; '
                'reassess hourly.');
      case WithdrawalSeverity.moderate:
        regimen.add(useLorazepam
            ? 'Lorazepam 2 mg for CIWA-Ar ≥ 8, repeat hourly to '
                'response.'
            : 'Chlordiazepoxide 20–30 mg for CIWA-Ar ≥ 8, repeat '
                'hourly to response.');
      case WithdrawalSeverity.severe:
        regimen.add(useLorazepam
            ? 'Lorazepam 2–4 mg for CIWA-Ar ≥ 8 (IV 2 mg if '
                'severe), repeat to response under close monitoring.'
            : 'Chlordiazepoxide 30–50 mg loading for CIWA-Ar ≥ 15, '
                'repeat to response under close monitoring.');
    }
  }

  // Thiamine (the recurring failure point).
  String thiamine;
  if (i.severity == WithdrawalSeverity.severe || !i.outpatient) {
    thiamine =
        'Parenteral B-vitamins (e.g. Pabrinex IV pairs BD–TDS) for '
        '3–5 days BEFORE any carbohydrate / glucose, then high-dose '
        'oral thiamine. Oral alone is inadequate in active drinkers.';
  } else {
    thiamine =
        'Oral thiamine 100 mg TDS prophylactically. Escalate to '
        'parenteral if poor diet, vomiting, or any Wernicke '
        'features — give BEFORE carbohydrate.';
  }

  final monitoring = i.outpatient
      ? 'Daily review (in person / phone). Safety-net for confusion, '
          'ataxia, seizures → present immediately.'
      : 'CIWA-Ar + vital signs hourly while symptomatic, reducing as '
          'it settles. Daily U&E, glucose, magnesium; correct '
          'electrolytes.';

  final escalation = i.severity == WithdrawalSeverity.severe ||
          i.seizureOrDtHistory
      ? 'Delirium tremens / repeated seizures: escalate to a '
          'monitored / HDU setting; IV benzodiazepine titration; '
          'phenobarbital or adjuncts per local protocol; treat '
          'precipitants.'
      : 'Escalate to inpatient / monitored care if CIWA-Ar fails to '
          'settle, seizures, or evolving confusion.';

  if (i.seizureOrDtHistory) {
    cautions.add(
      'Prior withdrawal seizures / DTs — higher relapse risk; '
      'lower threshold for inpatient + generous early dosing.',
    );
  }
  cautions
    ..add('Check + replace magnesium and potassium — '
        'hypomagnesaemia perpetuates seizures.')
    ..add('Avoid antipsychotics as monotherapy (lower seizure '
        'threshold); use only as a benzo adjunct for severe '
        'agitation / hallucinosis.')
    ..add('Screen for head injury / infection / hypoglycaemia '
        'masquerading as withdrawal.');

  return AlcoholWithdrawalPlan(
    benzoChoice: benzo,
    regimen: regimen,
    thiamine: thiamine,
    monitoring: monitoring,
    escalation: escalation,
    cautions: cautions,
  );
}
