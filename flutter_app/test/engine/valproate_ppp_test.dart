import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/valproate_ppp.dart';

void main() {
  test('not of childbearing potential → not applicable', () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(childbearingPotential: false),
    );
    expect(r.verdict, ValproateVerdict.notApplicable);
  });

  test('pregnant → avoid', () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(pregnant: true),
    );
    expect(r.verdict, ValproateVerdict.avoid);
  });

  test('bipolar with alternatives available → avoid', () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(),
    );
    expect(r.verdict, ValproateVerdict.avoid);
    expect(r.headline, contains('Bipolar'));
  });

  test('childbearing, no alternative, PPP incomplete → conditional',
      () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(
        forBipolar: false,
        noEffectiveAlternative: true,
      ),
    );
    expect(r.verdict, ValproateVerdict.conditional);
    expect(r.outstanding, isNotEmpty);
  });

  test('all PPP conditions met → permitted', () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(
        forBipolar: false,
        noEffectiveAlternative: true,
        highlyEffectiveContraception: true,
        annualRiskAcknowledgement: true,
        specialistReview: true,
      ),
    );
    expect(r.verdict, ValproateVerdict.permitted);
    expect(r.outstanding, isEmpty);
  });

  test('risk-magnitude caution always present', () {
    final r = evaluateValproatePpp(const ValproatePppInput());
    expect(r.cautions.join(' '), contains('10%'));
  });

  test('clipboard summary reports verdict', () {
    final r = evaluateValproatePpp(
      const ValproatePppInput(
        forBipolar: false,
        noEffectiveAlternative: true,
      ),
    );
    final s = r.clipboardSummary();
    expect(s, contains('Valproate PPP'));
    expect(s, contains('Outstanding PPP requirements:'));
  });
}
