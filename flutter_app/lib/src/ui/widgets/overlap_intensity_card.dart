// Overlap-intensity card — surfaces the clinical concern about co-
// prescribing the FROM and TO drugs during the cross-titration window.
//
// "Cross-taper" in Maudsley 15th ed. ch.3 explicitly allows co-pres-
// cribing two drugs while reducing one and increasing the other. The
// clinical question is HOW MUCH overlap, for HOW LONG, and between
// which receptor profiles. This card answers that question.
//
// The engine (`psychswitch_engine/overlap_intensity.dart`) computes
// a 0–100 score from:
//   • Day-1 dose intensity (fraction of typical target for each drug)
//   • Co-prescription duration (days where both > 0)
//   • Mechanism multiplier (serotonergic stacking, QTc additive,
//     sedation additive, EPS additive, anticholinergic burden)
//
// The UI surfaces:
//   1. Tone-tinted progress bar with the score and tier label.
//   2. Engine's plain-English rationale.
//   3. Each mechanism flag as a chip + its specific clinical concern
//      (what to monitor, when, why) — the senior-physician handoff.
//   4. Component breakdown so the assessment is auditable.

import 'package:flutter/material.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/overlap_intensity.dart';

class OverlapIntensityCard extends StatelessWidget {
  const OverlapIntensityCard({required this.assessment, super.key});

  final OverlapAssessment assessment;

  /// Pick the design-token tone for a tier — green / blue / amber / red.
  static Color _toneFor(OverlapTier t) => switch (t) {
        OverlapTier.low => AppColors.to,
        OverlapTier.moderate => AppColors.accent,
        OverlapTier.high => AppColors.warning,
        OverlapTier.severe => AppColors.danger,
      };

  /// Per-mechanism clinical reasoning — what to monitor, why it
  /// matters, and the actionable handoff. The engine produces the
  /// FLAG tag; the UI is the place that decides how to talk to the
  /// clinician about it.
  static String _clinicalConcernFor(String flag) => switch (flag) {
        'serotonergic_stacking' =>
          'Two serotonergic drugs co-prescribed raise the risk of '
              'serotonin syndrome on overlap days. Counsel patient on '
              'red flags: tremor, hyperreflexia, clonus, hyperthermia, '
              'autonomic instability, agitation. Lowest risk if both '
              'agents stay at conservative doses through the overlap '
              'window. Document baseline at Day 1 and reassess at the '
              'midpoint of the taper.',
        'qt_additive' =>
          'Both agents prolong QTc additively. Obtain a baseline ECG '
              'before initiating overlap if patient has cardiac history, '
              'electrolyte derangement, or pre-existing QTc > 450 ms. '
              'Repeat ECG at peak overlap (typically Day 4–7). Correct '
              'K+ and Mg2+ proactively. Avoid further QT-prolonging '
              'co-prescriptions (azoles, macrolides, ondansetron) during '
              'this window.',
        'sedation_additive' =>
          'Sedation compounds during overlap. Counsel on driving, '
              'machinery, and falls risk — especially in patients over '
              '65 or on concomitant anxiolytics. Consider asymmetric '
              'dosing (e.g. one drug nocte) to spread the peak sedative '
              'load across the day. Review at Day 3 and Day 7.',
        'eps_additive' =>
          'Compounded D2-blockade raises extrapyramidal risk during '
              'overlap. Lower threshold to start anticholinergic cover '
              '(procyclidine, benztropine) if early EPS signs emerge. '
              'Examine for cogwheel rigidity, akathisia, and tongue '
              'fasciculations at every visit through the taper.',
        'anticholinergic_burden' =>
          'Compounded anticholinergic load — watch confusion (especially '
              'in patients over 65 and those with cognitive impairment), '
              'urinary retention, constipation, dry mouth, blurred '
              'vision. Avoid additional anticholinergics during the '
              'overlap. Reassess MMSE / MoCA at midpoint if baseline '
              'cognition is borderline.',
        _ => '',
      };

