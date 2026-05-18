import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/delirium_4at.dart';

void main() {
  test('four items registered with heterogeneous option scores', () {
    expect(kFourAtItems.length, 4);
    final alert = kFourAtItems.first;
    expect(alert.options.map((o) => o.score), containsAll(<int>[0, 4]));
  });

  test('all-zero → delirium unlikely (severity 0)', () {
    final r = scoreFourAt(<String, int>{
      'alertness': 0,
      'amt4': 0,
      'attention': 0,
      'acute_change': 0,
    });
    expect(r.total, 0);
    expect(r.severity, 0);
    expect(r.label, 'Delirium unlikely');
  });

  test('total 1-3 → possible cognitive impairment', () {
    final r = scoreFourAt(<String, int>{'amt4': 1, 'attention': 1});
    expect(r.total, 2);
    expect(r.severity, 1);
    expect(r.label, 'Possible cognitive impairment');
  });

  test('abnormal alertness alone (4) → possible delirium', () {
    final r = scoreFourAt(<String, int>{'alertness': 4});
    expect(r.total, 4);
    expect(r.severity, 2);
    expect(r.label, 'Possible delirium');
  });

  test('acute change (4) crosses the ≥4 threshold', () {
    final r = scoreFourAt(<String, int>{'acute_change': 4});
    expect(r.severity, 2);
  });

  test('missing answers treated as 0', () {
    expect(scoreFourAt(<String, int>{}).total, 0);
  });

  test('clipboard summary contains score + label', () {
    final r = scoreFourAt(<String, int>{'alertness': 4});
    expect(r.clipboardSummary(), contains('4 / 12'));
    expect(r.clipboardSummary(), contains('Possible delirium'));
  });
}
