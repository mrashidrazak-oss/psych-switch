// Movement disorder identifier — tick features, see the top
// differential + management plan.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/movement_disorder.dart';

class MovementDisorderScreen extends StatefulWidget {
  const MovementDisorderScreen({super.key});

  @override
  State<MovementDisorderScreen> createState() =>
      _MovementDisorderScreenState();
}

class _MovementDisorderScreenState extends State<MovementDisorderScreen> {
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
    final result = rankMovementDisorder(_ticked);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement disorder'),
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
            _TopDifferentialBanner(result: result),
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
                    'Tick the features the patient shows. The most '
                    'likely diagnosis surfaces at the top with its '
                    'first-line management.',
                    style: ClinicalText.body,
                  ),
                  const SizedBox(height: ClinicalSpace.lg),
                  for (final f in kMovementFeatures)
                    _FeatureRow(
                      feature: f,
                      checked: _ticked.contains(f.id),
                      onTap: () => _toggle(f.id),
                    ),
                  const SizedBox(height: ClinicalSpace.lg),
                  if (result.top != null) ...<Widget>[
                    _ManagementCard(result: result),
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

class _TopDifferentialBanner extends StatelessWidget {
  const _TopDifferentialBanner({required this.result});
  final MovementResult result;

  ({Color tone, Color ink, String label}) _palette() {
    final top = result.top;
    if (top == null) {
      return (
        tone: ClinicalPalette.surfaceMuted,
        ink: ClinicalPalette.mutedStrong,
        label: 'Tick features to identify',
      );
    }
    switch (top.id) {
      case 'parkinsonism':
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk,
          label: 'Drug-induced parkinsonism',
        );
      case 'dystonia':
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk,
          label: 'Acute dystonic reaction',
        );
      case 'akathisia':
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk,
          label: 'Akathisia',
        );
      case 'td':
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk,
          label: 'Tardive dyskinesia',
        );
      case 'tremor':
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk,
          label: 'Drug-induced tremor',
        );
      default:
        return (
          tone: ClinicalPalette.surfaceMuted,
          ink: ClinicalPalette.mutedStrong,
          label: top.name,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
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
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.top == null ? Icons.help_outline : Icons.check_rounded,
              color: p.ink,
            ),
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'TOP DIFFERENTIAL',
                  style: ClinicalText.eyebrow,
                ),
                const SizedBox(height: 2),
                Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
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
    required this.checked,
    required this.onTap,
  });

  final MovementFeature feature;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: checked
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
                    color: checked ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: checked
                          ? Colors.transparent
                          : ClinicalPalette.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  child: checked
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: checked
                              ? ClinicalPalette.ctaText
                              : ClinicalPalette.text,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: checked
                              ? ClinicalPalette.ctaText.withValues(alpha: 0.85)
                              : ClinicalPalette.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
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

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.result});
  final MovementResult result;

  @override
  Widget build(BuildContext context) {
    final top = result.top!;
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'First-line management',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            top.management,
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

class _RankingsCard extends StatelessWidget {
  const _RankingsCard({required this.rankings});
  final List<MovementRanking> rankings;

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
                Text(
                  'features matched',
                  style: ClinicalText.caption,
                ),
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
            _RankingRow(ranking: rankings[i]),
          ],
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.ranking});
  final MovementRanking ranking;

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
              '${r.matches}/${r.featureCount}',
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
              'Clinical aid — confirm with formal exam (AIMS for TD; '
              'observation procedure for akathisia). Differentials '
              'may overlap; clinical judgement always wins.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
