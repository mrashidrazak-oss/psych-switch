// NMS rechallenge — answer the readiness questions, see the verdict
// and the safer-restart protocol.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/nms_rechallenge.dart';

class NmsRechallengeScreen extends StatefulWidget {
  const NmsRechallengeScreen({super.key});

  @override
  State<NmsRechallengeScreen> createState() =>
      _NmsRechallengeScreenState();
}

class _NmsRechallengeScreenState
    extends State<NmsRechallengeScreen> {
  bool _recovered = false;
  bool _delayed = false;
  bool _essential = true;
  bool _severePrior = false;

  void _reset() {
    setState(() {
      _recovered = false;
      _delayed = false;
      _essential = true;
      _severePrior = false;
    });
    unawaited(hapticsTap());
  }

  ({Color tone, Color ink}) _palette(NmsRechallengeVerdict v) {
    switch (v) {
      case NmsRechallengeVerdict.notReady:
        return (
          tone: ClinicalPalette.toneSand,
          ink: ClinicalPalette.toneSandInk
        );
      case NmsRechallengeVerdict.proceedCautious:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case NmsRechallengeVerdict.avoid:
        return (
          tone: ClinicalPalette.toneRose,
          ink: ClinicalPalette.toneRoseInk
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateNmsRechallenge(
      fullyRecovered: _recovered,
      atLeastTwoWeeksSinceRecovery: _delayed,
      antipsychoticEssential: _essential,
      priorEpisodeSevereOrComplicated: _severePrior,
    );
    final p = _palette(r.verdict);
    final dirty =
        _recovered || _delayed || !_essential || _severePrior;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMS rechallenge'),
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
                    r.verdict.label,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.headline,
                    style: ClinicalText.caption.copyWith(
                      color: p.ink.withValues(alpha: 0.85),
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
                  const Text('READINESS',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  _Toggle(
                    label: 'Fully recovered (clinical + CK '
                        'normalised)',
                    value: _recovered,
                    onChanged: (v) {
                      setState(() => _recovered = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: '≥ ~2 weeks since full recovery',
                    value: _delayed,
                    onChanged: (v) {
                      setState(() => _delayed = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Antipsychotic clinically essential',
                    value: _essential,
                    onChanged: (v) {
                      setState(() => _essential = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Prior episode severe / complicated',
                    value: _severePrior,
                    onChanged: (v) {
                      setState(() => _severePrior = v);
                      unawaited(hapticsTap());
                    },
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  _PlanCard(
                    sections: <(String, List<String>)>[
                      ('Steps', r.steps),
                      ('Cautions', r.cautions),
                    ],
                    clipboard: r.clipboardSummary,
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const _Disclaimer(
                    text:
                        'Maudsley 15e. Rechallenge only after full '
                        'recovery + a clear delay, with monitoring '
                        'and a stop-and-escalate plan in place.',
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
