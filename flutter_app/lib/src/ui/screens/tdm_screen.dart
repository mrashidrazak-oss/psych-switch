// Therapeutic Drug Monitoring interpreter.
//
// Pick the drug, enter the level, the screen surfaces a tier
// (subtherapeutic / therapeutic / supratherapeutic / toxic) with a
// one-line clinical action.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/tdm.dart';

class TdmScreen extends StatefulWidget {
  const TdmScreen({super.key});

  @override
  State<TdmScreen> createState() => _TdmScreenState();
}

class _TdmScreenState extends State<TdmScreen> {
  TdmDrug _selected = kTdmDrugs.first;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  TdmInterpretation? _interpret() {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v < 0) return null;
    return interpretLevel(_selected, v);
  }

  void _pickDrug(TdmDrug d) {
    setState(() {
      _selected = d;
      _ctrl.clear();
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final result = _interpret();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TDM interpreter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xxl,
          ),
          children: <Widget>[
            const _Hero(),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Drug', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final d in kTdmDrugs)
                  _DrugChip(
                    drug: d,
                    selected: _selected.id == d.id,
                    onTap: () => _pickDrug(d),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              padding: const EdgeInsets.all(ClinicalSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('LEVEL', style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType
                        .numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g. 0.7',
                      suffixText: _selected.unit,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ClinicalSpace.sm + 2),
                  Text(
                    'Target — ${_selected.targetCopy}',
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Timing — ${_selected.timingCopy}',
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.lg),
            if (result != null) _ResultCard(result: result),
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneMint,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Therapeutic monitoring',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneMintInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Map a serum level to a clear action',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneMintInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Lithium · clozapine · valproate · lamotrigine. Returns the '
            'tier (subtherapeutic / therapeutic / supratherapeutic / '
            'toxic) plus the standard action and timing reminder.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneMintInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrugChip extends StatelessWidget {
  const _DrugChip({
    required this.drug,
    required this.selected,
    required this.onTap,
  });

  final TdmDrug drug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md + 2,
            vertical: ClinicalSpace.sm,
          ),
          child: Text(
            drug.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final TdmInterpretation result;

  ({Color tone, Color ink}) _palette() {
    switch (result.tier) {
      case TdmTier.subtherapeutic:
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk
        );
      case TdmTier.therapeuticLow:
      case TdmTier.therapeutic:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case TdmTier.therapeuticHigh:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case TdmTier.supratherapeutic:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case TdmTier.toxic:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    return SquircleCard(
      tone: p.tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                result.level.toStringAsFixed(
                  result.level == result.level.roundToDouble() ? 0 : 2,
                ),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  height: 1,
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
                  result.drug.unit,
                  style: TextStyle(
                    fontSize: 14,
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
                  tdmTierLabel(result.tier),
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
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.headline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.ink,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.action,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: p.ink,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
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
              'Reference ranges are general adult psychiatric targets. '
              'Always correlate with patient response, side effects, '
              'and the clinical context.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
