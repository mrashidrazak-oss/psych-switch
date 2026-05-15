// Columbia-Suicide Severity Rating Scale — bedside screener.
//
// Walks the clinician through the five-level ideation ladder + the
// behaviour questions, then surfaces a clear tier (low / moderate /
// high) with a one-line recommended action.
//
// DECISION SUPPORT, NOT A DECISION. Footer disclaimer makes this
// explicit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/cssrs.dart';

class CssrsScreen extends StatefulWidget {
  const CssrsScreen({super.key});

  @override
  State<CssrsScreen> createState() => _CssrsScreenState();
}

class _CssrsScreenState extends State<CssrsScreen> {
  int _level = 0; // 0 means no ideation
  bool _ideationLastMonth = false;
  bool _behaviourLifetime = false;
  bool _behaviourLast3Months = false;

  void _setLevel(int v) {
    setState(() {
      _level = v;
      if (v == 0) _ideationLastMonth = false;
    });
    unawaited(hapticsTap());
  }

  void _toggleIdeationMonth() {
    setState(() => _ideationLastMonth = !_ideationLastMonth);
    unawaited(hapticsTap());
  }

  void _toggleBehaviourLifetime() {
    setState(() {
      _behaviourLifetime = !_behaviourLifetime;
      if (!_behaviourLifetime) _behaviourLast3Months = false;
    });
    unawaited(hapticsTap());
  }

  void _toggleBehaviourRecent() {
    setState(() {
      _behaviourLast3Months = !_behaviourLast3Months;
      if (_behaviourLast3Months) _behaviourLifetime = true;
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(() {
      _level = 0;
      _ideationLastMonth = false;
      _behaviourLifetime = false;
      _behaviourLast3Months = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final input = CssrsInput(
      highestIdeationLevel: _level,
      ideationLastMonth: _ideationLastMonth,
      behaviourLifetime: _behaviourLifetime,
      behaviourLast3Months: _behaviourLast3Months,
    );
    final result = evaluateCssrs(input);
    return Scaffold(
      appBar: AppBar(
        title: const Text('C-SSRS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_level > 0 || _behaviourLifetime)
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
            _VerdictBanner(result: result),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  const _SectionHeader(
                    eyebrow: 'Ideation',
                    title: 'Highest level reached',
                    sub: 'Pick the most-severe rung the patient has '
                        'reached at any point — or "none" if denied.',
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _LevelRow(
                    level: 0,
                    label: 'No ideation',
                    note: 'Denies wish to die or suicidal thoughts.',
                    selected: _level == 0,
                    onTap: () => _setLevel(0),
                  ),
                  for (final item in kCssrsIdeationLadder) ...<Widget>[
                    const SizedBox(height: 6),
                    _LevelRow(
                      level: item.level,
                      label: item.prompt,
                      note: item.note,
                      selected: _level == item.level,
                      onTap: () => _setLevel(item.level),
                    ),
                  ],
                  if (_level > 0) ...<Widget>[
                    const SizedBox(height: ClinicalSpace.md),
                    _ToggleRow(
                      label: 'Ideation present in the last month?',
                      value: _ideationLastMonth,
                      onTap: _toggleIdeationMonth,
                    ),
                  ],
                  const SizedBox(height: ClinicalSpace.lg),
                  const _SectionHeader(
                    eyebrow: 'Behaviour',
                    title: 'Self-injurious behaviour with intent',
                    sub: 'Includes actual attempts, interrupted / '
                        'aborted attempts, and preparatory acts '
                        '(e.g. acquiring means, writing a note).',
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _ToggleRow(
                    label: 'Any-lifetime behaviour?',
                    value: _behaviourLifetime,
                    onTap: _toggleBehaviourLifetime,
                  ),
                  const SizedBox(height: 6),
                  _ToggleRow(
                    label: 'Within the last 3 months?',
                    value: _behaviourLast3Months,
                    onTap: _toggleBehaviourRecent,
                    enabled: _behaviourLifetime,
                  ),
                  const SizedBox(height: ClinicalSpace.lg),
                  _SummaryCard(result: result),
                  const SizedBox(height: ClinicalSpace.md),
                  _CrisisLinkRow(),
                  const SizedBox(height: ClinicalSpace.md),
                  Text(
                    'Posner K, Brent D, Lucas C, et al. The Columbia '
                    'Suicide Severity Rating Scale. NIMH 2008.',
                    textAlign: TextAlign.center,
                    style: ClinicalText.caption
                        .copyWith(color: ClinicalPalette.muted),
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

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.result});
  final CssrsResult result;

  ({Color tone, Color ink, IconData icon}) _palette() {
    switch (result.tier) {
      case CssrsTier.none:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk,
          icon: Icons.check_rounded,
        );
      case CssrsTier.low:
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk,
          icon: Icons.visibility_outlined,
        );
      case CssrsTier.moderate:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk,
          icon: Icons.warning_amber_rounded,
        );
      case CssrsTier.high:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk,
          icon: Icons.priority_high_rounded,
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
            child: Icon(p.icon, color: p.ink),
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${result.tierLabel} risk',
                  style: TextStyle(
                    fontSize: 18,
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
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.sub,
  });
  final String eyebrow;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(eyebrow.toUpperCase(), style: ClinicalText.eyebrow),
        const SizedBox(height: 4),
        Text(title, style: ClinicalText.subtitle),
        const SizedBox(height: 2),
        Text(sub, style: ClinicalText.caption.copyWith(height: 1.5)),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.label,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final String label;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  ({Color tone, Color ink}) _tonePalette() {
    if (level == 0) {
      return (
        tone: ClinicalPalette.toneMint,
        ink: ClinicalPalette.toneMintInk
      );
    }
    if (level <= 2) {
      return (
        tone: ClinicalPalette.toneSky,
        ink: ClinicalPalette.toneSkyInk
      );
    }
    if (level == 3) {
      return (
        tone: ClinicalPalette.toneSand,
        ink: ClinicalPalette.toneSandInk
      );
    }
    return (
      tone: ClinicalPalette.toneRose,
      ink: ClinicalPalette.toneRoseInk,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _tonePalette();
    return Material(
      color: selected ? p.tone : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.md,
            ClinicalSpace.md,
            ClinicalSpace.md,
            ClinicalSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.ink : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  level.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : ClinicalPalette.text,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? p.ink : ClinicalPalette.text,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: selected
                            ? p.ink.withValues(alpha: 0.8)
                            : ClinicalPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: p.ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.md,
              vertical: ClinicalSpace.md,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: value
                          ? Colors.transparent
                          : ClinicalPalette.borderStrong,
                      width: 1.2,
                    ),
                  ),
                  child: value
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: ClinicalPalette.cta)
                      : null,
                ),
                const SizedBox(width: ClinicalSpace.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});
  final CssrsResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Recommended next step',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.recommendation,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.5,
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

class _CrisisLinkRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.tonePeach,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      onTap: () => context.pushNamed(Routes.crisis),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk,
                color: ClinicalPalette.tonePeachInk),
          ),
          const SizedBox(width: ClinicalSpace.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Crisis lifelines + safety plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ClinicalPalette.tonePeachInk,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Talian Kasih · Befrienders · Stanley-Brown plan',
                  style: TextStyle(
                    fontSize: 12,
                    color: ClinicalPalette.tonePeachInk,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: ClinicalPalette.tonePeachInk.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
