// Dose-equivalency calculator — three families on one screen.
//   • Antipsychotics    → CPZ-eq
//   • Antidepressants   → fluoxetine-eq
//   • Benzodiazepines   → diazepam-eq
//
// Pick family → from-drug → enter dose → optional to-drug. The card
// surfaces both the reference-units expression and the converted
// dose. RN parity: `screens/EquivalencyScreen.tsx`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/dose_equivalents.dart';

class EquivalencyScreen extends StatefulWidget {
  const EquivalencyScreen({super.key});

  @override
  State<EquivalencyScreen> createState() => _EquivalencyScreenState();
}

class _EquivalencyScreenState extends State<EquivalencyScreen> {
  EquivalencyFamily _family = EquivalencyFamily.cpz;
  String? _fromId;
  String? _toId;
  final _doseCtl = TextEditingController();

  static const _tabs = <(EquivalencyFamily, String, String)>[
    (EquivalencyFamily.cpz, 'Antipsychotics', 'CPZ-eq'),
    (EquivalencyFamily.fluoxetine, 'Antidepressants', 'FLX-eq'),
    (EquivalencyFamily.diazepam, 'Benzodiazepines', 'DZP-eq'),
  ];

  @override
  void dispose() {
    _doseCtl.dispose();
    super.dispose();
  }

  void _setFamily(EquivalencyFamily f) {
    if (f == _family) return;
    setState(() {
      _family = f;
      _fromId = null;
      _toId = null;
      _doseCtl.clear();
    });
  }

  String _fmt(num n) {
    if (n is int || n == n.toInt()) return n.toInt().toString();
    return n.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final meta = equivalencyFamilies[_family]!;
    final fromDose = double.tryParse(_doseCtl.text);
    final validDose = fromDose != null && fromDose > 0;

    final refResult = (validDose && _fromId != null)
        ? doseInReferenceUnits(_family, _fromId!, fromDose)
        : null;
    final convResult =
        (validDose && _fromId != null && _toId != null && _fromId != _toId)
            ? convertWithinFamily(_family, _fromId!, fromDose, _toId!)
            : null;

    // Form column — picker + dose input + family tabs + meta.
    final form = <Widget>[
            // Family tabs.
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: <Widget>[
                  for (final (f, label, sub) in _tabs)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _setFamily(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.sm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: f == _family
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                label,
                                style: TextStyle(
                                  color: f == _family
                                      ? Colors.white
                                      : AppColors.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Gap.v(2),
                              Text(
                                sub,
                                style: TextStyle(
                                  color: f == _family
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : AppColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Gap.v(AppSpace.md),

            // Family meta.
            Text(meta.title, style: AppTextSizes.eyebrow),
            const Gap.v(2),
            Text(
              'Reference: ${meta.reference.name} ${_fmt(meta.reference.mg)} mg = '
              '1 ${meta.shortLabel}',
              style: AppTextSizes.micro.copyWith(height: 1.5),
            ),
            const Gap.v(AppSpace.md),

            // From picker + dose.
            const Text('FROM DRUG', style: AppTextSizes.eyebrow),
            const Gap.v(AppSpace.sm),
            _DrugPicker(
              entries: meta.entries,
              selectedId: _fromId,
              onChanged: (id) => setState(() => _fromId = id),
            ),
            const Gap.v(AppSpace.md),
            TextField(
              controller: _doseCtl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Current dose (mg)',
                suffixText: 'mg',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Gap.v(AppSpace.lg),

            // To picker (optional).
            const Text(
              'CONVERT TO (OPTIONAL)',
              style: AppTextSizes.eyebrow,
            ),
            const Gap.v(AppSpace.sm),
            _DrugPicker(
              entries: meta.entries.where((e) => e.id != _fromId).toList(),
              selectedId: _toId,
              onChanged: (id) => setState(() => _toId = id),
              hint: 'Pick a target drug',
            ),
    ];

    // Output column — equivalent dose + limitations + citations.
    final output = <Widget>[
            // Result.
            if (refResult != null)
              _ResultPanel(
                meta: meta,
                fromName: meta.entries
                    .firstWhere((e) => e.id == _fromId)
                    .genericName,
                fromDoseMg: fromDose!,
                refUnits: refResult.refUnits,
                referenceDoseMg: refResult.referenceDoseMg,
                conv: convResult == null
                    ? null
                    : (
                        toName: meta.entries
                            .firstWhere((e) => e.id == _toId)
                            .genericName,
                        toDoseMg: convResult.toDoseMg,
                      ),
                fmt: _fmt,
              ),

            const Gap.v(AppSpace.lg),

            // Limitations + sources.
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.5),
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
                  const Text('LIMITATIONS', style: AppTextSizes.eyebrow),
                  const Gap.v(AppSpace.xs),
                  for (final l in meta.limitations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $l',
                        style: AppTextSizes.micro.copyWith(height: 1.5),
                      ),
                    ),
                  const Gap.v(AppSpace.sm),
                  const Text('SOURCES', style: AppTextSizes.eyebrow),
                  const Gap.v(AppSpace.xs),
                  for (final c in meta.citations)
                    Text(
                      '· $c',
                      style: AppTextSizes.micro
                          .copyWith(fontFamily: 'monospace'),
                    ),
                ],
              ),
            ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose equivalency'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: context.isWide
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg + 4,
                  AppSpace.lg,
                  AppSpace.lg + 4,
                  AppSpace.xl,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: form,
                        ),
                      ),
                    ),
                    const Gap.h(AppSpace.xl),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: output,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg + 4,
                  AppSpace.lg,
                  AppSpace.lg + 4,
                  AppSpace.xl,
                ),
                children: <Widget>[
                  ...form,
                  const Gap.v(AppSpace.lg),
                  ...output,
                ],
              ),
      ),
    );
  }
}

class _DrugPicker extends StatelessWidget {
  const _DrugPicker({
    required this.entries,
    required this.selectedId,
    required this.onChanged,
    this.hint = 'Pick a drug',
  });

  final List<EquivalencyEntry> entries;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String?>(
            value: selectedId,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            iconEnabledColor: AppColors.muted,
            hint: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
              ),
              child: Text(
                hint,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.md),
                  child: Text(
                    '— none —',
                    style:
                        TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ),
              ),
              for (final e in entries)
                DropdownMenuItem<String?>(
                  value: e.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    child: Text(
                      e.genericName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.meta,
    required this.fromName,
    required this.fromDoseMg,
    required this.refUnits,
    required this.referenceDoseMg,
    required this.conv,
    required this.fmt,
  });

  final EquivalencyFamilyMeta meta;
  final String fromName;
  final num fromDoseMg;
  final num refUnits;
  final num referenceDoseMg;
  final ({String toName, num toDoseMg})? conv;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
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
          const Text(
            'EQUIVALENT DOSE',
            style: AppTextSizes.eyebrow,
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            '$fromName ${fmt(fromDoseMg)} mg',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Gap.v(AppSpace.xs),
          Text(
            '≈ ${fmt(refUnits)} ${meta.shortLabel} '
            '(${fmt(referenceDoseMg)} mg ${meta.reference.name})',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (conv != null) ...<Widget>[
            const Gap.v(AppSpace.md),
            const Divider(height: 1),
            const Gap.v(AppSpace.md),
            const Text('CONVERTS TO', style: AppTextSizes.eyebrow),
            const Gap.v(AppSpace.xs + 2),
            Text(
              '${conv!.toName} ${fmt(conv!.toDoseMg)} mg',
              style: const TextStyle(
                color: AppColors.to,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
