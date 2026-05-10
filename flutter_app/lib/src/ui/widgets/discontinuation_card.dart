// Discontinuation-syndrome banner for the from-drug.
//
// Hidden when severity is `low` (no clinical action). Shows expected
// symptoms, the strategy (e.g. "bridge to fluoxetine"), and the
// relevant half-life. RN parity: `components/DiscontinuationCard.tsx`.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/discontinuation.dart';

class DiscontinuationCard extends StatelessWidget {
  const DiscontinuationCard({
    required this.flag,
    required this.drugDisplayName,
    super.key,
  });

  final DiscontinuationFlag flag;
  final String drugDisplayName;

  Color _toneFor(DiscontinuationSeverity s) {
    switch (s) {
      case DiscontinuationSeverity.low:
        return AppColors.to;
      case DiscontinuationSeverity.moderate:
      case DiscontinuationSeverity.high:
        return AppColors.warning;
      case DiscontinuationSeverity.veryHigh:
        return AppColors.danger;
    }
  }

  String _label(DiscontinuationSeverity s) {
    switch (s) {
      case DiscontinuationSeverity.low:
        return 'Low';
      case DiscontinuationSeverity.moderate:
        return 'Moderate';
      case DiscontinuationSeverity.high:
        return 'High';
      case DiscontinuationSeverity.veryHigh:
        return 'Very high';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (flag.severity == DiscontinuationSeverity.low) {
      return const SizedBox.shrink();
    }
    final tone = _toneFor(flag.severity);

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
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            color: tone,
                            size: 14,
                          ),
                          const Gap.h(AppSpace.xs + 2),
                          Expanded(
                            child: Text(
                              'STOPPING ${drugDisplayName.toUpperCase()} '
                              '· ${_label(flag.severity).toUpperCase()} RISK',
                              style: AppTextSizes.eyebrow
                                  .copyWith(color: tone),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap.v(AppSpace.xs + 2),
                      Text(
                        flag.symptoms,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const Gap.v(AppSpace.sm),
                      RichText(
                        text: TextSpan(
                          style: AppTextSizes.micro.copyWith(height: 1.5),
                          children: <InlineSpan>[
                            const TextSpan(
                              text: 'Strategy: ',
                              style: TextStyle(
                                color: AppColors.mutedStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: flag.strategy),
                          ],
                        ),
                      ),
                      if (flag.halfLifeHours != null) ...<Widget>[
                        const Gap.v(AppSpace.xs),
                        Text(
                          't½ ≈ ${flag.halfLifeHours} h',
                          style: AppTextSizes.eyebrow,
                        ),
                      ],
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
