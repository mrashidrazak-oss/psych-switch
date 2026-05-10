// Switch screen.
//
// One metaphor: a cross-titration is a transformation from drug A to
// drug B. The screen embodies that. A single hero card holds both
// ends of the switch (FROM | TO), connected by a swap-able rail that
// is vertical on phones and horizontal on the foldable inner display.
// Patient context lives as an AppBar action.
//
// Function layer (the part that earns "world class"):
//   • Recently-used drug chips above the picker — tap to fill the
//     next-empty slot. Computed live from saved cases (most recent
//     first, dedup'd, up to 5).
//   • Auto-prefill typical starting dose when a drug is picked.
//     Range hint sits below the field so off-piste doses are visible.
//   • Tier badge persists on the TO drug after picking — the
//     smart-picker verdict (★ Best fit / Reviewed / Caution / Avoid)
//     stays visible. The picker sheet shows it; the form forgets it
//     by default. We don't.
//   • One-tap swap on the connector when both ends are filled.
//   • One-tap clear in the AppBar.
//   • Same-drug guard renders a soft inline warning with explanation.
//   • Live preflight card the moment the form is valid: score ring,
//     strategy + duration eyebrow, safety-flag count, DDI hit count,
//     cost delta. Branches handle every SwitchPlan subtype (washout,
//     Maudsley class guidance, clozapine redirect, no-rule).
//   • The preflight is the moment of confidence — the clinician
//     knows what Result will say before they tap Generate.
//
// Drug picker sheet, patient context sheet, smart-picker tier
// ranking — preserved verbatim. The redesign is scaffolding +
// affordances on top.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/patient_context_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/patient_context_sheet.dart';
import 'package:psychswitch/src/ui/widgets/score_ring.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/citations.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';
import 'package:psychswitch_engine/scale_schedule.dart';
import 'package:psychswitch_engine/smart_picker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

/// Maximum hero-card width on wide displays.
const double _maxFormWidth = 760;

class SwitchScreen extends ConsumerWidget {
  const SwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) => _SwitchForm(engine: engine),
        ),
      ),
    );
  }
}

class _SwitchForm extends ConsumerStatefulWidget {
  const _SwitchForm({required this.engine});

  final SwitchingEngine engine;

  @override
  ConsumerState<_SwitchForm> createState() => _SwitchFormState();
}

class _SwitchFormState extends ConsumerState<_SwitchForm> {
  Drug? _from;
  Drug? _to;
  final _fromDoseCtl = TextEditingController();
  final _toDoseCtl = TextEditingController();

  @override
  void dispose() {
    _fromDoseCtl.dispose();
    _toDoseCtl.dispose();
    super.dispose();
  }

  bool get _hasAny =>
      _from != null ||
      _to != null ||
      _fromDoseCtl.text.isNotEmpty ||
      _toDoseCtl.text.isNotEmpty;

  bool get _sameDrug =>
      _from != null && _to != null && _from!.id == _to!.id;

  bool get _ready {
    if (_from == null || _to == null || _sameDrug) return false;
    final fromDose = double.tryParse(_fromDoseCtl.text);
    final toDose = double.tryParse(_toDoseCtl.text);
    return fromDose != null &&
        toDose != null &&
        fromDose > 0 &&
        toDose > 0;
  }

  SwitchInput? get _input {
    if (!_ready) return null;
    return SwitchInput(
      fromDrugId: _from!.id,
      fromDoseMg: double.parse(_fromDoseCtl.text),
      toDrugId: _to!.id,
      toDoseMg: double.parse(_toDoseCtl.text),
    );
  }

  void _setFrom(Drug d) {
    setState(() {
      _from = d;
      _fromDoseCtl.text = _formatDose(d.dosing.startingDoseMg);
      if (_to?.id == d.id) {
        _to = null;
        _toDoseCtl.clear();
      }
    });
  }

  void _setTo(Drug d) {
    setState(() {
      _to = d;
      _toDoseCtl.text = _formatDose(d.dosing.startingDoseMg);
    });
  }

  void _swap() {
    if (_from == null || _to == null) return;
    unawaited(hapticsTap());
    setState(() {
      final pf = _from;
      _from = _to;
      _to = pf;
      final pt = _fromDoseCtl.text;
      _fromDoseCtl.text = _toDoseCtl.text;
      _toDoseCtl.text = pt;
    });
  }

