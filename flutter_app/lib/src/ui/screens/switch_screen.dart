// Switch wizard — Phase 4C MVP.
//
// Four-step flow: pick from-drug, enter from-dose, pick to-drug, enter
// to-dose, navigate to /result with the assembled SwitchInput.
//
// Drug selection lists every visible (non-hidden) drug from the engine
// in a searchable picker. The smart-picker tier ranking (top /
// reviewed / fallback / caution / avoid) is applied to the to-drug
// list once the from-drug is chosen, so reviewed pairs float to the
// top.
//
// Patient context, AE filter, and saved-case integration are deferred
// to Phase 5.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
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

class _SwitchForm extends StatefulWidget {
  const _SwitchForm({required this.engine});

  final SwitchingEngine engine;

  @override
  State<_SwitchForm> createState() => _SwitchFormState();
}

class _SwitchFormState extends State<_SwitchForm> {
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

  @override
  Widget build(BuildContext context) {
    final visibleDrugs = widget.engine.listDrugs();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: <Widget>[
        const _StepLabel(text: 'FROM DRUG'),
        const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          _DoseField(
            label: '${_from!.genericName} dose (mg)',
            controller: _fromDoseCtl,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 32),

        const _StepLabel(text: 'TO DRUG'),
        const SizedBox(height: 8),
        _DrugPickerField(
          label: 'Choose drug',
          selected: _to,
          drugs: visibleDrugs.where((d) => d.id != _from?.id).toList(),
          rules: widget.engine.listRules(),
          fromDrugId: _from?.id,
          onPicked: (d) => setState(() => _to = d),
        ),
        if (_to != null) ...<Widget>[
          const SizedBox(height: 16),
          _DoseField(
            label: '${_to!.genericName} dose (mg)',
            controller: _toDoseCtl,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _ready ? _onContinue : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.surface,
              foregroundColor: Colors.white,
              disabledForegroundColor: AppColors.muted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Generate plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
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
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                selected?.genericName ?? label,
                style: TextStyle(
                  color: selected != null ? AppColors.text : AppColors.muted,
                  fontSize: 15,
                  fontWeight:
                      selected != null ? FontWeight.w600 : FontWeight.w400,
                ),
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
        height: mq.size.height * 0.7,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            // Drag handle.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtl,
                autofocus: true,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search drugs',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.bg,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ranked.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.border, height: 1),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  const SizedBox(height: 2),
                  Text(
                    ranked.drug.drugClass,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (ranked.tags.isNotEmpty) _TierTag(ranked: ranked),
          ],
        ),
      ),
    );
  }
}

class _TierTag extends StatelessWidget {
  const _TierTag({required this.ranked});

  final RankedDrug ranked;

  @override
  Widget build(BuildContext context) {
    final tag = ranked.tags.first;
    final color = switch (ranked.tier) {
      RelevanceTier.top => AppColors.to,
      RelevanceTier.reviewed => AppColors.accent,
      RelevanceTier.fallback => AppColors.muted,
      RelevanceTier.caution => AppColors.warning,
      RelevanceTier.avoid => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
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
      style: const TextStyle(color: AppColors.text, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
