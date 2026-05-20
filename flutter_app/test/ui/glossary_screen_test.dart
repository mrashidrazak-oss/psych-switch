// Glossary screen — verifies the search box filters the list and the
// clear button restores it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/glossary_screen.dart';

Widget _harness() {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: Routes.glossary,
        path: '/',
        builder: (_, __) => const GlossaryScreen(),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Glossary — header + at least one term render', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('Glossary'), findsOneWidget);
    expect(find.textContaining('terms'), findsOneWidget);
  });

  testWidgets('Glossary — typing a query filters the list, X clears it',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Pre-filter count (e.g. "47 terms").
    final unfiltered =
        tester.widget<Text>(find.textContaining('terms')).data ?? '';
    expect(unfiltered, isNotEmpty);

    // Type a query that should narrow the list.
    await tester.enterText(find.byType(TextField), 'qtc');
    await tester.pumpAndSettle();

    // Counter line now reads "N of M matches".
    expect(find.textContaining('match'), findsOneWidget);

    // Clear button appears when there's a query.
    final clearBtn = find.byIcon(Icons.close_rounded);
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // After clear, count line goes back to "N terms".
    expect(find.textContaining('terms'), findsOneWidget);
  });
}
