// Tests for the Dart psych_switch_score port. No TS counterpart exists.
// Score composition is exercised end-to-end with synthetic inputs.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/adverse_effects.dart';
import 'package:psychswitch_engine/citations.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';
import 'package:psychswitch_engine/scale_schedule.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';

const _emptyMetabolite = ActiveMetabolite(
  name: null,
  halfLifeHours: null,
  clinicallySignificant: false,
);
const _emptyCyp = CypInteractions(
  substrateOf: <String>[],
  inhibitorOf: <String>[],
  switchingRelevance: '',
);
const _emptyDosing = Dosing(
  startingDoseMg: 0,
  typicalTargetRangeMg: <double>[],
  maxDoseMg: 0,
  increments: <double>[],
  formulationsAvailableMy: <String>[],
);

Drug _drug(String id) => Drug(
      id: id,
      genericName: id,
      drugClass: 'antipsychotic-sga',
      malaysianBrandNames: const <String>[],
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: _emptyMetabolite,
      cypInteractions: _emptyCyp,
      dosing: _emptyDosing,
      formulationNotes: '',
      citations: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

ScaleResult _exactMatch() => const ScaleResult(
      schedule: <ScheduleStep>[],
      applied: ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 1,
        toFactor: 1,
      ),
      adapted: false,
      warnings: <ScaleWarning>[],
      evidencePenalty: 0,
    );

ScaleResult _mildAdapt() => const ScaleResult(
      schedule: <ScheduleStep>[],
      applied: ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 1.25,
        toFactor: 1.0,
      ),
      adapted: true,
      warnings: <ScaleWarning>[],
      evidencePenalty: 1,
    );

ScaleResult _extremeAdapt() => const ScaleResult(
      schedule: <ScheduleStep>[],
      applied: ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 3,
        toFactor: 1,
      ),
      adapted: true,
      warnings: <ScaleWarning>[],
      evidencePenalty: 1,
    );

