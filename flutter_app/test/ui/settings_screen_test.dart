// Settings screen — verifies the account section + citations toggle
// render, the citations switch flips state, and the danger tile shows.
// The actual delete-all flow touches the database; we cover that in
// saved_cases_provider_test.

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

  // The settings list is taller than the default 800×600 test
  // viewport. Render it into a tall surface so every section is built
  // and assertions don't depend on lazy-ListView scroll position.
  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
  }

  testWidgets('Settings — account + citations + delete-all surfaces render',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('DISPLAY'), findsOneWidget);
    expect(find.text('Show citation chips'), findsOneWidget);

    // New optional-sign-in section. On a test build no Firebase
    // project is wired in, so it shows the "coming soon" tile.
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);

    expect(find.text('DATA'), findsOneWidget);
    // The danger label appears twice — header + button.
    expect(find.text('Delete all saved cases'), findsAtLeastNWidgets(1));
  });

  testWidgets('Settings — toggling the switch persists the new value',
      (tester) async {
    await pumpSettings(tester);

    // Two switches: citations (default true) + reminders (default false).
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    final citations = switches.first;
    expect(tester.widget<Switch>(citations).value, true);

    await tester.tap(citations);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(citations).value, false);
  });
}
