import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/benzo_taper.dart';

void main() {
  test('benzoDrugById returns expected agents', () {
    expect(benzoDrugById('diazepam')?.name, 'Diazepam');
    expect(benzoDrugById('alprazolam')?.name, 'Alprazolam');
    expect(benzoDrugById('zopiclone')?.name, 'Zopiclone');
    expect(benzoDrugById('imaginary'), isNull);
  });

  group('diazepam equivalence', () {
    test('10 mg diazepam ≡ 10 mg diazepam', () {
      final d = benzoDrugById('diazepam')!;
      expect(diazepamEquivalent(d, 10), 10);
    });

    test('1 mg lorazepam ≡ 10 mg diazepam', () {
      final l = benzoDrugById('lorazepam')!;
      expect(diazepamEquivalent(l, 1), 10);
    });

    test('2 mg alprazolam ≡ 40 mg diazepam', () {
      final a = benzoDrugById('alprazolam')!;
      expect(diazepamEquivalent(a, 2), 40);
    });

    test('0.5 mg clonazepam ≡ 10 mg diazepam', () {
      final c = benzoDrugById('clonazepam')!;
      expect(diazepamEquivalent(c, 0.5), 10);
    });
  });

  group('taper plan shape', () {
    test('first step is the start dose; last step is STOP (0)', () {
      final p = buildBenzoTaper(
        startDiazepamMg: 40,
        speed: BenzoTaperSpeed.moderate,
      );
      expect(p.steps.first.diazepamMg, 40);
      expect(p.steps.last.diazepamMg, 0);
    });

    test('doses are monotonically non-increasing', () {
      final p = buildBenzoTaper(
        startDiazepamMg: 30,
        speed: BenzoTaperSpeed.cautious,
      );
      for (var i = 1; i < p.steps.length; i++) {
        expect(p.steps[i].diazepamMg <= p.steps[i - 1].diazepamMg,
            isTrue);
      }
    });

    test('cautious plan longer than faster plan', () {
      final slow = buildBenzoTaper(
        startDiazepamMg: 40,
        speed: BenzoTaperSpeed.cautious,
      );
      final fast = buildBenzoTaper(
        startDiazepamMg: 40,
        speed: BenzoTaperSpeed.faster,
      );
      expect(slow.totalDays > fast.totalDays, isTrue);
    });

    test('terminates for a wide dose range (no runaway loop)', () {
      for (final start in <double>[5, 10, 20, 40, 80, 120]) {
        for (final s in BenzoTaperSpeed.values) {
          final p = buildBenzoTaper(startDiazepamMg: start, speed: s);
          expect(p.steps.length, lessThan(82));
          expect(p.steps.last.diazepamMg, 0);
        }
      }
    });

    test('clipboard summary mentions diazepam-equivalent + STOP', () {
      final p = buildBenzoTaper(
        startDiazepamMg: 30,
        speed: BenzoTaperSpeed.moderate,
      );
      final s = p.clipboardSummary();
      expect(s, contains('diazepam-equivalent'));
      expect(s, contains('STOP'));
    });
  });
}
