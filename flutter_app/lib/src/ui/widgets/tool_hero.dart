// Clinical-poster hero header for tool screens.
//
// Same chrome rhythm as the bespoke Result / Clozapine / QTc-stacker
// heros — a tone-tinted identity band (icon + title + tagline), a row
// of twin/triple stat cells split by hairline rules, and a tinted
// rationale band underneath — but packaged as one reusable widget so
// the curated launch tools share an identical, world-class header.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

/// A single stat cell in a [ToolHero] — an eyebrow [label], a big
/// [value], and a small trailing [unit].
class ToolHeroStat {
  /// Creates a [ToolHeroStat].
  const ToolHeroStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  /// Small upper-case eyebrow, e.g. `CATALOGUE`.
  final String label;

  /// The headline figure, e.g. `42`.
  final String value;

  /// Trailing unit, e.g. `drugs`.
  final String unit;
}

/// Clinical-poster hero header for a tool screen.
class ToolHero extends StatelessWidget {
  /// Creates a [ToolHero].
  const ToolHero({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.tone,
    required this.stats,
    required this.rationale,
    super.key,
  });

  /// Identity icon shown in the tinted badge.
  final IconData icon;

  /// Screen title — large, bold.
  final String title;

  /// One-line description under the title.
  final String tagline;

  /// Accent colour for the identity band + icon badge.
  final Color tone;

  /// One to three stat cells.
  final List<ToolHeroStat> stats;

  /// Plain-language explanation shown in the footer band.
  final String rationale;

  @override
  Widget build(BuildContext context) {
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
          // ── Identity band ───────────────────────────────────────
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
                  child: Icon(icon, size: 19, color: tone),
                ),
                const Gap.h(ClinicalSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: ClinicalPalette.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const Gap.v(ClinicalSpace.xs - 1),
                      Text(
                        tagline,
                        style: const TextStyle(
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
          // ── Stats row ───────────────────────────────────────────
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
                for (var i = 0; i < stats.length; i++) ...<Widget>[
                  if (i > 0)
                    Container(
                      width: 0.5,
                      height: 36,
                      color: ClinicalPalette.border.withValues(alpha: 0.6),
                    ),
                  Expanded(child: _StatCell(stat: stats[i])),
                ],
              ],
            ),
          ),
          // ── Rationale band ──────────────────────────────────────
          Container(
            color: ClinicalPalette.bg.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
            ),
            child: Text(
              rationale,
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});

  final ToolHeroStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            stat.label,
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
              Flexible(
                child: Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  stat.unit,
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
