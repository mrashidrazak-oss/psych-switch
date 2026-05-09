// Verify the Riverpod engine providers resolve against the real
// asset bundle and produce a working SwitchingEngine.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/switching_engine.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('engine providers', () {
    test('loadedContentProvider resolves to a fully-loaded LoadedContent',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final content = await container.read(loadedContentProvider.future);
      expect(content.engine.listAllDrugs().length, equals(40));
      expect(content.engine.listRules().length, equals(126));
      expect(content.qtcData.drugs, isNotEmpty);
    });

    test('engineProvider is a SwitchingEngine you can call', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = await container.read(engineProvider.future);
      expect(engine, isA<SwitchingEngine>());
      final plan = engine.generateSwitchPlan(
        const SwitchInput(
          fromDrugId: 'olanzapine',
          fromDoseMg: 20,
          toDrugId: 'aripiprazole',
          toDoseMg: 15,
        ),
      );
      expect(plan, isA<SwitchPlanOk>());
    });

    test('two reads share a cached engine instance', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = await container.read(engineProvider.future);
      final b = await container.read(engineProvider.future);
      expect(identical(a, b), isTrue);
    });
  });
}
