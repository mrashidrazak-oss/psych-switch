// Antipsychotic-induced hyperprolactinaemia — enter the prolactin
// level, see the band, the prolactinoma-exclusion threshold, and the
// stepwise management plan.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/hyperprolactinaemia.dart';

class HyperprolactinaemiaScreen extends StatefulWidget {
  const HyperprolactinaemiaScreen({super.key});

  @override
  State<HyperprolactinaemiaScreen> createState() =>
      _HyperprolactinaemiaScreenState();
}

class _HyperprolactinaemiaScreenState
    extends State<HyperprolactinaemiaScreen> {
  final _ctrl = TextEditingController();
  bool _symptomatic = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _prl {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v < 0) return null;
    return v;
  }

  void _reset() {
    setState(() {
      _ctrl.clear();
      _symptomatic = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateHyperprolactinaemia(
      prolactin: _prl,
      symptomatic: _symptomatic,
    );
    final dirty = _ctrl.text.isNotEmpty || _symptomatic;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperprolactinaemia'),
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
                        const Text('SERUM PROLACTIN',
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
                            hintText: 'e.g. 1200',
                            suffixText: 'mIU/L',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: ClinicalSpace.sm),
                        Text(
                          'Units mIU/L (1 ng/mL ≈ 21 mIU/L). A very '
                          'high level is too high to blame the drug '
                          'alone — exclude a prolactinoma.',
                          style: ClinicalText.caption
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _Toggle(
                    label:
                        'Symptomatic (galactorrhoea, menstrual / '
                        'sexual dysfunction)',
                    value: _symptomatic,
                    onChanged: (v) {
                      setState(() => _symptomatic = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: ClinicalSpace.md),
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
  final HyperprolactinResult result;

  ({Color tone, Color ink}) _p() {
    switch (result.band) {
      case ProlactinBand.normal:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case ProlactinBand.mild:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case ProlactinBand.moderate:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case ProlactinBand.high:
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
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  result.band.label,
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
          ),
          if (result.imagingAdvised)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius:
                    BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: Text(
                'MRI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
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
                    height: 1.4,
                    color: ClinicalPalette.text,
                  ),
                ),
              ),
              const SizedBox(width: ClinicalSpace.sm),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});
  final HyperprolactinResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Imaging',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            result.imagingAdvised
                ? 'Pituitary MRI advised — exclude prolactinoma.'
                : 'Not mandated on level alone; image if symptoms or '
                    'level are out of keeping with the drug.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
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
              'Maudsley 15e / Endocrine Society. Confirm with a '
              'repeat + macroprolactin before major change; do not '
              'stop an effective antipsychotic for an asymptomatic '
              'mild rise.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
