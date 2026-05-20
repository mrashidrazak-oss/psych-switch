// Cost comparison card — Malaysian formulary cost (MYR) for the
// from-drug + to-drug, with tier (subsidised → expensive) and a delta
// hint (e.g. "RM 80/mo more"). RN parity:
// `components/CostComparisonCard.tsx`.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/cost_data.dart';
import 'package:psychswitch_engine/types/drug.dart';

class CostComparisonCard extends StatelessWidget {
  const CostComparisonCard({
    required this.fromDrug,
    required this.toDrug,
    super.key,
  });

  final Drug fromDrug;
  final Drug toDrug;

  Color _tierTone(CostTier t) {
    switch (t) {
      case CostTier.subsidised:
        return ClinicalPalette.toneMintInk;
      case CostTier.affordable:
        return ClinicalPalette.accent;
      case CostTier.moderate:
        return ClinicalPalette.warning;
      case CostTier.expensive:
        return ClinicalPalette.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromCost = costFor(fromDrug.id);
    final toCost = costFor(toDrug.id);
    if (fromCost == null && toCost == null) return const SizedBox.shrink();

    String? deltaLabel;
    var deltaTone = ClinicalPalette.muted;
    if (fromCost != null && toCost != null) {
      final delta = toCost.monthlyCostMyr - fromCost.monthlyCostMyr;
      if (delta == 0) {
        deltaLabel = 'no change';
      } else if (delta > 0) {
        deltaLabel = 'RM ${delta.toStringAsFixed(0)}/mo more';
        deltaTone = ClinicalPalette.warning;
      } else {
        deltaLabel = 'RM ${(-delta).toStringAsFixed(0)}/mo less';
        deltaTone = ClinicalPalette.toneMintInk;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
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
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ClinicalPalette.toneMintInk.withValues(alpha: 0.15),
                  border: Border.all(
                    color: ClinicalPalette.toneMintInk.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: ClinicalPalette.toneMintInk,
                  size: 16,
                ),
              ),
              const Gap.h(ClinicalSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Affordability hint',
                      style: TextStyle(
                        color: ClinicalPalette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.v(2),
                    Text(
                      'Estimated monthly cost · Malaysian Ringgit',
                      style: ClinicalText.caption,
                    ),
                  ],
                ),
              ),
              if (deltaLabel != null)
                Text(
                  deltaLabel,
                  style: TextStyle(
                    color: deltaTone,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
          const Gap.v(ClinicalSpace.md - 2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _CostCell(
                    drug: fromDrug,
                    entry: fromCost,
                    side: 'FROM',
                    tone:
                        fromCost == null ? null : _tierTone(fromCost.tier),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: ClinicalSpace.sm),
                  child: Center(
                    child: Text(
                      '→',
                      style: TextStyle(
                        color: ClinicalPalette.muted,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _CostCell(
                    drug: toDrug,
                    entry: toCost,
                    side: 'TO',
                    tone: toCost == null ? null : _tierTone(toCost.tier),
                  ),
                ),
              ],
            ),
          ),
          const Gap.v(ClinicalSpace.sm + 2),
          Text(
            'Curated rough estimates from MOH formulary + retail '
            'pharmacy aggregates. Not real-time pricing — verify with '
            'your local procurement quote before counselling on cost.',
            style: ClinicalText.caption.copyWith(
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostCell extends StatelessWidget {
  const _CostCell({
    required this.drug,
    required this.entry,
    required this.side,
    required this.tone,
  });

  final Drug drug;
  final CostEntry? entry;
  final String side;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.sm + 2,
        ClinicalSpace.sm,
        ClinicalSpace.sm + 2,
        ClinicalSpace.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(side, style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs),
          Text(
            drug.genericName,
            style: const TextStyle(
              color: ClinicalPalette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (entry == null) ...<Widget>[
            const Gap.v(2),
            const Text('No cost data', style: ClinicalText.caption),
          ] else ...<Widget>[
            const Gap.v(ClinicalSpace.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.xs + 2,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: tone!.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ClinicalRadii.chip - 2),
              ),
              child: Text(
                tierLabel(entry!.tier).toUpperCase(),
                style: TextStyle(
                  color: tone,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.xs),
            Text(
              '${formatMyr(entry!.monthlyCostMyr)}/mo',
              style: const TextStyle(
                color: ClinicalPalette.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFeatures: <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            if (entry!.note != null) ...<Widget>[
              const Gap.v(2),
              Text(
                entry!.note!,
                style: ClinicalText.caption.copyWith(
                  fontSize: 10,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
