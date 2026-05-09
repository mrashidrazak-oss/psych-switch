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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                "TODAY'S PULSE",
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              _CountChip(
                count: counts[PulseTier.overdue] ?? 0,
                color: AppColors.danger,
                label: 'overdue',
              ),
              const SizedBox(width: 6),
              _CountChip(
                count: counts[PulseTier.today] ?? 0,
                color: AppColors.warning,
                label: 'today',
              ),
              const SizedBox(width: 6),
              _CountChip(
                count: counts[PulseTier.soon] ?? 0,
                color: AppColors.accent,
                label: 'this week',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...preview.map((p) => _PulseRow(pulse: p)),
          if (pulses.length > preview.length) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '+${pulses.length - preview.length} more',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
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
        return AppColors.danger;
      case PulseTier.today:
        return AppColors.warning;
      case PulseTier.soon:
        return AppColors.accent;
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pulse.entry.label,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    pulse.caseLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _whenText(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
