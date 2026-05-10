// Result screen — Phase 4D + 5A.
//
// Renders the engine's SwitchPlan output. Five status branches:
//   • ok                  → schedule table + safety flags + citations
//                           + PsychSwitch Score ring (5A)
//                           + monitoring plan card (5A)
//   • maudsley_guidance   → strategy headline + detail + safety flags
//   • maoi_washout        → washout instructions + duration
//   • clozapine_redirect  → "Use the Clozapine module" call-out
//   • no_rule             → reason text
//
// Predicted-AE card, cost hint, smart alternatives — deferred to 5B+.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/patient_context_provider.dart';
import 'package:psychswitch/src/providers/preferences_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/services/notification_service.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/cost_comparison_card.dart';
import 'package:psychswitch/src/ui/widgets/crossover_chart.dart';
import 'package:psychswitch/src/ui/widgets/ddi_warnings_card.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/predicted_ae_card.dart';
import 'package:psychswitch/src/ui/widgets/score_ring.dart';
import 'package:psychswitch/src/ui/widgets/specialty_depth_card.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart' as ui;
import 'package:psychswitch/src/util/export_pdf.dart';
import 'package:psychswitch/src/util/share_plan.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/citations.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/monitoring.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/predicted_ae_profile.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';
import 'package:psychswitch_engine/scale_schedule.dart';
import 'package:psychswitch_engine/specialty.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';
import 'package:psychswitch_engine/util/case_id.dart';
import 'package:share_plus/share_plus.dart';

/// Payload passed via `GoRouterState.extra` when navigating to /result.
class ResultScreenArgs {
  const ResultScreenArgs({required this.input});

