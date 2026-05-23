// Disclaimer first-launch gate — verifies:
//   • The brand hero, headline, all three bullets, and CTA render.
//   • Tapping the CTA flips the persisted ack flag (prefs key
//     `psychswitch.disclaimer.ack.v1`) and the provider's value.
//   • A second `build()` call sees the persisted true.
//
// Engine isn't loaded here — the gate sits above the router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/providers/disclaimer_provider.dart';
import 'package:psychswitch/src/ui/screens/disclaimer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness() => const ProviderScope(
      child: MaterialApp(home: DisclaimerScreen()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Disclaimer — hero, headline, bullets, and CTA render',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('PsychSwitch'), findsOneWidget);
    // Tagline switched from all-caps eyebrow to sentence case when
    // the disclaimer hero adopted the home screen's brand mark.
    expect(find.text('Reviewed cross-titration'), findsOneWidget);

    expect(find.text('Decision support,'), findsOneWidget);
    expect(find.text('not medical advice.'), findsOneWidget);

    // Three bullet titles.
    expect(find.text('Grounded in primary sources'), findsOneWidget);
    expect(
      find.text('Not a substitute for clinical judgement'),
      findsOneWidget,
    );
    expect(find.text('Cross-check primary sources'), findsOneWidget);

    // CTA.
    expect(
      find.text('I am a healthcare professional'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping the CTA persists the ack and flips the provider',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DisclaimerScreen)),
    );
    // Force-resolve the provider's first build so we can compare
    // against a real value rather than the AsyncLoading sentinel.
    expect(await container.read(disclaimerAcknowledgedProvider.future), false);

    await tester.tap(find.text('I am a healthcare professional'));
    await tester.pumpAndSettle();

    // Now in data(true).
    expect(
      container.read(disclaimerAcknowledgedProvider).valueOrNull,
      true,
    );

    // And the persistence key actually flipped — survives a rebuild.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('psychswitch.disclaimer.ack.v1'), true);
  });
}