void main() {
  group('computePsychSwitchScore', () {
    test('clean grade-A switch with no warnings → excellent', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('aripiprazole'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
        ),
      );
      expect(s.total, equals(100));
      expect(s.band, equals(ScoreBand.excellent));
      expect(s.headline, contains('Excellent fit'));
      expect(s.headline, contains('grade A'));
    });

    test('grade-D drops 30 points → caution band at 70', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('aripiprazole'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.d,
        ),
      );
      expect(s.total, equals(70));
      expect(s.band, equals(ScoreBand.caution));
      expect(s.components.evidence.delta, equals(-30));
    });

    test('avoid-grade DDI dominates the score', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('phenelzine'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[
            DdiHit(
              pair: <String>['fluoxetine', 'phenelzine'],
              severity: DdiSeverity.avoid,
              mechanism: DdiMechanism.serotonergic,
              message: 'Avoid',
            ),
          ],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
        ),
      );
      expect(s.components.ddiSafety.delta, equals(-35));
      expect(s.headline, contains('avoid-grade DDI'));
    });

    test('danger-level context warning + danger DDI → poor band', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('valproate'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[
            DdiHit(
              pair: <String>['x', 'y'],
              severity: DdiSeverity.avoid,
              mechanism: DdiMechanism.serotonergic,
              message: 'Avoid',
            ),
          ],
          contextWarnings: const <ContextWarning>[
            ContextWarning(
              severity: WarningSeverity.danger,
              message: 'Pregnancy contraindication',
            ),
          ],
          evidenceGrade: EvidenceGrade.b,
        ),
      );
      // 100 - 10 (B) - 25 (danger) - 35 (avoid DDI) = 30
      expect(s.total, equals(30));
      expect(s.band, equals(ScoreBand.poor));
      expect(s.headline, contains('contraindication flagged'));
    });

    test('avoidAe match: switchCandidate adds +5 bonus', () {
      const ae = AdverseEffect(
        id: 'weight_gain',
        category: AdverseEffectCategory.metabolic,
        label: 'Weight gain',
        summary: '',
        causedBy: <String>['olanzapine'],
        switchCandidates: <String>['aripiprazole'],
        management: '',
        citations: <String>[],
      );
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('aripiprazole'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
          avoidAe: ae,
        ),
      );
      // Already 100, +5 capped at 100.
      expect(s.total, equals(100));
      expect(s.components.aeAlignment.delta, equals(5));
      expect(
        s.components.aeAlignment.note.toLowerCase(),
        contains('avoids weight gain'),
      );
    });

    test('avoidAe match: causedBy gives -20', () {
      const ae = AdverseEffect(
        id: 'weight_gain',
        category: AdverseEffectCategory.metabolic,
        label: 'Weight gain',
        summary: '',
        causedBy: <String>['olanzapine'],
        switchCandidates: <String>['aripiprazole'],
        management: '',
        citations: <String>[],
      );
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('olanzapine'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
          avoidAe: ae,
        ),
      );
      expect(s.components.aeAlignment.delta, equals(-20));
    });

    test('mild dose adaptation costs 3 points', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('aripiprazole'),
          scaleResult: _mildAdapt(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
        ),
      );
      expect(s.components.doseFidelity.delta, equals(-3));
      expect(s.total, equals(97));
    });

    test('extreme dose adaptation costs 10 points', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('aripiprazole'),
          scaleResult: _extremeAdapt(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[],
          evidenceGrade: EvidenceGrade.a,
        ),
      );
      expect(s.components.doseFidelity.delta, equals(-10));
      expect(s.total, equals(90));
    });

    test('context safety capped at -30 even with multiple dangers', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('valproate'),
          scaleResult: _exactMatch(),
          ddiHits: const <DdiHit>[],
          contextWarnings: const <ContextWarning>[
            ContextWarning(
              severity: WarningSeverity.danger,
              message: 'Danger 1',
            ),
            ContextWarning(
              severity: WarningSeverity.danger,
              message: 'Danger 2',
            ),
            ContextWarning(
              severity: WarningSeverity.danger,
              message: 'Danger 3',
            ),
          ],
          evidenceGrade: EvidenceGrade.a,
        ),
      );
      expect(s.components.contextSafety.delta, equals(-30));
    });

    test('total never below 0', () {
      final s = computePsychSwitchScore(
        ScoreInputs(
          toDrug: _drug('valproate'),
          scaleResult: _extremeAdapt(),
          ddiHits: const <DdiHit>[
            DdiHit(
              pair: <String>['x', 'y'],
              severity: DdiSeverity.avoid,
              mechanism: DdiMechanism.serotonergic,
              message: 'Avoid',
            ),
          ],
          contextWarnings: const <ContextWarning>[
            ContextWarning(
              severity: WarningSeverity.danger,
              message: 'Danger',
            ),
          ],
          evidenceGrade: EvidenceGrade.d,
        ),
      );
      expect(s.total, greaterThanOrEqualTo(0));
    });
  });

  group('bandFor', () {
    test('boundaries map correctly', () {
      expect(bandFor(100), equals(ScoreBand.excellent));
      expect(bandFor(90), equals(ScoreBand.excellent));
      expect(bandFor(89), equals(ScoreBand.good));
      expect(bandFor(75), equals(ScoreBand.good));
      expect(bandFor(74), equals(ScoreBand.caution));
      expect(bandFor(50), equals(ScoreBand.caution));
      expect(bandFor(49), equals(ScoreBand.poor));
      expect(bandFor(0), equals(ScoreBand.poor));
    });
  });

  group('bandLabel', () {
    test('all bands have non-empty labels', () {
      for (final b in ScoreBand.values) {
        expect(bandLabel(b), isNotEmpty);
      }
    });
  });

  group('ScoreBand jsonValue round-trips', () {
    test('every band parses back', () {
      for (final b in ScoreBand.values) {
        expect(ScoreBand.fromJson(b.jsonValue), equals(b));
      }
    });
  });
}
