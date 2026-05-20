// Adverse-effect reverse lookup.
//
// Question this answers: "Patient on drug X has problem Y — what
// should I switch to?" Filter by category, tap a problem, see culprit
// drugs + candidate switch targets + management notes.
// RN parity: `screens/AdverseEffectsScreen.tsx`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';
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

    final hero = ToolHero(
      icon: Icons.health_and_safety_outlined,
      title: 'Adverse-effect lookup',
      tagline: 'Cause → candidate switch target',
      tone: ClinicalPalette.warning,
      stats: <ToolHeroStat>[
        ToolHeroStat(
          label: 'PROBLEMS',
          value: '${adverseEffects.length}',
          unit: 'effects',
        ),
        ToolHeroStat(
          label: 'CATEGORIES',
          value: '${grouped.length}',
          unit: 'groups',
        ),
      ],
      rationale: 'Reverse lookup — pick a side effect to see the '
          'likely culprit drugs, candidate switch targets and '
          'management notes.',
    );

    final categorisedList = <Widget>[
      for (final cat
          in _categoryOrder.where((c) => grouped[c] != null))
        Padding(
          padding: const EdgeInsets.only(bottom: ClinicalSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: ClinicalSpace.xs),
                child: Text(
                  categoryLabels[cat]?.toUpperCase() ??
                      cat.jsonValue.toUpperCase(),
                  style: ClinicalText.eyebrow,
                ),
              ),
              const Gap.v(ClinicalSpace.sm),
              Container(
                decoration: BoxDecoration(
                  color: ClinicalPalette.surface,
                  border: Border.all(color: ClinicalPalette.border.withValues(alpha: 0.7), width: 0.5),
                  borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < grouped[cat]!.length; i++)
                      _AeRow(
                        ae: grouped[cat]![i],
                        isLast: i == grouped[cat]!.length - 1,
                        isActive: _selected?.id == grouped[cat]![i].id,
                        onTap: () => setState(() {
                          _selected = _selected?.id == grouped[cat]![i].id
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adverse-effect lookup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: context.isWide
            // Wide: list on the left, detail panel pinned to the right
            // (or a soft "pick a problem" prompt when nothing's selected).
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.lg,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xl,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            hero,
                            const Gap.v(ClinicalSpace.md),
                            ...categorisedList,
                          ],
                        ),
                      ),
                    ),
                    const Gap.h(ClinicalSpace.xl),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _selected == null
                            ? _PickPrompt()
                            : _DetailPanel(
                                ae: _selected!,
                                capitalize: _capitalize,
                                onClose: () =>
                                    setState(() => _selected = null),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            // Narrow: detail expands inline above the list, AnimatedSize
            // for the smooth reveal.
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.lg,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xl,
                ),
                children: <Widget>[
                  hero,
                  const Gap.v(ClinicalSpace.md),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _selected == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding:
                                const EdgeInsets.only(bottom: ClinicalSpace.lg),
                            child: _DetailPanel(
                              ae: _selected!,
                              capitalize: _capitalize,
                              onClose: () =>
                                  setState(() => _selected = null),
                            ),
                          ),
                  ),
                  ...categorisedList,
                ],
              ),
      ),
    );
  }
}

class _PickPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(color: ClinicalPalette.border.withValues(alpha: 0.7), width: 0.5),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.touch_app_outlined,
            color: ClinicalPalette.muted,
            size: 28,
          ),
          const Gap.v(ClinicalSpace.md),
          const Text(
            'Pick a problem',
            style: TextStyle(
              color: ClinicalPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap.v(ClinicalSpace.xs),
          Text(
            'Tap any adverse-effect on the left to see its common '
            'causes, candidate switch targets, and management note.',
            style: ClinicalText.caption.copyWith(height: 1.5),
          ),
        ],
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
          ? ClinicalPalette.accent.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isLast
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ae.label,
                        style: const TextStyle(
                          color: ClinicalPalette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ClinicalPalette.muted,
                      size: 18,
                    ),
                  ],
                ),
                const Gap.v(2),
                Text(
                  ae.summary,
                  style: ClinicalText.caption,
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
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.accent.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.md + 2,
        ClinicalSpace.md,
        ClinicalSpace.md + 2,
        ClinicalSpace.md,
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
                      style: ClinicalText.eyebrow,
                    ),
                    const Gap.v(2),
                    Text(
                      ae.label,
                      style: const TextStyle(
                        color: ClinicalPalette.text,
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
                  color: ClinicalPalette.muted,
                ),
                tooltip: 'Close',
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.sm),
          Text(
            ae.summary,
            style: ClinicalText.caption.copyWith(height: 1.5),
          ),
          const Gap.v(ClinicalSpace.md),

          Text(
            'COMMON CAUSES',
            style: ClinicalText.eyebrow.copyWith(color: ClinicalPalette.warning),
          ),
          const Gap.v(ClinicalSpace.xs + 2),
          Wrap(
            spacing: ClinicalSpace.xs + 2,
            runSpacing: ClinicalSpace.xs + 2,
            children: <Widget>[
              for (final id in ae.causedBy)
                StatusPill(label: capitalize(id), tone: ClinicalPalette.warning),
            ],
          ),
          const Gap.v(ClinicalSpace.md),

          Text(
            'CANDIDATE SWITCH TARGETS',
            style: ClinicalText.eyebrow.copyWith(color: ClinicalPalette.toneMintInk),
          ),
          const Gap.v(ClinicalSpace.xs + 2),
          Wrap(
            spacing: ClinicalSpace.xs + 2,
            runSpacing: ClinicalSpace.xs + 2,
            children: <Widget>[
              for (final id in ae.switchCandidates)
                StatusPill(label: capitalize(id), tone: ClinicalPalette.toneMintInk),
            ],
          ),
          const Gap.v(ClinicalSpace.md),

          const Text('MANAGEMENT', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs),
          Text(
            ae.management,
            style: const TextStyle(
              color: ClinicalPalette.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (ae.citations.isNotEmpty) ...<Widget>[
            const Gap.v(ClinicalSpace.sm),
            Text(
              ae.citations.first,
              style: ClinicalText.eyebrow.copyWith(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}
