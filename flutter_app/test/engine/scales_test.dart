// Tests for the clinical-scales engine. Locks the scoring math + the
// severity-band thresholds so any future content edit must update
// these tests deliberately.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/scales.dart';

void main() {
  group('scaleById', () {
    test('returns each registered scale', () {
      expect(scaleById('phq9')?.name, 'PHQ-9');
      expect(scaleById('gad7')?.name, 'GAD-7');
      expect(scaleById('hamd17')?.name, 'HAM-D-17');
      expect(scaleById('aims')?.name, 'AIMS');
    });

    test('returns null on unknown id', () {
      expect(scaleById('imaginary'), isNull);
    });
  });

  group('PHQ-9 max + bands', () {
    test('max score = 27', () {
      expect(scaleById('phq9')!.maxScore, 27);
    });

    test('all-zero answers → minimal band (severity 0)', () {
      final r = scoreScale(scaleById('phq9')!, <String, int>{});
      expect(r.total, 0);
      expect(r.band.label, 'None / minimal');
      expect(r.band.severity, 0);
    });

    test('score 7 → mild', () {
      final r = scoreScale(scaleById('phq9')!, <String, int>{
        'phq9_1': 2, 'phq9_2': 2, 'phq9_3': 3,
      });
      expect(r.total, 7);
      expect(r.band.label, 'Mild');
    });

    test('score 12 → moderate', () {
      final r = scoreScale(scaleById('phq9')!, <String, int>{
        'phq9_1': 3, 'phq9_2': 3, 'phq9_3': 3, 'phq9_4': 3,
      });
      expect(r.total, 12);
      expect(r.band.label, 'Moderate');
    });

    test('score 17 → moderately severe', () {
      final r = scoreScale(scaleById('phq9')!, <String, int>{
        'phq9_1': 3, 'phq9_2': 3, 'phq9_3': 3, 'phq9_4': 3,
        'phq9_5': 2, 'phq9_6': 3,
      });
      expect(r.total, 17);
      expect(r.band.label, 'Moderately severe');
    });

    test('all-3 across 9 items → severe (27)', () {
      final ans = <String, int>{
        for (var i = 1; i <= 9; i++) 'phq9_$i': 3,
      };
      final r = scoreScale(scaleById('phq9')!, ans);
      expect(r.total, 27);
      expect(r.band.label, 'Severe');
      expect(r.band.severity, 4);
    });
  });

  group('GAD-7 bands', () {
    test('max = 21, all-zero → minimal', () {
      expect(scaleById('gad7')!.maxScore, 21);
      final r = scoreScale(scaleById('gad7')!, <String, int>{});
      expect(r.total, 0);
      expect(r.band.label, 'Minimal');
    });

    test('score 10 → moderate', () {
      final ans = <String, int>{
        for (var i = 1; i <= 5; i++) 'gad7_$i': 2,
      };
      final r = scoreScale(scaleById('gad7')!, ans);
      expect(r.total, 10);
      expect(r.band.label, 'Moderate');
    });

    test('score 15 → severe', () {
      final ans = <String, int>{
        for (var i = 1; i <= 5; i++) 'gad7_$i': 3,
      };
      final r = scoreScale(scaleById('gad7')!, ans);
      expect(r.total, 15);
      expect(r.band.label, 'Severe');
    });
  });

  group('HAM-D-17 mixed anchors', () {
    test('max score = 52 (9 items 0–4 + 8 items 0–2)', () {
      expect(scaleById('hamd17')!.maxScore, 52);
    });

    test('boundary 7 → no depression, 8 → mild', () {
      final s = scaleById('hamd17')!;
      expect(scoreScale(s, <String, int>{'hamd_1': 4, 'hamd_3': 3})
          .band.label, 'No depression');
      expect(scoreScale(s, <String, int>{'hamd_1': 4, 'hamd_3': 4})
          .band.label, 'Mild');
    });

    test('clamps over-the-max input', () {
      final r = scoreScale(scaleById('hamd17')!, <String, int>{
        'hamd_1': 99,
      });
      expect(r.total, 4); // clamped to item max
    });
  });

  group('AIMS — only items 1–7 sum, items 8–12 ignored from total', () {
    test('max scored total = 28 (7 items × 4)', () {
      expect(scaleById('aims')!.maxScore, 28);
    });

    test('global / yes-no items do not inflate the total', () {
      final r = scoreScale(scaleById('aims')!, <String, int>{
        'aims_8': 4, 'aims_9': 4, 'aims_10': 4,
        'aims_11': 1, 'aims_12': 1,
      });
      expect(r.total, 0);
      expect(r.band.label, 'No dyskinesia');
    });

    test('moderate band at score 10', () {
      final ans = <String, int>{
        for (var i = 1; i <= 5; i++) 'aims_$i': 2,
      };
      final r = scoreScale(scaleById('aims')!, ans);
      expect(r.total, 10);
      expect(r.band.label, 'Moderate');
    });

    test('severe band at score 18+', () {
      final ans = <String, int>{
        'aims_1': 4, 'aims_2': 4, 'aims_3': 4,
        'aims_4': 3, 'aims_5': 3,
      };
      final r = scoreScale(scaleById('aims')!, ans);
      expect(r.total, 18);
      expect(r.band.label, 'Severe');
    });
  });

  test('every scale has at least one band, contiguous from 0', () {
    for (final s in kClinicalScales) {
      expect(s.bands, isNotEmpty);
      expect(s.bands.first.min, 0);
      // Each band's max+1 should be the next band's min.
      for (var i = 0; i < s.bands.length - 1; i++) {
        expect(s.bands[i].max + 1, s.bands[i + 1].min,
            reason: '${s.name} band ${i + 1} non-contiguous');
      }
      // Last band's max should reach the scale's maxScore (or beyond).
      expect(s.bands.last.max >= s.maxScore, isTrue,
          reason: '${s.name} last band does not cover maxScore');
    }
  });
}
