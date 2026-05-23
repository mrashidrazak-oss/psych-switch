// Clozapine myocarditis surveillance — tick findings during the
// first weeks of titration, see the schedule + continue/review/stop
// triage.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/clozapine_myocarditis.dart';

class ClozapineMyocarditisScreen extends StatefulWidget {
  const ClozapineMyocarditisScreen({super.key});

  @override
  State<ClozapineMyocarditisScreen> createState() =>
      _ClozapineMyocarditisScreenState();
}

class _ClozapineMyocarditisScreenState
    extends State<ClozapineMyocarditisScreen> {
  final Set<String> _ticked = <String>{};

  void _toggle(String id) {
    setState(() {
      if (!_ticked.add(id)) _ticked.remove(id);
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(_ticked.clear);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r =
        evaluateClozapineMyocarditis(findings: _ticked);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clozapine myocarditis'),
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
                  SquircleCard(
                    child: Text(
                      'Tick any finding present during the first '
                      '~6–8 weeks of titration. Routine FBC '
                      'monitoring does not detect myocarditis — '
                      'this is a separate surveillance stream.',
                      style: ClinicalText.caption
                          .copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('FINDINGS',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final f in kMyocarditisFindings)
                    ...<Widget>[
                      _FeatureRow(
                        label: f.label,
                        tier: f.severity == 'red'
                            ? 'red flag'
                            : 'amber',
                        red: f.severity == 'red',
                        ticked: _ticked.contains(f.id),
                        onTap: () => _toggle(f.id),
                      ),
                      const SizedBox(height: 6),
                    ],
                  const SizedBox(height: ClinicalSpace.sm),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.result});
  final MyocarditisResult result;

  ({Color tone, Color ink}) _p() {
    switch (result.action) {
      case MyocarditisAction.continueMonitoring:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case MyocarditisAction.urgentReview:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case MyocarditisAction.stopNow:
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.action.label,
            style: TextStyle(
              fontSize: 19,
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
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.tier,
    required this.red,
    required this.ticked,
    required this.onTap,
  });
  final String label;
  final String tier;
  final bool red;
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ticked
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: ticked
                        ? ClinicalPalette.ctaText
                        : red
                            ? ClinicalPalette.toneRoseInk
                            : ClinicalPalette.tonePeachInk,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});
  final MyocarditisResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Action now',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final s in result.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Bullet(text: s),
            ),
          const SizedBox(height: ClinicalSpace.md),
          const TonePill(
            label: 'Surveillance schedule',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final s in result.schedule)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Bullet(text: s),
            ),
          const SizedBox(height: ClinicalSpace.md),
          const TonePill(
            label: 'Cautions',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final c in result.cautions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Bullet(text: c),
            ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy plan',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Plan');
            },
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle,
              size: 6, color: ClinicalPalette.toneSandInk),
        ),
        const SizedBox(width: ClinicalSpace.sm + 2),
        Expanded(
          child: Text(
            text,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              height: 1.5,
            ),
          ),
        ),
      ],
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
              'Maudsley 15e / Ronaldson clozapine myocarditis '
              'protocol. Use local troponin/CRP reference ranges; '
              'when in doubt, hold the dose and involve cardiology.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
