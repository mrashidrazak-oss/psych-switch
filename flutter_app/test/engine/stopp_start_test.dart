// Tests for the STOPP/START gerontology rules.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/stopp_start.dart';

void main() {
  test('empty regimen → no rules trigger', () {
    expect(applyStoppStart(const <String>[]), isEmpty);
  });

  test('regimen with diazepam triggers both long-benzo + chronic-benzo '
      'STOPP rules', () {
    final hits = applyStoppStart(const <String>['diazepam']);
    final ids = hits.map((h) => h.rule.id).toSet();
    expect(ids, containsAll(<String>['stopp_long_benzo', 'stopp_benzo_chronic']));
  });

  test('amitriptyline triggers TCA + anticholinergic-burden warnings', () {
    final hits = applyStoppStart(const <String>['amitriptyline']);
    final ids = hits.map((h) => h.rule.id).toSet();
    expect(ids, contains('stopp_tca_anticholinergic'));
  });

  test('paroxetine surfaces the SSRI-specific STOPP rule', () {
    final hits = applyStoppStart(const <String>['paroxetine']);
    expect(hits.any((h) => h.rule.id == 'stopp_paroxetine'), isTrue);
  });

  test('procyclidine triggers two rules (anticholinergic burden + '
      'prophylactic anti-EPS)', () {
    final hits = applyStoppStart(const <String>['procyclidine']);
    final ids = hits.map((h) => h.rule.id).toSet();
    expect(ids, containsAll(<String>[
      'stopp_anticholinergic_psychotropic',
      'stopp_anticholinergic_for_eps',
    ]));
  });

  test('matchedDrugIds reflects which drugs in the regimen hit the rule',
      () {
    final hits = applyStoppStart(
      const <String>['diazepam', 'lorazepam', 'sertraline'],
    );
    final chronic = hits.firstWhere(
      (h) => h.rule.id == 'stopp_benzo_chronic',
    );
    expect(chronic.matchedDrugIds, containsAll(<String>['diazepam', 'lorazepam']));
    expect(chronic.matchedDrugIds, isNot(contains('sertraline')));
  });

  test('every rule has rationale + title', () {
    for (final r in kStoppStartRules) {
      expect(r.title, isNotEmpty);
      expect(r.rationale, isNotEmpty);
    }
  });
}
