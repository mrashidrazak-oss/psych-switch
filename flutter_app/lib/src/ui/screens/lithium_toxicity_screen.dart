// Lithium toxicity — enter level + tick clinical features, see the
// graded tier, staged management, and the dialysis verdict.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/lithium_toxicity.dart';

class LithiumToxicityScreen extends StatefulWidget {
  const LithiumToxicityScreen({super.key});

  @override
  State<LithiumToxicityScreen> createState() =>
      _LithiumToxicityScreenState();
}

class _LithiumToxicityScreenState
    extends State<LithiumToxicityScreen> {
  final _ctrl = TextEditingController();
  final Set<String> _features = <String>{};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _level {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v < 0) return null;
    return v;
  }

  void _toggle(String id) {
    setState(() {
      if (_features.contains(id)) {
        _features.remove(id);
      } else {
        _features.add(id);
      }
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(() {
      _ctrl.clear();
      _features.clear();
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateLithiumToxicity(
      level: _level,
      features: _features,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lithium toxicity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_features.isNotEmpty || _ctrl.text.isNotEmpty)
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
                  SquircleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('SERUM LITHIUM',
                            style: ClinicalText.eyebrow),
                        const SizedBox(height: ClinicalSpace.sm),
                        TextField(
                          controller: _ctrl,
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'e.g. 2.8',
                            suffixText: 'mmol/L',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: ClinicalSpace.sm),
                        Text(
                          'Toxicity is graded by the WORSE of level '
                          'and clinical features — chronic toxicity '
                          'can occur at a "therapeutic" level.',
                          style: ClinicalText.caption
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('CLINICAL FEATURES',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final f in kLithiumFeatures) ...<Widget>[
                    _FeatureRow(
                      feature: f,
                      ticked: _features.contains(f.id),
                      onTap: () => _toggle(f.id),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  _ManagementCard(result: r),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.result});
  final LithiumToxResult result;

  ({Color tone, Color ink}) _p() {
    switch (result.tier) {
      case LithiumToxTier.none:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case LithiumToxTier.mild:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case LithiumToxTier.moderate:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case LithiumToxTier.severe:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk
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
                  result.tier.label,
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
          if (result.dialysisIndicated)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: Text(
                'DIALYSE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.ticked,
    required this.onTap,
  });

  final LithiumFeature feature;
  final bool ticked;
  final VoidCallback onTap;

  Color get _tierColor => switch (feature.tier) {
        'severe' => ClinicalPalette.toneRoseInk,
        'moderate' => ClinicalPalette.tonePeachInk,
        _ => ClinicalPalette.toneSandInk,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
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
                  color: ticked ? Colors.white : Colors.transparent,
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
                  feature.label,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ticked
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Text(
                  feature.tier,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: ticked
                        ? ClinicalPalette.ctaText
                        : _tierColor,
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

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.result});
  final LithiumToxResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Management',
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
          const SizedBox(height: ClinicalSpace.md),
          const TonePill(
            label: 'Haemodialysis',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            result.dialysisIndicated
                ? 'Indicated — ${result.dialysisRationale}'
                : result.dialysisRationale,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w700,
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
              showCopiedToast(context, label: 'Summary');
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
              'Maudsley 15e / EXTRIP (Decker 2015). Discuss every '
              'moderate–severe case with toxicology / renal — '
              'dialysis decisions are individualised to clearance '
              'and trend.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
