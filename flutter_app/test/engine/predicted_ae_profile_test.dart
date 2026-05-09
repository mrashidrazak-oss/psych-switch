// Tests for the Dart predicted_ae_profile port.
// Mirrors engine/__tests__/predictedAeProfile.test.ts, but uses inline
// Drug fixtures rather than getDrug() (which we haven't ported yet).

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/predicted_ae_profile.dart';
import 'package:psychswitch/src/engine/types/drug.dart';
import 'package:psychswitch/src/engine/types/enums.dart';

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

Drug _drug({
  required String id,
  RiskLevel? sedation,
  RiskLevel? epsRisk,
  RiskLevel? prolactinRisk,
  RiskLevel? qtcRisk,
  MetabolicRisk? metabolicRisk,
  DiscontinuationSyndromeRisk? discontinuationSyndromeRisk,
}) =>
    Drug(
      id: id,
      genericName: id,
      drugClass: 'antidepressant',
      malaysianBrandNames: const <String>[],
      halfLife: const HalfLife(meanHours: 24, rangeHours: <double>[]),
      activeMetabolite: _emptyMetabolite,
      cypInteractions: _emptyCyp,
      sedation: sedation,
      epsRisk: epsRisk,
      prolactinRisk: prolactinRisk,
      qtcRisk: qtcRisk,
      metabolicRisk: metabolicRisk,
      discontinuationSyndromeRisk: discontinuationSyndromeRisk,
      dosing: _emptyDosing,
      formulationNotes: '',
      citations: const <String>[],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Test',
    );

void main() {
  group('predictAeProfile', () {
    test(
      'aripiprazole shows akathisia as high (reverse-lookup wins over '
      'low drug field)',
      () {
        final profile = predictAeProfile(
          _drug(
            id: 'aripiprazole',
            epsRisk: RiskLevel.low, // drug field says low (parkinsonism)
          ),
        );
        final eps = profile.predictions.firstWhere(
          (p) => p.ae.id == 'eps_akathisia',
        );
        expect(
          <AeLikelihood>[AeLikelihood.high, AeLikelihood.moderate],
          contains(eps.likelihood),
        );
      },
    );

    test('olanzapine shows weight gain as high', () {
      final profile = predictAeProfile(
        _drug(
          id: 'olanzapine',
          metabolicRisk: const MetabolicRisk(
            score: RiskLevel.high,
            notes: '',
          ),
        ),
      );
      final wt = profile.predictions.firstWhere(
        (p) => p.ae.id == 'weight_gain',
      );
      expect(wt.likelihood, equals(AeLikelihood.high));
    });

    test(
      'aripiprazole shows weight gain as lower-than-current when switching '
      'from olanzapine',
      () {
        final profile = predictAeProfile(
          _drug(id: 'aripiprazole'),
          _drug(id: 'olanzapine'),
        );
        final wt = profile.predictions.firstWhere(
          (p) => p.ae.id == 'weight_gain',
        );
        expect(wt.likelihood, equals(AeLikelihood.lowerThanCurrent));
      },
    );

    test('mirtazapine shows sedation high (per drug profile)', () {
      final profile = predictAeProfile(
        _drug(id: 'mirtazapine', sedation: RiskLevel.high),
      );
      final sed = profile.predictions.firstWhere(
        (p) => p.ae.id == 'sedation',
      );
      expect(
        <AeLikelihood>[AeLikelihood.high, AeLikelihood.moderate],
        contains(sed.likelihood),
      );
    });

    test('predictions sorted by likelihood (high first)', () {
      final profile = predictAeProfile(
        _drug(
          id: 'clozapine',
          sedation: RiskLevel.high,
          metabolicRisk: const MetabolicRisk(
            score: RiskLevel.high,
            notes: '',
          ),
        ),
      );
      final ranks = profile.predictions
          .map((p) => switch (p.likelihood) {
                AeLikelihood.high => 4,
                AeLikelihood.moderate => 3,
                AeLikelihood.low => 2,
                AeLikelihood.lowerThanCurrent => 1,
                AeLikelihood.unknown => 0,
              })
          .toList();
      for (var i = 1; i < ranks.length; i++) {
        expect(ranks[i], lessThanOrEqualTo(ranks[i - 1]));
      }
    });

    test('every prediction includes a non-empty reason', () {
      final profile = predictAeProfile(
        _drug(
          id: 'quetiapine',
          sedation: RiskLevel.high,
          metabolicRisk: const MetabolicRisk(
            score: RiskLevel.moderate,
            notes: '',
          ),
        ),
      );
      for (final p in profile.predictions) {
        expect(p.reason, isNotEmpty);
      }
    });

    test('drug not in any AE table returns empty predictions', () {
      final profile = predictAeProfile(_drug(id: 'unknown-drug'));
      expect(profile.predictions, isEmpty);
    });
  });

  group('likelihoodLabel', () {
    test('returns user-facing strings', () {
      expect(
        likelihoodLabel(AeLikelihood.high).toLowerCase(),
        contains('high'),
      );
      expect(
        likelihoodLabel(AeLikelihood.lowerThanCurrent).toLowerCase(),
        contains('lower'),
      );
    });
  });

  group('AeLikelihood jsonValue round-trips', () {
    test('every likelihood parses back', () {
      for (final l in AeLikelihood.values) {
        expect(AeLikelihood.fromJson(l.jsonValue), equals(l));
      }
    });
  });
}
