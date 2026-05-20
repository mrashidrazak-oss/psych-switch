// Quick calculator suite — four bedside calculators a psychiatrist
// reaches for daily:
//
//   • Creatinine clearance (Cockcroft-Gault) — for renal dose
//     adjustments on lithium, paliperidone, etc.
//   • Corrected QTc (Bazett + Fridericia) — for QTc-stacking
//     decisions.
//   • Lithium dose calculator (Jermain) — for prescribing the
//     starting dose to target trough 0.6–1.0 mmol/L.
//   • BMI (kg/m²) — for olanzapine / clozapine baseline.
//
// Pure presentation — every formula is implemented inline. No engine
// data needed.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculators'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xl,
          ),
          children: const <Widget>[
            _CalculatorsHero(),
            Gap.v(ClinicalSpace.lg),
            _CrClCalculator(),
            Gap.v(ClinicalSpace.lg),
            _QtcCalculator(),
            Gap.v(ClinicalSpace.lg),
            _BmiCalculator(),
            Gap.v(ClinicalSpace.lg),
            _FooterNote(),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────

class _CalculatorsHero extends StatelessWidget {
  const _CalculatorsHero();

  @override
  Widget build(BuildContext context) {
    const tone = ClinicalPalette.accent;
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: tone.withValues(alpha: 0.08),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.md + 2,
              ClinicalSpace.md,
              ClinicalSpace.md + 2,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.36),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    size: 19,
                    color: tone,
                  ),
                ),
                const Gap.h(ClinicalSpace.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Calculators',
                        style: TextStyle(
                          color: ClinicalPalette.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      Gap.v(ClinicalSpace.xs - 1),
                      Text(
                        'CrCl · QTc · BMI — bedside quick maths',
                        style: TextStyle(
                          color: ClinicalPalette.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: ClinicalPalette.bg.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
              ClinicalSpace.lg,
              ClinicalSpace.sm + 2,
            ),
            child: Text(
              'Every formula here is the standard equation — always '
              'sanity-check against the lab range and your local '
              'pathology service. Lithium dose calculator coming next.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic calc card wrapper ─────────────────────────────────────────

class _CalcCard extends StatelessWidget {
  const _CalcCard({
    required this.eyebrow,
    required this.title,
    required this.formula,
    required this.fields,
    required this.result,
  });

  final String eyebrow;
  final String title;
  final String formula;
  final List<Widget> fields;
  final Widget result;

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
          Text(eyebrow, style: ClinicalText.eyebrow),
          const Gap.v(ClinicalSpace.xs),
          Text(
            title,
            style: const TextStyle(
              color: ClinicalPalette.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
          const Gap.v(ClinicalSpace.xs),
          Text(
            formula,
            style: ClinicalText.caption.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
          const Gap.v(ClinicalSpace.md + 2),
          ...fields,
          const Gap.v(ClinicalSpace.md),
          Container(
            height: 0.5,
            color: ClinicalPalette.border.withValues(alpha: 0.5),
          ),
          const Gap.v(ClinicalSpace.md),
          result,
        ],
      ),
    );
  }
}

// ── Field helpers ─────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  const _NumField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
      ],
      onChanged: (_) => onChanged(),
      style: const TextStyle(
        color: ClinicalPalette.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixStyle: ClinicalText.caption.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: ClinicalText.eyebrow,
        ),
        const Gap.v(ClinicalSpace.xs + 2),
        Container(
          decoration: BoxDecoration(
            color: ClinicalPalette.bg,
            borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
            border: Border.all(
              color: ClinicalPalette.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: <Widget>[
              for (final (val, name) in options)
                Expanded(
                  child: _SegmentButton(
                    label: name,
                    isActive: val == selected,
                    onTap: () => onSelected(val),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: ClinicalSpace.sm + 1,
          ),
          decoration: BoxDecoration(
            color: isActive ? ClinicalPalette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            border: isActive
                ? Border.all(
                    color: ClinicalPalette.border.withValues(alpha: 0.7),
                    width: 0.5,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? ClinicalPalette.text : ClinicalPalette.muted,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.eyebrow,
    required this.value,
    required this.unit,
    this.subtitle,
    this.tone,
  });

  final String eyebrow;
  final String value;
  final String unit;
  final String? subtitle;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          eyebrow,
          style: const TextStyle(
            color: ClinicalPalette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
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
                color: tone ?? ClinicalPalette.text,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.05,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            const Gap.h(ClinicalSpace.xs + 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                unit,
                style: const TextStyle(
                  color: ClinicalPalette.mutedStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const Gap.v(ClinicalSpace.xs),
          Text(
            subtitle!,
            style: TextStyle(
              color: tone ?? ClinicalPalette.mutedStrong,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ── CrCl (Cockcroft-Gault) ────────────────────────────────────────────

enum _Sex { male, female }

class _CrClCalculator extends StatefulWidget {
  const _CrClCalculator();

  @override
  State<_CrClCalculator> createState() => _CrClCalculatorState();
}

class _CrClCalculatorState extends State<_CrClCalculator> {
  final _ageCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _creatCtl = TextEditingController();
  _Sex _sex = _Sex.male;

  @override
  void dispose() {
    _ageCtl.dispose();
    _weightCtl.dispose();
    _creatCtl.dispose();
    super.dispose();
  }

  double? get _crcl {
    final age = double.tryParse(_ageCtl.text);
    final weight = double.tryParse(_weightCtl.text);
    final creat = double.tryParse(_creatCtl.text);
    if (age == null || weight == null || creat == null || creat == 0) {
      return null;
    }
    // Cockcroft-Gault for creatinine in µmol/L:
    //   CrCl (mL/min) = ((140 − age) × weight × F) / (0.814 × creat)
    //   F = 1 (male), 0.85 (female).
    final f = _sex == _Sex.male ? 1.0 : 0.85;
    return ((140 - age) * weight * f) / (0.814 * creat);
  }

  ({String label, Color tone})? _categorise(double crcl) {
    if (crcl >= 90) return (label: 'Normal renal function', tone: ClinicalPalette.toneMintInk);
    if (crcl >= 60) {
      return (label: 'Mild impairment (CKD 2)', tone: ClinicalPalette.accent);
    }
    if (crcl >= 30) {
      return (label: 'Moderate impairment (CKD 3)', tone: ClinicalPalette.warning);
    }
    if (crcl >= 15) {
      return (label: 'Severe impairment (CKD 4) — dose-reduce', tone: ClinicalPalette.danger);
    }
    return (label: 'Kidney failure (CKD 5) — specialist input', tone: ClinicalPalette.danger);
  }

  @override
  Widget build(BuildContext context) {
    final crcl = _crcl;
    final cat = crcl != null ? _categorise(crcl) : null;
    return _CalcCard(
      eyebrow: 'RENAL',
      title: 'Creatinine clearance',
      formula: 'CrCl = ((140 − age) × wt × F) / (0.814 × serum-Cr)',
      fields: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumField(
                label: 'Age',
                suffix: 'yrs',
                controller: _ageCtl,
                onChanged: () => setState(() {}),
              ),
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: _NumField(
                label: 'Weight',
                suffix: 'kg',
                controller: _weightCtl,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        const Gap.v(ClinicalSpace.md),
        _NumField(
          label: 'Serum creatinine',
          suffix: 'µmol/L',
          controller: _creatCtl,
          onChanged: () => setState(() {}),
        ),
        const Gap.v(ClinicalSpace.md),
        _Segmented<_Sex>(
          label: 'Sex',
          options: const <(_Sex, String)>[
            (_Sex.male, 'Male'),
            (_Sex.female, 'Female'),
          ],
          selected: _sex,
          onSelected: (v) => setState(() => _sex = v),
        ),
      ],
      result: crcl == null
          ? Text(
              'Enter age, weight, and serum creatinine to compute.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            )
          : _ResultStat(
              eyebrow: 'CREATININE CLEARANCE',
              value: crcl.toStringAsFixed(0),
              unit: 'mL/min',
              subtitle: cat?.label,
              tone: cat?.tone,
            ),
    );
  }
}

// ── QTc (Bazett + Fridericia) ────────────────────────────────────────

enum _QtcMethod { bazett, fridericia }

class _QtcCalculator extends StatefulWidget {
  const _QtcCalculator();

  @override
  State<_QtcCalculator> createState() => _QtcCalculatorState();
}

class _QtcCalculatorState extends State<_QtcCalculator> {
  final _qtCtl = TextEditingController();
  final _hrCtl = TextEditingController();
  _QtcMethod _method = _QtcMethod.bazett;

  @override
  void dispose() {
    _qtCtl.dispose();
    _hrCtl.dispose();
    super.dispose();
  }

  double? get _qtc {
    final qt = double.tryParse(_qtCtl.text);
    final hr = double.tryParse(_hrCtl.text);
    if (qt == null || hr == null || hr <= 0) return null;
    // RR (s) = 60 / HR.
    final rr = 60 / hr;
    switch (_method) {
      case _QtcMethod.bazett:
        // QTcB = QT / sqrt(RR).
        return qt / math.sqrt(rr);
      case _QtcMethod.fridericia:
        // QTcF = QT / RR^(1/3).
        return qt / math.pow(rr, 1 / 3);
    }
  }

  ({String label, Color tone})? _categorise(double qtc) {
    if (qtc < 440) {
      return (label: 'Normal', tone: ClinicalPalette.toneMintInk);
    }
    if (qtc < 460) {
      return (label: 'Borderline (men) · upper-normal (women)', tone: ClinicalPalette.accent);
    }
    if (qtc < 500) {
      return (label: 'Prolonged — reassess QTc-prolonging meds', tone: ClinicalPalette.warning);
    }
    return (
      label: 'Severely prolonged — torsades risk',
      tone: ClinicalPalette.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final qtc = _qtc;
    final cat = qtc != null ? _categorise(qtc) : null;
    return _CalcCard(
      eyebrow: 'CARDIAC',
      title: 'Corrected QTc',
      formula: _method == _QtcMethod.bazett
          ? 'QTcB = QT / √RR    (RR = 60/HR)'
          : 'QTcF = QT / ∛RR    (RR = 60/HR)',
      fields: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumField(
                label: 'QT interval',
                suffix: 'ms',
                controller: _qtCtl,
                onChanged: () => setState(() {}),
              ),
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: _NumField(
                label: 'Heart rate',
                suffix: 'bpm',
                controller: _hrCtl,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        const Gap.v(ClinicalSpace.md),
        _Segmented<_QtcMethod>(
          label: 'Correction',
          options: const <(_QtcMethod, String)>[
            (_QtcMethod.bazett, 'Bazett'),
            (_QtcMethod.fridericia, 'Fridericia'),
          ],
          selected: _method,
          onSelected: (v) => setState(() => _method = v),
        ),
      ],
      result: qtc == null
          ? Text(
              'Enter the measured QT (ms) and heart rate (bpm) to '
              'compute the rate-corrected QTc.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            )
          : _ResultStat(
              eyebrow: _method == _QtcMethod.bazett ? 'QTcB' : 'QTcF',
              value: qtc.toStringAsFixed(0),
              unit: 'ms',
              subtitle: cat?.label,
              tone: cat?.tone,
            ),
    );
  }
}

// ── BMI ──────────────────────────────────────────────────────────────

class _BmiCalculator extends StatefulWidget {
  const _BmiCalculator();

  @override
  State<_BmiCalculator> createState() => _BmiCalculatorState();
}

class _BmiCalculatorState extends State<_BmiCalculator> {
  final _weightCtl = TextEditingController();
  final _heightCtl = TextEditingController();

  @override
  void dispose() {
    _weightCtl.dispose();
    _heightCtl.dispose();
    super.dispose();
  }

  double? get _bmi {
    final w = double.tryParse(_weightCtl.text);
    final hCm = double.tryParse(_heightCtl.text);
    if (w == null || hCm == null || hCm <= 0) return null;
    final hM = hCm / 100;
    return w / (hM * hM);
  }

  ({String label, Color tone})? _categorise(double bmi) {
    if (bmi < 18.5) {
      return (label: 'Underweight', tone: ClinicalPalette.accent);
    }
    if (bmi < 25) {
      return (label: 'Normal weight', tone: ClinicalPalette.toneMintInk);
    }
    if (bmi < 30) {
      return (label: 'Overweight', tone: ClinicalPalette.warning);
    }
    if (bmi < 35) return (label: 'Obesity class I', tone: ClinicalPalette.warning);
    if (bmi < 40) return (label: 'Obesity class II', tone: ClinicalPalette.danger);
    return (label: 'Obesity class III', tone: ClinicalPalette.danger);
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;
    final cat = bmi != null ? _categorise(bmi) : null;
    return _CalcCard(
      eyebrow: 'BASELINE',
      title: 'Body mass index',
      formula: 'BMI = weight / height² (kg, m)',
      fields: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumField(
                label: 'Weight',
                suffix: 'kg',
                controller: _weightCtl,
                onChanged: () => setState(() {}),
              ),
            ),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: _NumField(
                label: 'Height',
                suffix: 'cm',
                controller: _heightCtl,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      ],
      result: bmi == null
          ? Text(
              'Enter weight (kg) and height (cm) to compute.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            )
          : _ResultStat(
              eyebrow: 'BMI',
              value: bmi.toStringAsFixed(1),
              unit: 'kg/m²',
              subtitle: cat?.label,
              tone: cat?.tone,
            ),
    );
  }
}

// ── Footer note ──────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClinicalSpace.lg),
        child: Text(
          "Bedside heuristics. Always confirm against the lab's "
          'reference range and re-check on a second sample before '
          'making prescribing decisions.',
          style: ClinicalText.caption.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
