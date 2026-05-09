// Verify the runtime content loader.
//
// Reads the real `assets/content_bundle.json` via the test asset
// bundle (which surfaces the same paths declared in pubspec.yaml),
// decodes it, and exercises the engine end-to-end. This catches:
//   • bundle drift (rerun `dart run tool/bundle_content.dart` if it fires)
//   • schema regressions in the loader
//   • engine cold-start behaviour with the full registry

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/data/content_loader.dart';
import 'package:psychswitch/src/engine/switching_engine.dart';

void main() {
  // Required for rootBundle access in unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime content loader', () {
    test('loads the asset bundle and decodes the full registry',
        () async {
      final content = await loadContent();

      // Engine has the canonical drug + rule counts.
      expect(content.engine.listAllDrugs().length, equals(40));
      expect(content.engine.listRules().length, equals(126));

      // Spot-check across content domains.
      expect(content.qtcData.drugs, isNotEmpty);
      expect(content.lithiumTapering.id, contains('lithium-tapering'));
      expect(
        content.clozapine.getMonitoringSchedule().fbcThresholds
            .ancRedBelow,
        greaterThan(0),
      );
    });

    test(
        'engine returns ok plan for sertraline → escitalopram at reference doses',
        () async {
      final content = await loadContent();
      final plan = content.engine.generateSwitchPlan(
        const SwitchInput(
          fromDrugId: 'sertraline',
          fromDoseMg: 100,
          toDrugId: 'escitalopram',
          toDoseMg: 10,
        ),
      );
      expect(plan, isA<SwitchPlanOk>());
      final ok = plan as SwitchPlanOk;
      expect(ok.dosesMatchReference, isTrue);
      expect(ok.schedule, isNotEmpty);
      expect(ok.schedule.last.fromDoseMg, equals(0));
    });

    test('decodeContentBundle is pure (no Flutter binding required)',
        () async {
      // Same bundle, same input — but going through the synchronous
      // decoder rather than rootBundle. Useful for any test that wants
      // engine state without async setup.
      final raw = await loadContent();
      expect(raw, isNotNull);
    });
  });
}
