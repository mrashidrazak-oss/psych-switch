// Today's pulse card — Home screen surface for "what's due now"
// across all saved cases.
//
// Wraps `computeCasePulses` (engine/case_pulse.dart). Shows the top 3
// pulses sorted overdue → today → soon, with a small count summary
// in the header. Tapping a pulse opens the corresponding case on the
// Result screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch_engine/case_pulse.dart';
import 'package:psychswitch_engine/switching_engine.dart' as engine;

class TodayPulseCard extends ConsumerWidget {
  const TodayPulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    final asyncCases = ref.watch(savedCasesProvider);
    return asyncEngine.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (eng) => asyncCases.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (cases) {
          if (cases.isEmpty) return const SizedBox.shrink();
          final pulses = computeCasePulses(cases, eng);
          if (pulses.isEmpty) return const SizedBox.shrink();
          return _PulseList(pulses: pulses);
        },
      ),
    );
  }
}

class _PulseList extends StatelessWidget {
  const _PulseList({required this.pulses});

  final List<CasePulse> pulses;

  @override
  Widget build(BuildContext context) {
    final counts = pulseCountsByTier(pulses);
    final preview = pulses.take(3).toList();
    final overdue = counts[PulseTier.overdue] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: overdue > 0
              ? ClinicalPalette.danger.withValues(alpha: 0.35)
              : ClinicalPalette.border,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.md + 2,
        ClinicalSpace.md,
        ClinicalSpace.md + 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.monitor_heart_outlined,
                size: 14,
                color: ClinicalPalette.muted,
              ),
              const Gap.h(ClinicalSpace.xs + 2),
              const Text("TODAY'S PULSE", style: ClinicalText.eyebrow),
              const Spacer(),
              _CountChip(
                count: overdue,
                color: ClinicalPalette.danger,
                label: 'overdue',
              ),
              if (overdue > 0 &&
                  ((counts[PulseTier.today] ?? 0) > 0 ||
                      (counts[PulseTier.soon] ?? 0) > 0))
                const Gap.h(ClinicalSpace.xs + 2),
              _CountChip(
                count: counts[PulseTier.today] ?? 0,
                color: ClinicalPalette.warning,
                label: 'today',
              ),
              if ((counts[PulseTier.today] ?? 0) > 0 &&
                  (counts[PulseTier.soon] ?? 0) > 0)
                const Gap.h(ClinicalSpace.xs + 2),
              _CountChip(
                count: counts[PulseTier.soon] ?? 0,
                color: ClinicalPalette.accent,
                label: 'this week',
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.sm + 2),
          ...preview.map((p) => _PulseRow(pulse: p)),
          if (pulses.length > preview.length) ...<Widget>[
            const Gap.v(ClinicalSpace.xs),
            Text(
              '+${pulses.length - preview.length} more',
              style: ClinicalText.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Tooltip(
      message: '$count $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({required this.pulse});

  final CasePulse pulse;

  Color _tierColor() {
    switch (pulse.tier) {
      case PulseTier.overdue:
        return ClinicalPalette.danger;
      case PulseTier.today:
        return ClinicalPalette.warning;
      case PulseTier.soon:
        return ClinicalPalette.accent;
    }
  }

  String _whenText() {
    final d = pulse.daysFromNow;
    if (d == 0) return 'today';
    if (d == 1) return 'tomorrow';
    if (d == -1) return 'yesterday';
    if (d > 0) return 'in $d days';
    return '${-d} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor();
    return Semantics(
      button: true,
      label: '${pulse.entry.label}, ${pulse.caseLabel}, ${_whenText()}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            onTap: () => context.pushNamed(
              Routes.result,
              extra: ResultScreenArgs(
                input: engine.SwitchInput(
                  fromDrugId: pulse.fromDrugId,
                  fromDoseMg: 0, // doses unknown from pulse alone — Result
                  // screen falls back to the rule's reference doses.
                  toDrugId: pulse.toDrugId,
                  toDoseMg: 0,
                ),
              ),
            ),
            child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ClinicalSpace.xs + 2,
            horizontal: ClinicalSpace.xs,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const Gap.h(ClinicalSpace.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pulse.entry.label,
                      style: const TextStyle(
                        color: ClinicalPalette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap.v(1),
                    Text(
                      pulse.caseLabel,
                      style: ClinicalText.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap.h(ClinicalSpace.sm),
              Text(
                _whenText(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
