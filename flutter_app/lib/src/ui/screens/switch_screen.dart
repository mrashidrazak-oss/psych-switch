// Switch wizard.
//
// Patient context → from-drug + dose → to-drug + dose → Generate plan.
//
// Drug selection lists every visible (non-hidden) drug from the engine
// in a searchable picker. The smart-picker tier ranking (top /
// reviewed / fallback / caution / avoid) is applied to the to-drug
// list once the from-drug is chosen, so reviewed pairs float to the
// top.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/patient_context_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/patient_context_sheet.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch_engine/smart_picker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

class SwitchScreen extends ConsumerWidget {
  const SwitchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New switch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
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

  bool get _ready {
    if (_from == null || _to == null || _from!.id == _to!.id) return false;
    final fromDose = double.tryParse(_fromDoseCtl.text);
    final toDose = double.tryParse(_toDoseCtl.text);
    return fromDose != null &&
        toDose != null &&
        fromDose > 0 &&
        toDose > 0;
  }

  void _onContinue() {
    if (!_ready) return;
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
    setState(() {}); // force header summary rebuild
  }

  @override
  Widget build(BuildContext context) {
    final visibleDrugs = widget.engine.listDrugs();
    final ctx = ref.watch(patientContextProvider);
    final ctxSummary = summarisePatientContext(ctx);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xxl,
      ),
      children: <Widget>[
        const Text('PATIENT CONTEXT', style: AppTextSizes.eyebrow),
        const Gap.v(AppSpace.sm),
        _PatientContextTile(
          summary: ctxSummary,
          onTap: _openPatientContextSheet,
        ),
        const Gap.v(AppSpace.xxl),

        // From-drug section.
        Row(
          children: <Widget>[
            const _DrugDot(color: AppColors.from),
            const Gap.h(AppSpace.sm),
            Text(
              'FROM DRUG',
              style: AppTextSizes.eyebrow.copyWith(color: AppColors.from),
            ),
          ],
        ),
        const Gap.v(AppSpace.sm),
        _DrugPickerField(
          label: 'Choose drug',
          selected: _from,
          drugs: visibleDrugs,
          rules: widget.engine.listRules(),
          onPicked: (d) => setState(() {
            _from = d;
            // Clear to-drug if it was the same drug.
            if (_to?.id == d.id) _to = null;
          }),
        ),
        if (_from != null) ...<Widget>[
          const Gap.v(AppSpace.md),
          _DoseField(
            label: '${_from!.genericName} dose (mg)',
            controller: _fromDoseCtl,
            onChanged: (_) => setState(() {}),
          ),
        ],

        // Visual transition between from and to.
        const _TransitionRail(),

        // To-drug section.
        Row(
          children: <Widget>[
            const _DrugDot(color: AppColors.to),
            const Gap.h(AppSpace.sm),
            Text(
              'TO DRUG',
              style: AppTextSizes.eyebrow.copyWith(color: AppColors.to),
            ),
          ],
        ),
        const Gap.v(AppSpace.sm),
        _DrugPickerField(
          label: 'Choose drug',
          selected: _to,
          drugs: visibleDrugs.where((d) => d.id != _from?.id).toList(),
          rules: widget.engine.listRules(),
          fromDrugId: _from?.id,
          onPicked: (d) => setState(() => _to = d),
        ),
        if (_to != null) ...<Widget>[
          const Gap.v(AppSpace.md),
          _DoseField(
            label: '${_to!.genericName} dose (mg)',
            controller: _toDoseCtl,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const Gap.v(AppSpace.xl),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _ready ? _onContinue : null,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Generate plan'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrugDot extends StatelessWidget {
  const _DrugDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TransitionRail extends StatelessWidget {
  const _TransitionRail();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        children: <Widget>[
          const Gap.h(AppSpace.xs),
          Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppColors.from, AppColors.to],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const Gap.h(AppSpace.md),
          Text(
            'Cross-titration',
            style: AppTextSizes.micro.copyWith(letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _DrugPickerField extends StatelessWidget {
  const _DrugPickerField({
    required this.label,
    required this.selected,
    required this.drugs,
    required this.rules,
    required this.onPicked,
    this.fromDrugId,
  });

  final String label;
  final Drug? selected;
  final List<Drug> drugs;
  final List<SwitchingRule> rules;
  final ValueChanged<Drug> onPicked;
  final String? fromDrugId;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<Drug>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DrugPickerSheet(
        drugs: drugs,
        rules: rules,
        fromDrugId: fromDrugId,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasSelection
                  ? AppColors.borderStrong
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md + 2,
            vertical: AppSpace.md + 2,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                hasSelection ? Icons.medication : Icons.search,
                size: 18,
                color: hasSelection ? AppColors.text : AppColors.muted,
              ),
              const Gap.h(AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      hasSelection ? selected!.genericName : label,
                      style: TextStyle(
                        color: hasSelection
                            ? AppColors.text
                            : AppColors.muted,
                        fontSize: 15,
                        fontWeight: hasSelection
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (hasSelection) ...<Widget>[
                      const Gap.v(2),
                      Text(
                        selected!.drugClass,
                        style: AppTextSizes.micro,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      // Avoid the on-screen keyboard.
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: mq.size.height * 0.72,
        child: Column(
          children: <Widget>[
            const Gap.v(AppSpace.md),
            // Drag handle.
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
                  // The global InputDecorationTheme handles the rest.
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

class _PatientContextTile extends StatelessWidget {
  const _PatientContextTile({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasContext = summary.isNotEmpty;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasContext
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md + 2,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasContext
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  hasContext ? Icons.person : Icons.person_outline,
                  size: 16,
                  color: hasContext ? AppColors.accent : AppColors.muted,
                ),
              ),
              const Gap.h(AppSpace.md),
              Expanded(
                child: Text(
                  hasContext
                      ? summary
                      : 'Tap to add age, sex, organ function, comorbidities…',
                  style: TextStyle(
                    color: hasContext ? AppColors.text : AppColors.muted,
                    fontSize: 13,
                    fontWeight:
                        hasContext ? FontWeight.w500 : FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(
                Icons.tune,
                color: AppColors.muted,
                size: 18,
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
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'mg',
        suffixStyle: AppTextSizes.micro.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
