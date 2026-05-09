// Tests for the Dart qtc_stacker port. No TS counterpart exists.
//
// Tests are pure-Dart — they construct a [QtcRiskData] inline rather
// than loading the JSON, which keeps the suite fast and decoupled from
// the asset bundle. A separate integration test (Phase 4) will exercise
// the full registry from disk.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/qtc_stacker.dart';

QtcRiskData _fixture() => const QtcRiskData(
      id: 'qtc-test',
      rationale: 'Test fixture.',
      riskCategories: <QtcCategory, String>{
        QtcCategory.known: 'Known',
        QtcCategory.conditional: 'Conditional',
        QtcCategory.possible: 'Possible',
        QtcCategory.low: 'Low',
      },
      drugs: <QtcDrugEntry>[
        QtcDrugEntry(
          id: 'haloperidol',
          name: 'Haloperidol',
          category: 'antipsychotic',
          qtcCategory: QtcCategory.known,
          notes: 'Higher risk IV.',
        ),
        QtcDrugEntry(
          id: 'pimozide',
          name: 'Pimozide',
          category: 'antipsychotic',
          qtcCategory: QtcCategory.known,
          notes: 'Avoid combinations.',
        ),
        QtcDrugEntry(
          id: 'quetiapine',
          name: 'Quetiapine',
          category: 'antipsychotic',
          qtcCategory: QtcCategory.conditional,
          notes: 'Dose-dependent.',
        ),
        QtcDrugEntry(
          id: 'risperidone',
          name: 'Risperidone',
          category: 'antipsychotic',
          qtcCategory: QtcCategory.possible,
          notes: 'Modest effect.',
        ),
        QtcDrugEntry(
          id: 'sertraline',
          name: 'Sertraline',
          category: 'antidepressant',
          qtcCategory: QtcCategory.low,
          notes: 'Negligible.',
        ),
      ],
      riskThresholds: QtcRiskThresholds(
        overallAssessmentNote: 'See full registry.',
      ),
      citations: <String>['credible_meds'],
      lastReviewedISO: '2026-04-01',
      reviewedBy: 'Rashid',
    );

void main() {
  group('assessQtcRisk scoring', () {
    test('empty selection → none', () {
      final r = assessQtcRisk(<String>[], _fixture());
      expect(r.overallRisk, equals(OverallRisk.none));
      expect(r.summary, equals('No drugs selected.'));
      expect(r.recommendations.first, contains('No selected drug'));
    });

    test('one possible (1pt) → low', () {
      final r = assessQtcRisk(<String>['risperidone'], _fixture());
      expect(r.overallRisk, equals(OverallRisk.low));
    });

    test('one conditional (2pt) → low', () {
      final r = assessQtcRisk(<String>['quetiapine'], _fixture());
      expect(r.overallRisk, equals(OverallRisk.low));
    });

    test('one known (3pt) → moderate', () {
      final r = assessQtcRisk(<String>['haloperidol'], _fixture());
      expect(r.overallRisk, equals(OverallRisk.moderate));
    });

    test('two known (6pt) → high + cardiology recommendation', () {
      final r = assessQtcRisk(
        <String>['haloperidol', 'pimozide'],
        _fixture(),
      );
      expect(r.overallRisk, equals(OverallRisk.high));
      expect(r.knownCount, equals(2));
      expect(
        r.recommendations.any((s) => s.contains('Cardiology')),
        isTrue,
      );
    });

    test('three known (9pt) → very_high', () {
      // Synthesise extra known drug for the boundary test.
      const data = QtcRiskData(
        id: 'tri-known',
        rationale: 'Test',
        riskCategories: <QtcCategory, String>{
          QtcCategory.known: 'k',
          QtcCategory.conditional: 'c',
          QtcCategory.possible: 'p',
          QtcCategory.low: 'l',
        },
        drugs: <QtcDrugEntry>[
          QtcDrugEntry(
            id: 'a',
            name: 'A',
            category: 'x',
            qtcCategory: QtcCategory.known,
            notes: '',
          ),
          QtcDrugEntry(
            id: 'b',
            name: 'B',
            category: 'x',
            qtcCategory: QtcCategory.known,
            notes: '',
          ),
          QtcDrugEntry(
            id: 'c',
            name: 'C',
            category: 'x',
            qtcCategory: QtcCategory.known,
            notes: '',
          ),
        ],
        riskThresholds: QtcRiskThresholds(overallAssessmentNote: ''),
        citations: <String>[],
        lastReviewedISO: '2026',
        reviewedBy: 'Rashid',
      );
      final r = assessQtcRisk(<String>['a', 'b', 'c'], data);
      expect(r.overallRisk, equals(OverallRisk.veryHigh));
    });

    test('summary counts categories correctly', () {
      final r = assessQtcRisk(
        <String>['haloperidol', 'quetiapine', 'risperidone', 'sertraline'],
        _fixture(),
      );
      expect(r.knownCount, equals(1));
      expect(r.conditionalCount, equals(1));
      expect(r.possibleCount, equals(1));
      expect(r.summary, contains('4 drugs selected'));
      expect(r.summary, contains('1 Known'));
    });

    test('unknown ids are silently dropped', () {
      final r = assessQtcRisk(<String>['not-a-drug'], _fixture());
      expect(r.selectedDrugs, isEmpty);
      expect(r.overallRisk, equals(OverallRisk.none));
    });
  });

  group('listQtcDrugs', () {
    test('returns the registry drug list', () {
      expect(listQtcDrugs(_fixture()).length, equals(5));
    });
  });

  group('QtcCategory and OverallRisk jsonValue round-trips', () {
    test('every QtcCategory parses back', () {
      for (final c in QtcCategory.values) {
        expect(QtcCategory.fromJson(c.jsonValue), equals(c));
      }
    });

    test('every OverallRisk parses back', () {
      for (final r in OverallRisk.values) {
        expect(OverallRisk.fromJson(r.jsonValue), equals(r));
      }
    });
  });

  group('QtcRiskData.fromJson', () {
    test('decodes the canonical JSON shape', () {
      final raw = <String, dynamic>{
        'id': 'qtc',
        'rationale': 'TdP',
        'riskCategories': <String, dynamic>{
          'known': 'k',
          'conditional': 'c',
          'possible': 'p',
          'low': 'l',
        },
        'drugs': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'haloperidol',
            'name': 'Haloperidol',
            'category': 'antipsychotic',
            'qtcCategory': 'known',
            'notes': 'IV risk.',
          },
        ],
        'riskThresholds': <String, dynamic>{
          'overallAssessmentNote': 'See full.',
        },
        'citations': <String>['credible_meds'],
        'lastReviewedISO': '2026-04-01',
        'reviewedBy': 'Rashid',
      };
      final data = QtcRiskData.fromJson(raw);
      expect(data.drugs.length, equals(1));
      expect(data.drugs.first.qtcCategory, equals(QtcCategory.known));
      expect(data.riskCategories[QtcCategory.known], equals('k'));
    });
  });
}
