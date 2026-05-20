// About screen — pumps the screen with a real engine load and asserts
// the redesigned (Clinical Light) hero, stat tiles, and section cards
// render.
//
// package_info_plus uses a platform channel that doesn't exist in
// flutter_test; we stub it via setMockMethodCallHandler.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/about_screen.dart';

Widget _harness() {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: Routes.about,
        path: '/',
        builder: (_, __) => const AboutScreen(),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

/// Pump until the engine FutureProvider resolves. The new About uses
/// "Clinical scope" (not the old uppercase eyebrow) as the section
/// title.
Future<void> _waitForEngine(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (tester.any(find.text('CLINICAL SCOPE'))) return;
  }
  fail('Engine provider never resolved');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'PsychSwitch',
          'packageName': 'health.psychswitch.app',
          'version': '0.1.0',
          'buildNumber': '1',
        };
      }
      return null;
    });
  });

  tearDown(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'About — hero, stat grid, and section cards render',
    (tester) async {
      await tester.pumpWidget(_harness());
      await _waitForEngine(tester);

      // Hero wordmark + tagline. Tagline is now concatenated with the
      // version string, so we search by prefix.
      expect(find.text('PsychSwitch'), findsWidgets);
      expect(
        find.textContaining('Reviewed cross-titration'),
        findsOneWidget,
      );

      // Stat tile eyebrows.
      expect(find.text('DRUGS'), findsOneWidget);
      expect(find.text('REVIEWED RULES'), findsOneWidget);
      expect(find.text('ERRATA LOGGED'), findsOneWidget);
      expect(find.text('BUILD'), findsOneWidget);

      // Section eyebrows on the cards.
      expect(find.text('CLINICAL SCOPE'), findsOneWidget);

      // Below-the-fold sections appear after scrolling.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('LICENSING'), findsOneWidget);
    },
  );
}
