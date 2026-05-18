// Smoking-status CYP1A2 dose-adjustment calculator — pick the drug,
// the smoking change, and the current dose; the screen projects the
// level change and suggests a dose.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/smoking_adjustment.dart';

class SmokingAdjustmentScreen extends StatefulWidget {
  const SmokingAdjustmentScreen({super.key});

  @override
  State<SmokingAdjustmentScreen> createState() =>
      _SmokingAdjustmentScreenState();
}

class _SmokingAdjustmentScreenState
    extends State<SmokingAdjustmentScreen> {
  SmokingDrug _drug = kSmokingDrugs.first;
  SmokingChange _change = SmokingChange.stopping;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  SmokingAdjustment? _result() {
    final dose = double.tryParse(_ctrl.text.trim());
    if (dose == null || dose <= 0) return null;
    return computeSmokingAdjustment(
      drug: _drug,
      change: _change,
      currentDoseMg: dose,
    );
  }

  void _pickDrug(SmokingDrug d) {
    setState(() => _drug = d);
    unawaited(hapticsTap());
  }

  void _pickChange(SmokingChange c) {
    setState(() => _change = c);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = _result();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoking & CYP1A2'),
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
            Row(
              children: <Widget>[
                for (final d in kSmokingDrugs) ...<Widget>[
                  Expanded(
                    child: _BigChip(
                      label: d.name,
                      selected: _drug.id == d.id,
                      onTap: () => _pickDrug(d),
                    ),
                  ),
                  if (d != kSmokingDrugs.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Smoking change', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: _BigChip(
                    label: 'Stopping',
                    selected: _change == SmokingChange.stopping,
                    onTap: () => _pickChange(SmokingChange.stopping),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _BigChip(
                    label: 'Starting / resuming',
                    selected: _change == SmokingChange.starting,
                    onTap: () => _pickChange(SmokingChange.starting),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('CURRENT DAILY DOSE',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType
                        .numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'e.g. 450',
                      suffixText: 'mg',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ClinicalSpace.sm + 2),
                  Text(
                    _drug.note,
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.lg),
            if (r != null) _ResultCard(result: r),
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
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'CYP1A2 trap',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            "It's the smoke, not the nicotine",
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneSandInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Tobacco smoke induces CYP1A2. A patient admitted to a '
            'smoke-free ward can hit clozapine toxicity within days. '
            'NRT / vaping does NOT prevent it.',
            style: ClinicalText.body.copyWith(
              color:
                  ClinicalPalette.toneSandInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigChip extends StatelessWidget {
  const _BigChip({
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
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
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
  final SmokingAdjustment result;

  @override
  Widget build(BuildContext context) {
    final rising = result.change == SmokingChange.stopping;
    final tone =
        rising ? ClinicalPalette.toneRose : ClinicalPalette.toneSky;
    final ink = rising
        ? ClinicalPalette.toneRoseInk
        : ClinicalPalette.toneSkyInk;
    final pct = ((result.projectedLevelFactor - 1) * 100).round();
    final dir = pct >= 0 ? '+$pct%' : '$pct%';
    return SquircleCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                dir,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1,
                  letterSpacing: -1,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'projected level',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ink.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.headline,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Container(
            padding: const EdgeInsets.all(ClinicalSpace.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(ClinicalRadii.tile),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('CURRENT',
                          style: ClinicalText.eyebrow
                              .copyWith(color: ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${result.currentDoseMg.toStringAsFixed(0)} mg',
                        style: ClinicalText.subtitle.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: ink, size: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('SUGGESTED',
                          style: ClinicalText.eyebrow
                              .copyWith(color: ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${result.suggestedDoseMg.toStringAsFixed(0)} mg',
                        style: ClinicalText.subtitle.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.action,
            style: ClinicalText.body.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
              height: 1.55,
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
              'Population estimate — confirm with trough levels before '
              'and after the change. Effect develops over 1–4 weeks as '
              'enzyme expression turns over.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
