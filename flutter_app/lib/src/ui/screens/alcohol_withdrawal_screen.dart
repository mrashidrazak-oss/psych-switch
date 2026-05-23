// Alcohol-withdrawal regimen builder — severity + context toggles →
// drug choice, regimen, thiamine plan, monitoring, escalation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/alcohol_withdrawal.dart';

class AlcoholWithdrawalScreen extends StatefulWidget {
  const AlcoholWithdrawalScreen({super.key});

  @override
  State<AlcoholWithdrawalScreen> createState() =>
      _AlcoholWithdrawalScreenState();
}

class _AlcoholWithdrawalScreenState
    extends State<AlcoholWithdrawalScreen> {
  WithdrawalSeverity _severity = WithdrawalSeverity.moderate;
  bool _hepatic = false;
  bool _elderly = false;
  bool _seizureDt = false;
  bool _outpatient = false;

  void _set(VoidCallback fn) {
    setState(fn);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final plan = buildAlcoholWithdrawalPlan(
      AlcoholWithdrawalInput(
        severity: _severity,
        hepaticImpairment: _hepatic,
        elderlyOrFrail: _elderly,
        seizureOrDtHistory: _seizureDt,
        outpatient: _outpatient,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alcohol withdrawal'),
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
            ClinicalSpace.xxl,
          ),
          children: <Widget>[
            const _Hero(),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('SEVERITY', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Row(
              children: <Widget>[
                for (final s in WithdrawalSeverity.values) ...<Widget>[
                  Expanded(
                    child: _Seg(
                      label: s.label,
                      selected: _severity == s,
                      onTap: () => _set(() => _severity = s),
                    ),
                  ),
                  if (s != WithdrawalSeverity.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('CONTEXT', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            _Toggle(
              label: 'Significant hepatic impairment',
              value: _hepatic,
              onTap: () => _set(() => _hepatic = !_hepatic),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Elderly / frail',
              value: _elderly,
              onTap: () => _set(() => _elderly = !_elderly),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Prior withdrawal seizures / DTs',
              value: _seizureDt,
              onTap: () => _set(() => _seizureDt = !_seizureDt),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Community / outpatient detox',
              value: _outpatient,
              onTap: () => _set(() => _outpatient = !_outpatient),
            ),
            const SizedBox(height: ClinicalSpace.lg),
            _PlanCard(plan: plan),
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.tonePeach,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'CIWA-driven regimen',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.tonePeachInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Score with CIWA-Ar, dose with this',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.tonePeachInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Drug choice + regimen + the thiamine plan that prevents '
            "Wernicke's. Maudsley 15e / NICE CG100 / SIGN 74.",
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.tonePeachInk
                  .withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
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
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
              letterSpacing: 0.2,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final AlcoholWithdrawalPlan plan;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Benzodiazepine',
            tone: ClinicalPalette.surfaceMuted,
            ink: ClinicalPalette.mutedStrong,
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            plan.benzoChoice,
            style: ClinicalText.subtitle
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ClinicalSpace.md),
          _Section(title: 'REGIMEN', items: plan.regimen),
          _Para(title: 'THIAMINE', text: plan.thiamine),
          _Para(title: 'MONITORING', text: plan.monitoring),
          _Para(title: 'ESCALATION', text: plan.escalation),
          _Section(title: 'CAUTIONS', items: plan.cautions,
              warning: true),
          const SizedBox(height: ClinicalSpace.md),
          PillButton(
            label: 'Copy plan',
            icon: Icons.copy_rounded,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: plan.clipboardSummary()),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    this.warning = false,
  });

  final String title;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: ClinicalText.eyebrow),
        const SizedBox(height: ClinicalSpace.sm),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(
                    warning
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 14,
                    color: warning
                        ? ClinicalPalette.warning
                        : ClinicalPalette.success,
                  ),
                ),
                const SizedBox(width: ClinicalSpace.sm + 2),
                Expanded(
                  child: Text(it,
                      style: ClinicalText.body.copyWith(height: 1.5)),
                ),
              ],
            ),
          ),
        const SizedBox(height: ClinicalSpace.sm),
      ],
    );
  }
}

class _Para extends StatelessWidget {
  const _Para({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: ClinicalText.eyebrow),
        const SizedBox(height: ClinicalSpace.xs + 2),
        Text(text, style: ClinicalText.body.copyWith(height: 1.5)),
        const SizedBox(height: ClinicalSpace.md),
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
              'Doses are typical adult starting points — titrate to '
              'CIWA-Ar and local protocol. Symptom-triggered dosing '
              'needs trained staff scoring reliably.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
