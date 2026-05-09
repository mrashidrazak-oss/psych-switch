// Widget test for HomeScreen.
//
// Pumps the screen inside a real ProviderScope (so the engine
// provider does its real load against the asset bundle), waits for
// the async engine to resolve, then asserts that:
//   • the wordmark + ready-badge render
//   • the Start-a-switch button is tappable
//   • the tap navigates to /switch
//
// Both behaviours are checked in a single pumpWidget cycle. Splitting
// them across two `testWidgets` calls reliably wedges the second one
// — flutter_test's rootBundle + Riverpod FutureProvider don't tear
// down cleanly between widget-test calls in the same file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/home_screen.dart';

Widget _harness({GoRouter? router}) {
  final r = router ??
      GoRouter(
        routes: <RouteBase>[
          GoRoute(
            name: Routes.home,
            path: '/',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            name: Routes.switch_,
            path: '/switch',
            builder: (_, __) => const Scaffold(body: Text('switch-stub')),
          ),
        ],
      );
  return ProviderScope(
    child: MaterialApp.router(routerConfig: r),
  );
}

/// Pump until the engine FutureProvider resolves. We alternate
/// `runAsync` (lets real timers fire so the rootBundle future
/// completes) with `pump` (drives the widget rebuild). Generous
/// budget so a slow CI runner still has headroom.
Future<void> _waitForEngine(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (tester.any(find.text('Start a switch'))) return;
  }
  fail('Engine provider never resolved');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HomeScreen — wordmark + ready badge render and CTA navigates to /switch',
    (tester) async {
      await tester.pumpWidget(_harness());
      // Initial frame: spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _waitForEngine(tester);

      // Wordmark — appears in the body and in the MaterialApp title.
      expect(find.text('PsychSwitch'), findsWidgets);
      // Tagline.
      expect(
        find.textContaining('Reviewed cross-titration'),
        findsOneWidget,
      );
      // Ready-badge wording: "<drugs> drugs · <rules> reviewed switching rules".
      expect(
        find.textContaining('reviewed switching rules'),
        findsOneWidget,
      );
      // Primary CTA.
      expect(find.text('Start a switch'), findsOneWidget);

      // Tap navigates to /switch (stub).
      await tester.tap(find.text('Start a switch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('switch-stub'), findsOneWidget);
    },
  );
}
