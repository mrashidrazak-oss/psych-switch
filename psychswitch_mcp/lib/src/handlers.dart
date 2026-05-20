// MCP handlers — implement the 18 tools defined in tools.dart.
//
// Each handler takes a JSON-decoded argument map and returns a
// JSON-encodable result. The server.dart layer wraps the result in an
// MCP `content` envelope.
//
// Wraps the engine — caller passes [ServerContent] at construction
// so handlers don't reach for globals. This keeps the smoke test
// hermetic.

import 'package:psychswitch_engine/citations.dart';
// `tierLabel` is defined in both cost_data and overlap_intensity —
// hide it from one to disambiguate; we use the cost_data one here.
import 'package:psychswitch_engine/cost_data.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/dose_equivalents.dart';
import 'package:psychswitch_engine/errata.dart';
import 'package:psychswitch_engine/glossary.dart';
import 'package:psychswitch_engine/overlap_intensity.dart' hide tierLabel;
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/predicted_ae_profile.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';
import 'package:psychswitch_engine/quantitative_ae.dart';
import 'package:psychswitch_engine/scale_schedule.dart';
import 'package:psychswitch_engine/specialty.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';

import 'package:psychswitch_mcp/src/content_loader.dart';

typedef Handler = Future<Object> Function(Map<String, dynamic> args);
typedef HandlerRegistry = Map<String, Handler>;

