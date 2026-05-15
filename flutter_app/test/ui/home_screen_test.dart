// Widget test for HomeScreen — 2026-05-15 redesign.
//
// Pumps the screen inside a real ProviderScope (so the engine provider
// does its real load against the asset bundle), waits for the async
// engine to resolve, then asserts that the new clinical-light home:
//   • renders the greeting + hero
//   • shows the "Start a switch" black-pill CTA
//   • surfaces the drug-count / rules-count signal line
//   • navigates to /switch when the CTA is tapped

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

/// Pump until the engine FutureProvider resolves.
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
    'HomeScreen — hero renders and Start-a-switch CTA navigates to /switch',
    (tester) async {
      await tester.pumpWidget(_harness());
      // Initial frame: spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _waitForEngine(tester);

      // Greeting (Dr R appears in any time-of-day variant).
      expect(find.textContaining('Dr R'), findsOneWidget);
      // Hero copy.
      expect(find.text('Plan a safe cross-titration'), findsOneWidget);
      // Drug/rule signal line — verify the trailing source.
      expect(
        find.textContaining('Maudsley 15th ed.'),
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
