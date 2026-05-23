// Benzodiazepine taper planner — convert the agent to a diazepam
// equivalent, pick a speed, render the proportional taper schedule.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/benzo_taper.dart';

class BenzoTaperScreen extends StatefulWidget {
  const BenzoTaperScreen({super.key});

  @override
  State<BenzoTaperScreen> createState() => _BenzoTaperScreenState();
}

class _BenzoTaperScreenState extends State<BenzoTaperScreen> {
  BenzoDrug _drug = kBenzoDrugs.first;
  BenzoTaperSpeed _speed = BenzoTaperSpeed.moderate;
  final _ctrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _dose => double.tryParse(_ctrl.text.trim()) ?? 0;
  double get _diazepamEq =>
      _dose <= 0 ? 0 : diazepamEquivalent(_drug, _dose);

  void _pickDrug(BenzoDrug d) {
    setState(() => _drug = d);
    unawaited(hapticsTap());
  }

  void _pickSpeed(BenzoTaperSpeed s) {
    setState(() => _speed = s);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final eq = _diazepamEq;
    final plan = eq > 0
        ? buildBenzoTaper(startDiazepamMg: eq, speed: _speed)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benzo taper'),
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
            const Text('Current agent', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final d in kBenzoDrugs)
                  _Chip(
                    label: d.name,
                    selected: _drug.id == d.id,
                    onTap: () => _pickDrug(d),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('TOTAL DAILY DOSE',
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
                      hintText: 'e.g. 2',
                      suffixText: 'mg',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: ClinicalSpace.sm + 2),
                  Text(
                    _drug.note,
                    style: ClinicalText.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            if (eq > 0) ...<Widget>[
              const SizedBox(height: ClinicalSpace.md),
              SquircleCard(
                tone: ClinicalPalette.toneSky,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('DIAZEPAM-EQUIVALENT',
                              style: ClinicalText.eyebrow),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(eq)} mg / day',
                            style: ClinicalText.heading.copyWith(
                              color: ClinicalPalette.toneSkyInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz,
                        color: ClinicalPalette.toneSkyInk),
                  ],
                ),
              ),
            ],
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Taper speed', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Row(
              children: <Widget>[
                for (final s in BenzoTaperSpeed.values) ...<Widget>[
                  Expanded(
                    child: _SpeedChip(
                      label: benzoTaperSpeedLabel(s),
                      selected: _speed == s,
                      onTap: () => _pickSpeed(s),
                    ),
                  ),
                  if (s != BenzoTaperSpeed.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
            if (plan != null) ...<Widget>[
              const SizedBox(height: ClinicalSpace.lg),
              SquircleCard(
                tone: ClinicalPalette.toneLavender,
                child: Text(
                  '${benzoReductionPercent(_speed)}% of the current '
                  'diazepam dose every '
                  '${benzoStepIntervalDays(_speed)} days · '
                  '≈ ${(plan.totalDays / 7).ceil()} weeks',
                  style: ClinicalText.subtitle.copyWith(
                    color: ClinicalPalette.toneLavenderInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: ClinicalSpace.md),
              const Text('Schedule', style: ClinicalText.eyebrow),
              const SizedBox(height: ClinicalSpace.sm),
              _ScheduleCard(plan: plan),
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
                  showCopiedToast(context, label: 'Taper plan');
                },
              ),
            ],
            const SizedBox(height: ClinicalSpace.md),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Ashton method',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Switch to diazepam, then taper the equivalent',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneLavenderInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Convert the short-acting agent to its long-acting '
            'diazepam equivalent, then reduce a fixed proportion of '
            'the current dose each step — slower at the low end.',
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneLavenderInk
                  .withValues(alpha: 0.85),
              height: 1.5,
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
            horizontal: ClinicalSpace.md + 2,
            vertical: ClinicalSpace.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
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

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.plan});
  final BenzoTaperPlan plan;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < plan.steps.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: ClinicalSpace.lg,
              ),
            _StepRow(step: plan.steps[i]),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final BenzoStep step;

  @override
  Widget build(BuildContext context) {
    final isStop = step.diazepamMg == 0;
    final week = (step.cumulativeDay / 7).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg,
        vertical: ClinicalSpace.md,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Text(
              'Wk $week',
              style: ClinicalText.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: ClinicalPalette.muted,
              ),
            ),
          ),
          const SizedBox(width: ClinicalSpace.sm),
          Expanded(
            child: Text(
              isStop
                  ? 'Stop'
                  : '${_fmt(step.diazepamMg)} mg diazepam / day',
              style: ClinicalText.subtitle.copyWith(
                fontWeight: FontWeight.w800,
                color: isStop
                    ? ClinicalPalette.toneMintInk
                    : ClinicalPalette.text,
              ),
            ),
          ),
          if (isStop)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClinicalSpace.sm + 2,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: ClinicalPalette.toneMint,
                borderRadius: BorderRadius.circular(ClinicalRadii.pill),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: ClinicalPalette.toneMintInk,
                  letterSpacing: 0.6,
                ),
              ),
            )
          else
            Text('hold ${step.holdDays} d',
                style: ClinicalText.caption),
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
              'Equivalents are approximate (Ashton 2002 / Maudsley '
              '15e) and intended for switching. Hold or slow at any '
              'step withdrawal symptoms emerge; never accelerate.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
