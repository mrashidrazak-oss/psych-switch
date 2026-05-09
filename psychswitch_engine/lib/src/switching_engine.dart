// Switching engine — pure functions, no Flutter, no async, no I/O.
//
// This file deliberately does NOT do any clinical extrapolation. If a user
// asks for a switch outside the doses we have explicitly reviewed, we
// REFUSE to extrapolate. Linear scaling of antidepressant doses is unsafe
// and clinically unjustified, especially at the edges of the therapeutic
// window.
//
// Caller pattern (vs the TS port which static-imports every JSON):
// the [SwitchingEngine] class wraps a [List<Drug>] + [List<SwitchingRule>]
// + [Maudsley15Data] passed in at construction. The Phase 4 runtime
// loader composes those from `/content/` at app startup.
//
// Dart port of engine/switchingEngine.ts.

import 'package:psychswitch_engine/maudsley15.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

// ── Input + result types ────────────────────────────────────────────────

/// Caller-supplied switch description.
class SwitchInput {
  const SwitchInput({
    required this.fromDrugId,
    required this.fromDoseMg,
    required this.toDrugId,
    required this.toDoseMg,
  });

  final String fromDrugId;
  final num fromDoseMg;
  final String toDrugId;
  final num toDoseMg;
}

/// MAOI washout direction.
enum MaoiWashoutDirection {
  toMaoi('to_maoi'),
  fromMaoi('from_maoi');

  const MaoiWashoutDirection(this.jsonValue);

  final String jsonValue;
}

/// Discriminated-union output of [SwitchingEngine.generateSwitchPlan].
sealed class SwitchPlan {
  const SwitchPlan();

  String get status;

  Map<String, dynamic> toJson();
}

/// A reviewed cross-taper rule was found and the doses are within scope.
class SwitchPlanOk extends SwitchPlan {
  const SwitchPlanOk({
    required this.rule,
    required this.schedule,
    required this.safetyFlags,
    required this.citations,
    required this.dosesMatchReference,
    required this.inputDoses,
  });

  final SwitchingRule rule;
  final List<ScheduleStep> schedule;
  final List<String> safetyFlags;
  final List<String> citations;

  /// Whether the input doses match the rule's reviewed reference doses.
  final bool dosesMatchReference;

  /// The doses the input claimed (for display in the banner).
  final ({num fromMg, num toMg}) inputDoses;

  @override
  String get status => 'ok';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'rule': rule.toJson(),
        'schedule': schedule.map((s) => s.toJson()).toList(),
        'safetyFlags': safetyFlags,
        'citations': citations,
        'dosesMatchReference': dosesMatchReference,
        'inputDoses': <String, dynamic>{
          'fromMg': inputDoses.fromMg,
          'toMg': inputDoses.toMg,
        },
      };
}

/// No specific rule, but Maudsley 15th's matrix or a cross-category
/// fallback has class-level guidance.
class SwitchPlanMaudsleyGuidance extends SwitchPlan {
  const SwitchPlanMaudsleyGuidance({
    required this.guidance,
    required this.safetyFlags,
    required this.fromDrugName,
    required this.toDrugName,
  });

  final Maudsley15Guidance guidance;
  final List<String> safetyFlags;
  final String fromDrugName;
  final String toDrugName;

  @override
  String get status => 'maudsley_guidance';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'guidance': guidance.toJson(),
        'safetyFlags': safetyFlags,
        'fromDrugName': fromDrugName,
        'toDrugName': toDrugName,
      };
}

/// No rule and no class-level guidance — typically because a drug id is
/// unregistered.
class SwitchPlanNoRule extends SwitchPlan {
  const SwitchPlanNoRule({required this.reason});

  final String reason;

  @override
  String get status => 'no_rule';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'reason': reason,
      };
}

/// MAOI on either side — no cross-taper, washout only.
class SwitchPlanMaoiWashout extends SwitchPlan {
  const SwitchPlanMaoiWashout({
    required this.direction,
    required this.washoutDays,
    required this.reason,
    required this.safetyFlags,
  });

