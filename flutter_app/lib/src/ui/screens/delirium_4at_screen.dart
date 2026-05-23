// 4AT delirium assessment — pick an option per item, see the live
// total + tier + interpretation, copy a paste-ready summary.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/delirium_4at.dart';

class Delirium4atScreen extends StatefulWidget {
  const Delirium4atScreen({super.key});

  @override
  State<Delirium4atScreen> createState() => _Delirium4atScreenState();
}

class _Delirium4atScreenState extends State<Delirium4atScreen> {
  final Map<String, int> _answers = <String, int>{};

  void _pick(String itemId, int score) {
    setState(() => _answers[itemId] = score);
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_answers.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final result = scoreFourAt(_answers);
    return Scaffold(
      appBar: AppBar(
        title: const Text('4AT delirium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_answers.isNotEmpty)
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
                  for (var i = 0; i < kFourAtItems.length; i++) ...<Widget>[
                    _ItemCard(
                      index: i + 1,
                      item: kFourAtItems[i],
                      selected: _answers[kFourAtItems[i].id],
                      onPick: (s) => _pick(kFourAtItems[i].id, s),
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                  ],
                  _SummaryCard(result: result),
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
  final FourAtResult result;

  ({Color tone, Color ink}) _palette() {
    switch (result.severity) {
      case 0:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case 1:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      default:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk
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
          Text(
            '${result.total}',
            style: TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -1,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '/ 12',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.ink.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: Text(
                result.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.index,
    required this.item,
    required this.selected,
    required this.onPick,
  });

  final int index;
  final FourAtItem item;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected != null
                      ? ClinicalPalette.cta
                      : ClinicalPalette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected != null
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.mutedStrong,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  item.title,
                  style: ClinicalText.subtitle
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(item.prompt,
              style: ClinicalText.body.copyWith(height: 1.5)),
          const SizedBox(height: ClinicalSpace.md),
          for (final o in item.options) ...<Widget>[
            _OptionRow(
              label: o.label,
              score: o.score,
              selected: selected == o.score,
              onTap: () => onPick(o.score),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.score,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int score;
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
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: selected
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.text,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Text(
                  '+$score',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.mutedStrong,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});
  final FourAtResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Interpretation',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.interpretation,
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
              'Bellelli 2014 — free for clinical use (the4at.com). '
              'A positive screen is not a diagnosis; confirm against '
              'DSM-5-TR and search for the precipitant.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
