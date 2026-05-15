// Halal & Ramadan dose-timing tool.
//
// Per-drug Suhoor / Iftar recommendations for psychiatric medications,
// targeted at Muslim-majority Malaysia where up to two-thirds of
// patients fast during Ramadan. Content drafted by Rashid in the RN
// era (`content/ramadan/guidance.json`); engine model in
// `psychswitch_engine/lib/src/ramadan.dart`. This file is presentation
// only.
//
// Layout:
//   • Clinical-poster hero — moon-crescent icon + tagline + twin stats
//     (drugs covered · clinical principles).
//   • General principles bullets (collapsible-feel via tinted band).
//   • Drug list — search-filterable, each row a tappable card showing
//     dose recommendation chip + rationale + special note.
//
// The drug list rows route to the drug profile when tapped (we wire
// that in the next pass once entry points are unified).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/ramadan.dart';

class RamadanScreen extends ConsumerStatefulWidget {
  const RamadanScreen({super.key});

  @override
  ConsumerState<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends ConsumerState<RamadanScreen> {
  final _searchCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ramadanDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halal & Ramadan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (data) {
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? data.drugs
                : data.drugs.where((d) {
                    return d.name.toLowerCase().contains(q) ||
                        d.id.toLowerCase().contains(q);
                  }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                ClinicalSpace.lg + 4,
                ClinicalSpace.lg,
                ClinicalSpace.lg + 4,
                ClinicalSpace.xl,
              ),
              children: <Widget>[
                _RamadanHero(
                  totalDrugs: data.drugs.length,
                  principles: data.generalPrinciples.length,
                  rationale: data.rationale,
                ),
                const Gap.v(ClinicalSpace.lg),
                _PrinciplesCard(principles: data.generalPrinciples),
                const Gap.v(ClinicalSpace.lg),
                // ── Search bar ───────────────────────────────────────
                _SearchField(
                  controller: _searchCtl,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const Gap.v(ClinicalSpace.md),
                // ── Drug rows ────────────────────────────────────────
                const Text(
                  'DRUG-SPECIFIC GUIDANCE',
                  style: ClinicalText.eyebrow,
                ),
                const Gap.v(ClinicalSpace.sm),
                if (filtered.isEmpty)
                  _EmptyResults(query: _query.trim())
                else
                  for (final d in filtered) ...<Widget>[
                    _RamadanDrugCard(drug: d),
                    const Gap.v(ClinicalSpace.sm),
                  ],
                const Gap.v(ClinicalSpace.lg),
                const _FooterNote(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────

class _RamadanHero extends StatelessWidget {
  const _RamadanHero({
    required this.totalDrugs,
    required this.principles,
    required this.rationale,
  });

  final int totalDrugs;
  final int principles;
  final String rationale;

  // Strip the engine-internal audit suffix before display.
  String _cleanRationale(String r) =>
      r.replaceAll(RegExp(r'\s*PENDING_CLINICAL_REVIEW.*$'), '').trim();

  @override
  Widget build(BuildContext context) {
    const tone = ClinicalPalette.toneMintInk; // calm green for Ramadan
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Identity band.
          Container(
            color: tone.withValues(alpha: 0.08),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.md - 2,
              ClinicalSpace.md + 2,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.36),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                  ),
                  child: const Icon(
                    Icons.dark_mode_outlined,
                    size: 19,
                    color: tone,
                  ),
                ),
                const Gap.h(ClinicalSpace.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Halal & Ramadan',
                        style: TextStyle(
                          color: ClinicalPalette.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      Gap.v(ClinicalSpace.xs - 1),
                      Text(
                        'Suhoor · Iftar dose-timing guidance',
                        style: TextStyle(
                          color: ClinicalPalette.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.lg,
              ClinicalSpace.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _MiniStat(
                    eyebrow: 'DRUGS COVERED',
                    value: '$totalDrugs',
                    unit: totalDrugs == 1 ? 'drug' : 'drugs',
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 36,
                  color: ClinicalPalette.border.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: _MiniStat(
                    eyebrow: 'GENERAL PRINCIPLES',
                    value: '$principles',
                    unit: principles == 1 ? 'point' : 'points',
                  ),
                ),
              ],
            ),
          ),
          // Rationale band.
          Container(
            color: ClinicalPalette.bg.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
            ),
            child: Text(
              _cleanRationale(rationale),
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.eyebrow,
    required this.value,
    required this.unit,
  });

  final String eyebrow;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: const TextStyle(
              color: ClinicalPalette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  color: ClinicalPalette.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.05,
                  fontFeatures: <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: ClinicalPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Principles ──────────────────────────────────────────────────────

class _PrinciplesCard extends StatelessWidget {
  const _PrinciplesCard({required this.principles});

  final List<String> principles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'GENERAL PRINCIPLES',
            style: ClinicalText.eyebrow.copyWith(color: ClinicalPalette.toneMintInk),
          ),
          const Gap.v(ClinicalSpace.sm + 2),
          for (var i = 0; i < principles.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                color: ClinicalPalette.border.withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(vertical: ClinicalSpace.sm),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: const BoxDecoration(
                    color: ClinicalPalette.toneMintInk,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap.h(ClinicalSpace.sm + 2),
                Expanded(
                  child: Text(
                    principles[i],
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Search ──────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search drugs',
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: ClinicalPalette.muted,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: ClinicalPalette.muted,
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClinicalSpace.xl),
      child: Center(
        child: Text(
          query.isEmpty
              ? 'No drugs in the Ramadan registry yet.'
              : 'No matches for "$query".',
          style: ClinicalText.caption.copyWith(height: 1.55),
        ),
      ),
    );
  }
}

// ── Per-drug card ───────────────────────────────────────────────────

class _RamadanDrugCard extends StatelessWidget {
  const _RamadanDrugCard({required this.drug});

  final RamadanDrug drug;

  Color _recoTone(RamadanRecommendation r) {
    switch (r) {
      case RamadanRecommendation.suhoor:
        return ClinicalPalette.toneLavenderInk;
      case RamadanRecommendation.iftar:
        return ClinicalPalette.accent;
      case RamadanRecommendation.suhoorOrIftar:
        return ClinicalPalette.mutedStrong;
      case RamadanRecommendation.suhoorAndIftar:
      case RamadanRecommendation.iftarOrSuhoorAndIftar:
      case RamadanRecommendation.suhoorAndIftarOrIftar:
        return ClinicalPalette.accent;
      case RamadanRecommendation.discussWithTeam:
        return ClinicalPalette.warning;
    }
  }

  IconData _recoIcon(RamadanRecommendation r) {
    switch (r) {
      case RamadanRecommendation.suhoor:
        return Icons.wb_twilight_rounded; // pre-dawn
      case RamadanRecommendation.iftar:
        return Icons.nights_stay_outlined; // dusk
      case RamadanRecommendation.suhoorOrIftar:
        return Icons.swap_horiz_rounded;
      case RamadanRecommendation.suhoorAndIftar:
      case RamadanRecommendation.iftarOrSuhoorAndIftar:
      case RamadanRecommendation.suhoorAndIftarOrIftar:
        return Icons.repeat_rounded;
      case RamadanRecommendation.discussWithTeam:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _recoTone(drug.recommendation);
    return Material(
      color: ClinicalPalette.surface,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(hapticsTap());
          context.pushNamed(
            Routes.drugProfile,
            pathParameters: <String, String>{'id': drug.id},
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: ClinicalPalette.border.withValues(alpha: 0.7),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(ClinicalRadii.tile),
          ),
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg - 2,
            ClinicalSpace.md + 2,
            ClinicalSpace.lg - 2,
            ClinicalSpace.md + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Row 1: drug name + dosing chip + recommendation chip.
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      drug.name,
                      style: const TextStyle(
                        color: ClinicalPalette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const Gap.h(ClinicalSpace.sm),
                  _DosingChip(text: prettifyDosing(drug.dosing)),
                ],
              ),
              const Gap.v(ClinicalSpace.sm + 2),
              // Row 2: recommendation chip (full-width-ish).
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm + 2,
                  vertical: ClinicalSpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.32),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(_recoIcon(drug.recommendation), size: 13, color: tone),
                    const Gap.h(ClinicalSpace.xs + 2),
                    Text(
                      drug.recommendation.label.toUpperCase(),
                      style: TextStyle(
                        color: tone,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap.v(ClinicalSpace.sm + 2),
              // Rationale body.
              Text(
                drug.rationale,
                style: ClinicalText.caption.copyWith(height: 1.55),
              ),
              if (drug.specialNote.isNotEmpty) ...<Widget>[
                const Gap.v(ClinicalSpace.sm),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    ClinicalSpace.sm + 2,
                    ClinicalSpace.xs + 2,
                    ClinicalSpace.sm + 2,
                    ClinicalSpace.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: ClinicalPalette.bg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: ClinicalPalette.mutedStrong,
                      ),
                      const Gap.h(ClinicalSpace.xs + 2),
                      Expanded(
                        child: Text(
                          drug.specialNote,
                          style: const TextStyle(
                            color: ClinicalPalette.mutedStrong,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DosingChip extends StatelessWidget {
  const _DosingChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ClinicalPalette.bg.withValues(alpha: 0.6),
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ClinicalPalette.mutedStrong,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClinicalSpace.lg),
        child: Text(
          'Guidance is general. Always individualise: clinical state, '
          'religious practice, local fast duration, and patient preference '
          'shape the final plan.',
          style: ClinicalText.caption.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
