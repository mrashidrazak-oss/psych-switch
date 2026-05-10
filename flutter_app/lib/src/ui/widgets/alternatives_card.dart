// What-if alternatives card. Reuses the smart-picker engine to surface
// the top 3 *other* drugs the clinician could reasonably switch to from
// the same from-drug, given the current patient context. The current
// to-drug is excluded — this is the "if this doesn't work out"
// explorer scenario. Tap an alternative to start a new switch.
//
// RN parity: `components/AlternativesCard.tsx`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/smart_picker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';

class AlternativesCard extends StatelessWidget {
  const AlternativesCard({
    required this.engine,
    required this.fromDrug,
    required this.currentToDrug,
    required this.context,
    super.key,
  });

  final SwitchingEngine engine;
  final Drug fromDrug;
  final Drug currentToDrug;
  final PatientContext context;

  static const Map<RelevanceTier, String> _tierLabel =
      <RelevanceTier, String>{
    RelevanceTier.top: '★ Best fit',
    RelevanceTier.reviewed: 'Reviewed',
    RelevanceTier.fallback: 'Fallback',
    RelevanceTier.caution: 'Caution',
    RelevanceTier.avoid: 'Avoid',
  };

  Color _toneFor(RelevanceTier t) {
    switch (t) {
      case RelevanceTier.top:
        return AppColors.warning;
      case RelevanceTier.reviewed:
        return AppColors.to;
      case RelevanceTier.fallback:
        return AppColors.muted;
      case RelevanceTier.caution:
        return AppColors.warning;
      case RelevanceTier.avoid:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final all = engine
        .listDrugs()
        .where((d) => d.id != fromDrug.id && d.id != currentToDrug.id)
        .toList();
    final ranked = rankDrugs(
      all,
      RankInput(
        rules: engine.listRules(),
        fromDrugId: fromDrug.id,
        context: context,
      ),
    );
    final picks = ranked
        .where((r) =>
            r.tier == RelevanceTier.top || r.tier == RelevanceTier.reviewed)
        .take(3)
        .toList();
    if (picks.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md + 2,
              AppSpace.md - 2,
              AppSpace.md + 2,
              AppSpace.md - 2,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.from.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.from.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm + 2),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.from,
                  ),
                ),
                const Gap.h(AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        "What if this doesn't work out?",
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap.v(2),
                      Text(
                        '${picks.length} alternative '
                        '${picks.length == 1 ? 'target' : 'targets'} '
                        'from ${fromDrug.genericName}',
                        style: AppTextSizes.micro,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < picks.length; i++)
            _AlternativeRow(
              ranked: picks[i],
              isLast: i == picks.length - 1,
              tierLabel: _tierLabel[picks[i].tier]!,
              tone: _toneFor(picks[i].tier),
              onTap: () => _goToAlternative(ctx, picks[i].drug),
            ),
        ],
      ),
    );
  }

  void _goToAlternative(BuildContext context, Drug to) {
    // Replace the current Result so back returns to Switch (or further
    // up). We use go (not push) on /result with the new args.
    context.goNamed(
      Routes.result,
      extra: ResultScreenArgs(
        input: SwitchInput(
          fromDrugId: fromDrug.id,
          fromDoseMg: fromDrug.dosing.startingDoseMg,
          toDrugId: to.id,
          toDoseMg: to.dosing.startingDoseMg,
        ),
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({
    required this.ranked,
    required this.isLast,
    required this.tierLabel,
    required this.tone,
    required this.onTap,
  });

  final RankedDrug ranked;
  final bool isLast;
  final String tierLabel;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        ranked.drug.genericName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap.v(2),
                      Text(
                        ranked.drug.drugClass,
                        style: AppTextSizes.micro,
                      ),
                    ],
                  ),
                ),
                const Gap.h(AppSpace.sm),
                StatusPill(label: tierLabel, tone: tone, compact: true),
                const Gap.h(AppSpace.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
