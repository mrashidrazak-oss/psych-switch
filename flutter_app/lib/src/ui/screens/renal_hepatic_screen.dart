// Renal & hepatic dosing reference — pick a drug, switch axis
// (renal / hepatic), pick the impairment band, see the guidance.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/renal_hepatic_dosing.dart';

class RenalHepaticScreen extends StatefulWidget {
  const RenalHepaticScreen({super.key});

  @override
  State<RenalHepaticScreen> createState() => _RenalHepaticScreenState();
}

class _RenalHepaticScreenState extends State<RenalHepaticScreen> {
  late RenalHepaticEntry _drug = kRenalHepaticTable.first;
  bool _renalAxis = true;
  RenalBand _renalBand = RenalBand.moderate;
  HepaticBand _hepaticBand = HepaticBand.moderate;

  void _pickDrug(RenalHepaticEntry e) {
    setState(() => _drug = e);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final guidance = _renalAxis
        ? _drug.renalFor(_renalBand)
        : _drug.hepaticFor(_hepaticBand);
    final bandLabel = _renalAxis
        ? _renalBand.label
        : _hepaticBand.label;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renal & hepatic'),
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
                for (final e in kRenalHepaticTable)
                  _Chip(
                    label: e.drugName,
                    selected: _drug.drugId == e.drugId,
                    onTap: () => _pickDrug(e),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AxisChip(
                    label: 'Renal',
                    selected: _renalAxis,
                    onTap: () {
                      setState(() => _renalAxis = true);
                      unawaited(hapticsTap());
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _AxisChip(
                    label: 'Hepatic',
                    selected: !_renalAxis,
                    onTap: () {
                      setState(() => _renalAxis = false);
                      unawaited(hapticsTap());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.md),
            if (_renalAxis)
              Column(
                children: <Widget>[
                  for (final b in RenalBand.values)
                    _BandRow(
                      label: b.label,
                      selected: _renalBand == b,
                      onTap: () {
                        setState(() => _renalBand = b);
                        unawaited(hapticsTap());
                      },
                    ),
                ],
              )
            else
              Column(
                children: <Widget>[
                  for (final b in HepaticBand.values)
                    _BandRow(
                      label: b.label,
                      selected: _hepaticBand == b,
                      onTap: () {
                        setState(() => _hepaticBand = b);
                        unawaited(hapticsTap());
                      },
                    ),
                ],
              ),
            const SizedBox(height: ClinicalSpace.lg),
            _GuidanceCard(
              drugName: _drug.drugName,
              axis: _renalAxis ? 'Renal' : 'Hepatic',
              bandLabel: bandLabel,
              guidance: guidance,
            ),
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
            label: 'Organ-impairment dosing',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneMintInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Dose for the kidney and the liver in front of you',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneMintInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Per-drug adjustment by eGFR band and Child-Pugh class. '
            'Summarised from the Maudsley 15e, the Renal Drug Handbook, '
            'and SmPCs.',
            style: ClinicalText.body.copyWith(
              color:
                  ClinicalPalette.toneMintInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md + 2,
            vertical: ClinicalSpace.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
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

class _AxisChip extends StatelessWidget {
  const _AxisChip({
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
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
                      fontSize: 13.5,
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
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.drugName,
    required this.axis,
    required this.bandLabel,
    required this.guidance,
  });

  final String drugName;
  final String axis;
  final String bandLabel;
  final String guidance;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TonePill(
                label: axis,
                tone: const Color(0xFFFFFFFF),
                ink: ClinicalPalette.toneSandInk,
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  bandLabel,
                  textAlign: TextAlign.end,
                  style: ClinicalText.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ClinicalPalette.toneSandInk
                        .withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            guidance,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy guidance',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              final txt =
                  '$drugName · $axis ($bandLabel): $guidance';
              await Clipboard.setData(ClipboardData(text: txt));
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guidance copied')),
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
              'Quick reference only. Confirm against the current '
              'product label and involve a renal / hepatic pharmacist '
              'for live decisions.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
