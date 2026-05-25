// Widget test for ResultScreen.
//
// Exercises four plan branches against the real engine + asset bundle.
// All four are pumped within a single `testWidgets` because flutter_test's
// rootBundle + Riverpod FutureProvider don't tear down cleanly between
// widget-test calls (same constraint that home_screen_test.dart hit).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch_engine/switching_engine.dart';

GoRouter _routerFor(SwitchInput input) => GoRouter(
      routes: <RouteBase>[
        GoRoute(
          name: Routes.result,
          path: '/',
          builder: (_, __) => ResultScreen(args: ResultScreenArgs(input: input)),
        ),
      ],
    );

Widget _harness(SwitchInput input) => ProviderScope(
      child: MaterialApp.router(routerConfig: _routerFor(input)),
    );

/// Pump until the engine FutureProvider resolves.
Future<void> _waitForReady(
  WidgetTester tester,
  Finder readySignal,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (tester.any(readySignal)) return;
  }
  fail('Engine provider never resolved');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Result screen branches: ok / maoi / clozapine / no_rule',
    (tester) async {
      // ── 1. Reviewed (ok) — sertraline → escitalopram ──────────────
      await tester.pumpWidget(
        _harness(
          const SwitchInput(
            fromDrugId: 'sertraline',
            fromDoseMg: 100,
            toDrugId: 'escitalopram',
            toDoseMg: 10,
          ),
        ),
      );
      await _waitForReady(tester, find.text('Reviewed schedule'));
      // "FROM" / "TO" appear in both the hero drug-pair band AND the
      // schedule-table header now (post-redesign). Test that at least
      // one exists for each — the hero label is what we're verifying.
      expect(find.text('FROM'), findsWidgets);
      expect(find.text('TO'), findsWidgets);
      // Schedule + citations live below the fold on a 800x600 viewport
      // because the predicted-AE card sits between the hero and the
      // table — drag both into view.
      await tester.dragUntilVisible(
        find.text('SCHEDULE'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('SCHEDULE'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('CITATIONS'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('CITATIONS'), findsOneWidget);

      // ── 2. MAOI washout — sertraline → moclobemide ────────────────
      await tester.pumpWidget(
        _harness(
          const SwitchInput(
            fromDrugId: 'sertraline',
            fromDoseMg: 100,
            toDrugId: 'moclobemide',
            toDoseMg: 300,
          ),
        ),
      );
      await _waitForReady(tester, find.text('MAOI washout required'));
      expect(find.text('MAOI WASHOUT'), findsOneWidget);
      expect(
        find.textContaining('14-day washout required'),
        findsOneWidget,
      );

      // ── 3. Clozapine redirect — olanzapine → clozapine ────────────
      await tester.pumpWidget(
        _harness(
          const SwitchInput(
            fromDrugId: 'olanzapine',
            fromDoseMg: 20,
            toDrugId: 'clozapine',
            toDoseMg: 300,
          ),
        ),
      );
      // Clozapine is now a curated launch tool — the redirect card
      // surfaces the "Open Clozapine module" CTA so the clinician can
      // jump straight to the titration / FBC / ANC tabs. The title
      // changes from 'Clozapine initiation' (dark-shipped variant) to
      // 'Use Clozapine module' (CTA variant).
      await _waitForReady(tester, find.text('Use Clozapine module'));
      expect(find.text('CLOZAPINE INITIATION'), findsOneWidget);
      expect(find.text('Open Clozapine module'), findsOneWidget);

      // ── 4. no_rule — unregistered drug id ─────────────────────────
      await tester.pumpWidget(
        _harness(
          const SwitchInput(
            fromDrugId: 'not-a-real-drug',
            fromDoseMg: 10,
            toDrugId: 'sertraline',
            toDoseMg: 100,
          ),
        ),
      );
      await _waitForReady(tester, find.text('No reviewed rule'));
      expect(find.text('NO REVIEWED RULE'), findsOneWidget);
    },
  );
}
