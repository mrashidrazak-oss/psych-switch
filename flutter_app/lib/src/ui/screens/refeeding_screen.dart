// Refeeding-syndrome risk (NICE) — tick criteria, see the tier +
// feeding / monitoring plan.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/refeeding.dart';

class RefeedingScreen extends StatefulWidget {
  const RefeedingScreen({super.key});

  @override
  State<RefeedingScreen> createState() => _RefeedingScreenState();
}

class _RefeedingScreenState extends State<RefeedingScreen> {
  final Set<String> _ticked = <String>{};

  void _toggle(String id) {
    setState(() {
      if (_ticked.contains(id)) {
        _ticked.remove(id);
      } else {
        _ticked.add(id);
      }
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_ticked.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateRefeeding(_ticked);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refeeding risk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_ticked.isNotEmpty)
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _Banner(result: r),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  const _GroupLabel('Major criteria — any one = high risk'),
                  for (final c in kRefeedMajor)
                    _Row(
                      label: c.label,
                      ticked: _ticked.contains(c.id),
                      onTap: () => _toggle(c.id),
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _GroupLabel('Minor criteria — any two = high risk'),
                  for (final c in kRefeedMinor)
                    _Row(
                      label: c.label,
                      ticked: _ticked.contains(c.id),
                      onTap: () => _toggle(c.id),
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _GroupLabel('Extreme risk modifiers (MARSIPAN)'),
                  for (final c in kRefeedExtreme)
                    _Row(
                      label: c.label,
                      ticked: _ticked.contains(c.id),
                      onTap: () => _toggle(c.id),
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  _PlanCard(result: r),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ClinicalSpace.xs,
        bottom: ClinicalSpace.sm,
      ),
      child: Text(text.toUpperCase(), style: ClinicalText.eyebrow),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.result});
  final RefeedResult result;

  ({Color tone, Color ink, String label}) _p() {
    switch (result.tier) {
      case RefeedTier.notHighRisk:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk,
          label: 'NOT HIGH RISK'
        );
      case RefeedTier.highRisk:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk,
          label: 'HIGH RISK'
        );
      case RefeedTier.extremeRisk:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk,
          label: 'EXTREME RISK'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p();
    return Container(
      width: double.infinity,
      color: p.tone,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.md + 2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.headline,
                  style: ClinicalText.caption.copyWith(
                    color: p.ink.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            ),
            child: Text(
              '${result.majorCount}M · ${result.minorCount}m',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.ink,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.ticked,
    required this.onTap,
  });

  final String label;
  final bool ticked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: ticked
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
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        ticked ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ticked
                          ? Colors.transparent
                          : ClinicalPalette.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  child: ticked
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: ClinicalPalette.cta)
                      : null,
                ),
                const SizedBox(width: ClinicalSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: ticked
                          ? ClinicalPalette.ctaText
                          : ClinicalPalette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});
  final RefeedResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Feeding & monitoring plan',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.management,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied')),
              );
            },
          ),
        ],
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
              'NICE CG32 + MARSIPAN. Do not delay feeding to fully '
              'correct electrolytes — replace as you feed. Manage '
              'extreme risk with medical / specialist ED support.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
