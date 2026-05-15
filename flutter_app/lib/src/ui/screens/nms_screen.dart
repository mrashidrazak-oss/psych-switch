// NMS rapid screener — Levenson criteria.
//
// Tick major / minor criteria + confirm dopamine-blocker exposure;
// the screen surfaces a tier verdict (unlikely / possible / probable
// / definite) with action recommendations.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/emergency_screens.dart';

class NmsScreen extends StatefulWidget {
  const NmsScreen({super.key});

  @override
  State<NmsScreen> createState() => _NmsScreenState();
}

class _NmsScreenState extends State<NmsScreen> {
  final Set<String> _ticked = <String>{};
  bool _exposed = true;

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
    setState(() {
      _ticked.clear();
      _exposed = true;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final result = evaluateNms(
      ticked: _ticked,
      antipsychoticExposure: _exposed,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMS screener'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_ticked.isNotEmpty || !_exposed)
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
                  _ExposureCard(
                    exposed: _exposed,
                    onTap: () {
                      setState(() => _exposed = !_exposed);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _SectionLabel(
                    eyebrow: 'Major criteria',
                    title: '${_count(kNmsMajor)} of ${kNmsMajor.length}',
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final c in kNmsMajor)
                    _CriterionRow(
                      criterion: c,
                      checked: _ticked.contains(c.id),
                      onTap: () => _toggle(c.id),
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  _SectionLabel(
                    eyebrow: 'Minor criteria',
                    title: '${_count(kNmsMinor)} of ${kNmsMinor.length}',
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final c in kNmsMinor)
                    _CriterionRow(
                      criterion: c,
                      checked: _ticked.contains(c.id),
                      onTap: () => _toggle(c.id),
                    ),
                  const SizedBox(height: ClinicalSpace.lg),
                  _ActionCard(result: result),
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

  int _count(List<NmsCriterion> list) =>
      list.where((c) => _ticked.contains(c.id)).length;
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.result});
  final NmsResult result;

  ({Color tone, Color ink, IconData icon}) _palette() {
    switch (result.tier) {
      case NmsTier.unlikely:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk,
          icon: Icons.check_rounded,
        );
      case NmsTier.possible:
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk,
          icon: Icons.visibility_outlined,
        );
      case NmsTier.probable:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk,
          icon: Icons.warning_amber_rounded,
        );
      case NmsTier.definite:
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
                  result.tier.name.toUpperCase(),
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

class _ExposureCard extends StatelessWidget {
  const _ExposureCard({required this.exposed, required this.onTap});
  final bool exposed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: exposed
          ? ClinicalPalette.toneRose
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.md + 2),
          child: Row(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: exposed
                      ? ClinicalPalette.toneRoseInk
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: exposed
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: exposed
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: ClinicalSpace.md),
              const Expanded(
                child: Text(
                  'Recent (≤ 7 days) antipsychotic / dopamine-blocker '
                  'exposure',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ClinicalPalette.text,
                    height: 1.4,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(eyebrow.toUpperCase(), style: ClinicalText.eyebrow),
        const Spacer(),
        Text(
          title,
          style: ClinicalText.caption.copyWith(
            fontWeight: FontWeight.w800,
            color: ClinicalPalette.text,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.criterion,
    required this.checked,
    required this.onTap,
  });

  final NmsCriterion criterion;
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
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: checked
                        ? Colors.white
                        : Colors.transparent,
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
                  child: Text(
                    criterion.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: checked
                          ? ClinicalPalette.ctaText
                          : ClinicalPalette.text,
                      height: 1.4,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.result});
  final NmsResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Action',
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
              'Levenson criteria — clinical aid, not a substitute for '
              'senior medical review. ICU + medicine input required '
              'for any probable / definite case.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
