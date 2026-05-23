// Antipsychotic in Parkinsonism / Lewy body / dementia — pick the
// context, see safe choices, agents to avoid and the safeguards.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/antipsychotic_in_parkinsonism.dart';

class AntipsychoticInParkinsonismScreen extends StatefulWidget {
  const AntipsychoticInParkinsonismScreen({super.key});

  @override
  State<AntipsychoticInParkinsonismScreen> createState() =>
      _AntipsychoticInParkinsonismScreenState();
}

class _AntipsychoticInParkinsonismScreenState
    extends State<AntipsychoticInParkinsonismScreen> {
  NeuroContext _context = NeuroContext.parkinsonsPsychosis;

  @override
  Widget build(BuildContext context) {
    final r = evaluateNeuroAntipsychotic(_context);
    final danger = _context == NeuroContext.lewyBody;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antipsychotic + Parkinsonism'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: danger
                  ? ClinicalPalette.toneRose
                  : ClinicalPalette.toneSand,
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
                    r.context.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: danger
                          ? ClinicalPalette.toneRoseInk
                          : ClinicalPalette.toneSandInk,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.headline,
                    style: ClinicalText.caption.copyWith(
                      color: (danger
                              ? ClinicalPalette.toneRoseInk
                              : ClinicalPalette.toneSandInk)
                          .withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
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
                  const Text('CONTEXT',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final c in NeuroContext.values) ...<Widget>[
                    _PickRow(
                      label: c.label,
                      selected: _context == c,
                      onTap: () {
                        setState(() => _context = c);
                        unawaited(hapticsTap());
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  _PlanCard(
                    sections: <(String, List<String>)>[
                      ('Before any antipsychotic', r.firstSteps),
                      ('Preferred (if unavoidable)', r.preferred),
                      ('Avoid', r.avoid),
                      ('Cautions', r.cautions),
                    ],
                    clipboard: r.clipboardSummary,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(
                    text:
                        'Maudsley 15e / NICE dementia + Parkinson’s '
                        'guidance. Non-drug measures first; any '
                        'antipsychotic is lowest-dose, time-limited '
                        'and reviewed.',
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

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
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
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected
                    ? ClinicalPalette.ctaText
                    : ClinicalPalette.mutedStrong,
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected
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
            label: 'Copy guidance',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: clipboard()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Guidance');
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