  final MaoiWashoutDirection direction;
  final int washoutDays;
  final String reason;
  final List<String> safetyFlags;

  @override
  String get status => 'maoi_washout';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'direction': direction.jsonValue,
        'washoutDays': washoutDays,
        'reason': reason,
        'safetyFlags': safetyFlags,
      };
}

/// Switching TO clozapine is a specialist initiation decision.
class SwitchPlanClozapineRedirect extends SwitchPlan {
  const SwitchPlanClozapineRedirect({
    required this.fromDrugName,
    required this.reason,
    required this.guidance,
  });

  final String fromDrugName;
  final String reason;
  final String guidance;

  @override
  String get status => 'clozapine_redirect';

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'fromDrugName': fromDrugName,
        'reason': reason,
        'guidance': guidance,
      };
}

// ── Engine ─────────────────────────────────────────────────────────────

/// Wraps the drug + rule registry + Maudsley fallback data and exposes
/// the public engine API.
class SwitchingEngine {
  SwitchingEngine({
    required List<Drug> drugs,
    required List<SwitchingRule> rules,
    required this.maudsley15Data,
  })  : _drugs = drugs,
        _rules = rules,
        _drugById = <String, Drug>{for (final d in drugs) d.id: d};

  final List<Drug> _drugs;
  final List<SwitchingRule> _rules;
  final Maudsley15Data maudsley15Data;
  final Map<String, Drug> _drugById;

  /// Look up a drug record by id. Searches ALL drugs including hidden
  /// ones (needed for MAOI safety checks and LAI rule lookups).
  Drug? getDrug(String id) => _drugById[id];

  /// Drugs visible in the picker — excludes hidden entries (MAOIs,
  /// deprecated LAI formulations).
  List<Drug> listDrugs() =>
      _drugs.where((d) => !(d.hidden ?? false)).toList();

  /// All registered drugs including hidden — for tests and admin.
  List<Drug> listAllDrugs() => List<Drug>.from(_drugs);

  /// All reviewed switching rules.
  List<SwitchingRule> listRules() => List<SwitchingRule>.from(_rules);

  /// Generate a cross-taper plan for [input].
  ///
  /// The dispatch order mirrors the TS engine and is critical for
  /// safety:
  ///   1. clozapine redirect (TO clozapine = specialist module)
  ///   2. MAOI hard-block — runs before rule lookup
  ///   3. specific reviewed rule
  ///   4. Maudsley 15th matrix
  ///   5. cross-category fallback
  ///   6. no_rule
  SwitchPlan generateSwitchPlan(SwitchInput input) {
    final fromDrug = getDrug(input.fromDrugId);
    final toDrug = getDrug(input.toDrugId);

    // Clozapine redirect.
    if (toDrug?.id == 'clozapine') {
      return SwitchPlanClozapineRedirect(
        fromDrugName: fromDrug?.genericName ?? input.fromDrugId,
        reason:
            'Clozapine initiation is a specialist decision for treatment-resistant schizophrenia. A standard cross-taper rule cannot safely capture the full overlap-and-taper strategy.',
        guidance:
            'Use the Clozapine module (accessible from the Home screen) for the full titration protocol. Continue the current antipsychotic in parallel during titration, then taper and stop once clozapine is established at the therapeutic dose. The speed of the taper depends on clinical response. Consult Maudsley 14th edition chapter on clozapine initiation.',
      );
    }

    // MAOI hard-block.
    if (fromDrug != null &&
        toDrug != null &&
        ((fromDrug.isMAOI ?? false) || (toDrug.isMAOI ?? false))) {
      return _computeMaoiWashout(fromDrug, toDrug);
    }

    // Specific reviewed rule lookup.
    SwitchingRule? rule;
    for (final r in _rules) {
      if (r.fromDrugId == input.fromDrugId &&
          r.toDrugId == input.toDrugId) {
        rule = r;
        break;
      }
    }

    if (rule == null) {
      if (fromDrug != null && toDrug != null) {
        final guidance =
            lookupMaudsley15Strategy(fromDrug, toDrug, maudsley15Data) ??
                _generateCrossCategoryGuidance(fromDrug, toDrug);
        if (guidance != null) {
          return SwitchPlanMaudsleyGuidance(
            guidance: guidance,
            safetyFlags: deriveSafetyFlags(fromDrug, toDrug),
            fromDrugName: fromDrug.genericName,
            toDrugName: toDrug.genericName,
          );
        }
      }
      return SwitchPlanNoRule(
        reason:
            'No reviewed rule exists for ${input.fromDrugId} → ${input.toDrugId}. One or both drug IDs may be unregistered.',
      );
    }

    final dosesMatchReference =
        input.fromDoseMg == rule.doseRatios.fromCurrentDoseMg &&
            input.toDoseMg == rule.doseRatios.toTargetDoseMg;

    final derived = (fromDrug != null && toDrug != null)
        ? deriveSafetyFlags(fromDrug, toDrug)
        : <String>[];
    final mergedFlags = <String>[
      ...rule.safetyFlags,
      for (final f in derived)
        if (!rule.safetyFlags.contains(f)) f,
    ];

    return SwitchPlanOk(
      rule: rule,
      schedule: rule.schedule,
      safetyFlags: mergedFlags,
      citations: rule.citations,
      dosesMatchReference: dosesMatchReference,
      inputDoses: (fromMg: input.fromDoseMg, toMg: input.toDoseMg),
    );
  }

