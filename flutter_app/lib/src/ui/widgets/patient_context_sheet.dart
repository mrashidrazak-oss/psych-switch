// Patient context sheet — Phase 7B.
//
// Modal bottom sheet that lets the clinician build a [PatientContext]
// for the current switch. Returns the new context (or null if
// cancelled) so callers can write it to [patientContextProvider].
//
// Surfaces:
//   • DEMOGRAPHICS — age, sex
//   • ORGAN FUNCTION — renal band, hepatic band
//   • PREGNANCY — pregnant + trimester, breastfeeding
//   • LIFESTYLE — smoker
//   • COMORBIDITIES — cardiac · seizure · diabetes · obesity ·
//     dyslipidemia
//
// A "Clear" button on the action row resets to [emptyContext]. The
// header shows an inline summary so the clinician knows what they're
// editing.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';

/// Open the patient-context sheet. Resolves to the new [PatientContext]
/// when the user taps Apply, or `null` if they dismissed.
Future<PatientContext?> showPatientContextSheet(
  BuildContext context, {
  required PatientContext initial,
}) {
  return showModalBottomSheet<PatientContext>(
    context: context,
    isScrollControlled: true,
    // backgroundColor + shape come from the global BottomSheetTheme.
    builder: (_) => _PatientContextSheet(initial: initial),
  );
}

/// One-line human summary of [ctx]. Empty string means "no context set".
String summarisePatientContext(PatientContext ctx) {
  final parts = <String>[];
  if (ctx.ageYears != null) parts.add('${ctx.ageYears!.toInt()}y');
  if (ctx.sex != null) parts.add(_sexLabel(ctx.sex!));
  if (ctx.renal != null && ctx.renal != RenalFn.normal) {
    parts.add('renal ${_renalLabel(ctx.renal!)}');
  }
  if (ctx.hepatic != null && ctx.hepatic != HepaticFn.normal) {
    parts.add('hepatic ${_hepaticLabel(ctx.hepatic!)}');
  }
  if (ctx.pregnant ?? false) {
    parts.add(
      ctx.trimester != null ? 'pregnant T${ctx.trimester}' : 'pregnant',
    );
  }
  if (ctx.breastfeeding ?? false) parts.add('breastfeeding');
  if (ctx.smoker ?? false) parts.add('smoker');
  final como = ctx.comorbidities;
  if (como != null) {
    if (como.cardiac ?? false) parts.add('cardiac');
    if (como.seizure ?? false) parts.add('seizure');
    if (como.diabetes ?? false) parts.add('diabetes');
    if (como.obesity ?? false) parts.add('obesity');
    if (como.dyslipidemia ?? false) parts.add('dyslipidemia');
  }
  return parts.join(' · ');
}

String _sexLabel(Sex s) => switch (s) {
      Sex.male => 'M',
      Sex.female => 'F',
      Sex.other => 'O',
    };

String _renalLabel(RenalFn r) => switch (r) {
      RenalFn.normal => 'normal',
      RenalFn.mild => 'mild',
      RenalFn.moderate => 'moderate',
      RenalFn.severe => 'severe',
    };

String _hepaticLabel(HepaticFn h) => switch (h) {
      HepaticFn.normal => 'normal',
      HepaticFn.mild => 'mild',
      HepaticFn.moderate => 'moderate',
      HepaticFn.severe => 'severe',
    };

class _PatientContextSheet extends StatefulWidget {
  const _PatientContextSheet({required this.initial});

  final PatientContext initial;

  @override
  State<_PatientContextSheet> createState() => _PatientContextSheetState();
}

