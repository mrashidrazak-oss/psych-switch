// QTc Stacker — multi-select drug list → aggregate cumulative QTc
// risk + management recommendations. RN parity:
// `screens/QtcStackerScreen.tsx`.
//
// Engine: psychswitch_engine/qtc_stacker.dart `assessQtcRisk(ids, data)`.
// Risk scoring is in the engine (known × 3, conditional × 2,
// possible × 1, threshold tiers); we only render.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/qtc_stacker.dart';

const List<String> _categoryOrder = <String>[
  'antipsychotic',
  'antidepressant',
  'mood-stabilizer',
  'antibiotic',
  'other',
];

const Map<String, String> _categoryLabel = <String, String>{
  'antipsychotic': 'ANTIPSYCHOTICS',
  'antidepressant': 'ANTIDEPRESSANTS',
  'mood-stabilizer': 'MOOD STABILIZERS',
  'antibiotic': 'ANTIBIOTICS',
  'other': 'OTHER (ANTIEMETICS, OPIOIDS)',
};

Color _toneFor(QtcCategory c) {
  switch (c) {
    case QtcCategory.known:
      return ClinicalPalette.danger;
    case QtcCategory.conditional:
      return ClinicalPalette.warning;
    case QtcCategory.possible:
      return ClinicalPalette.accent;
    case QtcCategory.low:
      return ClinicalPalette.muted;
  }
}

Color _riskTone(OverallRisk r) {
  switch (r) {
    case OverallRisk.none:
    case OverallRisk.low:
      return ClinicalPalette.toneMintInk;
    case OverallRisk.moderate:
      return ClinicalPalette.warning;
    case OverallRisk.high:
    case OverallRisk.veryHigh:
      return ClinicalPalette.danger;
  }
}

String _riskLabel(OverallRisk r) {
  switch (r) {
    case OverallRisk.none:
      return 'No significant QTc risk';
    case OverallRisk.low:
      return 'Low QTc risk';
    case OverallRisk.moderate:
      return 'Moderate QTc risk — ECG recommended';
    case OverallRisk.high:
      return 'HIGH QTc risk — ECG REQUIRED';
    case OverallRisk.veryHigh:
      return 'VERY HIGH QTc risk — cardiology input';
  }
}

class QtcStackerScreen extends ConsumerStatefulWidget {
  const QtcStackerScreen({super.key});

  @override
  ConsumerState<QtcStackerScreen> createState() => _QtcStackerScreenState();
}

class _QtcStackerScreenState extends ConsumerState<QtcStackerScreen> {
  final Set<String> _selected = <String>{};
  bool _showResult = false;

