import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/stimulant_cardiac_screen.dart';

void main() {
  test('no risk factors → proceed', () {
    final r = evaluateStimulantCardiacScreen();
    expect(r.verdict, StimulantCardiacVerdict.proceed);
    expect(r.steps.first, contains('baseline'));
  });

  test('any red flag → cardiology first', () {
    final r = evaluateStimulantCardiacScreen(
      riskFactors: <String>{'fh_scd'},
    );
    expect(r.verdict, StimulantCardiacVerdict.cardiologyFirst);
    expect(r.steps.first, contains('Do not start'));
  });

  test('flagged factors are echoed in the steps', () {
    final r = evaluateStimulantCardiacScreen(
      riskFactors: <String>{'structural', 'exertional'},
    );
    final joined = r.steps.join(' ');
    expect(joined, contains('structural'));
    expect(joined, contains('syncope'));
  });

  test('no-routine-ECG caution always present', () {
    final r = evaluateStimulantCardiacScreen();
    expect(r.cautions.join(' '), contains('not required for everyone'));
  });

  test('clipboard summary reports verdict', () {
    final r = evaluateStimulantCardiacScreen(
      riskFactors: <String>{'uncontrolled_htn'},
    );
    final s = r.clipboardSummary();
    expect(s, contains('Cardiology assessment BEFORE'));
    expect(s, contains('Steps:'));
  });
}
