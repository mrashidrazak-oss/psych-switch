// Tests for the movement-disorder identifier.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/movement_disorder.dart';

void main() {
  test('empty set → no top diagnosis', () {
    final r = rankMovementDisorder(<String>{});
    expect(r.topId, isNull);
  });

  test('three parkinsonism anchors → parkinsonism top', () {
    final r = rankMovementDisorder(<String>{
      'mvt_pkn_tremor', 'mvt_pkn_rigidity', 'mvt_pkn_bradykinesia',
    });
    expect(r.topId, 'parkinsonism');
  });

  test('acute dystonia anchors win over partial parkinsonism', () {
    final r = rankMovementDisorder(<String>{
      'mvt_dys_acute', 'mvt_dys_onset_hours', 'mvt_dys_distressing',
      'mvt_pkn_tremor',
    });
    expect(r.topId, 'dystonia');
  });

  test('akathisia inner restlessness + recent change → akathisia', () {
    final r = rankMovementDisorder(<String>{
      'mvt_aka_subjective', 'mvt_aka_movement', 'mvt_aka_recent_change',
    });
    expect(r.topId, 'akathisia');
  });

  test('chronic orobuccal + worse on stress → TD', () {
    final r = rankMovementDisorder(<String>{
      'mvt_td_chronic', 'mvt_td_orobuccal', 'mvt_td_worse_on_stress',
    });
    expect(r.topId, 'td');
  });

  test('postural tremor + lithium → tremor', () {
    final r = rankMovementDisorder(<String>{
      'mvt_trm_postural', 'mvt_trm_lithium_valproate',
    });
    expect(r.topId, 'tremor');
  });

  test('clipboard summary includes management when top exists', () {
    final r = rankMovementDisorder(<String>{
      'mvt_pkn_tremor', 'mvt_pkn_rigidity',
    });
    expect(r.clipboardSummary(), contains('Likely diagnosis'));
  });
}
