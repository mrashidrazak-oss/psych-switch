// Tests for the Dart clozapine port.
// Mirrors engine/__tests__/clozapine.test.ts. Synthetic content fixture
// shaped to match `/content/clozapine/` JSON; replaced with the real
// loader in Phase 4.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/clozapine.dart';
import 'package:psychswitch_engine/patient_context_pure.dart' show Sex;

TitrationProtocol _titration({
  required Sex sex,
  required bool smoker,
  required num target,
}) =>
    TitrationProtocol(
      id: 'titration-${sex.jsonValue}-${smoker ? 'smoker' : 'nonsmoker'}',
      variant: (sex: sex, smoker: smoker),
      targetDoseMg: target,
      rationale: 'Maudsley 15 schizophrenia.',
      totalDays: 20,
      steps: <TitrationStep>[
        const TitrationStep(
          day: 1,
          morningMg: 0,
          eveningMg: 6.25,
          totalMg: 6.25,
        ),
        for (var i = 2; i <= 19; i++)
          TitrationStep(
            day: i,
            morningMg: target / 2,
            eveningMg: target / 2,
            totalMg: target,
          ),
        TitrationStep(
          day: 20,
          morningMg: target / 2,
          eveningMg: target / 2,
          totalMg: target,
        ),
      ],
      postTitrationGuidance: 'Maintain at target.',
      missedDoseRule: 'If >48 hours missed, retitrate from day 1.',
      citations: const <String>['maudsley15_schizophrenia_clozapine'],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

const _fbcThresholds = FbcThresholds(
  ancGreenAtOrAbove: 2.0,
  ancAmberRange: FbcAmberRange(low: 1.5, high: 2.0),
  ancRedBelow: 1.5,
  wbcGreenAtOrAbove: 3.5,
  wbcAmberRange: FbcAmberRange(low: 3.0, high: 3.5),
  wbcRedBelow: 3.0,
  unit: '×10⁹/L',
  actions: FbcActions(
    green: 'Continue weekly FBC.',
    amber: 'Repeat in 48–72 h.',
    red: 'Stop clozapine; daily FBC; haematology referral.',
  ),
  benAdjustment: FbcBenAdjustment(
    ancGreenAtOrAbove: 1.5,
    ancAmberRange: FbcAmberRange(low: 1.0, high: 1.5),
    ancRedBelow: 1.0,
    wbcGreenAtOrAbove: 3.0,
    wbcAmberRange: FbcAmberRange(low: 2.5, high: 3.0),
    wbcRedBelow: 2.5,
    notes: 'BEN-adjusted thresholds per CPMS.',
  ),
);

ClozapineModule _module() => ClozapineModule(
      ClozapineContent(
        femaleNonSmoker:
            _titration(sex: Sex.female, smoker: false, target: 225),
        femaleSmoker: _titration(sex: Sex.female, smoker: true, target: 300),
        maleNonSmoker:
            _titration(sex: Sex.male, smoker: false, target: 250),
        maleSmoker: _titration(sex: Sex.male, smoker: true, target: 375),
        monitoringSchedule: const MonitoringScheduleData(
          id: 'monitoring',
          rationale: 'Lifelong haematological monitoring.',
          phases: <MonitoringPhase>[
            MonitoringPhase(
              phase: 'weekly',
              weekStart: 1,
              weekEnd: 18,
              frequency: 'every 7 days',
              test: 'FBC',
              notes: 'Weekly weeks 1–18.',
            ),
            MonitoringPhase(
              phase: 'fortnightly',
              weekStart: 19,
              weekEnd: 52,
              frequency: 'every 14 days',
              test: 'FBC',
              notes: 'Fortnightly weeks 19–52.',
            ),
            MonitoringPhase(
              phase: 'monthly',
              weekStart: 53,
              weekEnd: null,
              frequency: 'every 28 days',
              test: 'FBC',
              notes: 'Monthly thereafter.',
            ),
          ],
          milestones: <MonitoringMilestone>[
            MonitoringMilestone(
              id: 'baseline',
              timepoint: 'Pre-initiation',
              weekFromStart: 0,
              tests: <String>['FBC', 'ECG', 'troponin', 'BMI', 'lipids'],
              criticalNotes: 'ANC ≥2.0 required.',
            ),
          ],
          fbcThresholds: _fbcThresholds,
          citations: <String>['maudsley15_clozapine_monitoring'],
          lastReviewedISO: '2026-04-01',
          reviewedBy: 'Test',
        ),
        safetyConsiderations: const SafetyConsiderationsData(
          id: 'safety',
          considerations: <SafetyConsideration>[
            SafetyConsideration(
              id: 'agranulocytosis',
              severity: SafetySeverityLevel.danger,
              title: 'Agranulocytosis',
              body: '~0.8% lifetime risk.',
              monitoring: 'Weekly FBC.',
            ),
            SafetyConsideration(
              id: 'myocarditis',
              severity: SafetySeverityLevel.danger,
              title: 'Myocarditis',
              body: 'Weeks 2–4.',
              monitoring: 'Trop + CRP weekly.',
            ),
            SafetyConsideration(
              id: 'constipation-ileus',
              severity: SafetySeverityLevel.warning,
              title: 'Ileus',
              body: 'Constipation can progress to ileus.',
              monitoring: 'Bowel review.',
            ),
            SafetyConsideration(
              id: 'interruption-rule',
              severity: SafetySeverityLevel.warning,
              title: 'Interruption',
              body: '>48 h triggers retitration.',
              monitoring: 'See classifyInterruption().',
            ),
          ],
          citations: <String>['maudsley15_clozapine_safety'],
          lastReviewedISO: '2026-04-01',
          reviewedBy: 'Test',
        ),
        rechallengeRules: const RechallengeRulesData(
          id: 'rechallenge',
          rationale: 'Restart-tier table.',
          tiers: <RechallengeTier>[
            RechallengeTier(
              id: 'lt-48h',
              label: '<48 hours',
              maxHours: 48,
              severity: SafetySeverityLevel.info,
              heading: 'Restart at usual dose',
              guidance: 'Resume.',
              restartInstruction: 'Full dose.',
              retitrationRequired: false,
              monitoringNote: 'Standard.',
              warningSignsToWatch: <String>['hypotension', 'sedation'],
            ),
            RechallengeTier(
              id: '48h-5d',
              label: '48 h – 5 days',
              maxHours: 120,
              severity: SafetySeverityLevel.warning,
              heading: 'Re-titrate',
              guidance: 'Slow restart.',
              restartInstruction: 'Restart at 12.5 mg.',
              retitrationRequired: true,
              monitoringNote: 'Daily review.',
              warningSignsToWatch: <String>['hypotension', 'sedation'],
            ),
            RechallengeTier(
              id: 'gt-5d',
              label: '>5 days',
              maxHours: null,
              severity: SafetySeverityLevel.danger,
              heading: 'Full retitration',
              guidance: 'Restart from day 1.',
              restartInstruction: 'Full retitration protocol.',
              retitrationRequired: true,
              monitoringNote: 'Inpatient consideration.',
              warningSignsToWatch: <String>[
                'hypotension',
                'sedation',
                'tachycardia',
              ],
            ),
          ],
          absoluteContraindications: <String>['active myocarditis'],
          citations: <String>['maudsley15_clozapine_rechallenge'],
          lastReviewedISO: '2026-04-01',
          reviewedBy: 'Test',
        ),
        communityInitiation: const CommunityInitiationData(
          id: 'community',
          rationale: 'Outpatient initiation criteria.',
          relativeContraindications: <CommunityInitiationCriterion>[
            CommunityInitiationCriterion(
              id: 'cv',
              title: 'Cardiovascular disease',
              detail: 'Active CV disease.',
            ),
          ],
          essentialCriteria: <CommunityInitiationCriterion>[
            CommunityInitiationCriterion(
              id: 'compliance',
              title: 'Adherent',
              detail: 'Reliable for FBC.',
            ),
          ],
          initialWorkup: <CommunityInitiationCriterion>[
            CommunityInitiationCriterion(
              id: 'baseline-fbc',
              title: 'FBC',
              detail: 'ANC ≥2.0.',
            ),
          ],
          monitoringIntensity: CommunityMonitoringIntensity(
            first4Weeks: 'Weekly review.',
            weeks5To18: 'Weekly FBC.',
            weeks19To52: 'Fortnightly FBC.',
            year2Onwards: 'Monthly FBC.',
          ),
          citations: <String>['maudsley15_clozapine_community'],
          lastReviewedISO: '2026-04-01',
          reviewedBy: 'Test',
        ),
      ),
    );

void main() {
  group('clozapine titration protocols', () {
    final variants = <TitrationVariant>[
      (sex: Sex.female, smoker: false),
      (sex: Sex.female, smoker: true),
      (sex: Sex.male, smoker: false),
      (sex: Sex.male, smoker: true),
    ];

    test('all 4 variants start at 6.25 mg evening on day 1', () {
      final m = _module();
      for (final v in variants) {
        final p = m.getTitration(v);
        expect(p.steps[0].day, equals(1));
        expect(p.steps[0].morningMg, equals(0));
        expect(p.steps[0].eveningMg, equals(6.25));
        expect(p.steps[0].totalMg, equals(6.25));
      }
    });

    test('targets reflect sex × smoker pharmacokinetics', () {
      final m = _module();
      expect(
        m.getTitration((sex: Sex.female, smoker: false)).targetDoseMg,
        equals(225),
      );
      expect(
        m.getTitration((sex: Sex.female, smoker: true)).targetDoseMg,
        equals(300),
      );
      expect(
        m.getTitration((sex: Sex.male, smoker: false)).targetDoseMg,
        equals(250),
      );
      expect(
        m.getTitration((sex: Sex.male, smoker: true)).targetDoseMg,
        equals(375),
      );
    });

    test('smokers reach a higher target than non-smokers (CYP1A2 induction)',
        () {
      final m = _module();
      expect(
        m.getTitration((sex: Sex.female, smoker: true)).targetDoseMg,
        greaterThan(
          m.getTitration((sex: Sex.female, smoker: false)).targetDoseMg,
        ),
      );
      expect(
        m.getTitration((sex: Sex.male, smoker: true)).targetDoseMg,
        greaterThan(
          m.getTitration((sex: Sex.male, smoker: false)).targetDoseMg,
        ),
      );
    });

    test(
        'males reach a higher target than females within smoking-status',
        () {
      final m = _module();
      expect(
        m.getTitration((sex: Sex.male, smoker: false)).targetDoseMg,
        greaterThan(
          m.getTitration((sex: Sex.female, smoker: false)).targetDoseMg,
        ),
      );
      expect(
        m.getTitration((sex: Sex.male, smoker: true)).targetDoseMg,
        greaterThan(
          m.getTitration((sex: Sex.female, smoker: true)).targetDoseMg,
        ),
      );
    });

    test('every titration step has totalMg = morning + evening', () {
      final m = _module();
      for (final v in variants) {
        final p = m.getTitration(v);
        for (final step in p.steps) {
          expect(step.totalMg, equals(step.morningMg + step.eveningMg));
        }
      }
    });

    test('all 4 variants are 20-day protocols and end at the target dose',
        () {
      final m = _module();
      for (final v in variants) {
        final p = m.getTitration(v);
        expect(p.totalDays, equals(20));
        expect(p.steps.length, equals(20));
        expect(p.steps.last.totalMg, equals(p.targetDoseMg));
      }
    });

    test('all 4 variants document the >48h missed-dose rule', () {
      final m = _module();
      for (final v in variants) {
        expect(m.getTitration(v).missedDoseRule, contains('48'));
      }
    });

    test('citations reference Maudsley 15', () {
      final m = _module();
      for (final v in variants) {
        expect(
          m.getTitration(v).citations.any((c) => c.contains('maudsley15')),
          isTrue,
        );
      }
    });
  });

  group('monitoring schedule', () {
    test('first phase is weekly FBC for 18 weeks', () {
      final s = _module().getMonitoringSchedule();
      final weekly = s.phases.firstWhere((p) => p.phase == 'weekly');
      expect(weekly.weekStart, equals(1));
      expect(weekly.weekEnd, equals(18));
      expect(weekly.test, contains('FBC'));
    });

    test('monthly phase is indefinite (weekEnd = null)', () {
      final s = _module().getMonitoringSchedule();
      final monthly = s.phases.firstWhere((p) => p.phase == 'monthly');
      expect(monthly.weekEnd, isNull);
    });

    test('baseline milestone includes ECG and troponin', () {
      final s = _module().getMonitoringSchedule();
      final baseline = s.milestones.firstWhere((x) => x.id == 'baseline');
      expect(baseline.tests, contains('ECG'));
      expect(baseline.tests, contains('troponin'));
      expect(baseline.tests, contains('FBC'));
    });
  });

  group('classifyFbc — CPMS traffic-light thresholds', () {
    test('green when ANC and WBC both above green', () {
      final r = classifyFbc(
        ancE9PerL: 3.0,
        wbcE9PerL: 5.0,
        thresholds: _fbcThresholds,
      );
      expect(r.zone, equals(FbcZone.green));
    });

    test('amber when ANC below green but above red', () {
      final r = classifyFbc(
        ancE9PerL: 1.7,
        wbcE9PerL: 5.0,
        thresholds: _fbcThresholds,
      );
      expect(r.zone, equals(FbcZone.amber));
    });

    test('red when ANC below red', () {
      final r = classifyFbc(
        ancE9PerL: 1.2,
        wbcE9PerL: 5.0,
        thresholds: _fbcThresholds,
      );
      expect(r.zone, equals(FbcZone.red));
    });

    test('red when WBC below red even if ANC ok', () {
      final r = classifyFbc(
        ancE9PerL: 3.0,
        wbcE9PerL: 2.5,
        thresholds: _fbcThresholds,
      );
      expect(r.zone, equals(FbcZone.red));
    });

    test('BEN-adjusted green: ANC 1.6 is GREEN', () {
      final r = classifyFbc(
        ancE9PerL: 1.6,
        wbcE9PerL: 3.2,
        thresholds: _fbcThresholds,
        applyBen: true,
      );
      expect(r.zone, equals(FbcZone.green));
    });

    test('BEN-adjusted amber: ANC 1.2 is AMBER', () {
      final r = classifyFbc(
        ancE9PerL: 1.2,
        wbcE9PerL: 3.2,
        thresholds: _fbcThresholds,
        applyBen: true,
      );
      expect(r.zone, equals(FbcZone.amber));
    });

    test('BEN-adjusted red: ANC 0.9 is RED', () {
      final r = classifyFbc(
        ancE9PerL: 0.9,
        wbcE9PerL: 3.2,
        thresholds: _fbcThresholds,
        applyBen: true,
      );
      expect(r.zone, equals(FbcZone.red));
    });
  });

  group('classifyInterruption', () {
    test('<48 h returns the lt-48h tier', () {
      final t = _module().classifyInterruption(hours: 24);
      expect(t.id, equals('lt-48h'));
      expect(t.retitrationRequired, isFalse);
    });

    test('72 h returns the 48h-5d tier', () {
      final t = _module().classifyInterruption(days: 3);
      expect(t.id, equals('48h-5d'));
      expect(t.retitrationRequired, isTrue);
    });

    test('7 days returns the gt-5d tier', () {
      final t = _module().classifyInterruption(days: 7);
      expect(t.id, equals('gt-5d'));
      expect(t.severity, equals(SafetySeverityLevel.danger));
    });

    test('hours and days are summed', () {
      final t = _module().classifyInterruption(days: 2, hours: 1);
      // 49h → exceeds lt-48h, falls into 48h-5d.
      expect(t.id, equals('48h-5d'));
    });
  });

  group('safety considerations', () {
    test('includes the four highest-stakes considerations', () {
      final ids = _module()
          .getSafetyConsiderations()
          .considerations
          .map((c) => c.id)
          .toSet();
      expect(ids, contains('agranulocytosis'));
      expect(ids, contains('myocarditis'));
      expect(ids, contains('constipation-ileus'));
      expect(ids, contains('interruption-rule'));
    });

    test('agranulocytosis and myocarditis are danger severity', () {
      final list = _module().getSafetyConsiderations().considerations;
      final agra = list.firstWhere((c) => c.id == 'agranulocytosis');
      final myo = list.firstWhere((c) => c.id == 'myocarditis');
      expect(agra.severity, equals(SafetySeverityLevel.danger));
      expect(myo.severity, equals(SafetySeverityLevel.danger));
    });
  });

  group('FbcZone + SafetySeverityLevel jsonValue', () {
    test('FbcZone values have non-empty jsonValue', () {
      for (final z in FbcZone.values) {
        expect(z.jsonValue, isNotEmpty);
      }
    });

    test('SafetySeverityLevel parses round-trip', () {
      for (final s in SafetySeverityLevel.values) {
        expect(SafetySeverityLevel.fromJson(s.jsonValue), equals(s));
      }
    });
  });
}
