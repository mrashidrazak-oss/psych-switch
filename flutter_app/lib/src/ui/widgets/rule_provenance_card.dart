// Rule-provenance card — credibility lift.
//
// The defensibility argument lives here: who reviewed this rule, when,
// when the next review is due, the rule id (for grep), and any
// recorded corrections. Designed to look like a stamp on a clinical
// document — three bands inside a single card.
//
// RN parity: `components/RuleProvenanceCard.tsx`. Review cadence: 90
// days from `lastReviewedISO`.

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

  ({DateTime? nextReview, bool overdue, int daysToNext}) _computeReviewStatus(
    String lastReviewedISO,
  ) {
    final last = DateTime.tryParse(lastReviewedISO);
    if (last == null) {
      return (nextReview: null, overdue: false, daysToNext: 0);
    }
    final next = last.add(const Duration(days: _reviewCadenceDays));
    final delta = next.difference(DateTime.now()).inDays;
    return (
      nextReview: next,
      overdue: DateTime.now().isAfter(next),
      daysToNext: delta,
    );
  }

  String _humanDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Strip the engine-internal "PENDING - " prefix from the reviewer
  /// field for display. Keeps the audit trail clean while flagging
  /// pre-review content with a chip.
  ({String name, bool pending}) _parseReviewer(String raw) {
    final pending = raw.toLowerCase().startsWith('pending');
    final name = raw
        .replaceFirst(RegExp(r'^PENDING\s*[-—]\s*', caseSensitive: false), '')
        .trim();
    return (name: name.isEmpty ? raw : name, pending: pending);
  }

  @override
  Widget build(BuildContext context) {
    final status = _computeReviewStatus(rule.lastReviewedISO);
    final ruleErrata = errataForRule(rule.id);
    final reviewer = _parseReviewer(rule.reviewedBy);
    final tone = status.overdue
        ? AppColors.warning
        : (reviewer.pending ? AppColors.mutedStrong : AppColors.accent);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Identity band: reviewer + status chip ──────────────
          Container(
            color: tone.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg - 2,
              AppSpace.md + 2,
              AppSpace.md - 2,
              AppSpace.md + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Verified-stamp tile.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.36),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    size: 19,
                    color: tone,
                  ),
                ),
                const Gap.h(AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'REVIEWED BY',
                        style: AppTextSizes.eyebrow.copyWith(color: tone),
                      ),
                      const Gap.v(2),
                      Text(
                        reviewer.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap.h(AppSpace.sm),
                if (reviewer.pending)
                  const _StatusChip(
                    tone: AppColors.mutedStrong,
                    label: 'PENDING REVIEW',
                  )
                else if (status.overdue)
                  const _StatusChip(
                    tone: AppColors.warning,
                    label: 'REVIEW OVERDUE',
                  )
                else
                  const _StatusChip(
                    tone: AppColors.to,
                    label: 'IN REVIEW WINDOW',
                  ),
              ],
            ),
          ),
          // ── Stat row: reviewed date + next review countdown ────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg - 2,
              AppSpace.md + 2,
              AppSpace.lg - 2,
              AppSpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _ProvenanceStat(
                    eyebrow: 'LAST REVIEWED',
                    value: rule.lastReviewedISO,
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 36,
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: _ProvenanceStat(
                    eyebrow: 'NEXT REVIEW',
                    value: status.nextReview != null
                        ? _humanDate(status.nextReview!)
                        : '—',
                    subtitle: status.nextReview != null
                        ? (status.overdue
                            ? '${-status.daysToNext} days overdue'
                            : 'in ${status.daysToNext} days')
                        : null,
                    subtitleTone: status.overdue
                        ? AppColors.warning
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          // ── Footer: rule-id chip + errata link (when present) ──
          Container(
            color: AppColors.bg.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg - 2,
              AppSpace.sm + 2,
              AppSpace.md - 2,
              AppSpace.sm + 2,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    rule.id,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const Spacer(),
                if (ruleErrata.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.pushNamed(Routes.errata),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm + 2,
                          vertical: 3,
                        ),
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
                              '${ruleErrata.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
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

/// Single mini-stat inside the provenance card's middle band — eyebrow
/// + value (+ optional coloured subtitle for countdowns).
class _ProvenanceStat extends StatelessWidget {
  const _ProvenanceStat({
    required this.eyebrow,
    required this.value,
    this.subtitle,
    this.subtitleTone,
  });

  final String eyebrow;
  final String value;
  final String? subtitle;
  final Color? subtitleTone;

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
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                color: subtitleTone ?? AppColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.tone, required this.label});

  final Color tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
