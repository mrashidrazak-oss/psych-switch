// Tardive dyskinesia management — answer the ladder questions, see
// the evidence-based step.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/tardive_dyskinesia.dart';

class TardiveDyskinesiaScreen extends StatefulWidget {
  const TardiveDyskinesiaScreen({super.key});

  @override
  State<TardiveDyskinesiaScreen> createState() =>
      _TardiveDyskinesiaScreenState();
}

class _TardiveDyskinesiaScreenState
    extends State<TardiveDyskinesiaScreen> {
  bool _confirmed = false;
  bool _stillNeeded = true;
  bool _persists = false;
  bool _refractory = false;

  void _reset() {
    setState(() {
      _confirmed = false;
      _stillNeeded = true;
      _persists = false;
      _refractory = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateTardiveDyskinesia(
      confirmed: _confirmed,
      antipsychoticStillNeeded: _stillNeeded,
      persistsAfterOptimisation: _persists,
      refractory: _refractory,
    );
    final dirty =
        _confirmed || !_stillNeeded || _persists || _refractory;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tardive dyskinesia'),
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
              color: ClinicalPalette.toneSand,
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
                    r.step.label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: ClinicalPalette.toneSandInk,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.headline,
                    style: ClinicalText.caption.copyWith(
                      color: ClinicalPalette.toneSandInk
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
                  const Text('SITUATION',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  _Toggle(
                    label: 'TD confirmed (AIMS, other causes '
                        'excluded)',
                    value: _confirmed,
                    onChanged: (v) {
                      setState(() => _confirmed = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Antipsychotic still clinically needed',
                    value: _stillNeeded,
                    onChanged: (v) {
                      setState(() => _stillNeeded = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Persists after optimising the '
                        'antipsychotic',
                    value: _persists,
                    onChanged: (v) {
                      setState(() => _persists = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Refractory to a VMAT-2 inhibitor',
                    value: _refractory,
                    onChanged: (v) {
                      setState(() => _refractory = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _PlanCard(
                    sections: <(String, List<String>)>[
                      ('Options', r.options),
                      ('Cautions', r.cautions),
                    ],
                    clipboard: r.clipboardSummary,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(
                    text:
                        'Maudsley 15e. Never mask TD by increasing '
                        'the antipsychotic; track with serial AIMS '
                        'and minimise lifetime exposure.',
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
            label: 'Copy plan',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: clipboard()),
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
