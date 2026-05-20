// Wernicke's / thiamine — pick the scenario, see the route + dose +
// the glucose-before-thiamine / magnesium-cofactor key points.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/thiamine_wernicke.dart';

class ThiamineScreen extends StatefulWidget {
  const ThiamineScreen({super.key});

  @override
  State<ThiamineScreen> createState() => _ThiamineScreenState();
}

class _ThiamineScreenState extends State<ThiamineScreen> {
  ThiamineScenario _scenario =
      ThiamineScenario.prophylaxisHighRisk;

  void _pick(ThiamineScenario s) {
    setState(() => _scenario = s);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final plan = buildThiaminePlan(_scenario);
    final wernicke =
        _scenario == ThiamineScenario.suspectedWernicke;
    final tone = wernicke
        ? ClinicalPalette.toneRose
        : ClinicalPalette.toneSand;
    final ink = wernicke
        ? ClinicalPalette.toneRoseInk
        : ClinicalPalette.toneSandInk;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wernicke / thiamine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xxl,
          ),
          children: <Widget>[
            const _Hero(),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('SCENARIO', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            for (final s in ThiamineScenario.values) ...<Widget>[
              _ScenarioRow(
                label: s.label,
                selected: _scenario == s,
                onTap: () => _pick(s),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: ClinicalSpace.md),
            SquircleCard(
              tone: tone,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TonePill(
                    label: 'Regimen',
                    tone: const Color(0xFFFFFFFF),
                    ink: ink,
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  Text(
                    plan.headline,
                    style: ClinicalText.subtitle.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  Text(
                    plan.regimen,
                    style: ClinicalText.body.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  TonePill(
                    label: 'Key points',
                    tone: const Color(0xFFFFFFFF),
                    ink: ink,
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final k in plan.keyPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.priority_high,
                                size: 14, color: ink),
                          ),
                          const SizedBox(width: ClinicalSpace.sm + 2),
                          Expanded(
                            child: Text(
                              k,
                              style: ClinicalText.body.copyWith(
                                color: ink,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  PillButton(
                    label: 'Copy plan',
                    icon: Icons.copy_rounded,
                    expanded: true,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: plan.clipboardSummary()),
                      );
                      unawaited(hapticsConfirm());
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plan copied')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'The oral-thiamine trap',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Right route, before the glucose',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneLavenderInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Oral thiamine is inadequately absorbed in active / '
            'malnourished drinkers, and glucose before thiamine can '
            "precipitate Wernicke's. Maudsley 15e / NICE CG100 / RCP.",
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneLavenderInk
                  .withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.md),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected
                    ? ClinicalPalette.ctaText
                    : ClinicalPalette.mutedStrong,
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.shield_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              'Use your local parenteral B-vitamin product + dosing. '
              'When in doubt in an at-risk drinker, treat — '
              'under-treatment risks irreversible Korsakoff syndrome.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
