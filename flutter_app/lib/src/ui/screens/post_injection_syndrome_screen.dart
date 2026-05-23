// Olanzapine LAI post-injection syndrome — tick observed features,
// see the observation protocol + continue/escalate triage.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/post_injection_syndrome.dart';

class PostInjectionSyndromeScreen extends StatefulWidget {
  const PostInjectionSyndromeScreen({super.key});

  @override
  State<PostInjectionSyndromeScreen> createState() =>
      _PostInjectionSyndromeScreenState();
}

class _PostInjectionSyndromeScreenState
    extends State<PostInjectionSyndromeScreen> {
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
    final r = evaluatePostInjection(features: _ticked);
    final emergency = r.action == PdssAction.suspectedPdss;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olanzapine LAI — PDSS'),
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
            _Banner(
              title: r.action.label,
              subtitle: r.headline,
              tone: emergency
                  ? ClinicalPalette.toneRose
                  : ClinicalPalette.toneMint,
              ink: emergency
                  ? ClinicalPalette.toneRoseInk
                  : ClinicalPalette.toneMintInk,
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
                  SquircleCard(
                    child: Text(
                      'After every olanzapine pamoate injection, '
                      'tick any feature observed during the '
                      'mandatory observation period.',
                      style: ClinicalText.caption
                          .copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('OBSERVED FEATURES',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final f in kPdssFeatures) ...<Widget>[
                    _CheckRow(
                      label: f.label,
                      ticked: _ticked.contains(f.id),
                      onTap: () => _toggle(f.id),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  _PlanCard(
                    sections: <(String, List<String>)>[
                      ('Action now', r.steps),
                      ('Observation protocol', r.protocol),
                      ('Cautions', r.cautions),
                    ],
                    clipboard: r.clipboardSummary,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(
                    text:
                        'Maudsley 15e / olanzapine pamoate '
                        'risk-management programme. Always observe '
                        '≥ 3 h in a facility able to manage acute '
                        'sedation and delirium.',
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.ink,
  });
  final String title;
  final String subtitle;
  final Color tone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tone,
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
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: ClinicalText.caption.copyWith(
              color: ink.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.ticked,
    required this.onTap,
  });
  final String label;
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.sections,
    required this.clipboard,
  });
  final List<(String, List<String>)> sections;
  final String Function() clipboard;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final s in sections) ...<Widget>[
            TonePill(
              label: s.$1,
              tone: const Color(0xFFFFFFFF),
              ink: ClinicalPalette.toneSandInk,
            ),
            const SizedBox(height: ClinicalSpace.sm),
            for (final line in s.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle,
                          size: 6,
                          color: ClinicalPalette.toneSandInk),
                    ),
                    const SizedBox(width: ClinicalSpace.sm + 2),
                    Expanded(
                      child: Text(
                        line,
                        style: ClinicalText.body.copyWith(
                          color: ClinicalPalette.toneSandInk,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: ClinicalSpace.md),
          ],
          PillButton(
            label: 'Copy plan',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: clipboard()),
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

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});
  final String text;

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
              text,
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
