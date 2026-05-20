// Predicted adverse-effect profile for the to-drug.
//
// Reads `psychswitch_engine/predicted_ae_profile.dart`
// `predictAeProfile(toDrug, fromDrug?)` — combines the to-drug's typed
// risk fields with the reverse-lookup AE table to surface a
// prioritised list of "watch out for these on the new drug".
//
// UX:
//   • Collapsed by default (Result screen real-estate is tight).
//   • Header shows headline summary: "X likely · Y possible" or
//     "Mostly favourable profile" depending on counts.
//   • Each row carries a likelihood pill (high / moderate / low /
//     lower-than-current / unknown) — tone matched to severity.
//   • Tap a row to expand and see the engine's reason + the AE's
//     management note + (where available) a quantitative effect
//     string with citation.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/predicted_ae_profile.dart';
import 'package:psychswitch_engine/quantitative_ae.dart';

class PredictedAeCard extends StatefulWidget {
  const PredictedAeCard({required this.profile, super.key});

  final PredictedAeProfile profile;

  @override
  State<PredictedAeCard> createState() => _PredictedAeCardState();
}

class _PredictedAeCardState extends State<PredictedAeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final preds = widget.profile.predictions;
    if (preds.isEmpty) return const SizedBox.shrink();

    final high =
        preds.where((p) => p.likelihood == AeLikelihood.high).length;
    final moderate =
        preds.where((p) => p.likelihood == AeLikelihood.moderate).length;
    final headline = high > 0
        ? '$high likely · $moderate possible'
        : moderate > 0
            ? '$moderate possible side effect${moderate == 1 ? '' : 's'}'
            : 'Mostly favourable profile';

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Header (always visible, tap to toggle) ────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.md + 2,
                  vertical: ClinicalSpace.md - 2,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ClinicalPalette.warning.withValues(alpha: 0.15),
                        border: Border.all(
                          color: ClinicalPalette.warning.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ClinicalPalette.warning,
                      ),
                    ),
                    const Gap.h(ClinicalSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Predicted side-effect profile',
                            style: TextStyle(
                              color: ClinicalPalette.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap.v(2),
                          Text(
                            '${widget.profile.toDrug.genericName} · $headline',
                            style: ClinicalText.caption,
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

          // ── Body (visible when expanded) ──────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Divider(height: 1),
                      for (var i = 0; i < preds.length; i++)
                        _PredictionRow(
                          prediction: preds[i],
                          toDrugId: widget.profile.toDrug.id,
                          isLast: i == preds.length - 1,
                        ),
                      const Divider(height: 1),
                      Container(
                        color: ClinicalPalette.bg.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClinicalSpace.md + 2,
                          vertical: ClinicalSpace.sm,
                        ),
                        child: Text(
                          'Likelihoods are tier-based (high / moderate / '
                          'low) — not numeric probabilities. Drawn from '
                          'per-drug profile fields and the adverse-effect '
                          'reverse-lookup table. Verify with the Maudsley '
                          'reference if a tier surprises you.',
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

class _PredictionRow extends StatefulWidget {
  const _PredictionRow({
    required this.prediction,
    required this.toDrugId,
    required this.isLast,
  });

  final PredictedAe prediction;
  final String toDrugId;
  final bool isLast;

  @override
  State<_PredictionRow> createState() => _PredictionRowState();
}

class _PredictionRowState extends State<_PredictionRow> {
  bool _open = false;

  static Color _toneFor(AeLikelihood l) {
    switch (l) {
      case AeLikelihood.high:
        return ClinicalPalette.danger;
      case AeLikelihood.moderate:
        return ClinicalPalette.warning;
      case AeLikelihood.low:
        return ClinicalPalette.accent;
      case AeLikelihood.lowerThanCurrent:
        return ClinicalPalette.toneMintInk;
      case AeLikelihood.unknown:
        return ClinicalPalette.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prediction;
    final tone = _toneFor(p.likelihood);
    final quant = quantitativeForAe(widget.toDrugId, p.ae.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: ClinicalPalette.border),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.md + 2,
              vertical: ClinicalSpace.md - 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        p.ae.label,
                        style: const TextStyle(
                          color: ClinicalPalette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      if (quant != null) ...<Widget>[
                        const Gap.v(2),
                        Text(
                          formatEffect(quant),
                          style: const TextStyle(
                            color: ClinicalPalette.muted,
                            fontSize: 11,
                            height: 1.4,
                            fontFamily: 'monospace',
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                      if (_open) ...<Widget>[
                        const Gap.v(ClinicalSpace.xs + 2),
                        Text(
                          '${p.reason} ${p.ae.management}',
                          style: ClinicalText.caption.copyWith(height: 1.5),
                        ),
                        if (quant != null) ...<Widget>[
                          const Gap.v(2),
                          Text(
                            'SOURCE: ${quant.citation}'
                            '${quant.note != null ? ' · ${quant.note}' : ''}',
                            style: ClinicalText.eyebrow.copyWith(
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const Gap.h(ClinicalSpace.md),
                StatusPill(
                  label: likelihoodLabel(p.likelihood),
                  tone: tone,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
