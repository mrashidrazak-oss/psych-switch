// Drug profile detail screen.
//
// One screen, one drug. Surfaces everything the registry knows about
// a single agent in scannable bands — pharmacokinetics, dose ladder,
// risk profile, CYP interactions, Malaysian formulations, citations.
// Reached by route name `Routes.drugProfile` with the drug id passed
// as a path param.
//
// Designed as the missing "drill in" from anywhere a drug name
// appears — switch picker, result hero, history cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

class DrugProfileScreen extends ConsumerWidget {
  const DrugProfileScreen({required this.drugId, super.key});

  final String drugId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) {
            final drug = engine.getDrug(drugId);
            if (drug == null) {
              return const _NotFoundView();
            }
            return _DrugProfileBody(drug: drug);
          },
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.xxl),
        child: Text(
          'Drug not in the registry.',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ),
    );
  }
}

class _DrugProfileBody extends StatelessWidget {
  const _DrugProfileBody({required this.drug});

  final Drug drug;

  Color _categoryTone() {
    switch (drug.category) {
      case DrugCategory.antidepressant:
        return AppColors.from;
      case DrugCategory.antipsychotic:
        return AppColors.to;
      case DrugCategory.moodStabilizer:
        return AppColors.warning;
      case null:
        return AppColors.muted;
    }
  }

