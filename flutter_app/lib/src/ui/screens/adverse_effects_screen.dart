// Adverse-effect reverse lookup.
//
// Question this answers: "Patient on drug X has problem Y — what
// should I switch to?" Filter by category, tap a problem, see culprit
// drugs + candidate switch targets + management notes.
// RN parity: `screens/AdverseEffectsScreen.tsx`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/adverse_effects.dart';

const List<AdverseEffectCategory> _categoryOrder = <AdverseEffectCategory>[
  AdverseEffectCategory.metabolic,
  AdverseEffectCategory.extrapyramidal,
  AdverseEffectCategory.sexual,
  AdverseEffectCategory.sedation,
  AdverseEffectCategory.cardiovascular,
  AdverseEffectCategory.gastrointestinal,
  AdverseEffectCategory.hematologic,
  AdverseEffectCategory.cognitive,
  AdverseEffectCategory.discontinuation,
];

class AdverseEffectsScreen extends StatefulWidget {
  const AdverseEffectsScreen({super.key});

  @override
  State<AdverseEffectsScreen> createState() =>
      _AdverseEffectsScreenState();
}

class _AdverseEffectsScreenState extends State<AdverseEffectsScreen> {
  AdverseEffect? _selected;

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final grouped =
        <AdverseEffectCategory, List<AdverseEffect>>{};
    for (final ae in adverseEffects) {
      grouped.putIfAbsent(ae.category, () => <AdverseEffect>[]).add(ae);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adverse-effect lookup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg + 4,
            AppSpace.lg,
            AppSpace.lg + 4,
            AppSpace.xl,
          ),
          children: <Widget>[
            Text(
              'Find the cause and a candidate switch target for common '
              'problems.',
              style: AppTextSizes.caption.copyWith(height: 1.55),
            ),
            const Gap.v(AppSpace.md),

            // Detail panel — visible at the top when something is
            // selected. Smooth expand/collapse via AnimatedSize.
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _selected == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.lg),
                      child: _DetailPanel(
                        ae: _selected!,
                        capitalize: _capitalize,
                        onClose: () => setState(() => _selected = null),
                      ),
                    ),
            ),

            // Categorised list.
            for (final cat
                in _categoryOrder.where((c) => grouped[c] != null))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpace.xs),
                      child: Text(
                        categoryLabels[cat]?.toUpperCase() ??
                            cat.jsonValue.toUpperCase(),
                        style: AppTextSizes.eyebrow,
                      ),
                    ),
                    const Gap.v(AppSpace.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          for (var i = 0; i < grouped[cat]!.length; i++)
                            _AeRow(
                              ae: grouped[cat]![i],
                              isLast: i == grouped[cat]!.length - 1,
                              isActive:
                                  _selected?.id == grouped[cat]![i].id,
                              onTap: () => setState(() {
                                _selected = _selected?.id ==
                                        grouped[cat]![i].id
                                    ? null
                                    : grouped[cat]![i];
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AeRow extends StatelessWidget {
  const _AeRow({
    required this.ae,
    required this.isLast,
    required this.isActive,
    required this.onTap,
  });

  final AdverseEffect ae;
  final bool isLast;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? AppColors.accent.withValues(alpha: 0.1)
          : Colors.transparent,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ae.label,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ],
                ),
                const Gap.v(2),
                Text(
                  ae.summary,
                  style: AppTextSizes.micro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.ae,
    required this.onClose,
    required this.capitalize,
  });
  final AdverseEffect ae;
  final VoidCallback onClose;
  final String Function(String) capitalize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      categoryLabels[ae.category]?.toUpperCase() ??
                          ae.category.jsonValue.toUpperCase(),
                      style: AppTextSizes.eyebrow,
                    ),
                    const Gap.v(2),
                    Text(
                      ae.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                tooltip: 'Close',
              ),
            ],
          ),
          const Gap.v(AppSpace.sm),
          Text(
            ae.summary,
            style: AppTextSizes.micro.copyWith(height: 1.5),
          ),
          const Gap.v(AppSpace.md),

          Text(
            'COMMON CAUSES',
            style: AppTextSizes.eyebrow.copyWith(color: AppColors.warning),
          ),
          const Gap.v(AppSpace.xs + 2),
          Wrap(
            spacing: AppSpace.xs + 2,
            runSpacing: AppSpace.xs + 2,
            children: <Widget>[
              for (final id in ae.causedBy)
                StatusPill(label: capitalize(id), tone: AppColors.warning),
            ],
          ),
          const Gap.v(AppSpace.md),

          Text(
            'CANDIDATE SWITCH TARGETS',
            style: AppTextSizes.eyebrow.copyWith(color: AppColors.to),
          ),
          const Gap.v(AppSpace.xs + 2),
          Wrap(
            spacing: AppSpace.xs + 2,
            runSpacing: AppSpace.xs + 2,
            children: <Widget>[
              for (final id in ae.switchCandidates)
                StatusPill(label: capitalize(id), tone: AppColors.to),
            ],
          ),
          const Gap.v(AppSpace.md),

          const Text('MANAGEMENT', style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs),
          Text(
            ae.management,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (ae.citations.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.sm),
            Text(
              ae.citations.first,
              style: AppTextSizes.eyebrow.copyWith(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}
