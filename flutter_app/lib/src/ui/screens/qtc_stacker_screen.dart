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
      return AppColors.danger;
    case QtcCategory.conditional:
      return AppColors.warning;
    case QtcCategory.possible:
      return AppColors.accent;
    case QtcCategory.low:
      return AppColors.muted;
  }
}

Color _riskTone(OverallRisk r) {
  switch (r) {
    case OverallRisk.none:
    case OverallRisk.low:
      return AppColors.to;
    case OverallRisk.moderate:
      return AppColors.warning;
    case OverallRisk.high:
    case OverallRisk.veryHigh:
      return AppColors.danger;
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

            return Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg + 4,
                    AppSpace.lg,
                    AppSpace.lg + 4,
                    AppSpace.xxxl + AppSpace.lg, // room for FAB
                  ),
                  children: <Widget>[
                    Text(
                      'Select all current medications. Tap '
                      'Assess to get the aggregate QTc risk and '
                      'recommendations.',
                      style: AppTextSizes.caption.copyWith(height: 1.55),
                    ),
                    const Gap.v(AppSpace.md),

                    // Risk legend.
                    const _RiskLegend(),
                    const Gap.v(AppSpace.lg),

                    for (final cat in _categoryOrder) ...<Widget>[
                      if (grouped[cat]?.isNotEmpty ?? false) ...<Widget>[
                        Text(
                          _categoryLabel[cat] ?? cat.toUpperCase(),
                          style: AppTextSizes.eyebrow,
                        ),
                        const Gap.v(AppSpace.sm),
                        _DrugGroup(
                          drugs: grouped[cat]!,
                          selected: _selected,
                          onToggle: _toggle,
                        ),
                        const Gap.v(AppSpace.lg),
                      ],
                    ],

                    if (_showResult && _selected.isNotEmpty) ...<Widget>[
                      _AssessmentCard(assessment: assessment),
                      const Gap.v(AppSpace.md),
                      // Per-drug notes for selected drugs with non-low risk.
                      for (final d in assessment.selectedDrugs
                          .where((d) => d.qtcCategory != QtcCategory.low))
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpace.sm,
                          ),
                          child: _DrugNoteCard(drug: d),
                        ),
                      const Gap.v(AppSpace.md),
                    ],

                    // Source.
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md + 2,
                        AppSpace.md,
                        AppSpace.md + 2,
                        AppSpace.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'DATA SOURCE',
                            style: AppTextSizes.eyebrow,
                          ),
                          const Gap.v(AppSpace.xs),
                          for (var i = 0;
                              i < data.citations.take(2).length;
                              i++)
                            Text(
                              '[${i + 1}] ${data.citations[i]}',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          const Gap.v(AppSpace.xs),
                          Text(
                            'Reviewed by: ${data.reviewedBy}',
                            style: AppTextSizes.micro,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating Assess button.
                Positioned(
                  left: AppSpace.lg,
                  right: AppSpace.lg,
                  bottom: AppSpace.lg,
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
      spacing: AppSpace.md,
      runSpacing: AppSpace.xs + 2,
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
              const Gap.h(AppSpace.xs + 2),
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
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
          ? AppColors.accent.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md + 2,
              vertical: AppSpace.md - 2,
            ),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const Gap.h(AppSpace.md - 2),
                Expanded(
                  child: Text(
                    drug.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.16),
                    border: Border.all(color: tone.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
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
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 6, color: tone),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md + 2,
                    AppSpace.md,
                    AppSpace.md + 2,
                    AppSpace.md,
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
                      const Gap.v(AppSpace.xs),
                      Text(
                        assessment.summary,
                        style: AppTextSizes.micro.copyWith(height: 1.5),
                      ),
                      const Gap.v(AppSpace.md),
                      const Text(
                        'RECOMMENDATIONS',
                        style: AppTextSizes.eyebrow,
                      ),
                      const Gap.v(AppSpace.xs + 2),
                      for (final r in assessment.recommendations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $r',
                            style: const TextStyle(
                              color: AppColors.text,
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
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: tone),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md + 2,
                    AppSpace.md - 2,
                    AppSpace.md + 2,
                    AppSpace.md - 2,
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
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap.h(AppSpace.xs),
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
                      const Gap.v(AppSpace.xs),
                      Text(
                        drug.notes,
                        style: AppTextSizes.micro.copyWith(height: 1.5),
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
