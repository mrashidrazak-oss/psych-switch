// High-dose antipsychotic therapy — enter each agent's total daily
// dose, see the cumulative %-of-maximum and the HDAT safeguards.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/antipsychotic_high_dose.dart';

class AntipsychoticHighDoseScreen extends StatefulWidget {
  const AntipsychoticHighDoseScreen({super.key});

  @override
  State<AntipsychoticHighDoseScreen> createState() =>
      _AntipsychoticHighDoseScreenState();
}

class _AntipsychoticHighDoseScreenState
    extends State<AntipsychoticHighDoseScreen> {
  final Map<String, TextEditingController> _ctrls =
      <String, TextEditingController>{
    for (final ap in kAntipsychoticMaxDoses)
      ap.id: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> get _doses {
    final m = <String, double>{};
    _ctrls.forEach((id, c) {
      final v = double.tryParse(c.text.trim());
      if (v != null && v > 0) m[id] = v;
    });
    return m;
  }

  void _reset() {
    setState(() {
      for (final c in _ctrls.values) {
        c.clear();
      }
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateHighDose(_doses);
    final dirty = _ctrls.values.any((c) => c.text.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: const Text('High-dose antipsychotic'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (dirty)
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: r.isHighDose
                  ? ClinicalPalette.toneRose
                  : ClinicalPalette.toneMint,
              padding: const EdgeInsets.fromLTRB(
                ClinicalSpace.lg + 4,
                ClinicalSpace.md,
                ClinicalSpace.lg + 4,
                ClinicalSpace.md + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${r.totalPercent.toStringAsFixed(0)}% of '
                    'maximum',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: r.isHighDose
                          ? ClinicalPalette.toneRoseInk
                          : ClinicalPalette.toneMintInk,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.headline,
                    style: ClinicalText.caption.copyWith(
                      color: (r.isHighDose
                              ? ClinicalPalette.toneRoseInk
                              : ClinicalPalette.toneMintInk)
                          .withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  SquircleCard(
                    child: Text(
                      'Enter the TOTAL daily dose for each agent '
                      'used — regular + PRN + depot-equivalent. '
                      'Percentages use approximate maximum licensed '
                      'doses; confirm locally.',
                      style: ClinicalText.caption
                          .copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('DAILY DOSE (mg)',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final ap in kAntipsychoticMaxDoses) ...<Widget>[
                    _DoseRow(
                      label: ap.name,
                      maxMg: ap.maxDailyMg,
                      controller: _ctrls[ap.id]!,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  if (r.perDrug.isNotEmpty)
                    _PlanCard(
                      sections: <(String, List<String>)>[
                        ('Per drug', r.perDrug),
                        if (r.isHighDose)
                          ('HDAT safeguards', r.safeguards),
                        ('Cautions', r.cautions),
                      ],
                      clipboard: r.clipboardSummary,
                    ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(
                    text:
                        'Maudsley 15e / RCPsych HDAT consensus. '
                        'High dose is a documented, time-limited, '
                        'senior decision after optimising a single '
                        'agent — not a default.',
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

class _DoseRow extends StatelessWidget {
  const _DoseRow({
    required this.label,
    required this.maxMg,
    required this.controller,
    required this.onChanged,
  });
  final String label;
  final double maxMg;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.md,
        vertical: ClinicalSpace.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ClinicalPalette.text,
                  ),
                ),
                Text(
                  'max ${maxMg.toStringAsFixed(0)} mg',
                  style: ClinicalText.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'mg',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.sections,
    required this.clipboard,
  });
  final List<(String, List<String>)> sections;
  final String Function() clipboard;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final s in sections) ...<Widget>[
            TonePill(
              label: s.$1,
              tone: const Color(0xFFFFFFFF),
              ink: ClinicalPalette.toneSandInk,
            ),
            const SizedBox(height: ClinicalSpace.sm),
            for (final line in s.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle,
                          size: 6,
                          color: ClinicalPalette.toneSandInk),
                    ),
                    const SizedBox(width: ClinicalSpace.sm + 2),
                    Expanded(
                      child: Text(
                        line,
                        style: ClinicalText.body.copyWith(
                          color: ClinicalPalette.toneSandInk,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: ClinicalSpace.md),
          ],
          PillButton(
            label: 'Copy summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: clipboard()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: const EdgeInsets.all(ClinicalSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.shield_outlined,
              size: 16, color: ClinicalPalette.mutedStrong),
          const SizedBox(width: ClinicalSpace.sm + 2),
          Expanded(
            child: Text(
              text,
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
