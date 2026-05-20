// Widget test for the shared clinical-poster ToolHero header used by
// the curated launch-tool screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';

void main() {
  testWidgets('ToolHero renders icon, title, tagline, stats, rationale',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ToolHero(
            icon: Icons.balance_outlined,
            title: 'Dose equivalency',
            tagline: 'Cross-class dose conversion',
            tone: ClinicalPalette.accent,
            stats: <ToolHeroStat>[
              ToolHeroStat(
                label: 'FAMILIES',
                value: '3',
                unit: 'classes',
              ),
              ToolHeroStat(
                label: 'CATALOGUE',
                value: '42',
                unit: 'drugs',
              ),
            ],
            rationale: 'Convert a dose within a drug family.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.balance_outlined), findsOneWidget);
    expect(find.text('Dose equivalency'), findsOneWidget);
    expect(find.text('Cross-class dose conversion'), findsOneWidget);
    expect(find.text('FAMILIES'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('CATALOGUE'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.textContaining('Convert a dose'), findsOneWidget);
  });

  testWidgets('ToolHero supports a single stat cell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ToolHero(
            icon: Icons.biotech_outlined,
            title: 'TDM',
            tagline: 'Therapeutic drug monitoring',
            tone: ClinicalPalette.warning,
            stats: <ToolHeroStat>[
              ToolHeroStat(label: 'ASSAYS', value: '9', unit: 'drugs'),
            ],
            rationale: 'Interpret a serum level against its window.',
          ),
        ),
      ),
    );

    expect(find.text('TDM'), findsOneWidget);
    expect(find.text('ASSAYS'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });
}