  // ── MAOI washout ──────────────────────────────────────────────────────

  SwitchPlan _computeMaoiWashout(Drug fromDrug, Drug toDrug) {
    final fromIsMaoi = fromDrug.isMAOI ?? false;
    final toIsMaoi = toDrug.isMAOI ?? false;

    if (fromIsMaoi && toIsMaoi) {
      return SwitchPlanNoRule(
        reason:
            'MAOI-to-MAOI switches (${fromDrug.genericName} → ${toDrug.genericName}) are specialist decisions and not automated in v0.1. Consult primary references.',
      );
    }

    if (toIsMaoi) {
      final washoutDays = fromDrug.maoiWashout?.daysOffBeforeMAOI ?? 14;
      final washoutFlag = washoutDays >= 28
          ? 'maoi_washout_required_5_week'
          : 'maoi_washout_required_14_day';
      final flags = <String>[
        washoutFlag,
        for (final f in deriveSafetyFlags(fromDrug, toDrug))
          if (f != washoutFlag) f,
      ];
      return SwitchPlanMaoiWashout(
        direction: MaoiWashoutDirection.toMaoi,
        washoutDays: washoutDays,
        reason:
            'Switching to ${toDrug.genericName} (MAOI) requires $washoutDays days off ${fromDrug.genericName} to avoid serotonin syndrome.',
        safetyFlags: flags,
      );
    }

    final washoutDays = fromDrug.maoiClearanceDays ?? 14;
    const baseFlag = 'maoi_clearance_required';
    final flags = <String>[
      baseFlag,
      for (final f in deriveSafetyFlags(fromDrug, toDrug))
        if (f != baseFlag) f,
    ];
    return SwitchPlanMaoiWashout(
      direction: MaoiWashoutDirection.fromMaoi,
      washoutDays: washoutDays,
      reason:
          'Switching from ${fromDrug.genericName} requires $washoutDays day(s) clearance before starting ${toDrug.genericName} to avoid serotonin syndrome.',
      safetyFlags: flags,
    );
  }
}

// ── Cross-category fallback ─────────────────────────────────────────────