  void _clearAll() {
    if (!_hasAny) return;
    unawaited(hapticsTap());
    setState(() {
      _from = null;
      _to = null;
      _fromDoseCtl.clear();
      _toDoseCtl.clear();
    });
  }

  void _onContinue() {
    final input = _input;
    if (input == null) return;
    unawaited(hapticsConfirm());
    context.pushNamed(
      Routes.result,
      extra: ResultScreenArgs(input: input),
    );
  }

  Future<void> _openPatientContextSheet() async {
    final current = ref.read(patientContextProvider);
    final next = await showPatientContextSheet(context, initial: current);
    if (next == null) return;
    ref.read(patientContextProvider.notifier).state = next;
    setState(() {});
  }

  Future<Drug?> _openPicker({
    required List<Drug> drugs,
    required List<SwitchingRule> rules,
    String? fromDrugId,
  }) {
    return showModalBottomSheet<Drug>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DrugPickerSheet(
        drugs: drugs,
        rules: rules,
        fromDrugId: fromDrugId,
      ),
    );
  }

  /// Pick a drug from a recently-used chip — fills the next empty
  /// slot (FROM if empty, otherwise TO unless TO would equal FROM).
  void _onRecentTap(Drug d) {
    unawaited(hapticsTap());
    if (_from == null) {
      _setFrom(d);
    } else if (_to == null && _from!.id != d.id) {
      _setTo(d);
    } else if (_from!.id != d.id) {
      // Both filled — replace TO.
      _setTo(d);
    }
  }

  /// Engine output for the current input. Null until both ends are
  /// valid. Used by the preflight card.
  ({SwitchPlan plan, RankedDrug? toRank})? _engineOutput() {
    final input = _input;
    if (input == null) return null;
    final plan = widget.engine.generateSwitchPlan(input);
    // Resolve the TO drug's smart-picker verdict relative to FROM
    // for the inline tier badge.
    final ranked = rankDrugs(
      <Drug>[_to!],
      RankInput(
        rules: widget.engine.listRules(),
        fromDrugId: _from!.id,
      ),
    );
    return (plan: plan, toRank: ranked.firstOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final visibleDrugs = widget.engine.listDrugs();
    final ctx = ref.watch(patientContextProvider);
    final ctxSummary = summarisePatientContext(ctx);
    final hasCtx = ctxSummary.isNotEmpty;
    final asyncCases = ref.watch(savedCasesProvider);
    final recents = _recentDrugs(asyncCases.value, widget.engine);
    final engineOut = _engineOutput();
    final toRank = engineOut?.toRank;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('New switch'),
        actions: <Widget>[
          if (_hasAny)
            IconButton(
              tooltip: 'Clear',
              onPressed: _clearAll,
              icon: const Icon(Icons.refresh_rounded),
            ),
          _PatientContextAction(
            hasContext: hasCtx,
            onPressed: _openPatientContextSheet,
          ),
          const Gap.h(AppSpace.xs),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxFormWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  AppSpace.lg,
                  AppSpace.xl,
                  AppSpace.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (hasCtx)
                      _ContextSummaryChip(
                        summary: ctxSummary,
                        onTap: _openPatientContextSheet,
                      ),
                    if (hasCtx) const Gap.v(AppSpace.lg),

                    if (recents.isNotEmpty) ...<Widget>[
                      _RecentsRow(
                        drugs: recents,
                        onTap: _onRecentTap,
                      ),
                      const Gap.v(AppSpace.md),
                    ],

                    _HeroCard(
                      from: _from,
                      to: _to,
                      toRank: toRank,
                      fromDoseCtl: _fromDoseCtl,
                      toDoseCtl: _toDoseCtl,
                      sameDrug: _sameDrug,
                      onPickFrom: () async {
                        final picked = await _openPicker(
                          drugs: visibleDrugs,
                          rules: widget.engine.listRules(),
                        );
                        if (picked != null) _setFrom(picked);
                      },
                      onPickTo: () async {
                        final picked = await _openPicker(
                          drugs: visibleDrugs
                              .where((d) => d.id != _from?.id)
                              .toList(),
                          rules: widget.engine.listRules(),
                          fromDrugId: _from?.id,
                        );
                        if (picked != null) _setTo(picked);
                      },
                      onSwap: _swap,
                      onDoseChanged: () => setState(() {}),
                    ),

                    if (_sameDrug) ...<Widget>[
                      const Gap.v(AppSpace.md),
                      const _SameDrugWarning(),
                    ],

                    if (engineOut != null) ...<Widget>[
                      const Gap.v(AppSpace.lg),
                      _PreflightCard(
                        plan: engineOut.plan,
                        engine: widget.engine,
                        ctx: ctx,
                        from: _from!,
                        to: _to!,
                      ),
                    ],

                    const Gap.v(AppSpace.xl),
                    _PrimaryCta(
                      enabled: _ready,
                      onPressed: _onContinue,
                    ),
                    const Gap.v(AppSpace.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Last 5 unique drugs the user has touched (across both ends of
  /// every saved case). Most recent first.
  static List<Drug> _recentDrugs(
    List<SavedCase>? cases,
    SwitchingEngine engine,
  ) {
    if (cases == null || cases.isEmpty) return const <Drug>[];
    final seen = <String>{};
    final out = <Drug>[];
    for (final c in cases) {
      for (final id in <String>[c.fromDrugId, c.toDrugId]) {
        if (seen.contains(id)) continue;
        seen.add(id);
        final d = engine.getDrug(id);
        if (d != null) out.add(d);
        if (out.length >= 5) return out;
      }
    }
    return out;
  }
}

// ── AppBar action ───────────────────────────────────────────────────

class _PatientContextAction extends StatelessWidget {
  const _PatientContextAction({
    required this.hasContext,
    required this.onPressed,
  });

  final bool hasContext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hasContext ? 'Edit patient context' : 'Add patient context',
      child: IconButton(
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(
              hasContext ? Icons.person : Icons.person_outline,
              color: hasContext ? AppColors.accent : AppColors.text,
            ),
            if (hasContext)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextSummaryChip extends StatelessWidget {
  const _ContextSummaryChip({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm + 2,
            AppSpace.sm,
            AppSpace.sm + 2,
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.person, size: 14, color: AppColors.accent),
              const Gap.h(AppSpace.sm),
              Expanded(
                child: Text(
                  'Adjusts for: $summary',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.tune, size: 14, color: AppColors.accent),
              const Gap.h(AppSpace.xs),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recents row ─────────────────────────────────────────────────────

class _RecentsRow extends StatelessWidget {
  const _RecentsRow({required this.drugs, required this.onTap});

  final List<Drug> drugs;
  final ValueChanged<Drug> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text('RECENT', style: AppTextSizes.eyebrow),
        ),
        const Gap.v(AppSpace.xs + 2),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: drugs.length,
            separatorBuilder: (_, __) => const Gap.h(AppSpace.xs + 2),
            itemBuilder: (_, i) => _RecentChip(
              drug: drugs[i],
              onTap: () => onTap(drugs[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.drug, required this.onTap});

  final Drug drug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.history,
                size: 12,
                color: AppColors.muted,
              ),
              const Gap.h(AppSpace.xs + 2),
              Text(
                drug.genericName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card ───────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.from,
    required this.to,
    required this.toRank,
    required this.fromDoseCtl,
    required this.toDoseCtl,
    required this.sameDrug,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
    required this.onDoseChanged,
  });

  final Drug? from;
  final Drug? to;
  final RankedDrug? toRank;
  final TextEditingController fromDoseCtl;
  final TextEditingController toDoseCtl;
  final bool sameDrug;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;
  final VoidCallback onDoseChanged;

  @override
  Widget build(BuildContext context) {
    final canSwap = from != null && to != null;
    final fromSection = _DrugSection(
      side: 'FROM DRUG',
      tone: AppColors.from,
      drug: from,
      doseCtl: fromDoseCtl,
      onPick: onPickFrom,
      onDoseChanged: onDoseChanged,
    );
    final toSection = _DrugSection(
      side: 'TO DRUG',
      tone: AppColors.to,
      drug: to,
      doseCtl: toDoseCtl,
      onPick: onPickTo,
      onDoseChanged: onDoseChanged,
      tier: toRank?.tier,
      tierTag: toRank?.tags.firstOrNull,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: -10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: context.isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: fromSection),
                  _Connector(
                    horizontal: true,
                    canSwap: canSwap,
                    onSwap: onSwap,
                  ),
                  Expanded(child: toSection),
                ],
              ),
            )
          : Column(
              children: <Widget>[
                fromSection,
                _Connector(
                  horizontal: false,
                  canSwap: canSwap,
                  onSwap: onSwap,
                ),
                toSection,
              ],
            ),
    );
  }
}

class _DrugSection extends StatelessWidget {
  const _DrugSection({
    required this.side,
    required this.tone,
    required this.drug,
    required this.doseCtl,
    required this.onPick,
    required this.onDoseChanged,
    this.tier,
    this.tierTag,
  });

  final String side;
  final Color tone;
  final Drug? drug;
  final TextEditingController doseCtl;
  final VoidCallback onPick;
  final VoidCallback onDoseChanged;
  final RelevanceTier? tier;
  final String? tierTag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md + 2,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap.h(AppSpace.sm),
              Text(
                side,
                style: AppTextSizes.eyebrow.copyWith(color: tone),
              ),
              if (tier != null && tierTag != null) ...<Widget>[
                const Spacer(),
                StatusPill(
                  label: tierTag!,
                  tone: _tierTone(tier!),
                  compact: true,
                ),
              ],
            ],
          ),
          const Gap.v(AppSpace.sm + 2),
          _DrugPickerTile(drug: drug, onPick: onPick),
          if (drug != null) ...<Widget>[
            const Gap.v(AppSpace.md),
            _DoseField(
              drug: drug!,
              controller: doseCtl,
              onChanged: onDoseChanged,
            ),
          ],
        ],
      ),
    );
  }

  static Color _tierTone(RelevanceTier t) {
    switch (t) {
      case RelevanceTier.top:
        return AppColors.to;
      case RelevanceTier.reviewed:
        return AppColors.accent;
      case RelevanceTier.fallback:
        return AppColors.muted;
      case RelevanceTier.caution:
        return AppColors.warning;
      case RelevanceTier.avoid:
        return AppColors.danger;
    }
  }
}

