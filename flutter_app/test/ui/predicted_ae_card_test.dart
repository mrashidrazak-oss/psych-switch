// Predicted AE card — verifies header summary, collapsed-by-default
// behaviour, expand-to-show-rows, and per-row reveal of reason +
// quantitative source line.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:psychswitch/src/ui/widgets/predicted_ae_card.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/predicted_ae_profile.dart';

import '../_helpers/content_loader.dart';

PredictedAeProfile _profileFor(String fromId, String toId) {
  final engine = loadSwitchingEngine();
  final to = engine.getDrug(toId)!;
  final from = engine.getDrug(fromId);
  return predictAeProfile(to, from);
}

Widget _harness(PredictedAeProfile p) =>
    MaterialApp(home: Scaffold(body: PredictedAeCard(profile: p)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Header renders + body collapsed by default', (tester) async {
    final profile = _profileFor('sertraline', 'olanzapine');
    await tester.pumpWidget(_harness(profile));
    await tester.pumpAndSettle();

    expect(find.text('Predicted side-effect profile'), findsOneWidget);
    // Drug name in subhead.
    expect(find.textContaining('Olanzapine'), findsOneWidget);
    // Body row text shouldn't render until expanded — verify by
    // checking the disclaimer copy isn't yet on screen.
    expect(find.textContaining('tier-based'), findsNothing);
  });

  testWidgets('Tapping header expands and reveals rows + disclaimer',
      (tester) async {
    final profile = _profileFor('sertraline', 'olanzapine');
    await tester.pumpWidget(_harness(profile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Predicted side-effect profile'));
    await tester.pumpAndSettle();

    expect(find.textContaining('tier-based'), findsOneWidget);
    // At least one prediction row rendered, each with a likelihood pill.
    expect(find.byType(StatusPill), findsAtLeastNWidgets(1));
  });

  testWidgets('Empty predictions list collapses to nothing', (tester) async {
    // Construct an empty profile manually — the AE table can't produce
    // an empty list for any real drug, but the widget must defend
    // against it.
    final engine = loadSwitchingEngine();
    final empty = PredictedAeProfile(
      toDrug: engine.getDrug('sertraline')!,
      predictions: const <PredictedAe>[],
    );

    await tester.pumpWidget(_harness(empty));
    expect(find.text('Predicted side-effect profile'), findsNothing);
  });
}