/// Synthesise cross-category guidance when the Maudsley matrix has no entry.
///
/// Returns `null` only when both drugs are the same category — which means
/// something is missing from the matrix rather than being a cross-category
/// pair.
Maudsley15Guidance? _generateCrossCategoryGuidance(
  Drug fromDrug,
  Drug toDrug,
) {
  final fromCat = fromDrug.category ?? DrugCategory.antidepressant;
  final toCat = toDrug.category ?? DrugCategory.antidepressant;

  if (fromCat == toCat) return null;

  bool isAdAp(DrugCategory a, DrugCategory b) =>
      (a == DrugCategory.antidepressant && b == DrugCategory.antipsychotic) ||
      (a == DrugCategory.antipsychotic && b == DrugCategory.antidepressant);
  bool isApMs(DrugCategory a, DrugCategory b) =>
      (a == DrugCategory.antipsychotic && b == DrugCategory.moodStabilizer) ||
      (a == DrugCategory.moodStabilizer && b == DrugCategory.antipsychotic);
  bool isAdMs(DrugCategory a, DrugCategory b) =>
      (a == DrugCategory.antidepressant && b == DrugCategory.moodStabilizer) ||
      (a == DrugCategory.moodStabilizer && b == DrugCategory.antidepressant);

  if (isAdAp(fromCat, toCat)) {
    return const Maudsley15Guidance(
      strategy: Maudsley15Strategy.special,
      headline: 'Different therapeutic targets — not a standard switch',
      detail:
          'Antidepressants and antipsychotics serve different primary indications. '
          'Selecting one drug from each class usually represents an augmentation or '
          'de-escalation decision rather than a direct switch. If stopping an antidepressant '
          'while starting an antipsychotic (e.g. transitioning from unipolar depression to a '
          'first episode of psychosis), taper the antidepressant using its own discontinuation '
          'risk profile — do not abruptly stop high-discontinuation-risk agents such as paroxetine, '
          'venlafaxine or desvenlafaxine. If adding an antipsychotic as augmentation for '
          'treatment-resistant depression, this is a combination decision — the antidepressant '
          'is typically continued. Consult Maudsley 15th depression and psychosis chapters for the '
          'specific condition being treated.',
      citations: <String>[
        'maudsley15_ch3_general_principles',
        'maudsley15_schizophrenia_p231',
      ],
    );
  }

  if (isApMs(fromCat, toCat)) {
    return const Maudsley15Guidance(
      strategy: Maudsley15Strategy.crossTaperCautiously,
      headline:
          'Cross-taper cautiously — antipsychotics and mood stabilisers are often co-prescribed in bipolar disorder',
      detail:
          'Antipsychotics and mood stabilisers are frequently co-prescribed for acute mania and '
          'bipolar maintenance. If stopping one while maintaining the other, taper the drug being '
          'stopped slowly. Antipsychotics should be tapered over 4–8 weeks to avoid rebound '
          'psychosis — abrupt discontinuation carries significant risk. Mood stabilisers have their '
          'own pharmacokinetic considerations: carbamazepine is an enzyme inducer (levels of the '
          'antipsychotic may be affected), and valproate inhibits some metabolic pathways. Consult '
          'Maudsley 15th bipolar disorder chapters for evidence-based sequencing and dose monitoring.',
      citations: <String>[
        'maudsley15_bipolar_ch5_switching',
        'bap2016_bipolar',
      ],
    );
  }

  if (isAdMs(fromCat, toCat)) {
    return const Maudsley15Guidance(
      strategy: Maudsley15Strategy.crossTaperCautiously,
      headline:
          'Cross-taper cautiously — consider the underlying diagnosis when switching between these classes',
      detail:
          'Antidepressants and mood stabilisers are prescribed for different primary conditions. '
          'In bipolar disorder, antidepressants are often tapered once mood stabilisation is '
          'established — abrupt discontinuation carries a discontinuation syndrome risk (especially '
          'paroxetine, venlafaxine, desvenlafaxine). Mood stabilisers should generally not be '
          'stopped abruptly — lamotrigine withdrawal can trigger rebound seizures; lithium '
          'discontinuation risks rebound mania; valproate and carbamazepine have their own '
          'kinetics. If the patient is moving from an antidepressant to a mood stabiliser for '
          'a new bipolar diagnosis, ensure the mood stabiliser is at a therapeutic level before '
          'reducing the antidepressant. Consult Maudsley 15th bipolar and depression chapters.',
      citations: <String>[
        'maudsley15_bipolar_ch5_switching',
        'maudsley15_ch3_general_principles',
      ],
    );
  }

  return null;
}

