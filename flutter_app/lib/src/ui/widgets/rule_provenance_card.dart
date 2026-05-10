// Rule-provenance card — surfaces the trust signals that make a rule
// defensible at a CME: who reviewed it, when, when the next review is
// due, and the rule id. RN parity:
// `components/RuleProvenanceCard.tsx`. Review cadence: 90 days.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/errata.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

class RuleProvenanceCard extends StatelessWidget {
  const RuleProvenanceCard({required this.rule, super.key});

  final SwitchingRule rule;

  static const _reviewCadenceDays = 90;

  ({DateTime? nextReview, bool overdue}) _computeReviewStatus(
    String lastReviewedISO,
  ) {
    final last = DateTime.tryParse(lastReviewedISO);
    if (last == null) return (nextReview: null, overdue: false);
    final next = last.add(const Duration(days: _reviewCadenceDays));
    return (
      nextReview: next,
      overdue: DateTime.now().isAfter(next),
    );
  }

  String _humanDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final status = _computeReviewStatus(rule.lastReviewedISO);
    final ruleErrata = errataForRule(rule.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md - 2,
        AppSpace.md + 2,
        AppSpace.md - 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm + 2),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const Gap.h(AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('PROVENANCE', style: AppTextSizes.eyebrow),
                const Gap.v(2),
                Text(
                  rule.reviewedBy,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap.v(AppSpace.xs),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: <Widget>[
                    _DotLine(
                      tone: AppColors.muted,
                      text: 'Reviewed ${rule.lastReviewedISO}',
                    ),
                    if (status.nextReview != null)
                      _DotLine(
                        tone: status.overdue
                            ? AppColors.warning
                            : AppColors.to,
                        text: status.overdue
                            ? 'Next review overdue'
                            : 'Next review ${_humanDate(status.nextReview!)}',
                        bold: status.overdue,
                      ),
                  ],
                ),
                const Gap.v(AppSpace.xs),
                Text(
                  rule.id,
                  style: AppTextSizes.eyebrow.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                if (ruleErrata.isNotEmpty) ...<Widget>[
                  const Gap.v(AppSpace.sm),
                  GestureDetector(
                    onTap: () => context.pushNamed(Routes.errata),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap.h(AppSpace.xs + 2),
                        Text(
                          '${ruleErrata.length} correction'
                          '${ruleErrata.length == 1 ? '' : 's'} recorded',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap.h(AppSpace.xs),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotLine extends StatelessWidget {
  const _DotLine({
    required this.tone,
    required this.text,
    this.bold = false,
  });

  final Color tone;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const Gap.h(AppSpace.xs + 2),
        Text(
          text,
          style: TextStyle(
            color: tone == AppColors.muted ? AppColors.muted : tone,
            fontSize: 11,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