  final SwitchInput input;
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, this.args});

  final ResultScreenArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          if (args != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Save case',
              onPressed: () => _onSavePressed(context, ref, args!.input),
            ),
          if (args != null)
            asyncEngine.when(
              data: (engine) {
                final plan = engine.generateSwitchPlan(args!.input);
                if (plan is! SwitchPlanOk) return const SizedBox.shrink();
                return _ShareMenu(
                  plan: plan,
                  fromDrug: engine.getDrug(args!.input.fromDrugId),
                  toDrug: engine.getDrug(args!.input.toDrugId),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) {
            if (args == null) return const _MissingArgs();
            final plan = engine.generateSwitchPlan(args!.input);
            return _ResultBody(
              plan: plan,
              engine: engine,
              input: args!.input,
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSavePressed(
    BuildContext context,
    WidgetRef ref,
    SwitchInput input,
  ) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _SaveCaseDialog(),
    );
    if (label == null) return; // user cancelled
    final now = DateTime.now().toUtc().toIso8601String();
    final saved = SavedCase(
      id: mintCaseId(),
      label: label,
      fromDrugId: input.fromDrugId,
      fromDoseMg: input.fromDoseMg,
      toDrugId: input.toDrugId,
      toDoseMg: input.toDoseMg,
      startedISO: now,
      updatedISO: now,
    );
    await ref.read(savedCaseRepositoryProvider).save(saved);
    unawaited(hapticsConfirm());

    // Schedule monitoring reminders if the user has opted in. The
    // service writes nothing when permission is denied or no entries
    // are actionable from today onwards.
    final remindersOn =
        await ref.read(remindersEnabledProvider.future);
    if (remindersOn) {
      final engine = await ref.read(engineProvider.future);
      final ctx = ref.read(patientContextProvider);
      await NotificationService.instance.scheduleForCase(
        saved: saved,
        engine: engine,
        context: ctx,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          'Saved as "$label"',
          style: const TextStyle(color: AppColors.text),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Action menu in the AppBar — exposes "Share as text" (system share
/// sheet) and "Export PDF" (system print/share). Disabled when the
/// engine returns anything other than [SwitchPlanOk] — washout /
/// guidance / no-rule paths don't carry a schedule worth sharing.
class _ShareMenu extends StatelessWidget {
  const _ShareMenu({
    required this.plan,
    required this.fromDrug,
    required this.toDrug,
  });

  final SwitchPlanOk plan;
  final Drug? fromDrug;
  final Drug? toDrug;

  @override
  Widget build(BuildContext context) {
    if (fromDrug == null || toDrug == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Share or export',
      icon: const Icon(Icons.ios_share),
      onSelected: (v) async {
        unawaited(hapticsTap());
        switch (v) {
          case 'text':
            final body = formatPlanForShare(
              fromDrug: fromDrug!,
              toDrug: toDrug!,
              plan: plan,
            );
            await Share.share(
              body,
              subject:
                  'PsychSwitch — ${fromDrug!.genericName} → ${toDrug!.genericName}',
            );
          case 'pdf':
            await exportSwitchPlanPdf(
              fromDrug: fromDrug!,
              toDrug: toDrug!,
              plan: plan,
            );
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'text',
          child: ListTile(
            leading: Icon(Icons.notes_rounded),
            title: Text('Share as text'),
            subtitle: Text('WhatsApp · SMS · Email'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'pdf',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Export PDF'),
            subtitle: Text('Print · Save · AirDrop'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _SaveCaseDialog extends StatefulWidget {
  const _SaveCaseDialog();

  @override
  State<_SaveCaseDialog> createState() => _SaveCaseDialogState();
}

class _SaveCaseDialogState extends State<_SaveCaseDialog> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Save case',
        style: TextStyle(color: AppColors.text),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Free-form label — initials, room number, ward code. '
            'No patient identifiers.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctl,
            autofocus: true,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'e.g. JD · Bed 7 · 4F-12',
              hintStyle: TextStyle(color: AppColors.muted),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final v = _ctl.text.trim();
            if (v.isEmpty) return;
            Navigator.of(context).pop(v);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MissingArgs extends StatelessWidget {
  const _MissingArgs();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No switch input was provided. Go back and start a switch.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({
    required this.plan,
    required this.engine,
    required this.input,
  });

  final SwitchPlan plan;
  final SwitchingEngine engine;
  final SwitchInput input;

  String _drugName(String id) =>
      engine.getDrug(id)?.genericName ?? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(patientContextProvider);
    // Pull warnings for both ends of the switch — the from-drug warning
    // matters because the patient is still on it during cross-titration,
    // and the to-drug warning matters because they're starting it.
    final ctxWarnings = <ContextWarning>[
      ...warningsForDrug(ctx, input.fromDrugId),
      ...warningsForDrug(ctx, input.toDrugId),
    ];
    final body = _planContent(plan, ctx, ctxWarnings);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: <Widget>[
        EntranceFade(
          child: _DrugPairHeader(
            fromName: _drugName(input.fromDrugId),
            fromDose: input.fromDoseMg,
            toName: _drugName(input.toDrugId),
            toDose: input.toDoseMg,
          ),
        ),
        const SizedBox(height: 16),
        EntranceFade(index: 1, child: _StatusPill(plan: plan)),
        const SizedBox(height: 24),
        // Stagger the rest of the body — clamp the stagger index so
        // the tail (citations, monitoring) doesn't drag the entrance
        // out past 700ms even when the plan has many cards.
        for (var i = 0; i < body.length; i++)
          EntranceFade(index: (2 + i).clamp(0, 6), child: body[i]),
      ],
    );
  }

  /// DDI checker output as a list of widgets — empty when no hits, so
  /// it spreads cleanly into the body via `...`.
  List<Widget> _ddiSection(SwitchInput input) {
    final hits = checkPair(input.fromDrugId, input.toDrugId);
    if (hits.isEmpty) return const <Widget>[];
    return <Widget>[
      DdiWarningsCard(hits: hits),
      const SizedBox(height: 16),
    ];
  }

  /// Predicted AE card section. Returns empty when the engine produces
  /// no predictions (defensive — the typed risk fields + reverse-lookup
  /// table almost always yield at least one row).
  List<Widget> _predictedAeSection() {
    final toDrug = engine.getDrug(input.toDrugId);
    if (toDrug == null) return const <Widget>[];
    final fromDrug = engine.getDrug(input.fromDrugId);
    final profile = predictAeProfile(toDrug, fromDrug);
    if (profile.predictions.isEmpty) return const <Widget>[];
    return <Widget>[
      PredictedAeCard(profile: profile),
      const SizedBox(height: 16),
    ];
  }

  /// Cost comparison card section.
  List<Widget> _costSection() {
    final from = engine.getDrug(input.fromDrugId);
    final to = engine.getDrug(input.toDrugId);
    if (from == null || to == null) return const <Widget>[];
    return <Widget>[
      CostComparisonCard(fromDrug: from, toDrug: to),
      const SizedBox(height: 16),
    ];
  }

  /// Specialty depth (pregnancy / breastfeeding / pediatric / geriatric).
  List<Widget> _specialtySection(PatientContext ctx) {
    final from = engine.getDrug(input.fromDrugId);
    final to = engine.getDrug(input.toDrugId);
    if (from == null || to == null) return const <Widget>[];
    final assessment = assessSpecialty(
      fromDrugId: from.id,
      toDrugId: to.id,
      context: ctx,
      fromDrugName: from.genericName,
      toDrugName: to.genericName,
    );
    if (assessment.applicable.isEmpty ||
        assessment.recommendations.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      SpecialtyDepthCard(assessment: assessment),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _planContent(
    SwitchPlan plan,
    PatientContext ctx,
    List<ContextWarning> ctxWarnings,
  ) {
    return switch (plan) {
      final SwitchPlanOk ok =>
        <Widget>[
          // PsychSwitch Score ring — composite 0-100 over evidence,
          // AE alignment, context safety, DDI safety, dose fidelity.
          // Patient-context warnings feed in via 7B; DDI hits + AE
          // filter still TODO from earlier phases.
          if (engine.getDrug(input.toDrugId) case final toDrug?)
            _ScoreRingCard(
              plan: ok,
              toDrug: toDrug,
              dosesMatchReference: ok.dosesMatchReference,
              contextWarnings: ctxWarnings,
            ),
          const SizedBox(height: 16),
          if (ctxWarnings.isNotEmpty) ...<Widget>[
            _ContextWarningsCard(warnings: ctxWarnings),
            const SizedBox(height: 16),
          ],
          if (!ok.dosesMatchReference) ...<Widget>[
            const _ReferenceDosesBanner(),
            const SizedBox(height: 16),
          ],
          // Crossover shape chart — read the curves before the table.
          CrossoverChart(
            schedule: ok.schedule,
            totalDays: ok.rule.durationDays,
          ),
          const SizedBox(height: 16),
          _ScheduleCard(schedule: ok.schedule),
          const SizedBox(height: 16),
          if (ok.safetyFlags.isNotEmpty) ...<Widget>[
            _SafetyFlagsCard(flags: ok.safetyFlags),
            const SizedBox(height: 16),
          ],
          // DDI checker for the cross-taper overlap window. Renders
          // nothing when checkPair returns no hits.
          ..._ddiSection(input),
          _MonitoringPlanCard(
            fromDrugId: input.fromDrugId,
            toDrugId: input.toDrugId,
            patientContext: ctx,
          ),
          const SizedBox(height: 16),
          // Specialty depth — pregnancy / breastfeeding / pediatric /
          // geriatric. Renders only when patient context activates.
          ..._specialtySection(ctx),
          // Predicted AE profile for the to-drug.
          ..._predictedAeSection(),
          // Affordability hint.
          ..._costSection(),
          _CitationsCard(citations: ok.citations),
        ],
      SwitchPlanMaudsleyGuidance(
        :final guidance,
        :final safetyFlags,
      ) =>
        <Widget>[
          _GuidanceCard(
            headline: guidance.headline,
            detail: guidance.detail,
            waitDays: guidance.waitDays,
          ),
          const SizedBox(height: 16),
          if (safetyFlags.isNotEmpty) ...<Widget>[
            _SafetyFlagsCard(flags: safetyFlags),
            const SizedBox(height: 16),
          ],
          _CitationsCard(citations: guidance.citations),
        ],
      SwitchPlanMaoiWashout(
        :final washoutDays,
        :final reason,
        :final safetyFlags,
      ) =>
        <Widget>[
          _MaoiWashoutCard(washoutDays: washoutDays, reason: reason),
          const SizedBox(height: 16),
          if (safetyFlags.isNotEmpty)
            _SafetyFlagsCard(flags: safetyFlags),
        ],
      SwitchPlanClozapineRedirect(:final guidance) =>
        <Widget>[
          _ClozapineRedirectCard(guidance: guidance),
        ],
      SwitchPlanNoRule(:final reason) => <Widget>[
          _NoRuleCard(reason: reason),
        ],
    };
  }
}

class _DrugPairHeader extends StatelessWidget {
  const _DrugPairHeader({
    required this.fromName,
    required this.fromDose,
    required this.toName,
    required this.toDose,
  });

  final String fromName;
  final num fromDose;
  final String toName;
  final num toDose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Switch from $fromName ${_formatDose(fromDose)} milligrams '
          'to $toName ${_formatDose(toDose)} milligrams.',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _DrugTag(
                label: 'FROM',
                name: fromName,
                dose: fromDose,
                color: AppColors.from,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.muted,
                size: 20,
              ),
            ),
            Expanded(
              child: _DrugTag(
                label: 'TO',
                name: toName,
                dose: toDose,
                color: AppColors.to,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrugTag extends StatelessWidget {
  const _DrugTag({
    required this.label,
    required this.name,
    required this.dose,
    required this.color,
  });

  final String label;
  final String name;
  final num dose;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md - 2,
        AppSpace.md + 2,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const Gap.h(AppSpace.xs + 2),
              Text(
                label,
                style: AppTextSizes.eyebrow.copyWith(color: color),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Gap.v(2),
          Text(
            '${_formatDose(dose)} mg',
            style: AppTextSizes.caption.copyWith(
              color: AppColors.mutedStrong,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.plan});

  final SwitchPlan plan;

  ({String label, Color color}) _styleFor() => switch (plan) {
        SwitchPlanOk() => (label: 'Reviewed schedule', color: AppColors.to),
        SwitchPlanMaudsleyGuidance() =>
          (label: 'Maudsley class-level guidance', color: AppColors.accent),
        SwitchPlanMaoiWashout() =>
          (label: 'MAOI washout required', color: AppColors.danger),
        SwitchPlanClozapineRedirect() =>
          (label: 'Use Clozapine module', color: AppColors.warning),
        SwitchPlanNoRule() =>
          (label: 'No reviewed rule', color: AppColors.muted),
      };

  @override
  Widget build(BuildContext context) {
    final style = _styleFor();
    return Align(
      alignment: Alignment.centerLeft,
      child: ui.StatusPill(
        label: style.label,
        tone: style.color,
        dot: true,
      ),
    );
  }
}

class _ReferenceDosesBanner extends StatelessWidget {
  const _ReferenceDosesBanner();

  @override
  Widget build(BuildContext context) {
    return const _Banner(
      tone: AppColors.accent,
      eyebrow: 'REFERENCE DOSES',
      title: 'Schedule shown at reviewed reference doses',
      body:
          "The doses you entered differ from the rule's reviewed reference. "
          'Treat this schedule as an example — adapt proportionally to your '
          "patient's doses, rounding to formulation increments.",
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final List<ScheduleStep> schedule;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Schedule',
      child: Column(
        children: <Widget>[
          const _ScheduleRow(
            isHeader: true,
            day: 'Day',
            from: 'From',
            to: 'To',
            notes: 'Notes',
          ),
          const Divider(height: 1),
          ...schedule.indexed.map(
            ((int, ScheduleStep) e) {
              final (i, s) = e;
              return _ScheduleRow(
                day: s.day.toString(),
                from: _formatDose(s.fromDoseMg),
                to: _formatDose(s.toDoseMg),
                notes: s.notes ?? '',
                stripe: i.isOdd,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.day,
    required this.from,
    required this.to,
    required this.notes,
    this.isHeader = false,
    this.stripe = false,
  });

  final String day;
  final String from;
  final String to;
  final String notes;
  final bool isHeader;
  final bool stripe;

  // Tabular figures so digits line up vertically across rows — turns
  // the schedule into a real table rather than a column of text.
  static const _tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: isHeader ? AppColors.muted : AppColors.text,
      fontSize: 12,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: isHeader ? 1 : 0,
      fontFeatures: _tabularFigures,
    );
    final notesStyle = TextStyle(
      color: isHeader ? AppColors.muted : AppColors.mutedStrong,
      fontSize: 11.5,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
      height: 1.4,
      letterSpacing: isHeader ? 1 : 0,
    );
    return Container(
      color: stripe && !isHeader
          ? AppColors.surfaceHigh.withValues(alpha: 0.5)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 36,
            child: Text(
              day,
              style: labelStyle.copyWith(
                color: isHeader ? AppColors.muted : AppColors.accent,
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              from,
              style: labelStyle.copyWith(
                color: isHeader ? AppColors.muted : AppColors.from,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              to,
              style: labelStyle.copyWith(
                color: isHeader ? AppColors.muted : AppColors.to,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(child: Text(notes, style: notesStyle)),
        ],
      ),
    );
  }
}

class _ContextWarningsCard extends StatelessWidget {
  const _ContextWarningsCard({required this.warnings});

  final List<ContextWarning> warnings;

  Color _toneFor(WarningSeverity s) => switch (s) {
        WarningSeverity.info => AppColors.accent,
        WarningSeverity.warning => AppColors.warning,
        WarningSeverity.danger => AppColors.danger,
      };

  IconData _iconFor(WarningSeverity s) => switch (s) {
        WarningSeverity.info => Icons.info_outline,
        WarningSeverity.warning => Icons.warning_amber_outlined,
        WarningSeverity.danger => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Patient-context warnings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings.map((w) {
          final tone = _toneFor(w.severity);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(_iconFor(w.severity), size: 16, color: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (w.drugId != null)
                        Text(
                          w.drugId!.toUpperCase(),
                          style: TextStyle(
                            color: tone,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      Text(
                        w.message,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SafetyFlagsCard extends StatelessWidget {
  const _SafetyFlagsCard({required this.flags});

  final List<String> flags;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Safety flags',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: flags.map((f) => _FlagChip(flag: f)).toList(),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.flag});

  final String flag;

  Color _color() {
    if (flag.contains('avoid') ||
        flag.contains('contraindicat') ||
        flag.startsWith('maoi_washout') ||
        flag == 'discontinuation_syndrome_high' ||
        flag == 'qtc_additive_overlap') {
      return AppColors.warning;
    }
    return AppColors.accent;
  }

  String _label() => flag.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return ui.StatusPill(label: _label(), tone: _color());
  }
}

class _CitationsCard extends StatelessWidget {
  const _CitationsCard({required this.citations});

  final List<String> citations;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Citations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: citations
            .map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• $c',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.headline,
    required this.detail,
    this.waitDays,
  });

  final String headline;
  final String detail;
  final int? waitDays;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      tone: AppColors.accent,
      eyebrow: 'GUIDANCE',
      title: headline,
      body: waitDays != null
          ? '$detail\n\nWait period: $waitDays day${waitDays == 1 ? '' : 's'}.'
          : detail,
    );
  }
}

class _MaoiWashoutCard extends StatelessWidget {
  const _MaoiWashoutCard({
    required this.washoutDays,
    required this.reason,
  });

  final int washoutDays;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      tone: AppColors.danger,
      eyebrow: 'MAOI WASHOUT',
      title: '$washoutDays-day washout required',
      body: reason,
    );
  }
}

class _ClozapineRedirectCard extends StatelessWidget {
  const _ClozapineRedirectCard({required this.guidance});

  final String guidance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: const Border(
          left: BorderSide(color: AppColors.warning, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CLOZAPINE INITIATION',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use the Clozapine module',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guidance,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.pushNamed(Routes.clozapine),
              icon: const Icon(Icons.medical_services_outlined, size: 16),
              label: const Text('Open Clozapine module'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRuleCard extends StatelessWidget {
  const _NoRuleCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      tone: AppColors.muted,
      eyebrow: 'NO REVIEWED RULE',
      title: 'No specific reviewed rule for this pair',
      body: reason,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.tone,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final Color tone;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: tone, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: TextStyle(
              color: tone,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ScoreRingCard extends StatelessWidget {
  const _ScoreRingCard({
    required this.plan,
    required this.toDrug,
    required this.dosesMatchReference,
    required this.contextWarnings,
  });

  final SwitchPlanOk plan;
  final Drug toDrug;
  final bool dosesMatchReference;
  final List<ContextWarning> contextWarnings;

  @override
  Widget build(BuildContext context) {
    final grade = gradeCitations(plan.citations);
    // Phase 7B feeds patient-context warnings; DDI hits + AE filter are
    // still scaffolded empty until those features land. Dose fidelity is
    // approximate — true when input doses match the rule's reference,
    // otherwise treated as mild adaptation.
    final scaleResult = ScaleResult(
      schedule: plan.schedule,
      applied: const ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 1,
        toFactor: 1,
      ),
      adapted: !dosesMatchReference,
      warnings: const <ScaleWarning>[],
      evidencePenalty: dosesMatchReference ? 0 : 1,
    );
    final score = computePsychSwitchScore(
      ScoreInputs(
        toDrug: toDrug,
        scaleResult: scaleResult,
        ddiHits: const <DdiHit>[],
        contextWarnings: contextWarnings,
        evidenceGrade: grade,
      ),
    );
    return _Card(
      title: 'PsychSwitch Score',
      child: Row(
        children: <Widget>[
          ScoreRing(score: score),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  score.headline,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  score.components.evidence.note,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
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

class _MonitoringPlanCard extends StatelessWidget {
  const _MonitoringPlanCard({
    required this.fromDrugId,
    required this.toDrugId,
    required this.patientContext,
  });

  final String fromDrugId;
  final String toDrugId;
  final PatientContext patientContext;

  Color _categoryColor(MonitoringCategory c) {
    switch (c) {
      case MonitoringCategory.lab:
        return AppColors.accent;
      case MonitoringCategory.ecg:
        return AppColors.danger;
      case MonitoringCategory.physical:
        return AppColors.to;
      case MonitoringCategory.rating:
        return AppColors.warning;
      case MonitoringCategory.review:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = generateMonitoringPlan(
      toDrugId: toDrugId,
      fromDrugId: fromDrugId,
      context: patientContext,
    );
    if (plan.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    // Show the first 8 entries; rest get a "+N more" footnote so the
    // card stays scannable on small screens.
    const previewLimit = 8;
    final entries = plan.entries.take(previewLimit).toList();
    final hidden = plan.entries.length - entries.length;
    return _Card(
      title: 'Monitoring plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: _categoryColor(e.category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text(
                      'Day ${e.dayOffset}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          e.label,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          e.detail,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hidden > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '+$hidden more entr${hidden == 1 ? 'y' : 'ies'}',
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
