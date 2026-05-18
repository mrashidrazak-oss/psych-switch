import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/clozapine_gi.dart';

void main() {
  test('no findings → continue prophylaxis', () {
    final r = evaluateClozapineGi();
    expect(r.action, ClozapineGiAction.prophylaxis);
    expect(r.steps.join(' '), contains('prophylactic laxatives'));
  });

  test('an amber finding → escalate', () {
    final r = evaluateClozapineGi(
      findings: <String>{'no_bm_3d'},
    );
    expect(r.action, ClozapineGiAction.escalate);
  });

  test('a red finding → surgical emergency', () {
    final r = evaluateClozapineGi(
      findings: <String>{'vomiting'},
    );
    expect(r.action, ClozapineGiAction.emergency);
    expect(r.steps.first, contains('emergency'));
  });

  test('red overrides co-existing amber', () {
    final r = evaluateClozapineGi(
      findings: <String>{'no_bm_3d', 'no_flatus'},
    );
    expect(r.action, ClozapineGiAction.emergency);
  });

  test('higher-fatality caution always present', () {
    final r = evaluateClozapineGi();
    expect(r.cautions.join(' '),
        contains('HIGHER case-fatality than'));
  });

  test('clipboard summary reports action', () {
    final s = evaluateClozapineGi(
      findings: <String>{'absent_bowel_sounds'},
    ).clipboardSummary();
    expect(s, contains('Surgical emergency'));
    expect(s, contains('Steps:'));
  });
}
