// DDI warnings card — verifies severity-sorted rendering of engine
// hits, eyebrow + per-hit chrome, and that an empty list collapses
// to nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:psychswitch/src/ui/widgets/ddi_warnings_card.dart';
import 'package:psychswitch_engine/ddi.dart';

Widget _harness(List<DdiHit> hits) =>
    MaterialApp(home: Scaffold(body: DdiWarningsCard(hits: hits)));

void main() {
  testWidgets('Empty hit list renders nothing', (tester) async {
    await tester.pumpWidget(_harness(const <DdiHit>[]));
    expect(find.text('OVERLAP-WINDOW INTERACTIONS'), findsNothing);
  });

  testWidgets('Single hit renders eyebrow, severity label, and message',
      (tester) async {
    final hits = checkPair('fluoxetine', 'risperidone');
    expect(hits, isNotEmpty,
        reason: 'engine should flag CYP2D6 inhibitor + substrate');

    await tester.pumpWidget(_harness(hits));
    await tester.pumpAndSettle();

    expect(find.text('OVERLAP-WINDOW INTERACTIONS'), findsOneWidget);
    // First hit (warning, cyp_inhibition).
    expect(
      find.textContaining('WARNING · CYP INHIBITION'),
      findsOneWidget,
    );
    // Body copy from the engine pattern.
    expect(
      find.textContaining('substrate level may double'),
      findsOneWidget,
    );
    // Mitigation surfaces (RichText so opt into findRichText).
    expect(
      find.textContaining('Mitigation:', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Multiple hits sort most-severe first', (tester) async {
    // Two SSRIs → caution (serotonergic).
    // SSRI + MAOI → avoid (serotonergic).
    // We synthesise the AVOID + WARNING pair manually so we can
    // verify ordering without needing a real triple.
    final hits = <DdiHit>[
      const DdiHit(
        pair: <String>['x', 'y'],
        severity: DdiSeverity.caution,
        mechanism: DdiMechanism.sedationAdditive,
        message: 'caution-message',
      ),
      const DdiHit(
        pair: <String>['x', 'y'],
        severity: DdiSeverity.avoid,
        mechanism: DdiMechanism.serotonergic,
        message: 'avoid-message',
      ),
    ];

    await tester.pumpWidget(_harness(hits));
    await tester.pumpAndSettle();

    // Both messages render.
    expect(find.text('avoid-message'), findsOneWidget);
    expect(find.text('caution-message'), findsOneWidget);

    // AVOID appears physically above CAUTION.
    final avoidY =
        tester.getTopLeft(find.text('avoid-message')).dy;
    final cautionY =
        tester.getTopLeft(find.text('caution-message')).dy;
    expect(avoidY, lessThan(cautionY));
  });
}
