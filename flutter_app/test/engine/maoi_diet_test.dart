import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/maoi_diet.dart';

void main() {
  test('food table has all three risk tiers represented', () {
    final risks = kMaoiFoods.map((f) => f.risk).toSet();
    expect(risks, containsAll(TyramineRisk.values));
  });

  test('aged cheese is an avoid item', () {
    final cheese = kMaoiFoods.firstWhere(
      (f) => f.name.toLowerCase().contains('aged'),
    );
    expect(cheese.risk, TyramineRisk.avoid);
  });

  test('fresh meat is generally safe', () {
    final meat = kMaoiFoods.firstWhere(
      (f) => f.name.toLowerCase().contains('fresh meat'),
    );
    expect(meat.risk, TyramineRisk.safe);
  });

  test('empty query returns the full list', () {
    expect(searchFoods('').matches.length, kMaoiFoods.length);
  });

  test('search matches name or note, case-insensitive', () {
    final r = searchFoods('CHEESE');
    expect(r.matches, isNotEmpty);
    expect(
      r.matches.every((f) =>
          f.name.toLowerCase().contains('cheese') ||
          f.note.toLowerCase().contains('cheese')),
      isTrue,
    );
  });

  test('drug cautions + crisis script are non-empty', () {
    expect(kMaoiDrugCautions, isNotEmpty);
    expect(kHypertensiveCrisisManagement, contains('hypertensive'));
  });
}
