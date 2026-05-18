import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/ect_workup.dart';

void main() {
  int totalItems() =>
      kEctGroups.fold(0, (a, g) => a + g.items.length);

  test('groups + items registered', () {
    expect(kEctGroups.length, 4);
    expect(totalItems(), greaterThanOrEqualTo(14));
  });

  test('empty → nothing satisfied, not complete', () {
    final r = evaluateEct(<String>{});
    expect(r.satisfied, 0);
    expect(r.isComplete, isFalse);
    expect(r.outstanding.length, r.totalItems);
    expect(r.fraction, 0);
  });

  test('all ticked → complete + READY summary', () {
    final all = <String>{
      for (final g in kEctGroups)
        for (final it in g.items) it.id,
    };
    final r = evaluateEct(all);
    expect(r.isComplete, isTrue);
    expect(r.satisfied, r.totalItems);
    expect(r.outstanding, isEmpty);
    expect(r.clipboardSummary(), contains('READY'));
  });

  test('partial → outstanding lists the missing labels', () {
    final r = evaluateEct(<String>{'indication', 'consent'});
    expect(r.satisfied, 2);
    expect(r.isComplete, isFalse);
    expect(r.outstanding, isNot(contains('Clear indication documented')));
    expect(r.clipboardSummary(), contains('Outstanding:'));
  });

  test('medication-review group includes the lithium trap', () {
    final med = kEctGroups
        .firstWhere((g) => g.title == 'Medication review');
    expect(med.items.any((i) => i.id == 'lithium'), isTrue);
  });
}
