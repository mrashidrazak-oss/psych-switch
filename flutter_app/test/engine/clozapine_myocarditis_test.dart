import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/clozapine_myocarditis.dart';

void main() {
  test('no findings → continue monitoring', () {
    final r = evaluateClozapineMyocarditis();
    expect(r.action, MyocarditisAction.continueMonitoring);
    expect(r.schedule.join(' '), contains('Weekly troponin'));
  });

  test('a single red finding → STOP now', () {
    final r = evaluateClozapineMyocarditis(
      findings: <String>{'troponin_2x'},
    );
    expect(r.action, MyocarditisAction.stopNow);
    expect(r.steps.first, contains('STOP'));
  });

  test('one amber finding → urgent review', () {
    final r = evaluateClozapineMyocarditis(
      findings: <String>{'tachycardia'},
    );
    expect(r.action, MyocarditisAction.urgentReview);
  });

  test('two amber findings escalate to urgent review', () {
    final r = evaluateClozapineMyocarditis(
      findings: <String>{'tachycardia', 'flu_like'},
    );
    expect(r.action, MyocarditisAction.urgentReview);
    expect(r.headline, contains('Two or more'));
  });

  test('FBC-does-not-detect caution always present', () {
    final r = evaluateClozapineMyocarditis();
    expect(r.cautions.join(' '), contains('FBC monitoring does NOT'));
  });

  test('clipboard summary reports action + schedule', () {
    final r = evaluateClozapineMyocarditis(
      findings: <String>{'crp_100'},
    );
    final s = r.clipboardSummary();
    expect(s, contains('STOP'));
    expect(s, contains('surveillance schedule'));
  });
}
