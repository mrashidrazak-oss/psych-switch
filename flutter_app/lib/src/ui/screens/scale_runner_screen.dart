// Scale runner — renders one rating scale, captures per-item answers
// via tap-to-pick anchor segments, and lands the live total + severity
// band in a sticky banner at the top.
//
// Once every contributing item is answered, a "Copy summary" pill
// drops a clipboard-ready one-line summary in the form:
//   "PHQ-9: 14 / 27 — Moderate."
// which paste-fits straight into a clinical note.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/scales.dart';

class ScaleRunnerScreen extends StatefulWidget {
  const ScaleRunnerScreen({super.key, required this.scaleId});
  final String scaleId;

  @override
  State<ScaleRunnerScreen> createState() => _ScaleRunnerScreenState();
}

class _ScaleRunnerScreenState extends State<ScaleRunnerScreen> {
  final Map<String, int> _answers = <String, int>{};

  ClinicalScale? get _scale => scaleById(widget.scaleId);

  void _setAnswer(String id, int value) {
    setState(() {
      _answers[id] = value;
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_answers.clear);
    unawaited(hapticsTap());
  }

  int get _itemsAnswered =>
      _scale!.items.where((i) => _answers.containsKey(i.id)).length;
  int get _itemsTotal => _scale!.items.length;
  bool get _isComplete => _itemsAnswered >= _itemsTotal;

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    if (scale == null) return const _UnknownScaleScreen();

    final result = scoreScale(scale, _answers);
    final progress = _itemsAnswered / _itemsTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(scale.name),
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
            _ScoreBanner(
              result: result,
              answered: _itemsAnswered,
              total: _itemsTotal,
              progress: progress,
              complete: _isComplete,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  if (scale.headingPrompt != null) ...<Widget>[
                    SquircleCard(
                      tone: ClinicalPalette.surfaceMuted,
                      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
                      child: Text(
                        scale.headingPrompt!,
                        style: ClinicalText.body.copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                  ],
                  for (var i = 0; i < scale.items.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: ClinicalSpace.md),
                    _ItemCard(
                      item: scale.items[i],
                      index: i + 1,
                      current: _answers[scale.items[i].id],
                      onPick: (v) => _setAnswer(scale.items[i].id, v),
                    ),
                  ],
                  const SizedBox(height: ClinicalSpace.lg),
                  _Summary(
                    scale: scale,
                    result: result,
                    complete: _isComplete,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  Text(
                    scale.citation,
                    textAlign: TextAlign.center,
                    style: ClinicalText.caption.copyWith(
                      color: ClinicalPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score banner ────────────────────────────────────────────────────

/// Sticky banner under the AppBar that shows the running total, the
/// current severity band, and a slim progress bar.
class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({
    required this.result,
    required this.answered,
    required this.total,
    required this.progress,
    required this.complete,
  });

  final ScaleResult result;
  final int answered;
  final int total;
  final double progress;
  final bool complete;

  /// Tone family for the severity band.
  ({Color tone, Color ink}) _palette(int severity) {
    switch (severity) {
      case 0:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case 1:
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk
        );
      case 2:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case 3:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
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
    final p = _palette(result.band.severity);
    return Container(
      width: double.infinity,
      color: p.tone,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
                  ' / ${result.scale.maxScore}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.ink.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Spacer(),
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
                  result.band.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            '$answered of $total items answered',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.ink.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(p.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item card ───────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.index,
    required this.current,
    required this.onPick,
  });

  final ScaleItem item;
  final int index;
  final int? current;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current != null
                      ? ClinicalPalette.cta
                      : ClinicalPalette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: current != null
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.mutedStrong,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.prompt,
                      style: ClinicalText.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    if (item.subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: ClinicalText.caption.copyWith(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Column(
            children: <Widget>[
              for (var i = 0; i < item.anchors.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 6),
                _AnchorRow(
                  score: i,
                  label: item.anchors[i],
                  selected: current == i,
                  onTap: () => onPick(i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({
    required this.score,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int score;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? ClinicalPalette.cta : ClinicalPalette.surfaceMuted;
    final ink =
        selected ? ClinicalPalette.ctaText : ClinicalPalette.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md,
            vertical: ClinicalSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? ClinicalPalette.ctaText.withValues(alpha: 0.18)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.md - 2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: ink,
                    height: 1.35,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: ClinicalPalette.ctaText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary card ────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({
    required this.scale,
    required this.result,
    required this.complete,
  });

  final ClinicalScale scale;
  final ScaleResult result;
  final bool complete;

  String _clipboardText() =>
      '${scale.name}: ${result.total} / ${scale.maxScore} — '
      '${result.band.label}. ${result.band.interpretation}';

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
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
            result.band.interpretation,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label:
                complete ? 'Copy summary' : 'Copy partial summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _clipboardText()),
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

// ── Unknown-scale fallback ──────────────────────────────────────────

class _UnknownScaleScreen extends StatelessWidget {
  const _UnknownScaleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scale not found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.help_outline,
                size: 36,
                color: ClinicalPalette.muted,
              ),
              const SizedBox(height: ClinicalSpace.md),
              Text(
                "We couldn't find that scale.",
                textAlign: TextAlign.center,
                style: ClinicalText.subtitle.copyWith(
                  color: ClinicalPalette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