class _PatientContextSheetState extends State<_PatientContextSheet> {
  late TextEditingController _ageCtl;
  Sex? _sex;
  RenalFn? _renal;
  HepaticFn? _hepatic;
  bool _pregnant = false;
  int? _trimester;
  bool _breastfeeding = false;
  bool _smoker = false;
  bool _cardiac = false;
  bool _seizure = false;
  bool _diabetes = false;
  bool _obesity = false;
  bool _dyslipidemia = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _ageCtl = TextEditingController(
      text: i.ageYears != null ? i.ageYears!.toInt().toString() : '',
    );
    _sex = i.sex;
    _renal = i.renal;
    _hepatic = i.hepatic;
    _pregnant = i.pregnant ?? false;
    _trimester = i.trimester;
    _breastfeeding = i.breastfeeding ?? false;
    _smoker = i.smoker ?? false;
    final c = i.comorbidities;
    _cardiac = c?.cardiac ?? false;
    _seizure = c?.seizure ?? false;
    _diabetes = c?.diabetes ?? false;
    _obesity = c?.obesity ?? false;
    _dyslipidemia = c?.dyslipidemia ?? false;
  }

  @override
  void dispose() {
    _ageCtl.dispose();
    super.dispose();
  }

  PatientContext _build() {
    final ageText = _ageCtl.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final hasComorbidities = _cardiac ||
        _seizure ||
        _diabetes ||
        _obesity ||
        _dyslipidemia;
    return PatientContext(
      ageYears: age,
      sex: _sex,
      renal: _renal,
      hepatic: _hepatic,
      pregnant: _pregnant ? true : null,
      trimester: _pregnant ? _trimester : null,
      breastfeeding: _breastfeeding ? true : null,
      smoker: _smoker ? true : null,
      comorbidities: hasComorbidities
          ? Comorbidities(
              cardiac: _cardiac ? true : null,
              seizure: _seizure ? true : null,
              diabetes: _diabetes ? true : null,
              obesity: _obesity ? true : null,
              dyslipidemia: _dyslipidemia ? true : null,
            )
          : null,
    );
  }

  void _clear() {
    setState(() {
      _ageCtl.text = '';
      _sex = null;
      _renal = null;
      _hepatic = null;
      _pregnant = false;
      _trimester = null;
      _breastfeeding = false;
      _smoker = false;
      _cardiac = false;
      _seizure = false;
      _diabetes = false;
      _obesity = false;
      _dyslipidemia = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: mq.size.height * 0.85,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpace.xl),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Patient context', style: AppTextSizes.subtitle),
              ),
            ),
            const Gap.v(AppSpace.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Optional. Every field below narrows the warnings, '
                  'monitoring add-ons, and PsychSwitch Score.',
                  style: AppTextSizes.caption.copyWith(height: 1.5),
                ),
              ),
            ),
            const Gap.v(AppSpace.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  const _SectionLabel('DEMOGRAPHICS'),
                  const SizedBox(height: 8),
                  _AgeField(controller: _ageCtl),
                  const SizedBox(height: 12),
                  _SegmentedRow<Sex>(
                    label: 'Sex',
                    options: const <(Sex?, String)>[
                      (null, 'Any'),
                      (Sex.male, 'Male'),
                      (Sex.female, 'Female'),
                      (Sex.other, 'Other'),
                    ],
                    selected: _sex,
                    onSelected: (v) => setState(() => _sex = v),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel('ORGAN FUNCTION'),
                  const SizedBox(height: 8),
                  _SegmentedRow<RenalFn>(
                    label: 'Renal',
                    options: const <(RenalFn?, String)>[
                      (null, 'Any'),
                      (RenalFn.normal, 'Normal'),
                      (RenalFn.mild, 'Mild'),
                      (RenalFn.moderate, 'Mod'),
                      (RenalFn.severe, 'Severe'),
                    ],
                    selected: _renal,
                    onSelected: (v) => setState(() => _renal = v),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedRow<HepaticFn>(
                    label: 'Hepatic',
                    options: const <(HepaticFn?, String)>[
                      (null, 'Any'),
                      (HepaticFn.normal, 'Normal'),
                      (HepaticFn.mild, 'Mild'),
                      (HepaticFn.moderate, 'Mod'),
                      (HepaticFn.severe, 'Severe'),
                    ],
                    selected: _hepatic,
                    onSelected: (v) => setState(() => _hepatic = v),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel('PREGNANCY · LIFESTYLE'),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Pregnant',
                    value: _pregnant,
                    onChanged: (v) => setState(() {
                      _pregnant = v;
                      if (!v) _trimester = null;
                    }),
                  ),
                  if (_pregnant) ...<Widget>[
                    const SizedBox(height: 8),
                    _SegmentedRow<int>(
                      label: 'Trimester',
                      options: const <(int?, String)>[
                        (null, '—'),
                        (1, 'T1'),
                        (2, 'T2'),
                        (3, 'T3'),
                      ],
                      selected: _trimester,
                      onSelected: (v) => setState(() => _trimester = v),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Breastfeeding',
                    value: _breastfeeding,
                    onChanged: (v) => setState(() => _breastfeeding = v),
                  ),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Current smoker',
                    description: 'CYP1A2 inducer — affects clozapine, '
                        'olanzapine plasma levels.',
                    value: _smoker,
                    onChanged: (v) => setState(() => _smoker = v),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel('COMORBIDITIES'),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Cardiac history',
                    description: 'Triggers QTc warnings on relevant agents.',
                    value: _cardiac,
                    onChanged: (v) => setState(() => _cardiac = v),
                  ),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Seizure history',
                    value: _seizure,
                    onChanged: (v) => setState(() => _seizure = v),
                  ),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Diabetes',
                    value: _diabetes,
                    onChanged: (v) => setState(() => _diabetes = v),
                  ),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Obesity',
                    value: _obesity,
                    onChanged: (v) => setState(() => _obesity = v),
                  ),
                  const SizedBox(height: 8),
                  _CheckRow(
                    label: 'Dyslipidemia',
                    value: _dyslipidemia,
                    onChanged: (v) => setState(() => _dyslipidemia = v),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.lg,
              ),
              child: Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const Gap.h(AppSpace.sm),
                  FilledButton(
                    onPressed: () {
                      unawaited(hapticsConfirm());
                      Navigator.of(context).pop(_build());
                    },
                    child: const Text('Apply'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextSizes.eyebrow);
  }
}

class _AgeField extends StatelessWidget {
  const _AgeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      style: const TextStyle(color: AppColors.text, fontSize: 15),
      // Decoration borders + fill come from the global InputDecorationTheme.
      decoration: const InputDecoration(
        labelText: 'Age (years)',
        suffixText: 'yrs',
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<(T?, String)> options;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap.v(AppSpace.xs + 2),
        Wrap(
          spacing: AppSpace.xs + 2,
          runSpacing: AppSpace.xs + 2,
          children: options.map((opt) {
            final value = opt.$1;
            final text = opt.$2;
            final isSelected = value == selected;
            return Material(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadii.sm + 2),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(value),
                child: Ink(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppRadii.sm + 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.accent : AppColors.text,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? AppColors.accent.withValues(alpha: 0.06)
          : AppColors.bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: value
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.sm + 2,
            AppSpace.sm,
            AppSpace.sm + 2,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        color: value ? AppColors.text : AppColors.text,
                        fontSize: 13,
                        fontWeight:
                            value ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (description != null) ...<Widget>[
                      const Gap.v(2),
                      Text(
                        description!,
                        style: AppTextSizes.micro.copyWith(height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
              // Switch theming comes from the global SwitchTheme.
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
