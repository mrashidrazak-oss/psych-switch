// Widget test for SwitchScreen.
//
// Verifies the four-step flow: pick from-drug, enter dose, pick
// to-drug, enter dose, tap Generate plan, land on /result with the
// SwitchInput intact in the route's extra payload.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/screens/switch_screen.dart';

GoRouter _testRouter() {
  ResultScreenArgs? captured;
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: Routes.switch_,
        path: '/',
        builder: (_, __) => const SwitchScreen(),
      ),
      GoRoute(
        name: Routes.result,
        path: '/result',
        builder: (_, state) {
          captured = state.extra as ResultScreenArgs?;
          final input = captured!.input;
          return Scaffold(
            body: Text(
              'result-stub: ${input.fromDrugId} ${input.fromDoseMg} '
              '→ ${input.toDrugId} ${input.toDoseMg}',
            ),
          );
        },
      ),
    ],
  );
}

Widget _harness() => ProviderScope(
      child: MaterialApp.router(routerConfig: _testRouter()),
    );

Future<void> _waitForEngine(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (tester.any(find.text('Generate plan'))) return;
  }
  fail('Engine provider never resolved (Generate-plan button missing)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Switch wizard: pick drugs, enter doses, navigate to result',
      (tester) async {
    await tester.pumpWidget(_harness());
    await _waitForEngine(tester);

    // Both pickers + Generate-plan button are present.
    expect(find.text('FROM DRUG'), findsOneWidget);
    expect(find.text('TO DRUG'), findsOneWidget);
    final generate = find.text('Generate plan');
    expect(generate, findsOneWidget);

    // Open the from-drug picker.
    await tester.tap(find.text('Pick a drug').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The bottom sheet shows a search field. Search for sertraline so
    // it's at the top of the visible list (the registry has 30+ drugs
    // and the sheet doesn't render past the viewport).
    expect(find.text('Search drugs'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'sertraline');
    await tester.pump();
    await tester.tap(find.text('Sertraline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // From-drug should now be set; dose field appears.
    expect(find.text('Sertraline dose (mg)'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Sertraline dose (mg)'),
      '100',
    );
    await tester.pump();

    // Open to-drug picker.
    await tester.tap(find.text('Pick a drug'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField).last, 'escitalopram');
    await tester.pump();
    await tester.tap(find.text('Escitalopram'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Escitalopram dose (mg)'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Escitalopram dose (mg)'),
      '10',
    );
    await tester.pump();

    // Generate plan should now be enabled — tap and assert navigation.
    await tester.tap(find.text('Generate plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining('result-stub: sertraline 100.0 → escitalopram 10.0'),
      findsOneWidget,
    );
  });
}
