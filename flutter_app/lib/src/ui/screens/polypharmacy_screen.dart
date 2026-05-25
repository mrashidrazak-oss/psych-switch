// Polypharmacy regimen checker. Rewritten 2026-05-23.
//
// Pick 3-6 drugs from the registry → composite-risk report in a
// single screen. Four signals:
//
//   • QTc-stacking score (reuses `qtc_stacker` engine)
//   • Anticholinergic Burden (ACB) sum (Boustani 2008)
//   • Sedation additive risk (counts drugs at moderate-or-above)
//   • DDI hits (`checkAll` from `ddi.dart`)
//
// One screen, four signals, daily-use power tool — the biggest single
// "is this regimen safe?" review a psychiatrist runs at every visit.
//
// Architecture (top → bottom):
//   - PolypharmacyScreen     Route widget; engine + qtc-data async.
//   - _PolypharmacyForm      Stateful body; owns selected drug set.
//   - _Body                  Renders hero + scores + DDI + drugs + picker.
//   - _ScoreGrid             2×2 grid of composite-risk score tiles.
//   - _ScoreTile             Single tinted score cell (eyebrow + big
//                            number + subtitle).
//   - _DdiCard               DDI hits grouped by severity tone.
//   - _DdiRow                One interaction; severity-tinted.
//   - _SelectedDrugsList     Picked drugs with per-row ACB / QTc /
//                            sedation badges + remove action.
//   - _RegimenRow            One picked-drug row.
//   - _DrugPicker            Search field + flat list of drugs to add.
//   - _PickerRow             One drug with check-state.
//   - _FooterNote            Scope + citation footer.
//
// Motion: EntranceFade cascade on first paint (hero → scores → DDI →
// selected list → picker → footer), 60ms stagger.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/tool_hero.dart';
import 'package:psychswitch_engine/anticholinergic.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/qtc_stacker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';

class PolypharmacyScreen extends ConsumerStatefulWidget {
  const PolypharmacyScreen({super.key});

  @override
  ConsumerState<PolypharmacyScreen> createState() =>
      _PolypharmacyScreenState();
}

class _PolypharmacyScreenState extends ConsumerState<PolypharmacyScreen> {
  final Set<String> _selected = <String>{};

  /// Count of picked drugs at sedation tier moderate or above. Used
  /// as the sedation-stacking score in the composite grid.
  int _sedationAdditiveCount(SwitchingEngine engine) {
    var n = 0;
    for (final id in _selected) {
      final d = engine.getDrug(id);
      if (d == null) continue;
      final s = d.sedation;
      if (s == RiskLevel.moderate ||
          s == RiskLevel.high ||
          s == RiskLevel.veryHigh) {
        n++;
      }
    }
    return n;
  }

  void _toggle(String id) {
    unawaited(hapticsTap());
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clear() {
    unawaited(hapticsTap());
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final asyncEngine = ref.watch(engineProvider);
    final asyncQtc = ref.watch(qtcDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regimen check'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: _clear,
              icon: const Icon(Icons.refresh_rounded),
            ),
          const Gap.h(ClinicalSpace.xs),
        ],
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, _) => EngineErrorView(error: e),
          data: (engine) => asyncQtc.when(
            loading: () => const EngineLoadingView(),
            error: (e, _) => EngineErrorView(error: e),
            data: (qtc) => _Body(
              engine: engine,
              qtc: qtc,
              selected: _selected,
              onToggle: _toggle,
              sedationAdditiveCount: _sedationAdditiveCount(engine),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.engine,
    required this.qtc,
    required this.selected,
    required this.onToggle,
    required this.sedationAdditiveCount,
  });

  final SwitchingEngine engine;
  final QtcRiskData qtc;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int sedationAdditiveCount;

