// Tests for emergency rapid screeners (NMS + serotonin syndrome).

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/emergency_screens.dart';

void main() {
  group('NMS Levenson criteria', () {
    test('no exposure → unlikely regardless of features', () {
      final r = evaluateNms(
        ticked: <String>{'nms_maj_fever', 'nms_maj_rigidity'},
        antipsychoticExposure: false,
      );
      expect(r.tier, NmsTier.unlikely);
    });

    test('3 major + exposure → definite', () {
      final r = evaluateNms(
        ticked: <String>{
          'nms_maj_fever', 'nms_maj_rigidity', 'nms_maj_ck',
        },
        antipsychoticExposure: true,
      );
      expect(r.tier, NmsTier.definite);
    });

    test('2 major + 4 minor + exposure → definite', () {
      final r = evaluateNms(
        ticked: <String>{
          'nms_maj_fever', 'nms_maj_rigidity',
          'nms_min_tachy', 'nms_min_bp', 'nms_min_consciousness',
          'nms_min_diaphoresis',
        },
        antipsychoticExposure: true,
      );
      expect(r.tier, NmsTier.definite);
    });

    test('2 major (only) + exposure → probable', () {
      final r = evaluateNms(
        ticked: <String>{'nms_maj_fever', 'nms_maj_ck'},
        antipsychoticExposure: true,
      );
      expect(r.tier, NmsTier.probable);
    });

    test('1 major + 2 minor + exposure → possible', () {
      final r = evaluateNms(
        ticked: <String>{
          'nms_maj_fever', 'nms_min_tachy', 'nms_min_diaphoresis',
        },
        antipsychoticExposure: true,
      );
      expect(r.tier, NmsTier.possible);
    });

    test('no major, no minor, exposure → unlikely', () {
      final r = evaluateNms(
        ticked: <String>{},
        antipsychoticExposure: true,
      );
      expect(r.tier, NmsTier.unlikely);
    });

    test('clipboard summary always contains tier + tally', () {
      final r = evaluateNms(
        ticked: <String>{'nms_maj_fever'},
        antipsychoticExposure: true,
      );
      final s = r.clipboardSummary();
      expect(s, contains('POSSIBLE'));
      expect(s, contains('1 of 3 major'));
    });
  });

  group('Serotonin syndrome — Hunter criteria', () {
    SerotoninFeatures feat({
      bool agent = false,
      bool spontaneousClonus = false,
      bool inducibleClonus = false,
      bool ocularClonus = false,
      bool agitation = false,
      bool diaphoresis = false,
      bool tremor = false,
      bool hyperreflexia = false,
      bool hypertonia = false,
      bool feverAbove38 = false,
    }) {
      return SerotoninFeatures(
        serotonergicAgent: agent,
        spontaneousClonus: spontaneousClonus,
        inducibleClonus: inducibleClonus,
        ocularClonus: ocularClonus,
        agitation: agitation,
        diaphoresis: diaphoresis,
        tremor: tremor,
        hyperreflexia: hyperreflexia,
        hypertonia: hypertonia,
        feverAbove38: feverAbove38,
      );
    }

    test('no agent → not met regardless of features', () {
      final r = evaluateSerotonin(
        feat(spontaneousClonus: true, agitation: true),
      );
      expect(r.met, isFalse);
    });

    test('agent + spontaneous clonus → met', () {
      final r = evaluateSerotonin(
        feat(agent: true, spontaneousClonus: true),
      );
      expect(r.met, isTrue);
      expect(r.path, 'spontaneous clonus');
    });

    test('inducible clonus alone (no agitation/diaphoresis) → not met', () {
      final r = evaluateSerotonin(
        feat(agent: true, inducibleClonus: true),
      );
      expect(r.met, isFalse);
    });

    test('inducible clonus + diaphoresis → met', () {
      final r = evaluateSerotonin(
        feat(agent: true, inducibleClonus: true, diaphoresis: true),
      );
      expect(r.met, isTrue);
    });

    test('tremor alone → not met; tremor + hyperreflexia → met', () {
      expect(evaluateSerotonin(feat(agent: true, tremor: true)).met,
          isFalse);
      expect(
          evaluateSerotonin(feat(agent: true, tremor: true, hyperreflexia: true)).met,
          isTrue);
    });

    test('hypertonia + fever > 38 + ocular clonus → met (severe)', () {
      final r = evaluateSerotonin(feat(
        agent: true,
        hypertonia: true,
        feverAbove38: true,
        ocularClonus: true,
      ));
      expect(r.met, isTrue);
      expect(r.path, contains('hypertonia'));
    });
  });
}
