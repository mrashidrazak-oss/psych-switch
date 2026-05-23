// Serotonin syndrome — Hunter Toxicity Criteria.
//
// 9 yes/no features. The engine traverses the decision tree and
// returns met / not-met plus the firing branch (for the note).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/emergency_screens.dart';

class SerotoninScreen extends StatefulWidget {
  const SerotoninScreen({super.key});

  @override
  State<SerotoninScreen> createState() => _SerotoninScreenState();
}

class _SerotoninScreenState extends State<SerotoninScreen> {
  bool _agent = true;
  bool _spontClonus = false;
  bool _inducibleClonus = false;
  bool _ocularClonus = false;
  bool _agitation = false;
  bool _diaphoresis = false;
  bool _tremor = false;
  bool _hyperreflexia = false;
  bool _hypertonia = false;
  bool _fever = false;

  void _toggle(void Function() body) {
    setState(body);
    unawaited(hapticsTap());
  }

  void _reset() {
    setState(() {
      _agent = true;
      _spontClonus = false;
      _inducibleClonus = false;
      _ocularClonus = false;
      _agitation = false;
      _diaphoresis = false;
      _tremor = false;
      _hyperreflexia = false;
      _hypertonia = false;
      _fever = false;
    });
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final f = SerotoninFeatures(
      serotonergicAgent: _agent,
      spontaneousClonus: _spontClonus,
      inducibleClonus: _inducibleClonus,
      ocularClonus: _ocularClonus,
      agitation: _agitation,
      diaphoresis: _diaphoresis,
      tremor: _tremor,
      hyperreflexia: _hyperreflexia,
      hypertonia: _hypertonia,
      feverAbove38: _fever,
    );
    final result = evaluateSerotonin(f);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serotonin syndrome'),
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
            _VerdictBanner(result: result),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.xxl,
                ),
                children: <Widget>[
                  _Toggle(
                    label: 'Serotonergic agent in last 5 weeks?',
                    value: _agent,
                    onTap: () => _toggle(() => _agent = !_agent),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('CLONUS', style: ClinicalText.eyebrow),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Spontaneous clonus',
                    value: _spontClonus,
                    onTap: () =>
                        _toggle(() => _spontClonus = !_spontClonus),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Inducible clonus',
                    value: _inducibleClonus,
                    onTap: () => _toggle(
                        () => _inducibleClonus = !_inducibleClonus),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Ocular clonus',
                    value: _ocularClonus,
                    onTap: () =>
                        _toggle(() => _ocularClonus = !_ocularClonus),
                  ),
                  const SizedBox(height: ClinicalSpace.md),
                  const Text('AUTONOMIC / NEUROMUSCULAR',
                      style: ClinicalText.eyebrow),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Agitation',
                    value: _agitation,
                    onTap: () =>
                        _toggle(() => _agitation = !_agitation),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Diaphoresis',
                    value: _diaphoresis,
                    onTap: () =>
                        _toggle(() => _diaphoresis = !_diaphoresis),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Tremor',
                    value: _tremor,
                    onTap: () => _toggle(() => _tremor = !_tremor),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Hyperreflexia',
                    value: _hyperreflexia,
                    onTap: () => _toggle(
                        () => _hyperreflexia = !_hyperreflexia),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Hypertonia',
                    value: _hypertonia,
                    onTap: () =>
                        _toggle(() => _hypertonia = !_hypertonia),
                  ),
                  const SizedBox(height: 6),
                  _Toggle(
                    label: 'Temperature > 38 °C',
                    value: _fever,
                    onTap: () => _toggle(() => _fever = !_fever),
                  ),
                  const SizedBox(height: ClinicalSpace.lg),
                  _ActionCard(result: result),
                  const SizedBox(height: ClinicalSpace.md),
                  Text(
                    'Dunkley EJC, Isbister GK, Sibbritt D et al. The '
                    'Hunter Serotonin Toxicity Criteria. QJM 2003;96:635-42.',
                    textAlign: TextAlign.center,
                    style: ClinicalText.caption
                        .copyWith(color: ClinicalPalette.muted),
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

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.result});
  final SerotoninResult result;

  @override
  Widget build(BuildContext context) {
    final met = result.met;
    final tone = met ? ClinicalPalette.toneRose : ClinicalPalette.toneMint;
    final ink = met
        ? ClinicalPalette.toneRoseInk
        : ClinicalPalette.toneMintInk;
    return Container(
      width: double.infinity,
      color: tone,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.md + 2,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              met ? Icons.priority_high_rounded : Icons.check_rounded,
              color: ink,
            ),
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  met ? 'HUNTER MET' : 'HUNTER not met',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.headline,
                  style: ClinicalText.caption.copyWith(
                    color: ink.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
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
    required this.onTap,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
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
                  color: value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value
                        ? Colors.transparent
                        : ClinicalPalette.borderStrong,
                    width: 1.2,
                  ),
                ),
                child: value
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
                    color: value
                        ? ClinicalPalette.ctaText
                        : ClinicalPalette.text,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.result});
  final SerotoninResult result;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Action',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.toneSandInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            result.recommendation,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
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
              showCopiedToast(context, label: 'Summary');
            },
          ),
        ],
      ),
    );
  }
}