  @override
  Widget build(BuildContext context) {
    // Visibility gate: hide LAI from this screen for now — same
    // pre-release scope as the switch picker. The full LAI module
    // ships with its own monitoring requirements.
    final visibleDrugs = engine
        .listDrugs()
        .where((d) => d.formulation != Formulation.lai)
        .toList();
    final selectedIds = selected.toList();
    final acb = assessAnticholinergicBurden(selectedIds);
    final qtcAssessment = assessQtcRisk(selectedIds, qtc);
    final ddiHits = checkAll(selectedIds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.lg,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        EntranceFade(
          child: ToolHero(
            icon: Icons.account_tree_outlined,
            title: 'Regimen check',
            tagline: 'Composite regimen-risk screen',
            tone: ClinicalPalette.accent,
            stats: <ToolHeroStat>[
              ToolHeroStat(
                label: 'CATALOGUE',
                value: '${visibleDrugs.length}',
                unit: 'drugs',
              ),
              ToolHeroStat(
                label: 'SELECTED',
                value: '${selected.length}',
                unit: selected.length == 1 ? 'drug' : 'drugs',
              ),
            ],
            rationale: selected.isEmpty
                ? "Pick everything the patient's on — psychotropics, "
                    'anti-EPS, antihistamines, the lot. The engine '
                    'returns a composite-risk report and flags drugs '
                    'worth deprescribing.'
                : '${selected.length} '
                    'drug${selected.length == 1 ? '' : 's'} in the '
                    'regimen. Scroll for the composite report or pick '
                    'more below.',
          ),
        ),
        const Gap.v(ClinicalSpace.lg),
        if (selected.isNotEmpty) ...<Widget>[
          EntranceFade(
            index: 1,
            child: _ScoreGrid(
              qtcOverall: qtcAssessment.overallRisk,
              qtcScore: qtcAssessment.knownCount * 3 +
                  qtcAssessment.conditionalCount * 2 +
                  qtcAssessment.possibleCount,
              acbTotal: acb.totalScore,
              acbCategory: acb.category,
              sedationAdditive: sedationAdditiveCount,
              ddiHits: ddiHits.length,
            ),
          ),
          const Gap.v(ClinicalSpace.lg),
          if (ddiHits.isNotEmpty) ...<Widget>[
            EntranceFade(
              index: 2,
              child: _DdiCard(hits: ddiHits, engine: engine),
            ),
            const Gap.v(ClinicalSpace.lg),
          ],
          EntranceFade(
            index: 3,
            child: _SelectedDrugsList(
              ids: selectedIds,
              engine: engine,
              acb: acb,
              qtc: qtc,
              onRemove: onToggle,
            ),
          ),
          const Gap.v(ClinicalSpace.lg),
        ],
        EntranceFade(
          index: selected.isEmpty ? 1 : 4,
          child: _DrugPicker(
            drugs: visibleDrugs,
            selected: selected,
            onToggle: onToggle,
          ),
        ),
        const Gap.v(ClinicalSpace.lg),
        EntranceFade(
          index: selected.isEmpty ? 2 : 5,
          child: const _FooterNote(),
        ),
      ],
    );
  }
}

// ── Composite score grid ────────────────────────────────────────────

