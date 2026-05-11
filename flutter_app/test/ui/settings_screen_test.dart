// Settings screen — verifies the citations toggle is present + flips
// state, and the danger tile renders. The actual delete-all flow
// touches the database; we cover that in saved_cases_provider_test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness() {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: Routes.settings,
        path: '/',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Stub shared_preferences with empty defaults — the Settings
    // screen falls back to the default (true) for showCitations.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Settings — citations toggle + delete-all surfaces render',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('DISPLAY'), findsOneWidget);
    expect(find.text('Show citation chips'), findsOneWidget);
    // DATA section now sits below the new WELCOME (replay-tour)
    // section which pushes it past the 800×600 test viewport — scroll
    // to bring it on screen.
    await tester.dragUntilVisible(
      find.text('DATA'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('DATA'), findsOneWidget);
    // The danger label appears twice — header + button.
    expect(find.text('Delete all saved cases'), findsAtLeastNWidgets(1));
  });

  testWidgets('Settings — toggling the switch persists the new value',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Two switches now: citations (default true) + reminders (default false).
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    final citations = switches.first;
    expect(tester.widget<Switch>(citations).value, true);

    await tester.tap(citations);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(citations).value, false);
  });
}
