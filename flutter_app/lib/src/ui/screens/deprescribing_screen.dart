// Antidepressant deprescribing — hyperbolic taper planner screen.
//
// Pick the antidepressant + taper speed; the engine renders a
// hyperbolic step schedule (proportional reduction of the current
// dose) ending in STOP. Copy a paste-ready plan for the chart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch_engine/deprescribing.dart';

class DeprescribingScreen extends StatefulWidget {
  const DeprescribingScreen({super.key});

  @override
  State<DeprescribingScreen> createState() => _DeprescribingScreenState();
}

class _DeprescribingScreenState extends State<DeprescribingScreen> {
  DeprescribeDrug _drug = kDeprescribeDrugs.first;
  TaperSpeed _speed = TaperSpeed.moderate;

  void _pickDrug(DeprescribeDrug d) {
    setState(() => _drug = d);
    unawaited(hapticsTap());
  }

  void _pickSpeed(TaperSpeed s) {
    setState(() => _speed = s);
    unawaited(hapticsTap());
  }

  @override
  Widget build(BuildContext context) {
    final plan = buildTaperPlan(drug: _drug, speed: _speed);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deprescribing'),
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
            const Text('Drug', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final d in kDeprescribeDrugs)
                  _Chip(
                    label: d.name,
                    selected: _drug.id == d.id,
                    onTap: () => _pickDrug(d),
                  ),
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Taper speed', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            Row(
              children: <Widget>[
                for (final s in TaperSpeed.values) ...<Widget>[
                  Expanded(
                    child: _SpeedChip(
                      label: taperSpeedLabel(s),
                      selected: _speed == s,
                      onTap: () => _pickSpeed(s),
                    ),
                  ),
                  if (s != TaperSpeed.values.last)
                    const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: ClinicalSpace.lg),
            SquircleCard(
              tone: ClinicalPalette.toneSky,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${taperReductionPercent(_speed)}% of the current '
                    'dose every ${taperIntervalDays(_speed)} days · '
                    '≈ ${(plan.totalDays / 7).ceil()} weeks total',
                    style: ClinicalText.subtitle.copyWith(
                      color: ClinicalPalette.toneSkyInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: ClinicalSpace.sm),
                  Text(
                    _drug.note,
                    style: ClinicalText.body.copyWith(
                      color: ClinicalPalette.toneSkyInk
                          .withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClinicalSpace.lg),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Taper plan copied')),
                );
              },
            ),
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
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Hyperbolic taper',
            tone: Color(0xFFFFFFFF),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'Stop the way the receptor curve actually behaves',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.toneLavenderInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Reductions are a fixed proportion of the CURRENT dose, so '
            'each step delivers roughly equal serotonin-transporter '
            'occupancy change — the Maudsley deprescribing method '
            '(Horowitz & Taylor).',
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
              fontSize: 13,
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
  final TaperPlan plan;

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
  final TaperStep step;

  @override
  Widget build(BuildContext context) {
    final isStop = step.doseMg == 0;
    final week = (step.cumulativeDay / 7).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg,
        vertical: ClinicalSpace.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            alignment: Alignment.centerLeft,
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
                  : '${_fmt(step.doseMg)} mg daily',
              style: ClinicalText.subtitle.copyWith(
                fontWeight: FontWeight.w800,
                color: isStop
                    ? ClinicalPalette.toneMintInk
                    : ClinicalPalette.text,
              ),
            ),
          ),
          if (!isStop)
            Text(
              'hold ${step.holdDays} d',
              style: ClinicalText.caption,
            )
          else
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
            ),
        ],
      ),
    );
  }
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  if ((v * 10) == (v * 10).roundToDouble()) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
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
              'Decision support only. Slow further (or pause) if '
              'withdrawal symptoms emerge — never accelerate to "get '
              'it over with". Confirm small doses are achievable with '
              'the available liquid / bead preparation.',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
