// Agitation management — pick severity + context flags, see the
// first/second-line + cautions, copy a paste-ready paragraph.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/agitation.dart';

class AgitationScreen extends StatefulWidget {
  const AgitationScreen({super.key});

  @override
  State<AgitationScreen> createState() => _AgitationScreenState();
}

class _AgitationScreenState extends State<AgitationScreen> {
  AgitationSeverity _severity = AgitationSeverity.moderate;
  bool _psychotic = false;
  bool _alcohol = false;
  bool _elderly = false;
  bool _pregnant = false;
  bool _refusingOral = false;

  void _set(VoidCallback body) {
    setState(body);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final ctx = AgitationContext(
      severity: _severity,
      psychotic: _psychotic,
      alcoholOrBenzoWithdrawal: _alcohol,
      elderly: _elderly,
      pregnant: _pregnant,
      refusingOral: _refusingOral,
    );
    final plan = buildAgitationPlan(ctx);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agitation'),
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
                Expanded(
                  child: _SeverityChip(
                    label: 'Mild',
                    selected: _severity == AgitationSeverity.mild,
                    onTap: () =>
                        _set(() => _severity = AgitationSeverity.mild),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SeverityChip(
                    label: 'Moderate',
                    selected: _severity == AgitationSeverity.moderate,
                    onTap: () => _set(
                        () => _severity = AgitationSeverity.moderate),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SeverityChip(
                    label: 'Severe',
                    selected: _severity == AgitationSeverity.severe,
                    onTap: () => _set(
                        () => _severity = AgitationSeverity.severe),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('CONTEXT', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            _Toggle(
              label: 'Psychotic features',
              value: _psychotic,
              onTap: () => _set(() => _psychotic = !_psychotic),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Alcohol or benzodiazepine withdrawal',
              value: _alcohol,
              onTap: () => _set(() => _alcohol = !_alcohol),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Elderly (≥ 65)',
              value: _elderly,
              onTap: () => _set(() => _elderly = !_elderly),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Pregnant',
              value: _pregnant,
              onTap: () => _set(() => _pregnant = !_pregnant),
            ),
            const SizedBox(height: 6),
            _Toggle(
              label: 'Refusing oral medication',
              value: _refusingOral,
              onTap: () => _set(() => _refusingOral = !_refusingOral),
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
            label: 'Acute management',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.tonePeachInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'De-escalate · medicate · document',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.tonePeachInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Stepwise plan from verbal de-escalation through oral PRN '
            'to IM rapid tranquillisation. Special handling for '
            'withdrawal · elderly · pregnancy · refusing oral.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.tonePeachInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected
                  ? ClinicalPalette.ctaText
                  : ClinicalPalette.text,
              letterSpacing: 0.3,
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
      color: value ? ClinicalPalette.cta : ClinicalPalette.surfaceMuted,
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
  final AgitationPlan plan;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('FIRST-LINE', style: ClinicalText.eyebrow),
          const SizedBox(height: ClinicalSpace.sm),
          for (final s in plan.firstLine) _Bullet(text: s),
          if (plan.secondLine.isNotEmpty) ...<Widget>[
            const SizedBox(height: ClinicalSpace.md),
            const Text(
              'SECOND-LINE IF INADEQUATE',
              style: ClinicalText.eyebrow,
            ),
            const SizedBox(height: ClinicalSpace.sm),
            for (final s in plan.secondLine) _Bullet(text: s),
          ],
          if (plan.cautions.isNotEmpty) ...<Widget>[
            const SizedBox(height: ClinicalSpace.md),
            const Text('CAUTIONS', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            for (final c in plan.cautions)
              _Bullet(text: c, warning: true),
          ],
          const SizedBox(height: ClinicalSpace.md + 2),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
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
            child: Text(
              text,
              style: ClinicalText.body.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
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
              'Adapted from Maudsley 15e + NICE NG10 + RCPsych RT '
              'guidance. Local hospital protocol overrides. Document '
              'indication, monitoring, post-injection observations.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