  String _localTierLabel() => switch (assessment.tier) {
        OverlapTier.low => 'Low overlap',
        OverlapTier.moderate => 'Moderate overlap',
        OverlapTier.high => 'High overlap',
        OverlapTier.severe => 'Severe overlap',
      };

  @override
  Widget build(BuildContext context) {
    // Engine emits an "empty" assessment when there are no overlap
    // days at all (direct switch, washout). Self-hide rather than
    // pollute the result with an empty "0/100, no overlap" card.
    if (assessment.label == 'No overlap' && assessment.score == 0) {
      return const SizedBox.shrink();
    }
    final tone = _toneFor(assessment.tier);
    final fraction = (assessment.score / 100).clamp(0, 1).toDouble();
    final overlapDays = assessment.components.overlapDays;
    final from = assessment.components.day1FromFraction;
    final to = assessment.components.day1ToFraction;
    final mult = assessment.components.mechanismMultiplier;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg - 2,
        AppSpace.md + 2,
        AppSpace.lg - 2,
        AppSpace.lg - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Eyebrow + score ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text('OVERLAP INTENSITY', style: AppTextSizes.eyebrow),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: assessment.score.toString(),
                      style: TextStyle(
                        color: tone,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const TextSpan(
                      text: ' /100',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: <Widget>[
                Container(
                  height: 5,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                AnimatedFractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(AppSpace.lg - 2),
          // ── Tier label ──────────────────────────────────────────
          Text(
            _localTierLabel().toUpperCase(),
            style: TextStyle(
              color: tone,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Gap.v(AppSpace.sm + 2),
          // ── Engine rationale (plain English how-derived) ────────
          Text(
            assessment.rationale,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          // ── Mechanism flags + per-flag clinical reasoning ───────
          if (assessment.flags.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.lg - 2),
            Container(
              height: 0.5,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            const Gap.v(AppSpace.md + 2),
            Text(
              'CLINICAL REASONING',
              style: AppTextSizes.eyebrow.copyWith(color: tone),
            ),
            const Gap.v(AppSpace.sm + 2),
            for (var i = 0; i < assessment.flags.length; i++) ...<Widget>[
              if (i > 0) const Gap.v(AppSpace.md + 2),
              _MechanismRow(
                flag: assessment.flags[i],
                tone: tone,
                concern: _clinicalConcernFor(assessment.flags[i]),
              ),
            ],
          ],
          // ── Component breakdown ─────────────────────────────────
          const Gap.v(AppSpace.lg - 2),
          Container(
            height: 0.5,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          const Gap.v(AppSpace.md + 2),
          _StatRow(
            label: 'Overlap window',
            value: '$overlapDays day${overlapDays == 1 ? '' : 's'}',
          ),
          const Gap.v(AppSpace.sm),
          _StatRow(
            label: 'Day 1 from-dose',
            value: '${(from * 100).round()}% of target',
          ),
          const Gap.v(AppSpace.sm),
          _StatRow(
            label: 'Day 1 to-dose',
            value: '${(to * 100).round()}% of target',
          ),
          const Gap.v(AppSpace.sm),
          _StatRow(
            label: 'Mechanism multiplier',
            value: '${mult.toStringAsFixed(1)}×',
          ),
        ],
      ),
    );
  }
}

/// Single mechanism row — flag label + per-flag clinical concern.
/// Tone-coloured dot anchors the row to the tier tone.
class _MechanismRow extends StatelessWidget {
  const _MechanismRow({
    required this.flag,
    required this.tone,
    required this.concern,
  });

  final String flag;
  final Color tone;
  final String concern;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const Gap.h(AppSpace.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                flagLabel(flag),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  height: 1.3,
                ),
              ),
              if (concern.isNotEmpty) ...<Widget>[
                const Gap.v(AppSpace.xs),
                Text(
                  concern,
                  style: const TextStyle(
                    color: AppColors.mutedStrong,
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Audit-trail breakdown row — label on left, value on right.
/// Tabular figures so the right column hangs on a clean vertical.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.mutedStrong,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            height: 1.3,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