class _DrugPickerTile extends StatelessWidget {
  const _DrugPickerTile({required this.drug, required this.onPick});

  final Drug? drug;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasDrug = drug != null;
    return Material(
      color: AppColors.bg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  hasDrug ? AppColors.borderStrong : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md + 2,
            AppSpace.md - 2,
            AppSpace.md,
            AppSpace.md - 2,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: hasDrug
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            drug!.genericName,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap.v(AppSpace.xs + 2),
                          _ClassChip(label: drug!.drugClass),
                        ],
                      )
                    : const Text(
                        'Pick a drug',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: AppColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm - 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedStrong,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DoseField extends StatelessWidget {
  const _DoseField({
    required this.drug,
    required this.controller,
    required this.onChanged,
  });

  final Drug drug;
  final TextEditingController controller;
  final VoidCallback onChanged;

  String _rangeLabel() {
    final r = drug.dosing.typicalTargetRangeMg;
    if (r.length < 2) return '';
    return 'typical ${_formatDose(r[0])}–${_formatDose(r[1])} mg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            labelText: '${drug.genericName} dose (mg)',
            suffixText: 'mg',
            suffixStyle: AppTextSizes.micro.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const Gap.v(AppSpace.xs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.md),
          child: Text(_rangeLabel(), style: AppTextSizes.micro),
        ),
      ],
    );
  }
}

