// Specialty-depth card — surfaces pregnancy / breastfeeding /
// pediatric / geriatric recommendations on the Result screen.
//
// Renders nothing unless at least one specialty is active for the
// current patient context (set via the PatientContext sheet on
// Switch). When active, this card dominates visual weight because
// these subgroups are exactly where general-purpose switching tools
// fail.
//
// RN parity: `components/SpecialtyDepthCard.tsx`.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/specialty.dart';

class SpecialtyDepthCard extends StatefulWidget {
  const SpecialtyDepthCard({required this.assessment, super.key});

  final SpecialtyAssessment assessment;

  @override
  State<SpecialtyDepthCard> createState() => _SpecialtyDepthCardState();
}

class _SpecialtyDepthCardState extends State<SpecialtyDepthCard> {
  bool _expanded = false;

  static const Map<Specialty, IconData> _icon = <Specialty, IconData>{
    Specialty.pregnancy: Icons.favorite_outline,
    Specialty.breastfeeding: Icons.child_care_outlined,
    Specialty.pediatric: Icons.auto_awesome,
    Specialty.geriatric: Icons.shield_outlined,
  };

  static const Map<Specialty, Color> _tint = <Specialty, Color>{
    Specialty.pregnancy: ClinicalPalette.danger,
    Specialty.breastfeeding: Color(0xFFA78BFA),
    Specialty.pediatric: ClinicalPalette.toneMintInk,
    Specialty.geriatric: ClinicalPalette.warning,
  };

  Color _toneFor(SpecialtyTier t) {
    switch (t) {
      case SpecialtyTier.preferred:
        return ClinicalPalette.toneMintInk;
      case SpecialtyTier.acceptable:
        return ClinicalPalette.accent;
      case SpecialtyTier.caution:
        return ClinicalPalette.warning;
      case SpecialtyTier.avoid:
        return ClinicalPalette.danger;
    }
  }

  String _tierLabel(SpecialtyTier t) {
    switch (t) {
      case SpecialtyTier.preferred:
        return 'Preferred';
      case SpecialtyTier.acceptable:
        return 'Acceptable';
      case SpecialtyTier.caution:
        return 'Caution';
      case SpecialtyTier.avoid:
        return 'Avoid';
    }
  }