/// 2×2 grid of composite-risk score tiles. Each tile colour-codes its
/// own concern level via tone-by-threshold mapping.
class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({
    required this.qtcOverall,
    required this.qtcScore,
    required this.acbTotal,
    required this.acbCategory,
    required this.sedationAdditive,
    required this.ddiHits,
  });

  final OverallRisk qtcOverall;
  final int qtcScore;
  final int acbTotal;
  final AcbCategory acbCategory;
  final int sedationAdditive;
  final int ddiHits;

  Color _qtcTone() {
    switch (qtcOverall) {
      case OverallRisk.none:
      case OverallRisk.low:
        return ClinicalPalette.toneMintInk;
      case OverallRisk.moderate:
        return ClinicalPalette.warning;
      case OverallRisk.high:
      case OverallRisk.veryHigh:
        return ClinicalPalette.danger;
    }
  }

  Color _acbTone() {
    switch (acbCategory) {
      case AcbCategory.none:
        return ClinicalPalette.toneMintInk;
      case AcbCategory.low:
        return ClinicalPalette.accent;
      case AcbCategory.moderate:
        return ClinicalPalette.warning;
      case AcbCategory.high:
        return ClinicalPalette.danger;
    }
  }

  Color _sedTone() {
    if (sedationAdditive <= 1) return ClinicalPalette.toneMintInk;
    if (sedationAdditive == 2) return ClinicalPalette.warning;
    return ClinicalPalette.danger;
  }

  Color _ddiTone() {
    if (ddiHits == 0) return ClinicalPalette.toneMintInk;
    if (ddiHits <= 2) return ClinicalPalette.warning;
    return ClinicalPalette.danger;
  }

  String _qtcLabel() {
    switch (qtcOverall) {
      case OverallRisk.none:
        return 'No concern';
      case OverallRisk.low:
        return 'Low risk';
      case OverallRisk.moderate:
        return 'Moderate — ECG advised';
      case OverallRisk.high:
        return 'High — ECG required';
      case OverallRisk.veryHigh:
        return 'Very high — cardiology';
    }
  }

  String _sedLabel() {
    if (sedationAdditive == 0) return 'No sedation stacking';
    if (sedationAdditive == 1) return 'Single sedating agent';
    if (sedationAdditive == 2) return 'Two sedating agents';
    return '$sedationAdditive sedating agents stacked';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('COMPOSITE RISK', style: ClinicalText.eyebrow),
        const Gap.v(ClinicalSpace.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _ScoreTile(
                eyebrow: 'QTc STACKING',
                value: '$qtcScore',
                unit: 'pts',
                subtitle: _qtcLabel(),
                tone: _qtcTone(),
              ),
            ),
            const Gap.h(ClinicalSpace.sm + 2),
            Expanded(
              child: _ScoreTile(
                eyebrow: 'ANTICHOLINERGIC',
                value: '$acbTotal',
                unit: 'ACB',
                subtitle: acbCategoryLabel(acbCategory),
                tone: _acbTone(),
              ),
            ),
          ],
        ),
        const Gap.v(ClinicalSpace.sm + 2),
        Row(
          children: <Widget>[
            Expanded(
              child: _ScoreTile(
                eyebrow: 'SEDATION',
                value: '$sedationAdditive',
                unit: 'agents',
                subtitle: _sedLabel(),
                tone: _sedTone(),
              ),
            ),
            const Gap.h(ClinicalSpace.sm + 2),
            Expanded(
              child: _ScoreTile(
                eyebrow: 'INTERACTIONS',
                value: '$ddiHits',
                unit: ddiHits == 1 ? 'hit' : 'hits',
                subtitle:
                    ddiHits == 0 ? 'No interactions' : 'See details below',
                tone: _ddiTone(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.eyebrow,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.tone,
  });

  final String eyebrow;
  final String value;
  final String unit;
  final String subtitle;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.md,
        ClinicalSpace.md - 2,
        ClinicalSpace.md,
        ClinicalSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: TextStyle(
              color: tone,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Gap.v(ClinicalSpace.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: TextStyle(
                  color: tone,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.05,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const Gap.h(ClinicalSpace.xs + 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: ClinicalPalette.mutedStrong,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 2),
          Text(
            subtitle,
            style: ClinicalText.caption.copyWith(height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── DDI card ────────────────────────────────────────────────────────

class _DdiCard extends StatelessWidget {
  const _DdiCard({required this.hits, required this.engine});

  final List<DdiHit> hits;
  final SwitchingEngine engine;

  Color _toneFor(DdiSeverity s) {
    switch (s) {
      case DdiSeverity.info:
        return ClinicalPalette.muted;
      case DdiSeverity.caution:
        return ClinicalPalette.accent;
      case DdiSeverity.warning:
        return ClinicalPalette.warning;
      case DdiSeverity.avoid:
        return ClinicalPalette.danger;
    }
  }

  String _name(String id) => engine.getDrug(id)?.genericName ?? id;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('DRUG INTERACTIONS', style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.sm + 2),
          for (var i = 0; i < hits.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                color: ClinicalPalette.border.withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(vertical: ClinicalSpace.sm),
              ),
            _DdiRow(
              hit: hits[i],
              tone: _toneFor(hits[i].severity),
              fromName: _name(hits[i].pair[0]),
              toName: _name(hits[i].pair[1]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DdiRow extends StatelessWidget {
  const _DdiRow({
    required this.hit,
    required this.tone,
    required this.fromName,
    required this.toName,
  });

  final DdiHit hit;
  final Color tone;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: Text(
                hit.severity.jsonValue.toUpperCase(),
                style: TextStyle(
                  color: tone,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Gap.h(ClinicalSpace.sm),
            Expanded(
              child: Text(
                '$fromName + $toName',
                style: const TextStyle(
                  color: ClinicalPalette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
        const Gap.v(ClinicalSpace.xs),
        Text(
          hit.message,
          style: ClinicalText.caption.copyWith(height: 1.55),
        ),
      ],
    );
  }
}

// ── Selected drugs list ─────────────────────────────────────────────

class _SelectedDrugsList extends StatelessWidget {
  const _SelectedDrugsList({
    required this.ids,
    required this.engine,
    required this.acb,
    required this.qtc,
    required this.onRemove,
  });

  final List<String> ids;
  final SwitchingEngine engine;
  final AcbAssessment acb;
  final QtcRiskData qtc;
  final ValueChanged<String> onRemove;

  Color _acbTone(AcbTier t) {
    switch (t) {
      case AcbTier.none:
        return ClinicalPalette.muted;
      case AcbTier.possible:
        return ClinicalPalette.accent;
      case AcbTier.definiteLow:
        return ClinicalPalette.warning;
      case AcbTier.definiteSevere:
        return ClinicalPalette.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('CURRENT REGIMEN', style: ClinicalText.eyebrow),
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
              for (var i = 0; i < ids.length; i++) ...<Widget>[
                if (i > 0)
                  Container(
                    height: 0.5,
                    color: ClinicalPalette.border.withValues(alpha: 0.5),
                  ),
                _RegimenRow(
                  drug: engine.getDrug(ids[i]),
                  drugId: ids[i],
                  acb: acb.entries[i].tier,
                  acbTone: _acbTone(acb.entries[i].tier),
                  onRemove: () => onRemove(ids[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RegimenRow extends StatelessWidget {
  const _RegimenRow({
    required this.drug,
    required this.drugId,
    required this.acb,
    required this.acbTone,
    required this.onRemove,
  });

  final Drug? drug;
  final String drugId;
  final AcbTier acb;
  final Color acbTone;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = drug?.genericName ?? drugId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.sm + 2,
        ClinicalSpace.sm,
        ClinicalSpace.sm + 2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    color: ClinicalPalette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                if (drug?.drugClass.isNotEmpty ?? false) ...<Widget>[
                  const Gap.v(1),
                  Text(drug!.drugClass, style: ClinicalText.caption),
                ],
              ],
            ),
          ),
          if (acb != AcbTier.none) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: acbTone.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: Text(
                'ACB ${acb.score}',
                style: TextStyle(
                  color: acbTone,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: ClinicalPalette.muted,
              size: 18,
            ),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Drug picker ─────────────────────────────────────────────────────

class _DrugPicker extends StatefulWidget {
  const _DrugPicker({
    required this.drugs,
    required this.selected,
    required this.onToggle,
  });

  final List<Drug> drugs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<_DrugPicker> createState() => _DrugPickerState();
}

class _DrugPickerState extends State<_DrugPicker> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.drugs
        : widget.drugs
            .where((d) =>
                d.genericName.toLowerCase().contains(q) ||
                d.drugClass.toLowerCase().contains(q))
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('ADD A DRUG', style: ClinicalText.eyebrow),
        const Gap.v(ClinicalSpace.sm),
        TextField(
          controller: _searchCtl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search drugs',
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: ClinicalPalette.muted,
            ),
          ),
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
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(ClinicalSpace.lg),
                  child: Text(
                    q.isEmpty ? 'No drugs.' : 'No matches for "$q".',
                    style: ClinicalText.caption.copyWith(height: 1.55),
                  ),
                )
              else
                for (var i = 0; i < filtered.length; i++) ...<Widget>[
                  if (i > 0)
                    Container(
                      height: 0.5,
                      color: ClinicalPalette.border.withValues(alpha: 0.5),
                    ),
                  _PickerRow(
                    drug: filtered[i],
                    isSelected: widget.selected.contains(filtered[i].id),
                    onTap: () => widget.onToggle(filtered[i].id),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.drug,
    required this.isSelected,
    required this.onTap,
  });

  final Drug drug;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md + 2,
          vertical: ClinicalSpace.sm + 2,
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? ClinicalPalette.accent
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ClinicalPalette.accent
                      : ClinicalPalette.borderStrong,
                ),
                borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    drug.genericName,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap.v(2),
                  Text(drug.drugClass, style: ClinicalText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer note ─────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.md + 2,
        ClinicalSpace.md,
        ClinicalSpace.md + 2,
        ClinicalSpace.md,
      ),
      decoration: BoxDecoration(
        color: ClinicalPalette.surfaceMuted,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: Text(
        'Composite-risk screen. QTc scoring after CredibleMeds; ACB '
        'after Boustani 2008. Sedation tier is the drug-profile field. '
        "DDI hits from the engine's pairwise checker.",
        style: ClinicalText.caption.copyWith(height: 1.5),
      ),
    );
  }
}