/// Build the 18-handler registry against the loaded engine.
HandlerRegistry buildHandlers(ServerContent content) {
  final engine = content.engine;

  // ── Helpers ──────────────────────────────────────────────────────
  Drug requireDrug(String id) {
    final d = engine.getDrug(id);
    if (d == null) throw ArgumentError('Unknown drugId: "$id"');
    return d;
  }

  PatientContext parseContext(Map<String, dynamic>? raw) {
    if (raw == null) return const PatientContext();
    final como = raw['comorbidities'] as Map<String, dynamic>?;
    return PatientContext(
      ageYears: raw['ageYears'] as num?,
      sex: _parseSex(raw['sex'] as String?),
      weightKg: raw['weightKg'] as num?,
      heightCm: raw['heightCm'] as num?,
      renal: _parseRenal(raw['renal'] as String?),
      egfr: raw['egfr'] as num?,
      hepatic: _parseHepatic(raw['hepatic'] as String?),
      pregnant: raw['pregnant'] as bool?,
      trimester: raw['trimester'] as int?,
      breastfeeding: raw['breastfeeding'] as bool?,
      smoker: raw['smoker'] as bool?,
      comorbidities: como == null
          ? null
          : Comorbidities(
              cardiac: como['cardiac'] as bool?,
              seizure: como['seizure'] as bool?,
              diabetes: como['diabetes'] as bool?,
              obesity: como['obesity'] as bool?,
              dyslipidemia: como['dyslipidemia'] as bool?,
            ),
    );
  }

  Map<String, dynamic> drugSummary(Drug d) => <String, dynamic>{
        'id': d.id,
        'genericName': d.genericName,
        'drugClass': d.drugClass,
        'category': d.category?.jsonValue,
        'formulation': d.formulation?.jsonValue,
        'hidden': d.hidden ?? false,
      };

  Map<String, dynamic> scheduleStepJson(ScheduleStep s) => <String, dynamic>{
        'day': s.day,
        'fromDoseMg': s.fromDoseMg,
        'toDoseMg': s.toDoseMg,
        if (s.notes != null) 'notes': s.notes,
        if (s.citations != null && s.citations!.isNotEmpty)
          'citations': s.citations,
      };

  Map<String, dynamic> switchPlanJson(SwitchPlan plan) {
    return switch (plan) {
      SwitchPlanOk(
        :final rule,
        :final schedule,
        :final safetyFlags,
        :final citations,
        :final dosesMatchReference,
        :final inputDoses,
      ) =>
        <String, dynamic>{
          'status': 'ok',
          'ruleId': rule.id,
          'strategy': rule.strategy.jsonValue,
          'durationDays': rule.durationDays,
          'rationale': rule.rationale,
          'schedule': schedule.map(scheduleStepJson).toList(),
          'safetyFlags': safetyFlags,
          'citations': citations,
          'dosesMatchReference': dosesMatchReference,
          'inputDoses': <String, dynamic>{
            'fromMg': inputDoses.fromMg,
            'toMg': inputDoses.toMg,
          },
        },
      SwitchPlanMaudsleyGuidance(
        :final guidance,
        :final safetyFlags,
        :final fromDrugName,
        :final toDrugName,
      ) =>
        <String, dynamic>{
          'status': 'maudsley_guidance',
          'fromDrugName': fromDrugName,
          'toDrugName': toDrugName,
          'guidance': guidance.toJson(),
          'safetyFlags': safetyFlags,
        },
      SwitchPlanMaoiWashout(
        :final direction,
        :final washoutDays,
        :final reason,
        :final safetyFlags,
      ) =>
        <String, dynamic>{
          'status': 'maoi_washout',
          'direction': direction.jsonValue,
          'washoutDays': washoutDays,
          'reason': reason,
          'safetyFlags': safetyFlags,
        },
      SwitchPlanClozapineRedirect(
        :final fromDrugName,
        :final reason,
        :final guidance,
      ) =>
        <String, dynamic>{
          'status': 'clozapine_redirect',
          'fromDrugName': fromDrugName,
          'reason': reason,
          'guidance': guidance,
        },
      SwitchPlanNoRule(:final reason) => <String, dynamic>{
          'status': 'no_rule',
          'reason': reason,
        },
    };
  }

  // ── Handlers ─────────────────────────────────────────────────────

  return <String, Handler>{
    'psychswitch_list_drugs': (args) async {
      final includeHidden = args['includeHidden'] as bool? ?? false;
      final drugs = includeHidden ? engine.listAllDrugs() : engine.listDrugs();
      return <String, dynamic>{
        'count': drugs.length,
        'drugs': drugs.map(drugSummary).toList(),
      };
    },

    'psychswitch_get_drug': (args) async {
      final id = args['drugId'] as String?;
      if (id == null) throw ArgumentError('drugId required');
      final d = requireDrug(id);
      return d.toJson();
    },

    'psychswitch_list_rules': (args) async {
      final rules = engine.listRules();
      return <String, dynamic>{
        'count': rules.length,
        'rules': rules
            .map(
              (r) => <String, dynamic>{
                'id': r.id,
                'fromDrugId': r.fromDrugId,
                'toDrugId': r.toDrugId,
                'strategy': r.strategy.jsonValue,
                'durationDays': r.durationDays,
                'citations': r.citations,
              },
            )
            .toList(),
      };
    },

    'psychswitch_generate_plan': (args) async {
      final input = SwitchInput(
        fromDrugId: args['fromDrugId']! as String,
        fromDoseMg: args['fromDoseMg']! as num,
        toDrugId: args['toDrugId']! as String,
        toDoseMg: args['toDoseMg']! as num,
      );
      final plan = engine.generateSwitchPlan(input);
      return switchPlanJson(plan);
    },

    'psychswitch_scale_schedule': (args) async {
      final fromId = args['fromDrugId']! as String;
      final toId = args['toDrugId']! as String;
      final fromDose = args['fromDoseMg']! as num;
      final toDose = args['toDoseMg']! as num;
      // Locate the rule via the engine; refuse if there's no reviewed
      // baseline to scale from.
      final plan = engine.generateSwitchPlan(
        SwitchInput(
          fromDrugId: fromId,
          fromDoseMg: fromDose,
          toDrugId: toId,
          toDoseMg: toDose,
        ),
      );
      if (plan is! SwitchPlanOk) {
        return <String, dynamic>{
          'status': plan.status,
          'message':
              'No reviewed rule for $fromId → $toId. Cannot scale a non-existent baseline.',
        };
      }
      final scaled = scaleSchedule(
        rule: plan.rule,
        fromDrug: requireDrug(fromId),
        toDrug: requireDrug(toId),
        userFromDose: fromDose,
        userToDose: toDose,
      );
      return <String, dynamic>{
        'mode': scaled.applied.mode.jsonValue,
        'fromFactor': scaled.applied.fromFactor,
        'toFactor': scaled.applied.toFactor,
        'adapted': scaled.adapted,
        'evidencePenalty': scaled.evidencePenalty,
        'schedule': scaled.schedule.map(scheduleStepJson).toList(),
        'warnings': scaled.warnings.map((w) => w.toJson()).toList(),
      };
    },

    'psychswitch_dose_equivalent': (args) async {
      final family = EquivalencyFamily.fromJson(args['family']! as String);
      final fromId = args['fromDrugId']! as String;
      final fromDose = args['fromDoseMg']! as num;
      final toId = args['toDrugId']! as String;
      final r = convertWithinFamily(family, fromId, fromDose, toId);
      if (r == null) {
        return <String, dynamic>{
          'error':
              'Either drug not in $family family, or non-positive dose. '
                  'Use psychswitch_list_drugs + check dosing.',
        };
      }
      return <String, dynamic>{
        'family': family.jsonValue,
        'fromDrugId': fromId,
        'fromDoseMg': fromDose,
        'toDrugId': toId,
        'toDoseMg': r.toDoseMg,
        'refUnits': r.refUnits,
      };
    },

    'psychswitch_predict_ae': (args) async {
      final toDrug = requireDrug(args['toDrugId']! as String);
      final fromId = args['fromDrugId'] as String?;
      final fromDrug = fromId == null ? null : engine.getDrug(fromId);
      final profile = predictAeProfile(toDrug, fromDrug);
      return <String, dynamic>{
        'toDrugId': toDrug.id,
        if (fromDrug != null) 'fromDrugId': fromDrug.id,
        'predictions': profile.predictions
            .map(
              (p) => <String, dynamic>{
                'aeId': p.ae.id,
                'aeLabel': p.ae.label,
                'category': p.ae.category.jsonValue,
                'likelihood': p.likelihood.jsonValue,
                'reason': p.reason,
              },
            )
            .toList(),
      };
    },

    'psychswitch_quantitative_ae': (args) async {
      final id = args['drugId']! as String;
      final effects = quantitativeFor(id);
      return <String, dynamic>{
        'drugId': id,
        'count': effects.length,
        'effects': effects
            .map(
              (e) => <String, dynamic>{
                'aeId': e.aeId,
                'metric': e.metric.jsonValue,
                'value': e.value,
                if (e.ci != null)
                  'ci': <num>[e.ci!.low, e.ci!.high],
                if (e.vs != null) 'vs': e.vs,
                'citation': e.citation,
                if (e.note != null) 'note': e.note,
                'formatted': formatEffect(e),
              },
            )
            .toList(),
      };
    },

    'psychswitch_check_ddi': (args) async {
      final ids = (args['drugIds'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>();
      final hits = checkAll(ids);
      return <String, dynamic>{
        'drugIds': ids,
        'hitCount': hits.length,
        'hits': hits.map((h) => h.toJson()).toList(),
      };
    },

    'psychswitch_compute_score': (args) async {
      final fromId = args['fromDrugId']! as String;
      final toId = args['toDrugId']! as String;
      final fromDose = args['fromDoseMg']! as num;
      final toDose = args['toDoseMg']! as num;

      final plan = engine.generateSwitchPlan(
        SwitchInput(
          fromDrugId: fromId,
          fromDoseMg: fromDose,
          toDrugId: toId,
          toDoseMg: toDose,
        ),
      );
      if (plan is! SwitchPlanOk) {
        return <String, dynamic>{
          'status': plan.status,
          'message': 'Score is only computed when a reviewed plan exists.',
        };
      }
      final toDrug = requireDrug(toId);
      final fromDrug = requireDrug(fromId);
      final scaled = scaleSchedule(
        rule: plan.rule,
        fromDrug: fromDrug,
        toDrug: toDrug,
        userFromDose: fromDose,
        userToDose: toDose,
      );
      final ddiHits = checkPair(fromId, toId);
      final score = computePsychSwitchScore(
        ScoreInputs(
          toDrug: toDrug,
          scaleResult: scaled,
          ddiHits: ddiHits,
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: gradeCitations(plan.citations),
        ),
      );
      return <String, dynamic>{
        'total': score.total,
        'band': score.band.jsonValue,
        'headline': score.headline,
        'components': <String, dynamic>{
          'evidence': score.components.evidence.toJson(),
          'aeAlignment': score.components.aeAlignment.toJson(),
          'contextSafety': score.components.contextSafety.toJson(),
          'ddiSafety': score.components.ddiSafety.toJson(),
          'doseFidelity': score.components.doseFidelity.toJson(),
        },
      };
    },

    'psychswitch_overlap_intensity': (args) async {
      final fromId = args['fromDrugId']! as String;
      final toId = args['toDrugId']! as String;
      final plan = engine.generateSwitchPlan(
        SwitchInput(
          fromDrugId: fromId,
          fromDoseMg: args['fromDoseMg']! as num,
          toDrugId: toId,
          toDoseMg: args['toDoseMg']! as num,
        ),
      );
      if (plan is! SwitchPlanOk) {
        return <String, dynamic>{
          'status': plan.status,
          'message': 'Overlap intensity needs a reviewed schedule.',
        };
      }
      final assessment = assessOverlapIntensity(
        fromDrug: requireDrug(fromId),
        toDrug: requireDrug(toId),
        schedule: plan.schedule,
      );
      return <String, dynamic>{
        'tier': assessment.tier.jsonValue,
        'score': assessment.score,
        'label': assessment.label,
        'rationale': assessment.rationale,
        'flags': assessment.flags,
        'components': <String, dynamic>{
          'overlapDays': assessment.components.overlapDays,
          'day1FromFraction': assessment.components.day1FromFraction,
          'day1ToFraction': assessment.components.day1ToFraction,
          'mechanismMultiplier': assessment.components.mechanismMultiplier,
        },
      };
    },

    'psychswitch_search': (args) async {
      final q = (args['query'] as String? ?? '').trim().toLowerCase();
      if (q.isEmpty) {
        return <String, dynamic>{'drugs': <dynamic>[], 'rules': <dynamic>[]};
      }
      final drugs = engine
          .listDrugs()
          .where(
            (d) =>
                d.id.toLowerCase().contains(q) ||
                d.genericName.toLowerCase().contains(q) ||
                d.drugClass.toLowerCase().contains(q),
          )
          .map(drugSummary)
          .toList();
      final rules = engine
          .listRules()
          .where(
            (r) =>
                r.id.toLowerCase().contains(q) ||
                r.fromDrugId.toLowerCase().contains(q) ||
                r.toDrugId.toLowerCase().contains(q) ||
                r.rationale.toLowerCase().contains(q),
          )
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'fromDrugId': r.fromDrugId,
              'toDrugId': r.toDrugId,
              'strategy': r.strategy.jsonValue,
            },
          )
          .toList();
      return <String, dynamic>{
        'query': q,
        'drugs': drugs,
        'rules': rules,
      };
    },

    'psychswitch_lookup_glossary': (args) async {
      final term = args['term']! as String;
      final entry = lookupTerm(term);
      if (entry == null) {
        return <String, dynamic>{
          'term': term,
          'found': false,
          'message': "No glossary entry for '$term'.",
        };
      }
      return <String, dynamic>{
        'term': entry.term,
        'definition': entry.definition,
        if (entry.relevance != null) 'relevance': entry.relevance,
        'found': true,
      };
    },

    'psychswitch_get_citation': (args) async {
      final key = args['key']! as String;
      final c = getCitation(key);
      return c.toJson();
    },

    'psychswitch_list_errata': (args) async {
      final scope = args['scope'] as String?;
      final since = args['sinceVersion'] as String?;
      final all = scope != null
          ? errataForScope(scope)
          : (since != null ? errataSinceVersion(since) : listErrata());
      return <String, dynamic>{
        'count': all.length,
        if (scope != null) 'scope': scope,
        if (since != null) 'sinceVersion': since,
        'entries': all.map((e) => e.toJson()).toList(),
      };
    },

    'psychswitch_context_warnings': (args) async {
      final id = args['drugId']! as String;
      final ctx = parseContext(args['context'] as Map<String, dynamic>?);
      final warnings = warningsForDrug(ctx, id);
      return <String, dynamic>{
        'drugId': id,
        'count': warnings.length,
        'warnings': warnings.map((w) => w.toJson()).toList(),
      };
    },

    'psychswitch_assess_specialty': (args) async {
      final fromId = args['fromDrugId']! as String;
      final toId = args['toDrugId']! as String;
      final ctx = parseContext(args['context'] as Map<String, dynamic>?);
      final fromDrug = engine.getDrug(fromId);
      final toDrug = engine.getDrug(toId);
      final assessment = assessSpecialty(
        fromDrugId: fromId,
        toDrugId: toId,
        context: ctx,
        fromDrugName: fromDrug?.genericName,
        toDrugName: toDrug?.genericName,
      );
      return <String, dynamic>{
        'applicable':
            assessment.applicable.map((s) => s.jsonValue).toList(),
        'headline': assessment.headline,
        'recommendations':
            assessment.recommendations.map((r) => r.toJson()).toList(),
      };
    },

    'psychswitch_cost': (args) async {
      final id = args['drugId']! as String;
      final c = costFor(id);
      if (c == null) {
        return <String, dynamic>{
          'drugId': id,
          'found': false,
          'message': "No cost data for '$id'.",
        };
      }
      return <String, dynamic>{
        'found': true,
        ...c.toJson(),
        'tierLabel': tierLabel(c.tier),
        'formatted': formatMyr(c.monthlyCostMyr),
      };
    },
  };
}

Sex? _parseSex(String? s) {
  if (s == null) return null;
  for (final v in Sex.values) {
    if (v.jsonValue == s) return v;
  }
  return null;
}

RenalFn? _parseRenal(String? s) {
  if (s == null) return null;
  for (final v in RenalFn.values) {
    if (v.jsonValue == s) return v;
  }
  return null;
}

HepaticFn? _parseHepatic(String? s) {
  if (s == null) return null;
  for (final v in HepaticFn.values) {
    if (v.jsonValue == s) return v;
  }
  return null;
}
