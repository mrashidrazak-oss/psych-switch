import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/hyperthermic_dx.dart';

void main() {
  test('four differentials registered', () {
    expect(kHyperthermicDifferentials.length, 4);
    final ids = kHyperthermicDifferentials.map((d) => d.id).toSet();
    expect(ids, containsAll(
        <String>['nms', 'serotonin', 'malignant_catatonia', 'anticholinergic']));
  });

  test('empty → no top differential', () {
    final r = rankHyperthermic(<String>{});
    expect(r.topId, isNull);
  });

  test('classic NMS picture ranks NMS first', () {
    final r = rankHyperthermic(<String>{
      'dopamine_antagonist',
      'onset_subacute',
      'lead_pipe_rigidity',
      'markedly_raised_ck',
    });
    expect(r.topId, 'nms');
  });

  test('clonus + serotonergic + rapid → serotonin syndrome', () {
    final r = rankHyperthermic(<String>{
      'serotonergic_agent',
      'onset_rapid',
      'clonus_hyperreflexia',
      'hyperactive_bowel',
    });
    expect(r.topId, 'serotonin');
  });

  test('dry/flushed + ileus + anticholinergic → anticholinergic', () {
    final r = rankHyperthermic(<String>{
      'anticholinergic_agent',
      'dry_flushed_skin',
      'absent_bowel_retention',
      'normal_tone',
    });
    expect(r.topId, 'anticholinergic');
  });

  test('catatonic prodrome → malignant catatonia', () {
    final r = rankHyperthermic(<String>{
      'psychiatric_prodrome',
      'catatonic_signs',
      'onset_subacute',
    });
    expect(r.topId, 'malignant_catatonia');
  });

  test('top differential exposes discriminator + management', () {
    final r = rankHyperthermic(<String>{
      'serotonergic_agent',
      'clonus_hyperreflexia',
    });
    expect(r.top, isNotNull);
    expect(r.top!.discriminator, isNotEmpty);
    expect(r.clipboardSummary(), contains('Leading differential'));
  });
}
