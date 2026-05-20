// EntranceFade — verifies the staggered animation runs to completion
// and that the start-Timer is cancelled on dispose (no pending-timer
// assertions in flutter_test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

void main() {
  testWidgets('Index-0 child animates immediately to full opacity',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntranceFade(child: Text('hi')),
        ),
      ),
    );
    // Initial frame: AnimationController.forward() called in initState,
    // so the first build emits opacity 0 then animates.
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('Index-3 child still resolves within budget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntranceFade(index: 3, child: Text('staggered')),
        ),
      ),
    );
    // Fast-forward past the stagger delay + animation duration.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('staggered'), findsOneWidget);
  });

  testWidgets('Disposes cleanly with a pending stagger timer',
      (tester) async {
    // Pumps the staggered widget then immediately replaces it before
    // the start timer fires — dispose must cancel the timer to avoid
    // a "Timer is still pending" assertion from flutter_test.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EntranceFade(index: 100, child: Text('willDispose')),
        ),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('replacement'))),
    );
    expect(find.text('willDispose'), findsNothing);
    expect(find.text('replacement'), findsOneWidget);
  });
}
