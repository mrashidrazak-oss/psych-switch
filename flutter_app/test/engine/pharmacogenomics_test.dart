// Tests for the pharmacogenomics quick reference.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/pharmacogenomics.dart';

void main() {
  test('pgxDrugs is de-duplicated + name-sorted', () {
    final drugs = pgxDrugs();
    final ids = drugs.map((d) => d.id).toList();
    expect(ids.toSet().length, ids.length);
    final names = drugs.map((d) => d.name).toList();
    final sorted = [...names]..sort();
    expect(names, sorted);
  });

  test('escitalopram has a CYP2C19 entry', () {
    final entries = pgxEntriesFor('escitalopram');
    expect(entries, isNotEmpty);
    expect(entries.first.gene, CypGene.cyp2c19);
  });

  test('paroxetine has a CYP2D6 entry', () {
    final entries = pgxEntriesFor('paroxetine');
    expect(entries.any((e) => e.gene == CypGene.cyp2d6), isTrue);
  });

  test('forPhenotype returns distinct text per phenotype', () {
    final e = pgxEntriesFor('amitriptyline').first;
    expect(e.forPhenotype(Metaboliser.poor),
        isNot(equals(e.forPhenotype(Metaboliser.normal))));
    expect(e.forPhenotype(Metaboliser.rapid),
        equals(e.forPhenotype(Metaboliser.ultrarapid)));
  });

  test('every entry has non-empty recommendations for all phenotypes',
      () {
    for (final e in kPgxTable) {
      for (final m in Metaboliser.values) {
        expect(e.forPhenotype(m), isNotEmpty,
            reason: '${e.drugName}/${e.gene.label}/$m empty');
      }
    }
  });

  test('unknown drug returns empty entry list', () {
    expect(pgxEntriesFor('imaginary'), isEmpty);
  });
}
