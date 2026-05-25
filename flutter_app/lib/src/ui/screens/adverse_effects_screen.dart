// Adverse-effect reverse lookup. Rewritten 2026-05-23.
//
// Question this answers: "Patient on drug X has problem Y — what
// should I switch to?" Filter by category, tap a problem, see culprit
// drugs + candidate switch targets + management notes.
//
// Architecture:
//   - AdverseEffectsScreen     Route widget; Scaffold + body.
//   - _AeBody                  Stateful body; owns selection + search.
//   - _SearchField             Filter input above the categorised list.
//   - _CategorySection         Eyebrow + bordered group of AE rows.
//   - _AeRow                   One adverse effect; tap toggles selection.
//   - _DetailPanel             Selected AE detail — causes, candidates,
//                              management, citation.
//   - _PickPrompt              Side-panel placeholder (wide layout) when
//                              nothing's selected.
//   - _NoMatches               Empty state when search filters everything
//                              out.
//
// Motion: cascade-in on first paint (hero → search → categorised list).
// Narrow layout: detail expands inline above the list via AnimatedSize.
// Wide layout: detail pinned right, list scrolls independently.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';
import 'package:psychswitch_engine/adverse_effects.dart';

/// Sort order for category sections — clinically-weighted (the most
/// common reasons a clinician seeks an AE-driven switch come first).
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
  State<AdverseEffectsScreen> createState() => _AdverseEffectsScreenState();
}

class _AdverseEffectsScreenState extends State<AdverseEffectsScreen> {
  AdverseEffect? _selected;
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Filtered + grouped AE map. Search filter compares against label,
  /// summary, causes, and switch candidates — typing "olanzapine"
  /// surfaces everything olanzapine causes; typing "weight" surfaces
  /// weight gain.
  Map<AdverseEffectCategory, List<AdverseEffect>> _groupedFiltered() {
    final q = _searchCtl.text.trim().toLowerCase();
    final grouped = <AdverseEffectCategory, List<AdverseEffect>>{};
    for (final ae in adverseEffects) {
      if (q.isNotEmpty) {
        final hay = <String>[
          ae.label.toLowerCase(),
          ae.summary.toLowerCase(),
          ...ae.causedBy.map((s) => s.toLowerCase()),
          ...ae.switchCandidates.map((s) => s.toLowerCase()),
        ].join(' ');
        if (!hay.contains(q)) continue;
      }
      grouped.putIfAbsent(ae.category, () => <AdverseEffect>[]).add(ae);
    }
    return grouped;
  }

  void _onAeTap(AdverseEffect ae) {
    setState(() {
      _selected = _selected?.id == ae.id ? null : ae;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedFiltered();
    final totalGrouped = grouped.values.fold<int>(0, (n, l) => n + l.length);

    final hero = ToolHero(
      icon: Icons.health_and_safety_outlined,
      title: 'Adverse-effect lookup',
      tagline: 'Culprit drug & switch targets',
      tone: ClinicalPalette.warning,
      stats: <ToolHeroStat>[
        ToolHeroStat(
          label: 'PROBLEMS',
          value: '${adverseEffects.length}',
          unit: 'effects',
        ),
        ToolHeroStat(
          label: 'CATEGORIES',
          value: '${_categoryOrder.length}',
          unit: 'groups',
        ),
      ],
      rationale: 'Reverse lookup — pick a side effect to see the '
          'likely culprit drugs, candidate switch targets and '
          'management notes.',
    );

    final categorisedList = <Widget>[
      for (final cat in _categoryOrder.where((c) => grouped[c] != null))
        Padding(
          padding: const EdgeInsets.only(bottom: ClinicalSpace.lg),
          child: _CategorySection(
            category: cat,
            effects: grouped[cat]!,
            selectedId: _selected?.id,
            onTap: _onAeTap,
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
            ? _WideLayout(
                hero: hero,
                searchField: _SearchField(
                  controller: _searchCtl,
                  onChanged: () => setState(() {}),
                ),
                categorisedList: categorisedList,
                hasMatches: totalGrouped > 0,
                detail: _selected,
                onCloseDetail: () => setState(() => _selected = null),
                capitalize: _capitalize,
              )
            : _NarrowLayout(
                hero: hero,
                searchField: _SearchField(
                  controller: _searchCtl,
                  onChanged: () => setState(() {}),
                ),
                categorisedList: categorisedList,
                hasMatches: totalGrouped > 0,
                detail: _selected,
                onCloseDetail: () => setState(() => _selected = null),
                capitalize: _capitalize,
              ),
      ),
    );
  }
}

// ── Layout shells ───────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.hero,
    required this.searchField,
    required this.categorisedList,
    required this.hasMatches,
    required this.detail,
    required this.onCloseDetail,
    required this.capitalize,
  });

