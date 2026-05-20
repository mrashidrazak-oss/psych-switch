import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/clozapine_fever.dart';

void main() {
  test('no findings (titration) → work up + monitor', () {
    final r = evaluateClozapineFever();
    expect(r.action, ClozapineFeverAction.workupMonitor);
    expect(r.investigations.join(' '), contains('FBC'));
  });

  test('chest/dyspnoea red flag → emergency', () {
    final r = evaluateClozapineFever(
      findings: <String>{'chest_dyspnoea'},
    );
    expect(r.action, ClozapineFeverAction.emergency);
    expect(r.investigations.first, contains('Withhold clozapine'));
  });

  test('sore throat → urgent withhold (agranulocytosis)', () {
    final r = evaluateClozapineFever(
      findings: <String>{'sore_throat'},
    );
    expect(r.action, ClozapineFeverAction.urgentWithhold);
    expect(r.differential.join(' '),
        contains('agranulocytosis / sepsis'));
  });

  test('red overrides co-existing amber', () {
    final r = evaluateClozapineFever(
      findings: <String>{'sore_throat', 'rigidity_autonomic'},
    );
    expect(r.action, ClozapineFeverAction.emergency);
  });

  test('benign-is-exclusion caution always present', () {
    final r = evaluateClozapineFever();
    expect(r.cautions.join(' '),
        contains('diagnosis of EXCLUSION'));
  });

  test('non-titration with no findings still works up', () {
    final r = evaluateClozapineFever(titrationPhase: false);
    expect(r.action, ClozapineFeverAction.workupMonitor);
    expect(r.differential, isNotEmpty);
  });

  test('clipboard summary reports action + sections', () {
    final s = evaluateClozapineFever(
      findings: <String>{'haemodynamic'},
    ).clipboardSummary();
    expect(s, contains('Emergency'));
    expect(s, contains('Differential to consider:'));
  });
}
