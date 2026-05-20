// Tests for the Dart depot_lai port. No TS counterpart — the
// reference data is exercised by hand here.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/depot_lai.dart';

void main() {
  group('Invega Sustenna', () {
    test('Day 1 loading dose is 150 mg eq deltoid only', () {
      final day1 = sustenna.initiationSteps.firstWhere(
        (s) => s.label == 'Day 1',
      );
      expect(day1.doseMgEq, equals(150));
      expect(day1.site, contains('Deltoid'));
    });

    test('Day 8 loading dose is 100 mg eq deltoid only', () {
      final day8 = sustenna.initiationSteps.firstWhere(
        (s) => s.label.startsWith('Day 8'),
      );
      expect(day8.doseMgEq, equals(100));
      expect(day8.site, contains('Deltoid'));
    });

    test('150 mg eq strength has volume 1.5 mL', () {
      final s = sustenna.availableStrengths
          .firstWhere((x) => x.mgEq == 150);
      expect(s.volumeMl, equals(1.5));
      expect(s.mgPP, equals(234));
    });

    test('5 strengths registered: 25 / 50 / 75 / 100 / 150 mg eq', () {
      final eqs = sustenna.availableStrengths.map((s) => s.mgEq).toList();
      expect(eqs, equals(<num>[25, 50, 75, 100, 150]));
    });

    test('Severe renal impairment is contraindicated', () {
      final severe = sustenna.renalAdjustments.firstWhere(
        (r) => r.category.contains('Moderate'),
      );
      expect(severe.day1, equals('CONTRAINDICATED'));
      expect(severe.maintenance, equals('CONTRAINDICATED'));
    });

    test('Missed-dose maintenance > 6 months requires full re-initiation',
        () {
      final danger = sustenna.missedDoseMaintenance.firstWhere(
        (s) => s.severity == DepotSeverity.danger,
      );
      expect(danger.condition, contains('> 6 months'));
      expect(danger.action, contains('Restart full initiation'));
    });
  });

  group('Invega Trinza', () {
    test('Eligibility requires ≥4 months stable on PP1M', () {
      expect(
        trinza.eligibilityCriteria.first,
        contains('≥ 4 months'),
      );
    });

    test('PP1M → PP3M conversion table covers 50/75/100/150 mg eq', () {
      final pp1m =
          trinza.pp1mToTrinzaConversion.map((c) => c.pp1mMgEq).toList();
      expect(pp1m, equals(<num>[50, 75, 100, 150]));
    });

    test('PP1M 100 mg eq converts to PP3M 350 mg eq', () {
      final c = trinza.pp1mToTrinzaConversion
          .firstWhere((x) => x.pp1mMgEq == 100);
      expect(c.pp3mMgEq, equals(350));
    });

    test('PP3M 525 bridge dose is 100 mg eq (corrected per FDA PI)', () {
      final bridge = trinza.pp1mBridgeTable
          .firstWhere((b) => b.pp3mStrengthMgEq == 525);
      expect(bridge.pp1mBridgeMgEq, equals(100));
    });

    test('4 strengths registered: 175 / 263 / 350 / 525 mg eq', () {
      final eqs = trinza.availableStrengths.map((s) => s.mgEq).toList();
      expect(eqs, equals(<num>[175, 263, 350, 525]));
    });

    test('Missed-dose > 9 months requires full PP1M reinitiation', () {
      final danger = trinza.missedDoseScenarios.firstWhere(
        (s) =>
            s.condition.contains('> 9 months'),
      );
      expect(danger.severity, equals(DepotSeverity.danger));
      expect(danger.action, contains('150 mg eq'));
    });

    test('Severe renal impairment is NOT recommended', () {
      final severe = trinza.renalAdjustments.firstWhere(
        (r) => r.category.contains('Moderate'),
      );
      expect(severe.notes, contains('NOT RECOMMENDED'));
    });
  });

  group('Abilify Maintena', () {
    test('Two strengths: 300 mg and 400 mg', () {
      final mgs =
          maintena.availableStrengths.map((s) => s.mgAripiprazole).toList();
      expect(mgs, equals(<num>[300, 400]));
    });

    test('14-day method: oral 10–20 mg + 400 mg IM Day 1', () {
      final m = maintena.initiationMethods.fourteenDay;
      expect(m.injection, contains('400 mg'));
      expect(m.oral, contains('14 consecutive days'));
    });

    test('1-day method: 800 mg total via two 400 mg injections', () {
      final m = maintena.initiationMethods.oneDay;
      expect(m.injection, contains('800 mg'));
      expect(m.injection, contains('two different sites'));
    });

    test('Strong CYP3A4 inducer (carbamazepine) is danger severity', () {
      final hit = maintena.drugInteractions.firstWhere(
        (d) => d.situation.contains('inducer'),
      );
      expect(hit.severity, equals(DepotSeverity.danger));
      expect(hit.action, contains('AVOID'));
    });

    test('CYP2D6 poor metaboliser requires dose reduction', () {
      final hit = maintena.drugInteractions.firstWhere(
        (d) => d.situation.contains('CYP2D6 poor metaboliser'),
      );
      expect(hit.action, contains('300 mg'));
    });

    test('No renal or hepatic dose adjustment required', () {
      expect(maintena.renalNote, contains('No dose adjustment'));
      expect(maintena.hepaticNote, contains('No dose adjustment'));
    });

    test('Missed-dose ≥ 5 weeks (2nd/3rd dose) requires re-initiation', () {
      final danger = maintena.missedDoseSecondThird.firstWhere(
        (s) => s.severity == DepotSeverity.danger,
      );
      expect(danger.condition, contains('≥ 5 weeks'));
    });
  });

  group('DepotSeverity jsonValue round-trips', () {
    test('every severity parses back', () {
      for (final s in DepotSeverity.values) {
        expect(DepotSeverity.fromJson(s.jsonValue), equals(s));
      }
    });
  });

  group('Citations are present', () {
    test('All three protocols carry FDA + Maudsley citations', () {
      expect(sustenna.citations, isNotEmpty);
      expect(trinza.citations, isNotEmpty);
      expect(maintena.citations, isNotEmpty);
      expect(
        sustenna.citations.any((c) => c.contains('FDA Prescribing')),
        isTrue,
      );
      expect(
        trinza.citations.any((c) => c.contains('FDA Prescribing')),
        isTrue,
      );
      expect(
        maintena.citations.any((c) => c.contains('FDA Prescribing')),
        isTrue,
      );
    });
  });
}
