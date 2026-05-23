// Psychotropic-induced hyponatraemia / SIADH — enter sodium, tick
// features, pick the culprit, see the graded plan + correction-rate
// safety net.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/hyponatraemia.dart';

const _features = <(String, String, String)>[
  ('seizures', 'Seizures', 'severe'),
  ('reduced_gcs', 'Reduced GCS', 'severe'),
  ('coma', 'Coma', 'severe'),
  ('cardiorespiratory_distress', 'Cardiorespiratory distress',
      'severe'),
  ('confusion', 'Confusion', 'moderate'),
  ('vomiting', 'Vomiting', 'moderate'),
  ('headache', 'Headache', 'moderate'),
  ('unsteadiness', 'Unsteadiness', 'moderate'),
  ('drowsiness', 'Drowsiness', 'moderate'),
];

const _culprits = <String>[
  'SSRI / SNRI',
  'Carbamazepine',
  'Oxcarbazepine',
  'Antipsychotic',
  'Other / mixed',
];

class HyponatraemiaScreen extends StatefulWidget {
  const HyponatraemiaScreen({super.key});

  @override
  State<HyponatraemiaScreen> createState() =>
      _HyponatraemiaScreenState();
}

class _HyponatraemiaScreenState extends State<HyponatraemiaScreen> {
  final _ctrl = TextEditingController();
  final Set<String> _ticked = <String>{};
  String _culprit = _culprits.first;
  bool _acute = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _na {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  void _toggle(String id) {
    setState(() {
      if (!_ticked.add(id)) _ticked.remove(id);
    });
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(() {
      _ctrl.clear();
      _ticked.clear();
      _culprit = _culprits.first;
      _acute = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateHyponatraemia(
      sodium: _na,
      features: _ticked,
      culprit: _culprit,
      acuteOnset: _acute,
    );
    final dirty = _ctrl.text.isNotEmpty ||
        _ticked.isNotEmpty ||
        _acute ||
        _culprit != _culprits.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyponatraemia / SIADH'),
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
            _Banner(result: r),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('SERUM SODIUM',
                            style: ClinicalText.eyebrow),
                        const SizedBox(height: ClinicalSpace.sm),
                        TextField(
                          controller: _ctrl,
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'e.g. 126',
                            suffixText: 'mmol/L',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: ClinicalSpace.sm),
                        Text(
                          'Graded by the WORSE of sodium and '
                          'symptoms. Confirm SIADH only after '
                          'excluding other causes.',
                          style: ClinicalText.caption
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('SUSPECTED CULPRIT',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final c in _culprits)
                        _Chip(
                          label: c,
                          selected: _culprit == c,
                          onTap: () {
                            setState(() => _culprit = c);
                            unawaited(hapticsTap());
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _Toggle(
                    label: 'Acute onset (< 48 h)',
                    value: _acute,
                    onChanged: (v) {
                      setState(() => _acute = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('CLINICAL FEATURES',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  for (final f in _features) ...<Widget>[
                    _FeatureRow(
                      label: f.$2,
                      tier: f.$3,
                      ticked: _ticked.contains(f.$1),
                      onTap: () => _toggle(f.$1),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: ClinicalSpace.sm),
                  _PlanCard(result: r),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.result});
  final HypoNaResult result;

  ({Color tone, Color ink}) _p() {
    switch (result.severity) {
      case HypoNaSeverity.none:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case HypoNaSeverity.mild:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case HypoNaSeverity.moderate:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case HypoNaSeverity.severe:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p();
    return Container(
      width: double.infinity,
      color: p.tone,
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
            result.severity.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            result.headline,
            style: ClinicalText.caption.copyWith(
              color: p.ink.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md,
            vertical: ClinicalSpace.sm + 2,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md,
            vertical: ClinicalSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ClinicalPalette.text,
                  ),
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.tier,
    required this.ticked,
    required this.onTap,
  });
  final String label;
  final String tier;
  final bool ticked;
  final VoidCallback onTap;

  Color get _tierColor => switch (tier) {
        'severe' => ClinicalPalette.toneRoseInk,
        _ => ClinicalPalette.tonePeachInk,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ticked
          ? ClinicalPalette.cta
          : ClinicalPalette.surfaceMuted,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(ClinicalSpace.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ticked ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ticked
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: ticked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: ClinicalPalette.cta)
                    : null,
              ),
              const SizedBox(width: ClinicalSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: ticked
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ticked
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(ClinicalRadii.pill),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: ticked
                        ? ClinicalPalette.ctaText
                        : _tierColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});
  final HypoNaResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Steps',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final s in result.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Bullet(text: s),
            ),
          if (result.cautions.isNotEmpty) ...<Widget>[
            const SizedBox(height: ClinicalSpace.md),
            const TonePill(
              label: 'Cautions',
              tone: Color(0xFFFFFFFF),
              ink: ClinicalPalette.toneSandInk,
            ),
            const SizedBox(height: ClinicalSpace.sm),
            for (final c in result.cautions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Bullet(text: c),
              ),
          ],
          const SizedBox(height: ClinicalSpace.md + 2),
          PillButton(
            label: 'Copy plan',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
              );
              unawaited(hapticsConfirm());
              if (!context.mounted) return;
              showCopiedToast(context, label: 'Plan');
            },
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle,
              size: 6, color: ClinicalPalette.toneSandInk),
        ),
        const SizedBox(width: ClinicalSpace.sm + 2),
        Expanded(
          child: Text(
            text,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

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
              'Maudsley 15e / UK hyponatraemia consensus. '
              'Moderate–severe cases are a medical emergency — '
              'manage jointly with acute medicine and cap the '
              'correction rate.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