// ── Safety-flag derivation ──────────────────────────────────────────────

/// Derive safety flags from drug profiles only — no rule needed.
///
/// Lets the UI surface profile-driven warnings even when no reviewed
/// cross-taper rule exists (no_rule path). Also frees rule authors from
/// having to remember to repeat the same warnings on every rule.
List<String> deriveSafetyFlags(Drug fromDrug, Drug toDrug) {
  final flags = <String>[];

  // High discontinuation syndrome risk on the from-drug.
  final discScore = fromDrug.discontinuationSyndromeRisk?.score;
  if (discScore == RiskLevel.high || discScore == RiskLevel.veryHigh) {
    flags.add('discontinuation_syndrome_high');
  }

  // Paroxetine anticholinergic-rebound flag.
  if (fromDrug.id == 'paroxetine') {
    flags.add('anticholinergic_rebound');
  }

  // Serotonergic overlap (SSRI/SNRI on both sides).
  const serotonergic = <String>{'SSRI', 'SNRI'};
  if (serotonergic.contains(fromDrug.drugClass) &&
      serotonergic.contains(toDrug.drugClass)) {
    flags.add('serotonin_syndrome_overlap_low');
  }

  // ── Antipsychotic-specific derivations ─────────────────────────────

  const anticholinergicAp = <String>{'olanzapine', 'quetiapine'};
  if (anticholinergicAp.contains(fromDrug.id) &&
      !anticholinergicAp.contains(toDrug.id)) {
    flags.add('cholinergic_rebound');
  }

  // Akathisia warning when switching INTO aripiprazole.
  if (toDrug.id == 'aripiprazole' || toDrug.id == 'aripiprazole-lai') {
    flags.add('akathisia_risk_aripiprazole');
  }

  // Prolactin normalisation.
  if (fromDrug.prolactinRisk == RiskLevel.high &&
      toDrug.prolactinRisk != null &&
      toDrug.prolactinRisk != RiskLevel.high) {
    flags.add('prolactin_normalisation');
  }

  // Long depot washout when the from-drug is an LAI.
  if (fromDrug.formulation == Formulation.lai) {
    flags.add('depot_washout_long');
  }

  // Oral overlap when destination LAI's protocol requires it.
  if (toDrug.formulation == Formulation.lai &&
      (toDrug.laiDetails?.needsOralOverlap ?? false)) {
    flags.add('lai_initiation_oral_overlap');
  }

  // QTc additive overlap.
  final fromQtc = _qtcRiskRank(fromDrug.qtcRisk);
  final toQtc = _qtcRiskRank(toDrug.qtcRisk);
  if (fromQtc >= 2 && toQtc >= 1) {
    flags.add('qtc_additive_overlap');
  }

  // Metabolic monitoring required on switch INTO a very-high-risk agent.
  if (toDrug.metabolicRisk?.score == RiskLevel.veryHigh &&
      fromDrug.metabolicRisk?.score != RiskLevel.veryHigh) {
    flags.add('metabolic_monitoring_required');
  }

  return flags;
}

int _qtcRiskRank(RiskLevel? r) {
  if (r == null) return 0;
  switch (r) {
    case RiskLevel.veryHigh:
    case RiskLevel.high:
      return 2;
    case RiskLevel.moderate:
    case RiskLevel.lowModerate:
      return 1;
    case RiskLevel.low:
      return 0;
  }
}