  final Widget hero;
  final Widget searchField;
  final List<Widget> categorisedList;
  final bool hasMatches;
  final AdverseEffect? detail;
  final VoidCallback onCloseDetail;
  final String Function(String) capitalize;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  EntranceFade(child: hero),
                  const Gap.v(ClinicalSpace.md),
                  EntranceFade(index: 1, child: searchField),
                  const Gap.v(ClinicalSpace.md),
                  if (hasMatches)
                    EntranceFade(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: categorisedList,
                      ),
                    )
                  else
                    const EntranceFade(index: 2, child: _NoMatches()),
                ],
              ),
            ),
          ),
          const Gap.h(ClinicalSpace.xl),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: detail == null
                  ? const _PickPrompt()
                  : _DetailPanel(
                      ae: detail!,
                      capitalize: capitalize,
                      onClose: onCloseDetail,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.hero,
    required this.searchField,
    required this.categorisedList,
    required this.hasMatches,
    required this.detail,
    required this.onCloseDetail,
    required this.capitalize,
  });

  final Widget hero;
  final Widget searchField;
  final List<Widget> categorisedList;
  final bool hasMatches;
  final AdverseEffect? detail;
  final VoidCallback onCloseDetail;
  final String Function(String) capitalize;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        EntranceFade(child: hero),
        const Gap.v(ClinicalSpace.md),
        EntranceFade(index: 1, child: searchField),
        const Gap.v(ClinicalSpace.md),
        // Inline detail expansion above the list — only renders when
        // an AE is selected. AnimatedSize handles the smooth reveal.
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: detail == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: ClinicalSpace.lg),
                  child: _DetailPanel(
                    ae: detail!,
                    capitalize: capitalize,
                    onClose: onCloseDetail,
                  ),
                ),
        ),
        if (hasMatches)
          EntranceFade(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categorisedList,
            ),
          )
        else
          const EntranceFade(index: 2, child: _NoMatches()),
      ],
    );
  }
}

// ── Search field ────────────────────────────────────────────────────

/// Inline filter — matches against label, summary, causes, and
/// candidate switch targets. Typing "olanzapine" surfaces everything
/// olanzapine causes; "weight" surfaces weight gain.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        border: Border.all(
          color: ClinicalPalette.border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: ClinicalSpace.md),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: ClinicalPalette.mutedStrong,
          ),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Filter — effect, drug, or symptom',
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                color: ClinicalPalette.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                onChanged();
              },
              borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: ClinicalPalette.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category section ────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.effects,
    required this.selectedId,
    required this.onTap,
  });

  final AdverseEffectCategory category;
  final List<AdverseEffect> effects;
  final String? selectedId;
  final ValueChanged<AdverseEffect> onTap;

  @override
  Widget build(BuildContext context) {
    final label = categoryLabels[category]?.toUpperCase() ??
        category.jsonValue.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: ClinicalSpace.xs),
          child: Text(label, style: ClinicalText.eyebrow),
        ),
        const Gap.v(ClinicalSpace.sm),
        Container(
          decoration: BoxDecoration(
            color: ClinicalPalette.surface,
            border: Border.all(
              color: ClinicalPalette.border.withValues(alpha: 0.7),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(ClinicalRadii.tile),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < effects.length; i++)
                _AeRow(
                  ae: effects[i],
                  isLast: i == effects.length - 1,
                  isActive: selectedId == effects[i].id,
                  onTap: () => onTap(effects[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── AE row ──────────────────────────────────────────────────────────

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
                    Icon(
                      isActive
                          ? Icons.expand_less_rounded
                          : Icons.chevron_right_rounded,
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

// ── Detail panel ────────────────────────────────────────────────────

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
          _DetailHeader(ae: ae, onClose: onClose),
          const Gap.v(ClinicalSpace.sm),
          Text(
            ae.summary,
            style: ClinicalText.caption.copyWith(height: 1.5),
          ),
          const Gap.v(ClinicalSpace.md),
          _PillSection(
            eyebrow: 'COMMON CAUSES',
            eyebrowColor: ClinicalPalette.warning,
            pillTone: ClinicalPalette.warning,
            ids: ae.causedBy,
            capitalize: capitalize,
          ),
          const Gap.v(ClinicalSpace.md),
          _PillSection(
            eyebrow: 'CANDIDATE SWITCH TARGETS',
            eyebrowColor: ClinicalPalette.toneMintInk,
            pillTone: ClinicalPalette.toneMintInk,
            ids: ae.switchCandidates,
            capitalize: capitalize,
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.ae, required this.onClose});

  final AdverseEffect ae;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = categoryLabels[ae.category]?.toUpperCase() ??
        ae.category.jsonValue.toUpperCase();
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(categoryLabel, style: ClinicalText.eyebrow),
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
    );
  }
}

/// Eyebrow + wrapped status-pills. Reused for both Common Causes and
/// Switch Candidates so the visual rhythm stays consistent.
class _PillSection extends StatelessWidget {
  const _PillSection({
    required this.eyebrow,
    required this.eyebrowColor,
    required this.pillTone,
    required this.ids,
    required this.capitalize,
  });

  final String eyebrow;
  final Color eyebrowColor;
  final Color pillTone;
  final List<String> ids;
  final String Function(String) capitalize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(eyebrow, style: ClinicalText.eyebrow.copyWith(color: eyebrowColor)),
        const Gap.v(ClinicalSpace.xs + 2),
        Wrap(
          spacing: ClinicalSpace.xs + 2,
          runSpacing: ClinicalSpace.xs + 2,
          children: <Widget>[
            for (final id in ids)
              StatusPill(label: capitalize(id), tone: pillTone),
          ],
        ),
      ],
    );
  }
}

// ── Pick prompt (wide-layout right rail) ───────────────────────────

class _PickPrompt extends StatelessWidget {
  const _PickPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
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

// ── No-matches state ───────────────────────────────────────────────

/// Shown when the search filter zeroes out every category. Calmer
/// than the awaiting-result card — the user is in an active query,
/// they just need to refine.
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.search_off_rounded,
            color: ClinicalPalette.muted,
            size: 26,
          ),
          Gap.v(ClinicalSpace.md),
          Text(
            'No matching effects',
            style: TextStyle(
              color: ClinicalPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          Gap.v(ClinicalSpace.xs),
          Text(
            'Try a different keyword — a symptom (weight, sedation, '
            'akathisia), a drug name, or a body system.',
            style: TextStyle(
              color: ClinicalPalette.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
