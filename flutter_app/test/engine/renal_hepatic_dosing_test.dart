import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/renal_hepatic_dosing.dart';

void main() {
  test('renalHepaticById returns expected drugs', () {
    expect(renalHepaticById('lithium')?.drugName, 'Lithium');
    expect(renalHepaticById('gabapentin')?.drugName, 'Gabapentin');
    expect(renalHepaticById('imaginary'), isNull);
  });

  test('lithium: avoid in dialysis, no hepatic adjustment', () {
    final e = renalHepaticById('lithium')!;
    expect(e.renalFor(RenalBand.dialysis).toLowerCase(),
        contains('avoid'));
    expect(e.hepaticFor(HepaticBand.severe).toLowerCase(),
        contains('no hepatic adjustment'));
  });

  test('lorazepam is the preferred benzo in hepatic impairment', () {
    final e = renalHepaticById('lorazepam')!;
    expect(e.hepaticFor(HepaticBand.severe).toLowerCase(),
        contains('preferred'));
  });

  test('gabapentin needs renal reduction but no hepatic change', () {
    final e = renalHepaticById('gabapentin')!;
    expect(e.renalFor(RenalBand.severe).toLowerCase(),
        contains('reduce'));
    expect(e.hepaticFor(HepaticBand.mild).toLowerCase(),
        contains('no adjustment'));
  });

  test('valproate contraindicated in Child-Pugh C', () {
    final e = renalHepaticById('valproate')!;
    expect(e.hepaticFor(HepaticBand.severe).toLowerCase(),
        contains('contraindicated'));
  });

  test('every entry has non-empty guidance for every band', () {
    for (final e in kRenalHepaticTable) {
      for (final r in RenalBand.values) {
        expect(e.renalFor(r), isNotEmpty,
            reason: '${e.drugName} renal $r empty');
      }
      for (final h in HepaticBand.values) {
        expect(e.hepaticFor(h), isNotEmpty,
            reason: '${e.drugName} hepatic $h empty');
      }
    }
  });

  test('band labels expose eGFR / Child-Pugh ranges', () {
    expect(RenalBand.moderate.label, contains('30'));
    expect(HepaticBand.severe.label, contains('Child-Pugh C'));
  });
}
