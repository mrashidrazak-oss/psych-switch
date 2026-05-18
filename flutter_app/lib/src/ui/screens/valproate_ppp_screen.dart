// Valproate Pregnancy Prevention Programme — answer the PPP gate
// questions, see the prescribing verdict + outstanding requirements.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/valproate_ppp.dart';

class ValproatePppScreen extends StatefulWidget {
  const ValproatePppScreen({super.key});

  @override
  State<ValproatePppScreen> createState() =>
      _ValproatePppScreenState();
}

class _ValproatePppScreenState extends State<ValproatePppScreen> {
  bool _childbearing = true;
  bool _pregnant = false;
  bool _bipolar = true;
  bool _noAlt = false;
  bool _contraception = false;
  bool _riskForm = false;
  bool _specialist = false;

  void _reset() {
    setState(() {
      _childbearing = true;
      _pregnant = false;
      _bipolar = true;
      _noAlt = false;
      _contraception = false;
      _riskForm = false;
      _specialist = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final r = evaluateValproatePpp(
      ValproatePppInput(
        childbearingPotential: _childbearing,
        pregnant: _pregnant,
        forBipolar: _bipolar,
        noEffectiveAlternative: _noAlt,
        highlyEffectiveContraception: _contraception,
        annualRiskAcknowledgement: _riskForm,
        specialistReview: _specialist,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valproate PPP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
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
                  const Text('PATIENT',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  _Toggle(
                    label: 'Able to become pregnant',
                    value: _childbearing,
                    onChanged: (v) =>
                        setState(() => _childbearing = v),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Currently pregnant',
                    value: _pregnant,
                    onChanged: (v) => setState(() => _pregnant = v),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Indication is bipolar (off = epilepsy)',
                    value: _bipolar,
                    onChanged: (v) => setState(() => _bipolar = v),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('PPP REQUIREMENTS',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: ClinicalSpace.sm),
                  _Toggle(
                    label: 'Effective alternatives tried / '
                        'unsuitable (documented)',
                    value: _noAlt,
                    onChanged: (v) => setState(() => _noAlt = v),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Highly effective contraception in place',
                    value: _contraception,
                    onChanged: (v) =>
                        setState(() => _contraception = v),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Signed annual Risk Acknowledgement Form',
                    value: _riskForm,
                    onChanged: (v) => setState(() => _riskForm = v),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Annual specialist review of need done',
                    value: _specialist,
                    onChanged: (v) =>
                        setState(() => _specialist = v),
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
  final ValproatePppResult result;

  ({Color tone, Color ink}) _p() {
    switch (result.verdict) {
      case ValproateVerdict.notApplicable:
        return (
          tone: ClinicalPalette.toneSky,
          ink: ClinicalPalette.toneSkyInk
        );
      case ValproateVerdict.permitted:
        return (
          tone: ClinicalPalette.toneMint,
          ink: ClinicalPalette.toneMintInk
        );
      case ValproateVerdict.conditional:
        return (
          tone: ClinicalPalette.tonePeach,
          ink: ClinicalPalette.tonePeachInk
        );
      case ValproateVerdict.avoid:
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
            result.verdict.label,
            style: TextStyle(
              fontSize: 19,
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
        onTap: () {
          onChanged(!value);
          unawaited(hapticsTap());
        },
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
              Switch(
                value: value,
                onChanged: (v) {
                  onChanged(v);
                  unawaited(hapticsTap());
                },
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
  final ValproatePppResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (result.outstanding.isNotEmpty) ...<Widget>[
            const TonePill(
              label: 'Outstanding PPP requirements',
              tone: Color(0xFFFFFFFF),
              ink: ClinicalPalette.toneSandInk,
            ),
            const SizedBox(height: ClinicalSpace.sm),
            for (final o in result.outstanding)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Bullet(text: o),
              ),
            const SizedBox(height: ClinicalSpace.md),
          ],
          const TonePill(
            label: 'Actions',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final a in result.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Bullet(text: a),
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
            label: 'Copy summary',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.clipboardSummary()),
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
              'Maudsley 15e / MHRA valproate safety guidance. '
              'Follow your national regulator’s current PPP '
              'requirements and forms; never stop valproate '
              'abruptly without a specialist plan.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
