// Hyperthermic-emergency differentiator — tick features, see the
// leading toxidrome + the distinguishing pearl + management.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/hyperthermic_dx.dart';

class HyperthermicDxScreen extends StatefulWidget {
  const HyperthermicDxScreen({super.key});

  @override
  State<HyperthermicDxScreen> createState() =>
      _HyperthermicDxScreenState();
}

class _HyperthermicDxScreenState extends State<HyperthermicDxScreen> {
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
    final result = rankHyperthermic(_ticked);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperthermic Dx'),
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
            _Banner(result: result),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  const Text(
                    'Tick the features present. The leading toxidrome '
                    'surfaces with its distinguishing pearl + '
                    'management.',
                    style: ClinicalText.body,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  for (final f in kHyperthermicFeatures) ...<Widget>[
                    _FeatureRow(
                      feature: f,
                      ticked: _ticked.contains(f.id),
                      onTap: () => _toggle(f.id),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  if (result.top != null) ...<Widget>[
                    _LeadingCard(result: result),
                    const SizedBox(height: ClinicalSpace.md),
                  ],
                  _RankingsCard(rankings: result.rankings),
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
  final HyperthermicResult result;

  @override
  Widget build(BuildContext context) {
    final t = result.top;
    final tone = t == null
        ? ClinicalPalette.surfaceMuted
        : ClinicalPalette.toneRose;
    final ink = t == null
        ? ClinicalPalette.mutedStrong
        : ClinicalPalette.toneRoseInk;
    return Container(
      width: double.infinity,
      color: tone,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.md + 2,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            t == null
                ? Icons.help_outline
                : Icons.priority_high_rounded,
            color: ink,
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('LEADING DIFFERENTIAL',
                    style: ClinicalText.eyebrow),
                const SizedBox(height: 2),
                Text(
                  t?.name ?? 'Tick features to differentiate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
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

  final HyperthermicFeature feature;
  final bool ticked;
  final VoidCallback onTap;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 1),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      feature.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ticked
                            ? ClinicalPalette.ctaText
                            : ClinicalPalette.text,
                      ),
                    ),
                    if (feature.subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: ticked
                              ? ClinicalPalette.ctaText
                                  .withValues(alpha: 0.85)
                              : ClinicalPalette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingCard extends StatelessWidget {
  const _LeadingCard({required this.result});
  final HyperthermicResult result;

  @override
  Widget build(BuildContext context) {
    final t = result.top!;
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Distinguishing pearl',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            t.discriminator,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w700,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
          const TonePill(
            label: 'Management',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            t.management,
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
              showCopiedToast(context, label: 'Summary');
            },
          ),
        ],
      ),
    );
  }
}

class _RankingsCard extends StatelessWidget {
  const _RankingsCard({required this.rankings});
  final List<HyperthermicRanking> rankings;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md,
              ClinicalSpace.lg,
              0,
            ),
            child: Row(
              children: <Widget>[
                Text('DIFFERENTIALS', style: ClinicalText.eyebrow),
                Spacer(),
                Text('features matched', style: ClinicalText.caption),
              ],
            ),
          ),
          for (var i = 0; i < rankings.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: ClinicalSpace.lg,
              ),
            _RankRow(ranking: rankings[i]),
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.ranking});
  final HyperthermicRanking ranking;

  @override
  Widget build(BuildContext context) {
    final r = ranking;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg,
        ClinicalSpace.md,
        ClinicalSpace.lg,
        ClinicalSpace.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  r.differential.name,
                  style: ClinicalText.subtitle
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(r.differential.tagline,
                    style: ClinicalText.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.sm + 2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: ClinicalPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            ),
            child: Text(
              '${r.matches}/${r.differential.features.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClinicalPalette.text,
                fontFeatures: <FontFeature>[
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
              'These toxidromes overlap and can co-exist; the ranking '
              'is a prompt, not a diagnosis. Treat the patient, escalate '
              'early, and involve toxicology / ICU.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
