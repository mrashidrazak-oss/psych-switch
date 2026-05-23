// Antipsychotic metabolic-monitoring scheduler — pick the start date,
// the screen renders the baseline / wk6 / wk12 / annual calendar with
// overdue + due-soon flags.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:psychswitch_engine/metabolic_monitoring.dart';

class MetabolicMonitoringScreen extends StatefulWidget {
  const MetabolicMonitoringScreen({super.key});

  @override
  State<MetabolicMonitoringScreen> createState() =>
      _MetabolicMonitoringScreenState();
}

class _MetabolicMonitoringScreenState
    extends State<MetabolicMonitoringScreen> {
  DateTime _start = DateTime.now();

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _start = picked);
      unawaited(hapticsTap());
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = buildMonitoringSchedule(startDate: _start);
    final next = schedule.nextDue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metabolic monitoring'),
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
            SquircleCard(
              onTap: _pickDate,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.event_outlined,
                      color: ClinicalPalette.mutedStrong),
                  const SizedBox(width: ClinicalSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('ANTIPSYCHOTIC START DATE',
                            style: ClinicalText.eyebrow),
                        const SizedBox(height: 2),
                        Text(
                          _fmt(_start),
                          style: ClinicalText.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined,
                      size: 18, color: ClinicalPalette.muted),
                ],
              ),
            ),
            if (next != null) ...<Widget>[
              const SizedBox(height: ClinicalSpace.md),
              _NextDueBanner(visit: next),
            ],
            const SizedBox(height: ClinicalSpace.lg),
            const Text('Schedule', style: ClinicalText.eyebrow),
            const SizedBox(height: ClinicalSpace.sm),
            for (final v in schedule.visits) ...<Widget>[
              _VisitCard(visit: v),
              const SizedBox(height: ClinicalSpace.sm + 2),
            ],
            const SizedBox(height: ClinicalSpace.xs),
            PillButton(
              label: 'Copy schedule',
              icon: Icons.copy_rounded,
              expanded: true,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: schedule.clipboardSummary()),
                );
                unawaited(hapticsConfirm());
                if (!context.mounted) return;
                showCopiedToast(context, label: 'Schedule');
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
      tone: ClinicalPalette.tonePeach,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TonePill(
            label: 'Monitoring calendar',
            tone: Color(0xFFFFFFFF),
            ink: ClinicalPalette.tonePeachInk,
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            'The monitoring nobody should miss',
            style: ClinicalText.heading.copyWith(
              color: ClinicalPalette.tonePeachInk,
            ),
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            'Baseline → week 6 → week 12 → annual, with the exact '
            'panel for each visit. Per Maudsley 15e / NICE CG178 / '
            'Lester UK adaptation.',
            style: ClinicalText.body.copyWith(
              color:
                  ClinicalPalette.tonePeachInk.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextDueBanner extends StatelessWidget {
  const _NextDueBanner({required this.visit});
  final MonitoringVisit visit;

  @override
  Widget build(BuildContext context) {
    final overdue = visit.isOverdue;
    final tone =
        overdue ? ClinicalPalette.toneRose : ClinicalPalette.toneSand;
    final ink = overdue
        ? ClinicalPalette.toneRoseInk
        : ClinicalPalette.toneSandInk;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            overdue
                ? Icons.error_outline
                : Icons.notifications_active_outlined,
            color: ink,
          ),
          const SizedBox(width: ClinicalSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  overdue ? 'OVERDUE' : 'DUE SOON',
                  style: ClinicalText.eyebrow.copyWith(color: ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${visit.label} visit',
                  style: ClinicalText.subtitle.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
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

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});
  final MonitoringVisit visit;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final flagged = visit.isOverdue || visit.isDueSoon;
    final tone = visit.isOverdue
        ? ClinicalPalette.toneRose
        : visit.isDueSoon
            ? ClinicalPalette.toneSand
            : null;
    final ink = visit.isOverdue
        ? ClinicalPalette.toneRoseInk
        : visit.isDueSoon
            ? ClinicalPalette.toneSandInk
            : ClinicalPalette.text;
    return SquircleCard(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                visit.label,
                style: ClinicalText.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const Spacer(),
              Text(
                _fmt(visit.dueDate),
                style: ClinicalText.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ink.withValues(alpha: 0.8),
                ),
              ),
              if (flagged) ...<Widget>[
                const SizedBox(width: ClinicalSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClinicalSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius:
                        BorderRadius.circular(ClinicalRadii.pill),
                  ),
                  child: Text(
                    visit.isOverdue ? 'OVERDUE' : 'SOON',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: ClinicalSpace.sm),
          for (final p in visit.params)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: ClinicalSpace.sm + 2),
                  Expanded(
                    child: Text(
                      p.label,
                      style: ClinicalText.body.copyWith(
                        color: ink,
                        height: 1.45,
                      ),
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
              'Generic schedule — clozapine and lithium carry their own '
              'mandatory protocols. Bring monitoring forward if the '
              'patient is symptomatic or on a high-metabolic-risk '
              'agent (olanzapine / clozapine).',
              style: ClinicalText.caption.copyWith(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
