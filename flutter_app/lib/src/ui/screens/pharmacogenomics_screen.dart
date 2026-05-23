// Pharmacogenomics quick reference — pick a drug + metaboliser
// phenotype, see the CYP2D6 / CYP2C19 dosing implication.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/pharmacogenomics.dart';

class PharmacogenomicsScreen extends StatefulWidget {
  const PharmacogenomicsScreen({super.key});

  @override
  State<PharmacogenomicsScreen> createState() =>
      _PharmacogenomicsScreenState();
}

class _PharmacogenomicsScreenState
    extends State<PharmacogenomicsScreen> {
  late ({String id, String name}) _drug = pgxDrugs().first;
  Metaboliser _phenotype = Metaboliser.normal;

  void _pickDrug(({String id, String name}) d) {
    setState(() => _drug = d);
    unawaited(hapticsTap());
  }

  void _pickPhenotype(Metaboliser m) {
    setState(() => _phenotype = m);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final entries = pgxEntriesFor(_drug.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacogenomics'),
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
                for (final d in pgxDrugs())
                  _Chip(
                    label: d.name,
                    selected: _drug.id == d.id,
                    onTap: () => _pickDrug(d),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Metaboliser phenotype',
                style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final m in Metaboliser.values)
                  _Chip(
                    label: m.label,
                    selected: _phenotype == m,
                    onTap: () => _pickPhenotype(m),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            for (final e in entries) ...<Widget>[
              _EntryCard(entry: e, phenotype: _phenotype),
              const SizedBox(height: ClinicalSpace.md),
            ],
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
            label: 'CYP2D6 · CYP2C19',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneMintInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Genotype → dosing implication',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneMintInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'CPIC / FDA-derived guidance for the psychotropics most '
            'affected by CYP2D6 and CYP2C19 metaboliser status. '
            'Educational quick reference — not a substitute for a '
            'curated genotype interpretation.',
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

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.phenotype});

  final PgxEntry entry;
  final Metaboliser phenotype;

  @override
  Widget build(BuildContext context) {
    final text = entry.forPhenotype(phenotype);
    final extreme = phenotype == Metaboliser.poor ||
        phenotype == Metaboliser.ultrarapid;
    final tone = extreme
        ? ClinicalPalette.toneSand
        : ClinicalPalette.surface;
    final ink = extreme
        ? ClinicalPalette.toneSandInk
        : ClinicalPalette.text;
    return SquircleCard(
      tone: extreme ? tone : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TonePill(
                label: entry.gene.label,
                tone: extreme
                    ? const Color(0xFFFFFFFF)
                    : ClinicalPalette.surfaceMuted,
                ink: extreme
                    ? ClinicalPalette.toneSandInk
                    : ClinicalPalette.mutedStrong,
              ),
              const Spacer(),
              Text(
                phenotype.label,
                style: ClinicalText.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            text,
            style: ClinicalText.body.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
          PillButton(
            label: 'Copy',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              final summary =
                  '${entry.drugName} · ${entry.gene.label} · '
                  '${phenotype.label}: $text';
              await Clipboard.setData(ClipboardData(text: summary));
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Recommendation');
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
              'Summarised from CPIC + FDA + Maudsley 15e. Phenotype '
              'requires an actual genotype result; drug–drug '
              'interactions can phenocopy a poor metaboliser. Confirm '
              'with a clinical pharmacologist before acting.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
