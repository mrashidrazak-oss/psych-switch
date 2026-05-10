// Switch screen.
//
// Designed around one metaphor: a cross-titration is a transformation
// from drug A to drug B. The screen embodies that. A single hero card
// holds both ends of the switch (FROM | TO), connected by a vertical
// rail on phones or a horizontal arrow on the foldable inner display.
// Patient context lives as an AppBar action — always reachable, never
// in the way of the form.
//
// Function changes from the previous design:
//   • Doses prefill to the drug's typical starting dose the moment a
//     drug is picked. Saves typing 90% of the time; user can edit.
//   • Range hint ("typical: 50–200 mg") sits below the dose field so
//     the clinician knows when they've gone off-piste.
//   • CTA carries a live preview subtitle ("≈ 14-day cross-taper")
//     once both ends are filled, so the clinician knows roughly
//     what they're about to see before tapping.
//   • Same-drug guard renders a soft inline warning instead of
//     silently disabling the button without explanation.
//
// Drug picker sheet, patient context sheet, smart-picker tier ranking
// — all preserved verbatim. The redesign is purely scaffolding +
// affordances on top.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/patient_context_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/patient_context_sheet.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/smart_picker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

/// Maximum hero-card width on wide displays. Anything wider gets
/// flanked by whitespace — the cross-titration metaphor only reads
/// when both ends are visible to the same eye in one beat.
const double _maxFormWidth = 720;

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

  /// Estimated plan preview for the CTA subtitle. Returns null until
  /// both drugs and doses are valid; returns "—" when the engine has
  /// no rule (still useful info — saves the user a tap).
  String? get _previewLabel {
    if (!_ready) return null;
    final input = SwitchInput(
      fromDrugId: _from!.id,
      fromDoseMg: double.parse(_fromDoseCtl.text),
      toDrugId: _to!.id,
      toDoseMg: double.parse(_toDoseCtl.text),
    );
    final plan = widget.engine.generateSwitchPlan(input);
    return switch (plan) {
      SwitchPlanOk(:final rule) =>
        '≈ ${rule.durationDays}-day ${_strategyLabel(rule.strategy.jsonValue)}',
      SwitchPlanMaoiWashout(:final washoutDays) =>
        'MAOI washout — $washoutDays days',
      SwitchPlanMaudsleyGuidance() => 'Maudsley class-level guidance',
      SwitchPlanClozapineRedirect() => 'Use the Clozapine module',
      SwitchPlanNoRule() => 'No reviewed rule',
    };
  }

  static String _strategyLabel(String key) {
    switch (key) {
      case 'direct':
        return 'direct switch';
      case 'cross-taper':
        return 'cross-taper';
      case 'plateau-cross-taper':
        return 'plateau cross-taper';
      case 'overlap-taper':
        return 'overlap taper';
      case 'washout':
        return 'washout';
      default:
        return key;
    }
  }

  void _onContinue() {
    if (!_ready) return;
    unawaited(hapticsConfirm());
    final input = SwitchInput(
      fromDrugId: _from!.id,
      fromDoseMg: double.parse(_fromDoseCtl.text),
      toDrugId: _to!.id,
      toDoseMg: double.parse(_toDoseCtl.text),
    );
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

  @override
  Widget build(BuildContext context) {
    final visibleDrugs = widget.engine.listDrugs();
    final ctx = ref.watch(patientContextProvider);
    final ctxSummary = summarisePatientContext(ctx);
    final hasCtx = ctxSummary.isNotEmpty;

    final hero = _HeroCard(
      from: _from,
      to: _to,
      fromDoseCtl: _fromDoseCtl,
      toDoseCtl: _toDoseCtl,
      sameDrug: _sameDrug,
      onPickFrom: () async {
        final picked = await _openPicker(
          drugs: visibleDrugs,
          rules: widget.engine.listRules(),
        );
        if (picked != null) {
          setState(() {
            _from = picked;
            // Prefill typical starting dose. User can edit.
            _fromDoseCtl.text =
                _formatDose(picked.dosing.startingDoseMg);
            // Clear to-drug if it's now the same drug.
            if (_to?.id == picked.id) _to = null;
          });
        }
      },
      onPickTo: () async {
        final picked = await _openPicker(
          drugs:
              visibleDrugs.where((d) => d.id != _from?.id).toList(),
          rules: widget.engine.listRules(),
          fromDrugId: _from?.id,
        );
        if (picked != null) {
          setState(() {
            _to = picked;
            _toDoseCtl.text =
                _formatDose(picked.dosing.startingDoseMg);
          });
        }
      },
      onDoseChanged: () => setState(() {}),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('New switch'),
        actions: <Widget>[
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
                    hero,
                    if (_sameDrug) ...<Widget>[
                      const Gap.v(AppSpace.md),
                      const _SameDrugWarning(),
                    ],
                    const Gap.v(AppSpace.xl),
                    _PrimaryCta(
                      enabled: _ready,
                      preview: _previewLabel,
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
              const Icon(
                Icons.person,
                size: 14,
                color: AppColors.accent,
              ),
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
              const Icon(
                Icons.tune,
                size: 14,
                color: AppColors.accent,
              ),
              const Gap.h(AppSpace.xs),
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
    required this.fromDoseCtl,
    required this.toDoseCtl,
    required this.sameDrug,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onDoseChanged,
  });

  final Drug? from;
  final Drug? to;
  final TextEditingController fromDoseCtl;
  final TextEditingController toDoseCtl;
  final bool sameDrug;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onDoseChanged;

  @override
  Widget build(BuildContext context) {
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
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: context.isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: fromSection),
                  const _HConnector(),
                  Expanded(child: toSection),
                ],
              ),
            )
          : Column(
              children: <Widget>[
                fromSection,
                const _VConnector(),
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
  });

  final String side;
  final Color tone;
  final Drug? drug;
  final TextEditingController doseCtl;
  final VoidCallback onPick;
  final VoidCallback onDoseChanged;

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
              color: hasDrug
                  ? AppColors.borderStrong
                  : AppColors.border,
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
                          const Gap.v(2),
                          Text(
                            drug!.drugClass,
                            style: AppTextSizes.micro,
                          ),
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
            // RN parity + test contract: '<drug> dose (mg)'.
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
          child: Text(
            _rangeLabel(),
            style: AppTextSizes.micro,
          ),
        ),
      ],
    );
  }
}

/// Vertical from→to connector — sits between the FROM and TO sections
/// on phones. A pair of horizontal hairlines top + bottom with a
/// centred badge holding a down-arrow.
class _VConnector extends StatelessWidget {
  const _VConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned.fill(
            child: Center(
              child: Divider(height: 1, thickness: 0.5),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              size: 14,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal connector — sits between the FROM and TO sections on
/// the foldable inner / tablet / desktop. Vertical hairline + centred
/// badge with a right-arrow.
class _HConnector extends StatelessWidget {
  const _HConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned.fill(
            child: Center(
              child: VerticalDivider(width: 1, thickness: 0.5),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.muted,
            ),
          ),
        ],
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

// ── Primary CTA ─────────────────────────────────────────────────────

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.enabled,
    required this.preview,
    required this.onPressed,
  });

  final bool enabled;
  final String? preview;
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
                    color: AppColors.accent.withValues(alpha: 0.28),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // RN parity + test contract: 'Generate plan'.
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
                    color: enabled
                        ? Colors.white
                        : AppColors.muted,
                  ),
                ],
              ),
              if (enabled && preview != null) ...<Widget>[
                const Gap.v(2),
                Text(
                  preview!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drug picker sheet (unchanged from previous design) ─────────────

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