  void _toggle(String id) {
    unawaited(hapticsTap());
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _showResult = false;
    });
  }

  void _onAssessPressed() {
    if (_selected.isEmpty) return;
    unawaited(hapticsConfirm());
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(qtcDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QTc stacker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: asyncData.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (data) {
            final assessment =
                assessQtcRisk(_selected.toList(), data);
            final grouped = <String, List<QtcDrugEntry>>{};
            for (final d in data.drugs) {
              grouped.putIfAbsent(d.category, () => <QtcDrugEntry>[]).add(d);
            }

            final totalDrugs = data.drugs.length;
            return Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    ClinicalSpace.lg + 4,
                    ClinicalSpace.lg,
                    ClinicalSpace.lg + 4,
                    ClinicalSpace.xxxl + ClinicalSpace.lg, // room for FAB
                  ),
                  children: <Widget>[
                    // ── Hero header — same clinical-poster chrome as
                    //     the Result, Clozapine and Depot heros.
                    _QtcHeroHeader(
                      totalDrugs: totalDrugs,
                      selectedCount: _selected.length,
                    ),
                    const Gap.v(ClinicalSpace.lg),

                    // Risk legend.
                    const _RiskLegend(),
                    const Gap.v(ClinicalSpace.lg),

                    for (final cat in _categoryOrder) ...<Widget>[
                      if (grouped[cat]?.isNotEmpty ?? false) ...<Widget>[
                        Text(
                          _categoryLabel[cat] ?? cat.toUpperCase(),
                          style: ClinicalText.eyebrow,
                        ),
                        const Gap.v(ClinicalSpace.sm),
                        _DrugGroup(
                          drugs: grouped[cat]!,
                          selected: _selected,
                          onToggle: _toggle,
                        ),
                        const Gap.v(ClinicalSpace.lg),
                      ],
                    ],

                    if (_showResult && _selected.isNotEmpty) ...<Widget>[
                      _AssessmentCard(assessment: assessment),
                      const Gap.v(ClinicalSpace.md),
                      // Per-drug notes for selected drugs with non-low risk.
                      for (final d in assessment.selectedDrugs
                          .where((d) => d.qtcCategory != QtcCategory.low))
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: ClinicalSpace.sm,
                          ),
                          child: _DrugNoteCard(drug: d),
                        ),
                      const Gap.v(ClinicalSpace.md),
                    ],

                    // Source.
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        ClinicalSpace.lg - 2,
                        ClinicalSpace.md + 2,
                        ClinicalSpace.lg - 2,
                        ClinicalSpace.md + 2,
                      ),
                      decoration: BoxDecoration(
                        color: ClinicalPalette.surface,
                        border: Border.all(
                          color: ClinicalPalette.border.withValues(alpha: 0.7),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'DATA SOURCE',
                            style: ClinicalText.eyebrow,
                          ),
                          const Gap.v(ClinicalSpace.sm),
                          for (var i = 0;
                              i < data.citations.take(2).length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '[${i + 1}] ${data.citations[i]}',
                                style: const TextStyle(
                                  color: ClinicalPalette.text,
                                  fontSize: 12.5,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          const Gap.v(ClinicalSpace.xs),
                          Text(
                            'Reviewed by: ${data.reviewedBy}',
                            style: ClinicalText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating Assess button.
                Positioned(
                  left: ClinicalSpace.lg,
                  right: ClinicalSpace.lg,
                  bottom: ClinicalSpace.lg,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : _onAssessPressed,
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        _selected.isEmpty
                            ? 'Select drugs to assess'
                            : 'Assess ${_selected.length} drug'
                                '${_selected.length == 1 ? '' : 's'}',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  const _RiskLegend();

  static const _entries = <(QtcCategory, String)>[
    (QtcCategory.known, 'Known'),
    (QtcCategory.conditional, 'Conditional'),
    (QtcCategory.possible, 'Possible'),
    (QtcCategory.low, 'Low'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ClinicalSpace.md,
      runSpacing: ClinicalSpace.xs + 2,
      children: <Widget>[
        for (final (cat, label) in _entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _toneFor(cat),
                  shape: BoxShape.circle,
                ),
              ),
              const Gap.h(ClinicalSpace.xs + 2),
              Text(
                label,
                style: TextStyle(
                  color: _toneFor(cat),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DrugGroup extends StatelessWidget {
  const _DrugGroup({
    required this.drugs,
    required this.selected,
    required this.onToggle,
  });

  final List<QtcDrugEntry> drugs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < drugs.length; i++)
            _DrugRow(
              drug: drugs[i],
              isSelected: selected.contains(drugs[i].id),
              isLast: i == drugs.length - 1,
              onTap: () => onToggle(drugs[i].id),
            ),
        ],
      ),
    );
  }
}

class _DrugRow extends StatelessWidget {
  const _DrugRow({
    required this.drug,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  final QtcDrugEntry drug;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(drug.qtcCategory);
    return Material(
      color: isSelected
          ? ClinicalPalette.accent.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: ClinicalPalette.border.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.md + 2,
              vertical: ClinicalSpace.md - 2,
            ),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ClinicalPalette.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? ClinicalPalette.accent
                          : ClinicalPalette.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(ClinicalRadii.chip - 2),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const Gap.h(ClinicalSpace.md - 2),
                Expanded(
                  child: Text(
                    drug.name,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClinicalSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.16),
                    border: Border.all(color: tone.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(ClinicalRadii.pill),
                  ),
                  child: Text(
                    drug.qtcCategory.jsonValue.toUpperCase(),
                    style: TextStyle(
                      color: tone,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
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

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment});
  final QtcAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final tone = _riskTone(assessment.overallRisk);
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ClinicalPalette.surface,
          border: Border.all(
            color: ClinicalPalette.border.withValues(alpha: 0.7),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 6, color: tone),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ClinicalSpace.md + 2,
                    ClinicalSpace.md,
                    ClinicalSpace.md + 2,
                    ClinicalSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _riskLabel(assessment.overallRisk),
                        style: TextStyle(
                          color: tone,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Gap.v(ClinicalSpace.xs),
                      Text(
                        assessment.summary,
                        style: ClinicalText.caption.copyWith(height: 1.5),
                      ),
                      const Gap.v(ClinicalSpace.md),
                      const Text(
                        'RECOMMENDATIONS',
                        style: ClinicalText.eyebrow,
                      ),
                      const Gap.v(ClinicalSpace.xs + 2),
                      for (final r in assessment.recommendations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $r',
                            style: const TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
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

class _DrugNoteCard extends StatelessWidget {
  const _DrugNoteCard({required this.drug});
  final QtcDrugEntry drug;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(drug.qtcCategory);
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ClinicalPalette.surface,
          border: Border.all(
            color: ClinicalPalette.border.withValues(alpha: 0.7),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: tone),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ClinicalSpace.md + 2,
                    ClinicalSpace.md - 2,
                    ClinicalSpace.md + 2,
                    ClinicalSpace.md - 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text(
                            drug.name,
                            style: const TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap.h(ClinicalSpace.xs),
                          Text(
                            '(${drug.qtcCategory.jsonValue})',
                            style: TextStyle(
                              color: tone,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap.v(ClinicalSpace.xs),
                      Text(
                        drug.notes,
                        style: ClinicalText.caption.copyWith(height: 1.5),
                      ),
                    ],
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

/// Clinical-poster hero for the QTc stacker. Same chrome rhythm as
/// the Result, Clozapine, Depot heros — tone-tinted identity band
/// with the eyebrow + tagline, twin stat cells with a hairline rule,
/// and a tinted rationale band underneath.
class _QtcHeroHeader extends StatelessWidget {
  const _QtcHeroHeader({
    required this.totalDrugs,
    required this.selectedCount,
  });

  final int totalDrugs;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    const tone = ClinicalPalette.warning;
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
          // ── Identity band ─────────────────────────────────────
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
                    Icons.monitor_heart_outlined,
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
                        'QTc stacker',
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
                        'Cumulative QTc-prolongation risk',
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
          // ── Stats row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.lg,
              ClinicalSpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _QtcMiniStat(
                    eyebrow: 'CATALOGUE',
                    value: '$totalDrugs',
                    unit: 'drugs',
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 36,
                  color: ClinicalPalette.border.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: _QtcMiniStat(
                    eyebrow: 'SELECTED',
                    value: '$selectedCount',
                    unit: selectedCount == 1 ? 'drug' : 'drugs',
                    tone: selectedCount == 0
                        ? ClinicalPalette.muted
                        : ClinicalPalette.accent,
                  ),
                ),
              ],
            ),
          ),
          // ── Rationale band ────────────────────────────────────
          Container(
            color: ClinicalPalette.bg.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
            ),
            child: Text(
              'Tap every drug the patient is on. CredibleMeds-tiered '
              'risk × dose-additive scoring → aggregate ECG / cardiology '
              'recommendation. Tap Assess once selections are complete.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtcMiniStat extends StatelessWidget {
  const _QtcMiniStat({
    required this.eyebrow,
    required this.value,
    required this.unit,
    this.tone,
  });

  final String eyebrow;
  final String value;
  final String unit;
  final Color? tone;

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
                style: TextStyle(
                  color: tone ?? ClinicalPalette.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.05,
                  fontFeatures: const <FontFeature>[
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