  String _categoryLabel() {
    switch (drug.category) {
      case DrugCategory.antidepressant:
        return 'ANTIDEPRESSANT';
      case DrugCategory.antipsychotic:
        return drug.formulation == Formulation.lai
            ? 'ANTIPSYCHOTIC · LAI'
            : 'ANTIPSYCHOTIC';
      case DrugCategory.moodStabilizer:
        return 'MOOD STABILIZER';
      case null:
        return 'OTHER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _categoryTone();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg + 4,
        AppSpace.lg,
        AppSpace.lg + 4,
        AppSpace.xl,
      ),
      children: <Widget>[
        _IdentityCard(drug: drug, tone: tone, categoryLabel: _categoryLabel()),
        const Gap.v(AppSpace.lg),
        _PharmacokineticsCard(drug: drug),
        const Gap.v(AppSpace.lg),
        _DosingCard(drug: drug, tone: tone),
        const Gap.v(AppSpace.lg),
        _RiskProfileCard(drug: drug),
        const Gap.v(AppSpace.lg),
        if (drug.maoiClearanceDays != null ||
            (drug.isMAOI ?? false) ||
            drug.maoiWashout != null) ...<Widget>[
          _MaoiCard(drug: drug),
          const Gap.v(AppSpace.lg),
        ],
        _CypInteractionsCard(drug: drug),
        const Gap.v(AppSpace.lg),
        if (drug.malaysianBrandNames.isNotEmpty) ...<Widget>[
          _BrandsCard(brands: drug.malaysianBrandNames),
          const Gap.v(AppSpace.lg),
        ],
        if (drug.formulationNotes.isNotEmpty) ...<Widget>[
          _NoteCard(
            eyebrow: 'FORMULATION NOTES',
            body: drug.formulationNotes,
          ),
          const Gap.v(AppSpace.lg),
        ],
        if (drug.citations.isNotEmpty) ...<Widget>[
          _CitationsCard(citations: drug.citations),
          const Gap.v(AppSpace.lg),
        ],
        _ProvenanceFooter(drug: drug),
      ],
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────

/// Identity hero — clinical-poster style with tone-tinted band naming
/// the drug + class + category chip on the right.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.drug,
    required this.tone,
    required this.categoryLabel,
  });

  final Drug drug;
  final Color tone;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Identity band (tone-tinted).
          Container(
            color: tone.withValues(alpha: 0.08),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md + 2,
              AppSpace.md - 2,
              AppSpace.md + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: tone,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap.h(AppSpace.sm + 2),
                          Flexible(
                            child: Text(
                              drug.genericName,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap.v(AppSpace.xs - 1),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          drug.drugClass,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap.h(AppSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      color: tone,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacokineticsCard extends StatelessWidget {
  const _PharmacokineticsCard({required this.drug});

  final Drug drug;

  String _formatHl(num? n) {
    if (n == null) return '—';
    if (n is int || n == n.toInt()) return '${n.toInt()} h';
    return '${n.toStringAsFixed(1)} h';
  }

  @override
  Widget build(BuildContext context) {
    final h = drug.halfLife;
    final m = drug.activeMetabolite;
    final metabolitePresent = m.name != null && m.name!.isNotEmpty;
    return _Card(
      eyebrow: 'PHARMACOKINETICS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  eyebrow: 'MEAN HALF-LIFE',
                  value: _formatHl(h.meanHours),
                  subtitle: h.rangeHours.length >= 2
                      ? 'range ${_formatHl(h.rangeHours.first)} – '
                          '${_formatHl(h.rangeHours.last)}'
                      : null,
                ),
              ),
              Container(
                width: 0.5,
                height: 36,
                color: AppColors.border.withValues(alpha: 0.6),
              ),
              Expanded(
                child: _MiniStat(
                  eyebrow: 'ACTIVE METABOLITE',
                  value: metabolitePresent
                      ? '${m.name} · ${_formatHl(m.halfLifeHours)}'
                      : 'None',
                  subtitle: metabolitePresent
                      ? (m.clinicallySignificant
                          ? 'Clinically significant'
                          : 'Minor')
                      : null,
                ),
              ),
            ],
          ),
          if (h.notes != null && h.notes!.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.md),
            Text(
              h.notes!,
              style: AppTextSizes.caption.copyWith(height: 1.55),
            ),
          ],
          if (metabolitePresent &&
              m.notes != null &&
              m.notes!.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.sm),
            Text(
              m.notes!,
              style: AppTextSizes.caption.copyWith(height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _DosingCard extends StatelessWidget {
  const _DosingCard({required this.drug, required this.tone});

  final Drug drug;
  final Color tone;

  String _fmt(num n) {
    if (n is int || n == n.toInt()) return n.toInt().toString();
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final d = drug.dosing;
    final range = d.typicalTargetRangeMg;
    final rangeLabel = range.length >= 2
        ? '${_fmt(range.first)}–${_fmt(range.last)} mg/day'
        : '${_fmt(range.first)} mg/day';
    return _Card(
      eyebrow: 'DOSING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  eyebrow: 'TYPICAL TARGET',
                  value: rangeLabel,
                ),
              ),
              Container(
                width: 0.5,
                height: 36,
                color: AppColors.border.withValues(alpha: 0.6),
              ),
              Expanded(
                child: _MiniStat(
                  eyebrow: 'MAX',
                  value: '${_fmt(d.maxDoseMg)} mg/day',
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          const Text(
            'AVAILABLE INCREMENTS',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const Gap.v(AppSpace.xs + 2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final inc in d.increments)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.32),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '${_fmt(inc)} mg',
                    style: TextStyle(
                      color: tone,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (d.formulationsAvailableMy.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.md),
            const Text(
              'AVAILABLE IN MALAYSIA',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const Gap.v(AppSpace.xs + 2),
            for (final f in d.formulationsAvailableMy)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $f',
                  style: AppTextSizes.caption.copyWith(height: 1.55),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RiskProfileCard extends StatelessWidget {
  const _RiskProfileCard({required this.drug});

  final Drug drug;

  // ── Risk-row data ──────────────────────────────────────────────
  List<({String label, RiskLevel? level})> _rows() => <
      ({String label, RiskLevel? level})
    >[
      (label: 'EPS', level: drug.epsRisk),
      (
        label: 'Metabolic',
        level: drug.metabolicRisk?.score,
      ),
      (label: 'Prolactin', level: drug.prolactinRisk),
      (label: 'QTc', level: drug.qtcRisk),
      (label: 'Sedation', level: drug.sedation),
      (
        label: 'Discontinuation',
        level: drug.discontinuationSyndromeRisk?.score,
      ),
    ];

  @override
  Widget build(BuildContext context) {
    final rows = _rows().where((r) => r.level != null).toList();
    if (rows.isEmpty) {
      return _Card(
        eyebrow: 'RISK PROFILE',
        child: Text(
          'No quantitative risk profile in the registry yet.',
          style: AppTextSizes.caption.copyWith(height: 1.55),
        ),
      );
    }
    return _Card(
      eyebrow: 'RISK PROFILE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                color: AppColors.border.withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              ),
            _RiskRow(label: rows[i].label, level: rows[i].level!),
          ],
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.label, required this.level});

  final String label;
  final RiskLevel level;

  Color _toneFor(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return AppColors.to;
      case RiskLevel.lowModerate:
      case RiskLevel.moderate:
        return AppColors.accent;
      case RiskLevel.high:
        return AppColors.warning;
      case RiskLevel.veryHigh:
        return AppColors.danger;
    }
  }

  double _fraction(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return 0.2;
      case RiskLevel.lowModerate:
        return 0.4;
      case RiskLevel.moderate:
        return 0.55;
      case RiskLevel.high:
        return 0.8;
      case RiskLevel.veryHigh:
        return 1;
    }
  }

  String _label(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.lowModerate:
        return 'LOW–MOD';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.veryHigh:
        return 'VERY HIGH';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(level);
    final frac = _fraction(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Text(
              _label(level),
              style: TextStyle(
                color: tone,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.xs + 1),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: <Widget>[
              Container(
                height: 4,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              AnimatedFractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: frac,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaoiCard extends StatelessWidget {
  const _MaoiCard({required this.drug});

  final Drug drug;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (drug.isMAOI ?? false) {
      lines.add(
        'Monoamine-oxidase inhibitor. Mandatory washout before / after '
        'serotonergic agents.',
      );
    }
    if (drug.maoiClearanceDays != null) {
      lines.add(
        'Clearance: ${drug.maoiClearanceDays} days before introducing '
        'a serotonergic agent.',
      );
    }
    if (drug.maoiWashout != null) {
      final w = drug.maoiWashout!;
      lines
        ..add(
          'Wait ${w.daysOffBeforeMAOI} days off this drug before '
          'starting an MAOI.',
        )
        ..add(
          'Wait ${w.daysOffAfterMAOI} days off an MAOI before starting '
          'this drug.',
        );
      if (w.notes.isNotEmpty) {
        lines.add(w.notes);
      }
    }
    return _Card(
      eyebrow: 'MAOI / WASHOUT',
      tone: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: Text(
                      l,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CypInteractionsCard extends StatelessWidget {
  const _CypInteractionsCard({required this.drug});

  final Drug drug;

  @override
  Widget build(BuildContext context) {
    final c = drug.cypInteractions;
    final entries = <(String, List<String>)>[
      ('Substrate of', c.substrateOf),
      ('Inhibitor of', c.inhibitorOf),
    ];
    final any = entries.any((e) => e.$2.isNotEmpty);
    if (!any) {
      return _Card(
        eyebrow: 'CYP INTERACTIONS',
        child: Text(
          'No documented CYP interactions in the registry.',
          style: AppTextSizes.caption.copyWith(height: 1.55),
        ),
      );
    }
    return _Card(
      eyebrow: 'CYP INTERACTIONS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < entries.length; i++)
            if (entries[i].$2.isNotEmpty) ...<Widget>[
              if (i > 0 && entries[i - 1].$2.isNotEmpty)
                Container(
                  height: 0.5,
                  color: AppColors.border.withValues(alpha: 0.5),
                  margin: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 88,
                    child: Text(
                      entries[i].$1.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final cyp in entries[i].$2)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              cyp,
                              style: const TextStyle(
                                color: AppColors.mutedStrong,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                      ],
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

class _BrandsCard extends StatelessWidget {
  const _BrandsCard({required this.brands});

  final List<String> brands;

  @override
  Widget build(BuildContext context) {
    return _Card(
      eyebrow: 'MALAYSIAN BRAND NAMES',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final b in brands)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                  width: 0.5,
                ),
              ),
              child: Text(
                b,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CitationsCard extends StatelessWidget {
  const _CitationsCard({required this.citations});

  final List<String> citations;

  @override
  Widget build(BuildContext context) {
    return _Card(
      eyebrow: 'CITATIONS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final c in citations)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $c',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.55,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProvenanceFooter extends StatelessWidget {
  const _ProvenanceFooter({required this.drug});

  final Drug drug;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Reviewed ${drug.lastReviewedISO} · ${drug.reviewedBy}',
        style: AppTextSizes.micro.copyWith(height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.eyebrow, required this.body});

  final String eyebrow;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Card(
      eyebrow: eyebrow,
      child: Text(
        body,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Shared chrome ─────────────────────────────────────────────────────

/// Plain card with eyebrow + child. Hairline border + AppRadii.lg+2.
class _Card extends StatelessWidget {
  const _Card({required this.eyebrow, required this.child, this.tone});

  final String eyebrow;
  final Widget child;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final eyebrowColor = tone ?? AppColors.muted;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: (tone ?? AppColors.border).withValues(
            alpha: tone == null ? 0.7 : 0.36,
          ),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg - 2,
        AppSpace.md + 2,
        AppSpace.lg - 2,
        AppSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: TextStyle(
              color: eyebrowColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const Gap.v(AppSpace.sm + 2),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.eyebrow,
    required this.value,
    this.subtitle,
  });

  final String eyebrow;
  final String value;
  final String? subtitle;

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
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              height: 1.25,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