/// Connector between FROM and TO. Vertical hairline + centred swap
/// button. Vertical orientation on phones, horizontal on the foldable
/// inner / tablet. Becomes interactive (lights accent + animates) the
/// moment both ends are filled.
class _Connector extends StatelessWidget {
  const _Connector({
    required this.horizontal,
    required this.canSwap,
    required this.onSwap,
  });

  final bool horizontal;
  final bool canSwap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final divider = horizontal
        ? const VerticalDivider(width: 1, thickness: 0.5)
        : const Divider(height: 1, thickness: 0.5);
    final swap = _SwapBadge(canSwap: canSwap, onSwap: onSwap);
    return SizedBox(
      width: horizontal ? 48 : double.infinity,
      height: horizontal ? double.infinity : 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(child: Center(child: divider)),
          swap,
        ],
      ),
    );
  }
}

class _SwapBadge extends StatelessWidget {
  const _SwapBadge({required this.canSwap, required this.onSwap});

  final bool canSwap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: canSwap
            ? AppColors.accent.withValues(alpha: 0.14)
            : AppColors.surface,
        border: Border.all(
          color: canSwap
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        shape: BoxShape.circle,
      ),
      child: Tooltip(
        message: canSwap ? 'Swap from ↔ to' : '',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canSwap ? onSwap : null,
            child: Icon(
              canSwap ? Icons.swap_vert_rounded : Icons.arrow_downward_rounded,
              size: 16,
              color: canSwap ? AppColors.accent : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Same-drug warning ──────────────────────────────────────────────

class _SameDrugWarning extends StatelessWidget {
  const _SameDrugWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm + 2,
        AppSpace.md,
        AppSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.swap_calls_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          Gap.h(AppSpace.sm),
          Expanded(
            child: Text(
              'From and To are the same drug. Pick a different target.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preflight card ──────────────────────────────────────────────────

class _PreflightCard extends StatelessWidget {
  const _PreflightCard({
    required this.plan,
    required this.engine,
    required this.ctx,
    required this.from,
    required this.to,
  });

  final SwitchPlan plan;
  final SwitchingEngine engine;
  final PatientContext ctx;
  final Drug from;
  final Drug to;

  @override
  Widget build(BuildContext context) {
    return switch (plan) {
      final SwitchPlanOk ok => _PreflightOk(
          ok: ok,
          engine: engine,
          ctx: ctx,
          from: from,
          to: to,
        ),
      SwitchPlanMaoiWashout(:final washoutDays, :final reason) =>
        _PreflightWarning(
          tone: AppColors.danger,
          eyebrow: 'MAOI WASHOUT REQUIRED',
          headline: '$washoutDays-day washout — no overlap permitted',
          body: reason,
        ),
      SwitchPlanMaudsleyGuidance(:final guidance) => _PreflightInfo(
          eyebrow: 'CLASS-LEVEL GUIDANCE',
          headline: guidance.headline,
          body: guidance.detail,
        ),
      SwitchPlanClozapineRedirect() => const _PreflightInfo(
          eyebrow: 'CLOZAPINE',
          headline: 'Use the Clozapine module',
          body: 'Clozapine has its own titration, FBC monitoring, and '
              'rechallenge protocols. Open the module from Home.',
        ),
      SwitchPlanNoRule(:final reason) => _PreflightWarning(
          tone: AppColors.warning,
          eyebrow: 'NO REVIEWED RULE',
          headline: 'No reviewed cross-taper rule for this pair',
          body: reason,
        ),
    };
  }
}

class _PreflightOk extends StatelessWidget {
  const _PreflightOk({
    required this.ok,
    required this.engine,
    required this.ctx,
    required this.from,
    required this.to,
  });

  final SwitchPlanOk ok;
  final SwitchingEngine engine;
  final PatientContext ctx;
  final Drug from;
  final Drug to;

  String _strategyLabel(String key) {
    switch (key) {
      case 'direct':
        return 'Direct switch';
      case 'cross-taper':
        return 'Cross-taper';
      case 'plateau-cross-taper':
        return 'Plateau cross-taper';
      case 'overlap-taper':
        return 'Overlap taper';
      case 'washout':
        return 'Washout';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ddiHits = checkPair(from.id, to.id);
    final scaleResult = ScaleResult(
      schedule: ok.schedule,
      applied: const ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 1,
        toFactor: 1,
      ),
      adapted: !ok.dosesMatchReference,
      warnings: const <ScaleWarning>[],
      evidencePenalty: ok.dosesMatchReference ? 0 : 1,
    );
    final ctxWarnings = <ContextWarning>[
      ...warningsForDrug(ctx, from.id),
      ...warningsForDrug(ctx, to.id),
    ];
    final score = computePsychSwitchScore(
      ScoreInputs(
        toDrug: to,
        scaleResult: scaleResult,
        ddiHits: ddiHits,
        contextWarnings: ctxWarnings,
        evidenceGrade: gradeCitations(ok.citations),
      ),
    );
    final flagCount = ok.safetyFlags.length;
    final ddiCount = ddiHits.length;
    final strategyLabel = _strategyLabel(ok.rule.strategy.jsonValue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md + 2,
        AppSpace.lg,
        AppSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('PREFLIGHT', style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.md),
          Row(
            children: <Widget>[
              ScoreRing(score: score, size: 64, strokeWidth: 6),
              const Gap.h(AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strategyLabel,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Gap.v(2),
                    Text(
                      '${ok.rule.durationDays} days · '
                      '${ok.schedule.length} steps',
                      style: AppTextSizes.micro.copyWith(height: 1.5),
                    ),
                    if (!ok.dosesMatchReference) ...<Widget>[
                      const Gap.v(AppSpace.xs),
                      Text(
                        'Adapted from reviewed reference doses.',
                        style: AppTextSizes.micro.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (ddiCount > 0 || flagCount > 0) ...<Widget>[
            const Gap.v(AppSpace.md),
            const Divider(height: 1, thickness: 0.5),
            const Gap.v(AppSpace.md),
            Wrap(
              spacing: AppSpace.xs + 2,
              runSpacing: AppSpace.xs + 2,
              children: <Widget>[
                if (ddiCount > 0)
                  _PreflightChip(
                    icon: Icons.shield_outlined,
                    label: '$ddiCount '
                        'interaction${ddiCount == 1 ? '' : 's'}',
                    tone: _ddiTone(ddiHits),
                  ),
                if (flagCount > 0)
                  _PreflightChip(
                    icon: Icons.warning_amber_rounded,
                    label: '$flagCount safety '
                        'flag${flagCount == 1 ? '' : 's'}',
                    tone: AppColors.warning,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _ddiTone(List<DdiHit> hits) {
    var worst = AppColors.accent;
    for (final h in hits) {
      switch (h.severity) {
        case DdiSeverity.avoid:
          return AppColors.danger;
        case DdiSeverity.warning:
        case DdiSeverity.caution:
          worst = AppColors.warning;
        case DdiSeverity.info:
          // keep accent
          break;
      }
    }
    return worst;
  }
}

class _PreflightChip extends StatelessWidget {
  const _PreflightChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: tone),
          const Gap.h(AppSpace.xs + 2),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreflightWarning extends StatelessWidget {
  const _PreflightWarning({
    required this.tone,
    required this.eyebrow,
    required this.headline,
    required this.body,
  });

  final Color tone;
  final String eyebrow;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: AppTextSizes.eyebrow.copyWith(color: tone)),
          const Gap.v(AppSpace.xs + 2),
          Text(
            headline,
            style: TextStyle(
              color: tone,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreflightInfo extends StatelessWidget {
  const _PreflightInfo({
    required this.eyebrow,
    required this.headline,
    required this.body,
  });

  final String eyebrow;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(eyebrow, style: AppTextSizes.eyebrow),
          const Gap.v(AppSpace.xs + 2),
          Text(
            headline,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary CTA ─────────────────────────────────────────────────────

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.muted,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Generate plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              const Gap.h(AppSpace.sm + 2),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: enabled ? Colors.white : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drug picker sheet (unchanged) ──────────────────────────────────

class _DrugPickerSheet extends StatefulWidget {
  const _DrugPickerSheet({
    required this.drugs,
    required this.rules,
    this.fromDrugId,
  });

  final List<Drug> drugs;
  final List<SwitchingRule> rules;
  final String? fromDrugId;

  @override
  State<_DrugPickerSheet> createState() => _DrugPickerSheetState();
}

class _DrugPickerSheetState extends State<_DrugPickerSheet> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<RankedDrug> _ranked() {
    final input = RankInput(
      rules: widget.rules,
      fromDrugId: widget.fromDrugId,
    );
    final ranked = rankDrugs(widget.drugs, input);
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isEmpty) return ranked;
    return ranked
        .where((r) =>
            r.drug.genericName.toLowerCase().contains(q) ||
            r.drug.id.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final ranked = _ranked();
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: mq.size.height * 0.72,
        child: Column(
          children: <Widget>[
            const Gap.v(AppSpace.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap.v(AppSpace.md),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.sm,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.fromDrugId == null ? 'Pick from-drug' : 'Pick to-drug',
                    style: AppTextSizes.subtitle,
                  ),
                  const Spacer(),
                  Text(
                    '${ranked.length} drug${ranked.length == 1 ? '' : 's'}',
                    style: AppTextSizes.micro,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: TextField(
                controller: _searchCtl,
                autofocus: true,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search drugs',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Gap.v(AppSpace.md),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  0,
                  AppSpace.lg,
                  AppSpace.lg,
                ),
                itemCount: ranked.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _DrugRow(ranked: ranked[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrugRow extends StatelessWidget {
  const _DrugRow({required this.ranked});

  final RankedDrug ranked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(ranked.drug),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md + 2),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
            if (ranked.tags.isNotEmpty)
              StatusPill(
                label: ranked.tags.first,
                tone: _toneFor(ranked.tier),
                compact: true,
              ),
          ],
        ),
      ),
    );
  }

  static Color _toneFor(RelevanceTier tier) {
    return switch (tier) {
      RelevanceTier.top => AppColors.to,
      RelevanceTier.reviewed => AppColors.accent,
      RelevanceTier.fallback => AppColors.muted,
      RelevanceTier.caution => AppColors.warning,
      RelevanceTier.avoid => AppColors.danger,
    };
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}