  int _tierRank(SpecialtyTier t) {
    switch (t) {
      case SpecialtyTier.avoid:
        return 0;
      case SpecialtyTier.caution:
        return 1;
      case SpecialtyTier.acceptable:
        return 2;
      case SpecialtyTier.preferred:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assessment;
    if (a.applicable.isEmpty || a.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = <Specialty, List<SpecialtyRecommendation>>{};
    for (final r in a.recommendations) {
      grouped.putIfAbsent(r.specialty, () => <SpecialtyRecommendation>[]).add(r);
    }

    // Hero tint = worst tier across all recs.
    final worstTier = a.recommendations
        .map((r) => r.tier)
        .reduce((acc, t) => _tierRank(t) < _tierRank(acc) ? t : acc);
    final heroTone = _toneFor(worstTier);
    final heroSpecialty = a.applicable.first;

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: heroTone.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                  ClinicalSpace.md + 2,
                  ClinicalSpace.md - 2,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _tint[heroSpecialty]!.withValues(alpha: 0.16),
                        border: Border.all(
                          color:
                              _tint[heroSpecialty]!.withValues(alpha: 0.3),
                        ),
                        borderRadius:
                            BorderRadius.circular(ClinicalRadii.chip + 2),
                      ),
                      child: Icon(
                        _icon[heroSpecialty],
                        size: 16,
                        color: _tint[heroSpecialty],
                      ),
                    ),
                    const Gap.h(ClinicalSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Specialty considerations',
                            style: TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap.v(2),
                          Text(
                            a.headline,
                            style: TextStyle(
                              color: heroTone,
                              fontSize: 11,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: ClinicalPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(height: 1),
                      for (final sp in a.applicable)
                        if ((grouped[sp] ?? const <SpecialtyRecommendation>[])
                            .isNotEmpty)
                          _SpecialtyGroup(
                            specialty: sp,
                            tint: _tint[sp]!,
                            recs: grouped[sp]!,
                            toneFor: _toneFor,
                            tierLabel: _tierLabel,
                          ),
                      Container(
                        color: ClinicalPalette.bg.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClinicalSpace.md + 2,
                          vertical: ClinicalSpace.sm,
                        ),
                        child: Text(
                          'Tiers (best → worst): preferred · acceptable · '
                          'caution · avoid. Drawn from Maudsley 15th, NICE '
                          'perinatal NG192, Beers 2023, FDA labelling.',
                          style: ClinicalText.caption.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyGroup extends StatelessWidget {
  const _SpecialtyGroup({
    required this.specialty,
    required this.tint,
    required this.recs,
    required this.toneFor,
    required this.tierLabel,
  });

  final Specialty specialty;
  final Color tint;
  final List<SpecialtyRecommendation> recs;
  final Color Function(SpecialtyTier) toneFor;
  final String Function(SpecialtyTier) tierLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: ClinicalPalette.bg.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md + 2,
            vertical: ClinicalSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap.h(ClinicalSpace.sm),
              Text(
                specialtyLabel(specialty).toUpperCase(),
                style: ClinicalText.eyebrow,
              ),
            ],
          ),
        ),
        for (var i = 0; i < recs.length; i++)
          _RecommendationRow(
            rec: recs[i],
            isLast: i == recs.length - 1,
            tone: toneFor(recs[i].tier),
            tierLabel: tierLabel(recs[i].tier),
          ),
      ],
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({
    required this.rec,
    required this.isLast,
    required this.tone,
    required this.tierLabel,
  });

  final SpecialtyRecommendation rec;
  final bool isLast;
  final Color tone;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: ClinicalPalette.border),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClinicalSpace.md + 2,
          ClinicalSpace.md - 2,
          ClinicalSpace.md + 2,
          ClinicalSpace.md - 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rec.drugName ?? rec.drugId,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap.v(2),
                  Text(
                    rec.rationale,
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                  if (rec.knownRisks != null) ...<Widget>[
                    const Gap.v(ClinicalSpace.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: ClinicalPalette.danger.withValues(alpha: 0.08),
                        border: const Border(
                          left: BorderSide(
                            color: ClinicalPalette.danger,
                            width: 2,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        ClinicalSpace.sm + 2,
                        ClinicalSpace.xs + 2,
                        ClinicalSpace.sm + 2,
                        ClinicalSpace.xs + 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'KNOWN RISKS',
                            style: ClinicalText.eyebrow.copyWith(
                              color: ClinicalPalette.danger,
                            ),
                          ),
                          const Gap.v(2),
                          Text(
                            rec.knownRisks!,
                            style: ClinicalText.caption.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (rec.doseFactor != null && rec.doseFactor! < 1) ...<Widget>[
                    const Gap.v(ClinicalSpace.xs + 2),
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          const TextSpan(text: 'Dose modifier: start at '),
                          TextSpan(
                            text:
                                '${(rec.doseFactor! * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ClinicalPalette.text,
                            ),
                          ),
                          const TextSpan(text: ' of adult target.'),
                        ],
                      ),
                      style: ClinicalText.caption,
                    ),
                  ],
                  if (rec.additionalMonitoring != null &&
                      rec.additionalMonitoring!.isNotEmpty) ...<Widget>[
                    const Gap.v(ClinicalSpace.xs + 2),
                    for (final m in rec.additionalMonitoring!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $m',
                          style: ClinicalText.caption.copyWith(height: 1.5),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const Gap.h(ClinicalSpace.md),
            StatusPill(label: tierLabel, tone: tone, compact: true),
          ],
        ),
      ),
    );
  }
}
