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
import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/alternatives_card.dart';
import 'package:psychswitch/src/ui/widgets/ddi_warnings_card.dart';
import 'package:psychswitch/src/ui/widgets/discontinuation_card.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/predicted_ae_card.dart';
import 'package:psychswitch/src/ui/widgets/rationale_panel.dart';
import 'package:psychswitch/src/ui/widgets/rule_provenance_card.dart';
import 'package:psychswitch/src/ui/widgets/score_ring.dart';
import 'package:psychswitch/src/ui/widgets/specialty_depth_card.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart' as ui;
import 'package:psychswitch/src/util/export_pdf.dart';
import 'package:psychswitch/src/util/share_plan.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/citations.dart';
import 'package:psychswitch_engine/ddi.dart';
import 'package:psychswitch_engine/discontinuation.dart';
import 'package:psychswitch_engine/monitoring.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/predicted_ae_profile.dart';
import 'package:psychswitch_engine/psych_switch_score.dart';
import 'package:psychswitch_engine/scale_schedule.dart';
import 'package:psychswitch_engine/specialty.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/taper_speed.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/enums.dart';
import 'package:psychswitch_engine/types/schedule_step.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';
import 'package:psychswitch_engine/util/case_id.dart';
import 'package:share_plus/share_plus.dart';

/// Payload passed via `GoRouterState.extra` when navigating to /result.
class ResultScreenArgs {
  const ResultScreenArgs({required this.input});

  final SwitchInput input;
}

/// Which schedule the result body is showing.
///
/// • `adapted` — the rule's reviewed schedule scaled proportionally to
///   the user's actual input doses (rounded to formulation increments,
///   clinical-max-capped, duplicate steps merged). The clinically-useful
///   default — what the prescriber should hand off.
/// • `reviewed` — the unmodified reviewed reference schedule, doses
///   exactly as published. Useful for verification: "what does the
///   source actually say?"
///
/// Only meaningful when the user's doses don't match the rule's
/// reviewed reference AND the scaling mode isn't `noScale` (fixed
/// protocols like LAI / washouts can't be proportionally scaled).
enum _ScheduleView { adapted, reviewed }

/// `autoDispose` so leaving /result resets the view to `.adapted` for
/// the next case. Shared between [_ResultBody] (which renders the
/// schedule) and [_ShareMenu] (which exports / shares whichever view
/// the clinician is currently looking at).
final _scheduleViewProvider =
    StateProvider.autoDispose<_ScheduleView>((_) => _ScheduleView.adapted);

/// Taper-speed selection — the dose progression in a reviewed rule
/// (100% → 75% → 50% → 25% → 0) is what's clinically reviewed; the
/// DAY INTERVALS between those steps are context-dependent (faster
/// for stable / monitored, slower for first-episode / high-relapse).
///
/// Only applies to cross-taper / plateau-cross-taper strategies AND
/// schedules long enough to compress (≥ 10 days, ≥ 3 steps — see
/// [speedToggleApplies]). Direct switches and washouts ignore this.
///
/// `autoDispose` so leaving /result resets to `TaperSpeed.standard`
/// (the Maudsley-reviewed default) for the next case.
final _taperSpeedProvider =
    StateProvider.autoDispose<TaperSpeed>((_) => TaperSpeed.standard);

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
                  input: args!.input,
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
///
/// Watches [_scheduleViewProvider] so the exported plan reflects the
/// view the clinician is currently looking at: adapted (default) or
/// reviewed reference. Re-runs `scaleSchedule` locally so it doesn't
/// have to share state with `_ResultBody` beyond the provider.
class _ShareMenu extends ConsumerWidget {
  const _ShareMenu({
    required this.plan,
    required this.input,
    required this.fromDrug,
    required this.toDrug,
  });

  final SwitchPlanOk plan;
  final SwitchInput input;
  final Drug? fromDrug;
  final Drug? toDrug;

  /// Build the [SwitchPlanOk] payload for share/export. Two transforms:
  ///   1. Adapted view: swap in the dose-scaled schedule and flip
  ///      `dosesMatchReference` so the formatter doesn't print the
  ///      "but you entered X mg" note (schedule already reflects the
  ///      user's doses).
  ///   2. Taper speed: compress / expand the day intervals to match
  ///      whichever speed the clinician picked on screen.
  ///
  /// Applied in that order — scaling first (doses), then speed (timing).
  SwitchPlanOk _payloadFor(_ScheduleView view, TaperSpeed speed) {
    if (fromDrug == null || toDrug == null) return plan;
    var schedule = plan.schedule;
    var dosesMatchReference = plan.dosesMatchReference;
    if (view == _ScheduleView.adapted) {
      final scaled = scaleSchedule(
        rule: plan.rule,
        fromDrug: fromDrug!,
        toDrug: toDrug!,
        userFromDose: input.fromDoseMg,
        userToDose: input.toDoseMg,
      );
      if (scaled.adapted) {
        schedule = scaled.schedule;
        // Schedule is now in the user's doses — suppress the formatter's
        // dose-mismatch note by claiming reference parity.
        dosesMatchReference = true;
      }
    }
    if (speed != TaperSpeed.standard) {
      schedule = compressSchedule(schedule, speed);
    }
    if (identical(schedule, plan.schedule) &&
        dosesMatchReference == plan.dosesMatchReference) {
      return plan;
    }
    return SwitchPlanOk(
      rule: plan.rule,
      schedule: schedule,
      safetyFlags: plan.safetyFlags,
      citations: plan.citations,
      dosesMatchReference: dosesMatchReference,
      inputDoses: plan.inputDoses,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fromDrug == null || toDrug == null) return const SizedBox.shrink();
    final view = ref.watch(_scheduleViewProvider);
    final pickedSpeed = ref.watch(_taperSpeedProvider);
    // Same speed-supported gate as the body: cross-taper / plateau /
    // overlap, ≥ 10-day span. Otherwise force standard for export.
    final s = plan.rule.strategy;
    final speedSupported = (s == Strategy.crossTaper ||
            s == Strategy.plateauCrossTaper ||
            s == Strategy.overlapTaper) &&
        speedToggleApplies(plan.schedule);
    final effectiveSpeed = speedSupported ? pickedSpeed : TaperSpeed.standard;
    return PopupMenuButton<String>(
      tooltip: 'Share or export',
      icon: const Icon(Icons.ios_share),
      onSelected: (v) async {
        unawaited(hapticsTap());
        final payload = _payloadFor(view, effectiveSpeed);
        switch (v) {
          case 'text':
            final body = formatPlanForShare(
              fromDrug: fromDrug!,
              toDrug: toDrug!,
              plan: payload,
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
              plan: payload,
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
    final view = ref.watch(_scheduleViewProvider);
    final pickedSpeed = ref.watch(_taperSpeedProvider);
    // Pull warnings for both ends of the switch — the from-drug warning
    // matters because the patient is still on it during cross-titration,
    // and the to-drug warning matters because they're starting it.
    final ctxWarnings = <ContextWarning>[
      ...warningsForDrug(ctx, input.fromDrugId),
      ...warningsForDrug(ctx, input.toDrugId),
    ];

    // For OK plans, run the dose scaler so we have both views available
    // (adapted = scaled to the user's input doses; reviewed = the rule's
    // raw schedule). `scaleSchedule` is pure and cheap — fine to call
    // on every build.
    final scaleResult = _scaleResultFor(plan);

    // Effective taper speed: only apply the user's pick when the rule
    // supports compression (cross-taper / plateau-cross-taper, ≥ 10
    // days, ≥ 3 steps). Direct switches and washouts ignore the toggle.
    final speedSupported = _speedSupported(plan);
    final effectiveSpeed = speedSupported ? pickedSpeed : TaperSpeed.standard;

    // Derive the on-screen duration from the COMPRESSED schedule's
    // last day rather than `adjustedDurationDays(...)`. The two
    // diverge by 1 day on certain speeds because per-step rounding
    // and total-duration rounding are independent functions — the
    // schedule's last day is the source of truth shown to the user.
    int? adjustedDuration;
    if (plan is SwitchPlanOk) {
      final pl = plan as SwitchPlanOk;
      final base = _displaySchedule(pl, scaleResult, view);
      final compressed = compressSchedule(base, effectiveSpeed);
      adjustedDuration = compressed.isEmpty
          ? pl.rule.durationDays
          : compressed.last.day;
    }

    final body = _planContent(
      plan,
      ctx,
      ctxWarnings,
      scaleResult,
      view,
      ref,
      effectiveSpeed,
      pickedSpeed,
      speedSupported,
    );
    final hero = <Widget>[
      EntranceFade(
        child: _ResultHero(
          input: input,
          fromName: _drugName(input.fromDrugId),
          toName: _drugName(input.toDrugId),
          plan: plan,
          toDrug: engine.getDrug(input.toDrugId),
          contextWarnings: ctxWarnings,
          overrideDurationDays: adjustedDuration,
        ),
      ),
      const Gap.v(AppSpace.xl - 4),
    ];

    if (context.isWide) {
      // Wide: hero band stays full width; the body splits into a
      // 2-up Wrap so each card fills half the row. Spacer gaps and
      // SizedBoxes are filtered out — Wrap handles its own spacing.
      final cards = body.whereType<Widget>().where((w) {
        if (w is SizedBox) return false;
        if (w is Gap) return false;
        return true;
      }).toList();
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: <Widget>[
          ...hero,
          LayoutBuilder(
            builder: (ctx, constraints) {
              final w = (constraints.maxWidth - AppSpace.lg) / 2;
              return Wrap(
                spacing: AppSpace.lg,
                runSpacing: AppSpace.lg,
                children: <Widget>[
                  for (var i = 0; i < cards.length; i++)
                    SizedBox(
                      width: w,
                      child: EntranceFade(
                        index: (2 + i).clamp(0, 6),
                        child: cards[i],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: <Widget>[
        ...hero,
        // Stagger the rest of the body — clamp the stagger index so
        // the tail (citations, monitoring) doesn't drag the entrance
        // out past 700ms even when the plan has many cards.
        for (var i = 0; i < body.length; i++)
          EntranceFade(index: (2 + i).clamp(0, 6), child: body[i]),
      ],
    );
  }

  /// Run the dose scaler for OK plans so the body has both the adapted
  /// and the reviewed schedules ready to render. Returns null for any
  /// non-OK branch (washout / guidance / clozapine / no-rule have no
  /// scalable schedule) and for OK plans where one of the drugs has
  /// gone missing from the registry (defensive).
  ScaleResult? _scaleResultFor(SwitchPlan plan) {
    if (plan is! SwitchPlanOk) return null;
    final fromDrug = engine.getDrug(input.fromDrugId);
    final toDrug = engine.getDrug(input.toDrugId);
    if (fromDrug == null || toDrug == null) return null;
    return scaleSchedule(
      rule: plan.rule,
      fromDrug: fromDrug,
      toDrug: toDrug,
      userFromDose: input.fromDoseMg,
      userToDose: input.toDoseMg,
    );
  }

  /// Pick which schedule to render. Defaults to adapted (scaled to the
  /// user's input doses) — falls back to the rule's reviewed schedule
  /// when (a) the user explicitly toggled to `.reviewed`, (b) the scaler
  /// didn't actually adapt anything (doses already match reference, or
  /// fixed protocol), or (c) the scaler couldn't run.
  static List<ScheduleStep> _displaySchedule(
    SwitchPlanOk ok,
    ScaleResult? scaleResult,
    _ScheduleView view,
  ) {
    if (scaleResult == null || !scaleResult.adapted) return ok.schedule;
    return view == _ScheduleView.adapted ? scaleResult.schedule : ok.schedule;
  }

  /// Whether taper-speed compression makes sense for this plan. True
  /// only for cross-taper / plateau-cross-taper strategies whose
  /// schedule has enough headroom (≥ 3 steps, ≥ 10-day span). Direct
  /// switches (1–2 day) and washouts get no toggle.
  static bool _speedSupported(SwitchPlan plan) {
    if (plan is! SwitchPlanOk) return false;
    final s = plan.rule.strategy;
    final crossish = s == Strategy.crossTaper ||
        s == Strategy.plateauCrossTaper ||
        s == Strategy.overlapTaper;
    if (!crossish) return false;
    return speedToggleApplies(plan.schedule);
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

  /// Discontinuation banner for the from-drug. Renders only when the
  /// engine flags moderate+ severity (the helper itself self-hides
  /// for `low`).
  List<Widget> _discontinuationSection() {
    final flag = getDiscontinuationFlag(input.fromDrugId);
    if (flag == null || flag.severity == DiscontinuationSeverity.low) {
      return const <Widget>[];
    }
    final from = engine.getDrug(input.fromDrugId);
    if (from == null) return const <Widget>[];
    return <Widget>[
      DiscontinuationCard(
        flag: flag,
        drugDisplayName: from.genericName,
      ),
      const SizedBox(height: 16),
    ];
  }

  /// What-if alternatives — top 3 reviewed switch targets from the
  /// same from-drug, excluding the current to-drug.
  List<Widget> _alternativesSection(PatientContext ctx, SwitchPlanOk plan) {
    final from = engine.getDrug(input.fromDrugId);
    final to = engine.getDrug(input.toDrugId);
    if (from == null || to == null) return const <Widget>[];
    return <Widget>[
      AlternativesCard(
        engine: engine,
        fromDrug: from,
        currentToDrug: to,
        context: ctx,
      ),
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
    ScaleResult? scaleResult,
    _ScheduleView view,
    WidgetRef ref,
    TaperSpeed effectiveSpeed,
    TaperSpeed pickedSpeed,
    bool speedSupported,
  ) {
    return switch (plan) {
      final SwitchPlanOk ok => <Widget>[
          // Score ring + strategy + status now live in _ResultHero.
          // The body picks up from the supporting clinical surfaces.
          if (ctxWarnings.isNotEmpty) ...<Widget>[
            _ContextWarningsCard(warnings: ctxWarnings),
            const Gap.v(AppSpace.lg),
          ],
          // Adapted-vs-reviewed banner — ALWAYS shown for OK plans so the
          // toggle is discoverable. Three states:
          //   • doses differ + scalable → full toggle banner
          //   • doses match reference   → "doses match" confirmation +
          //                               toggle still works (the two
          //                               views happen to render the
          //                               same schedule, but the label
          //                               clarifies what you're seeing)
          //   • fixed protocol + differ → no-toggle "schedule not scaled"
          if (scaleResult != null &&
              scaleResult.applied.mode == ScalingMode.noScale &&
              !ok.dosesMatchReference) ...<Widget>[
            _FixedProtocolNotice(inputDoses: ok.inputDoses),
            const Gap.v(AppSpace.lg),
          ] else if (scaleResult != null &&
              scaleResult.applied.mode != ScalingMode.noScale) ...<Widget>[
            _AdaptiveScheduleBanner(
              view: view,
              inputDoses: ok.inputDoses,
              rule: ok.rule,
              scaleResult: scaleResult,
              dosesMatchReference: ok.dosesMatchReference,
              onToggle: () {
                ref.read(_scheduleViewProvider.notifier).state =
                    view == _ScheduleView.adapted
                        ? _ScheduleView.reviewed
                        : _ScheduleView.adapted;
              },
            ),
            const Gap.v(AppSpace.lg),
          ],
          // Taper-speed selector — only renders when the rule's
          // strategy supports compression (cross-taper / plateau /
          // overlap, ≥ 10-day span). Lets the clinician pick Faster
          // (~½ Maudsley), Standard (Maudsley default), or Slower
          // (~1½× Maudsley) — driven by NHS / Stahl / real-world
          // evidence that the dose progression is what's reviewed,
          // not the day intervals.
          if (speedSupported) ...<Widget>[
            Builder(
              builder: (_) {
                // Same single-source-of-truth as the hero: derive the
                // displayed taper duration from the compressed schedule's
                // last day, not from a parallel rounding function. Keeps
                // the hero, the selector, and the table all in agreement.
                final compressed = compressSchedule(
                  _displaySchedule(ok, scaleResult, view),
                  effectiveSpeed,
                );
                final adjustedDays = compressed.isEmpty
                    ? ok.rule.durationDays
                    : compressed.last.day;
                return _TaperSpeedSelector(
                  picked: pickedSpeed,
                  onPick: (s) {
                    unawaited(hapticsTap());
                    ref.read(_taperSpeedProvider.notifier).state = s;
                  },
                  durationDays: adjustedDays,
                  originalDurationDays: ok.rule.durationDays,
                );
              },
            ),
            const Gap.v(AppSpace.lg),
          ],
          // Day-by-day cross-taper schedule. Schedule reflects both the
          // adapted/reviewed view and the taper-speed selection. The
          // CrossoverChart that used to sit above this is intentionally
          // removed — the schedule table is the primary source of truth;
          // a parallel curve added visual weight without adding signal.
          _ScheduleCard(
            schedule: compressSchedule(
              _displaySchedule(ok, scaleResult, view),
              effectiveSpeed,
            ),
          ),
          const Gap.v(AppSpace.lg),
          // Why this strategy was chosen — sits with the schedule.
          RationalePanel(rationale: ok.rule.rationale),
          const Gap.v(AppSpace.lg),
          if (ok.safetyFlags.isNotEmpty) ...<Widget>[
            _SafetyFlagsCard(flags: ok.safetyFlags),
            const Gap.v(AppSpace.lg),
          ],
          // Discontinuation-syndrome banner for the from-drug — sits
          // with the other safety surfaces above the DDI list.
          ..._discontinuationSection(),
          // DDI checker for the cross-taper overlap window. Renders
          // nothing when checkPair returns no hits.
          ..._ddiSection(input),
          _MonitoringPlanCard(
            fromDrugId: input.fromDrugId,
            toDrugId: input.toDrugId,
            patientContext: ctx,
          ),
          const Gap.v(AppSpace.lg),
          // Specialty depth — pregnancy / breastfeeding / pediatric /
          // geriatric. Renders only when patient context activates.
          ..._specialtySection(ctx),
          // Predicted AE profile for the to-drug.
          ..._predictedAeSection(),
          // What-if alternatives — top 3 reviewed targets from the
          // same from-drug.
          ..._alternativesSection(ctx, ok),
          // Rule provenance footer — trust signals for CME audit.
          RuleProvenanceCard(rule: ok.rule),
          const Gap.v(AppSpace.lg),
          _CitationsCard(citations: ok.citations),
        ],
      SwitchPlanMaudsleyGuidance(
        :final guidance,
        :final safetyFlags,
      ) =>
        <Widget>[
          // Verdict (eyebrow + headline + body) now lives in hero.
          if (safetyFlags.isNotEmpty) ...<Widget>[
            _SafetyFlagsCard(flags: safetyFlags),
            const Gap.v(AppSpace.lg),
          ],
          _CitationsCard(citations: guidance.citations),
        ],
      SwitchPlanMaoiWashout(:final safetyFlags) => <Widget>[
          // Verdict (X-day washout + reason) now lives in hero.
          if (safetyFlags.isNotEmpty) _SafetyFlagsCard(flags: safetyFlags),
        ],
      SwitchPlanClozapineRedirect() => const <Widget>[
          // Verdict + Open-Clozapine-module CTA both live in hero.
        ],
      SwitchPlanNoRule() => const <Widget>[
          // Verdict (eyebrow + reason) lives in hero.
        ],
    };
  }
}

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}

/// Unified result hero — drug-pair band on top, verdict band below.
///
/// Every plan branch lives here so the clinician sees ONE focal object:
/// the pair of drugs they asked about, and the engine's verdict on the
/// switch. For OK plans the verdict is composed (strategy · duration
/// eyebrow + ScoreRing + "Reviewed schedule"); for non-OK plans it's
/// a tone-tinted callout (washout / guidance / clozapine / no-rule).
///
/// The two bands are joined by a 0.5-px hairline divider, no shadow,
/// 0.5-px outer border. The same chrome rhythm as the new Switch hero.
class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.input,
    required this.fromName,
    required this.toName,
    required this.plan,
    required this.toDrug,
    required this.contextWarnings,
    this.overrideDurationDays,
  });

  final SwitchInput input;
  final String fromName;
  final String toName;
  final SwitchPlan plan;
  final Drug? toDrug;
  final List<ContextWarning> contextWarnings;

  /// Duration to render in the strategy eyebrow, overriding
  /// `plan.rule.durationDays` so the hero reflects the user's
  /// taper-speed selection (Faster / Slower compress / expand).
  /// Null for non-OK plans or when the speed toggle doesn't apply.
  final int? overrideDurationDays;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Switch from $fromName ${_formatDose(input.fromDoseMg)} milligrams '
          'to $toName ${_formatDose(input.toDoseMg)} milligrams.',
      container: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeroDrugBand(
                  fromName: fromName,
                  fromDose: input.fromDoseMg,
                  toName: toName,
                  toDose: input.toDoseMg,
                ),
                Container(
                  height: 0.5,
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
                _HeroVerdictBand(
                  plan: plan,
                  toDrug: toDrug,
                  contextWarnings: contextWarnings,
                  overrideDurationDays: overrideDurationDays,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drug-pair band. Two columns (FROM left, TO right) joined by a quiet
/// arrow. Names are sized to breathe — 17pt w700, -0.3 letter-spacing.
class _HeroDrugBand extends StatelessWidget {
  const _HeroDrugBand({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg + 2,
        AppSpace.lg,
        AppSpace.lg + 2,
        AppSpace.lg,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _HeroDrugCell(
              label: 'FROM',
              name: fromName,
              dose: fromDose,
              tone: AppColors.from,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.muted.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
          Expanded(
            child: _HeroDrugCell(
              label: 'TO',
              name: toName,
              dose: toDose,
              tone: AppColors.to,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDrugCell extends StatelessWidget {
  const _HeroDrugCell({
    required this.label,
    required this.name,
    required this.dose,
    required this.tone,
    this.alignEnd = false,
  });

  final String label;
  final String name;
  final num dose;
  final Color tone;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
    );
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!alignEnd) ...<Widget>[
              dot,
              const Gap.h(AppSpace.xs + 2),
            ],
            Text(
              label,
              style: AppTextSizes.eyebrow.copyWith(color: tone),
            ),
            if (alignEnd) ...<Widget>[
              const Gap.h(AppSpace.xs + 2),
              dot,
            ],
          ],
        ),
        const Gap.v(AppSpace.sm + 2),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.3,
          ),
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap.v(AppSpace.xxs),
        Text(
          '${_formatDose(dose)} mg',
          style: const TextStyle(
            color: AppColors.mutedStrong,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Verdict band — switches on plan type. OK = composed (strategy +
/// score ring + status). Non-OK = tone-tinted callout with eyebrow +
/// headline + status text + body, and an optional CTA for clozapine.
class _HeroVerdictBand extends StatelessWidget {
  const _HeroVerdictBand({
    required this.plan,
    required this.toDrug,
    required this.contextWarnings,
    this.overrideDurationDays,
  });

  final SwitchPlan plan;
  final Drug? toDrug;
  final List<ContextWarning> contextWarnings;
  final int? overrideDurationDays;

  @override
  Widget build(BuildContext context) {
    return switch (plan) {
      final SwitchPlanOk ok => _OkVerdict(
          plan: ok,
          toDrug: toDrug,
          contextWarnings: contextWarnings,
          overrideDurationDays: overrideDurationDays,
        ),
      SwitchPlanMaudsleyGuidance(:final guidance) => _ToneVerdict(
          tone: AppColors.accent,
          eyebrow: 'GUIDANCE',
          headline: guidance.headline,
          status: 'Maudsley class-level guidance',
          body: guidance.waitDays != null
              ? '${guidance.detail}\n\nWait period: ${guidance.waitDays} '
                  'day${guidance.waitDays == 1 ? '' : 's'}.'
              : guidance.detail,
        ),
      SwitchPlanMaoiWashout(:final washoutDays, :final reason) => _ToneVerdict(
          tone: AppColors.danger,
          eyebrow: 'MAOI WASHOUT',
          headline: '$washoutDays-day washout required',
          status: 'MAOI washout required',
          body: reason,
        ),
      SwitchPlanClozapineRedirect(:final guidance) => _ClozapineVerdict(
          guidance: guidance,
        ),
      SwitchPlanNoRule(:final reason) => _ToneVerdict(
          tone: AppColors.muted,
          eyebrow: 'NO REVIEWED RULE',
          headline: 'No specific reviewed rule for this pair',
          status: 'No reviewed rule',
          body: reason,
        ),
    };
  }
}

/// OK verdict band — strategy · duration eyebrow, ScoreRing, and the
/// "Reviewed schedule" status text alongside a meta line ("Doses
/// adapted · 3 safety flags" / etc.).
class _OkVerdict extends StatelessWidget {
  const _OkVerdict({
    required this.plan,
    required this.toDrug,
    required this.contextWarnings,
    this.overrideDurationDays,
  });

  final SwitchPlanOk plan;
  final Drug? toDrug;
  final List<ContextWarning> contextWarnings;
  final int? overrideDurationDays;

  String get _strategyLabel => switch (plan.rule.strategy) {
        Strategy.direct => 'DIRECT SWITCH',
        Strategy.crossTaper => 'CROSS-TAPER',
        Strategy.plateauCrossTaper => 'PLATEAU CROSS-TAPER',
        Strategy.overlapTaper => 'OVERLAP TAPER',
        Strategy.washout => 'WASHOUT',
      };

  /// Map the engine's score band to the matching design-token colour.
  /// Mirrors `ScoreRing._bandColor` so the dot + label in the verdict
  /// text uses the same tone as the arc itself.
  static Color _bandColor(ScoreBand band) => switch (band) {
        ScoreBand.excellent => AppColors.to,
        ScoreBand.good => AppColors.accent,
        ScoreBand.caution => AppColors.warning,
        ScoreBand.poor => AppColors.danger,
      };

  String get _metaLine {
    final parts = <String>[];
    if (!plan.dosesMatchReference) parts.add('Doses adapted');
    final flagCount = plan.safetyFlags.length;
    if (flagCount > 0) {
      parts.add('$flagCount safety flag${flagCount == 1 ? '' : 's'}');
    }
    return parts.join(' · ');
  }

  PsychSwitchScore _computeScore(Drug drug) {
    final grade = gradeCitations(plan.citations);
    final scaleResult = ScaleResult(
      schedule: plan.schedule,
      applied: const ScaleApplied(
        mode: ScalingMode.proportional,
        fromFactor: 1,
        toFactor: 1,
      ),
      adapted: !plan.dosesMatchReference,
      warnings: const <ScaleWarning>[],
      evidencePenalty: plan.dosesMatchReference ? 0 : 1,
    );
    return computePsychSwitchScore(
      ScoreInputs(
        toDrug: drug,
        scaleResult: scaleResult,
        ddiHits: const <DdiHit>[],
        contextWarnings: contextWarnings,
        evidenceGrade: grade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = toDrug == null ? null : _computeScore(toDrug!);
    final meta = _metaLine;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg + 2,
        AppSpace.md + 2,
        AppSpace.lg + 2,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Builder(
            builder: (_) {
              final days = overrideDurationDays ?? plan.rule.durationDays;
              return Text(
                '$_strategyLabel · $days DAY${days == 1 ? '' : 'S'}',
                style: AppTextSizes.eyebrow.copyWith(color: AppColors.to),
              );
            },
          ),
          const Gap.v(AppSpace.md),
          Row(
            children: <Widget>[
              if (score != null) ...<Widget>[
                ScoreRing(score: score, size: 64, strokeWidth: 6),
                const Gap.h(AppSpace.lg),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Status text + band name in one line — the band
                    // now lives alongside the number's home rather than
                    // crowded inside the ring. Tone-matched dot in band
                    // colour echoes the arc so the eye reads it as one
                    // composed unit: ring + label.
                    Row(
                      children: <Widget>[
                        const Flexible(
                          child: Text(
                            'Reviewed schedule',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (score != null) ...<Widget>[
                          const Gap.h(AppSpace.sm),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _bandColor(score.band),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap.h(AppSpace.xs + 1),
                          Text(
                            bandLabel(score.band),
                            style: TextStyle(
                              color: _bandColor(score.band),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap.v(AppSpace.xs),
                    Text(
                      meta.isNotEmpty
                          ? meta
                          : (score?.headline ?? 'Reviewed cross-titration'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tone-tinted verdict for non-OK plans. Left rail in `tone`, eyebrow
/// in `tone`, dark headline, then a status row in `tone` and the body.
class _ToneVerdict extends StatelessWidget {
  const _ToneVerdict({
    required this.tone,
    required this.eyebrow,
    required this.headline,
    required this.status,
    required this.body,
  });

  final Color tone;
  final String eyebrow;
  final String headline;

  /// Short status text shown in `tone` between headline and body —
  /// equivalent to the legacy StatusPill label.
  final String status;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: tone, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md + 2,
        AppSpace.lg + 2,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            eyebrow,
            style: AppTextSizes.eyebrow.copyWith(color: tone),
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            headline,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const Gap.v(AppSpace.xs + 2),
          Text(
            status,
            style: TextStyle(
              color: tone,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const Gap.v(AppSpace.sm + 2),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.mutedStrong,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clozapine redirect — same tone-tinted shape as `_ToneVerdict` but
/// adds the "Open Clozapine module" CTA. Kept distinct so the button
/// styling stays first-class.
class _ClozapineVerdict extends StatelessWidget {
  const _ClozapineVerdict({required this.guidance});

  final String guidance;

  @override
  Widget build(BuildContext context) {
    const tone = AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        border: const Border(left: BorderSide(color: tone, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md + 2,
        AppSpace.lg + 2,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CLOZAPINE INITIATION',
            style: AppTextSizes.eyebrow.copyWith(color: tone),
          ),
          const Gap.v(AppSpace.xs + 2),
          const Text(
            'Use Clozapine module',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const Gap.v(AppSpace.sm + 2),
          Text(
            guidance,
            style: const TextStyle(
              color: AppColors.mutedStrong,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const Gap.v(AppSpace.md + 2),
          FilledButton.icon(
            onPressed: () => context.pushNamed(Routes.clozapine),
            icon: const Icon(Icons.medical_services_outlined, size: 16),
            label: const Text('Open Clozapine module'),
            style: FilledButton.styleFrom(
              backgroundColor: tone,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md + 2,
                vertical: AppSpace.sm + 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive-schedule banner. Always shown for OK plans (fixed-protocol
/// rules excepted — they get [_FixedProtocolNotice] instead). Three
/// modes:
///
///   • **adapted** (default, doses differ) — schedule has been scaled
///     to the user's input doses. Eyebrow flips on toggle.
///   • **reviewed** (toggled, doses differ) — unmodified rule schedule.
///     One tap returns to adapted.
///   • **matched** (doses match reference) — both views render the
///     same schedule. The toggle is still rendered so the feature is
///     discoverable; the eyebrow stays informational ("doses match
///     reviewed reference") and the dose-context line is suppressed.
///
/// Replaces the older static `_ReferenceDosesBanner` that just said
/// "adapt this yourself" — the engine can adapt for you now, and the
/// reviewed view stays one tap away for verification.
class _AdaptiveScheduleBanner extends StatelessWidget {
  const _AdaptiveScheduleBanner({
    required this.view,
    required this.inputDoses,
    required this.rule,
    required this.scaleResult,
    required this.dosesMatchReference,
    required this.onToggle,
  });

  final _ScheduleView view;
  final ({num fromMg, num toMg}) inputDoses;
  final SwitchingRule rule;
  final ScaleResult scaleResult;
  final bool dosesMatchReference;
  final VoidCallback onToggle;

  bool get _isAdapted => view == _ScheduleView.adapted;

  @override
  Widget build(BuildContext context) {
    final tone = dosesMatchReference ? AppColors.to : AppColors.accent;
    final String eyebrow;
    if (dosesMatchReference) {
      eyebrow = 'DOSES MATCH REVIEWED REFERENCE';
    } else {
      eyebrow = _isAdapted
          ? 'SCHEDULE ADAPTED TO YOUR PATIENT'
          : 'SHOWING REVIEWED REFERENCE';
    }
    final ctaLabel = _isAdapted ? 'View reviewed' : 'View adapted';
    final warnings = scaleResult.warnings;
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: tone, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadii.lg),
          bottomRight: Radius.circular(AppRadii.lg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.md,
        AppSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  eyebrow,
                  style: AppTextSizes.eyebrow.copyWith(color: tone),
                ),
              ),
              const Gap.h(AppSpace.sm),
              _AdaptiveToggleButton(label: ctaLabel, onPressed: onToggle),
            ],
          ),
          const Gap.v(AppSpace.sm),
          if (dosesMatchReference)
            // Matched case — no dose-context line needed; the schedule
            // below IS the reviewed reference, exact to the published rule.
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Your input doses match the reviewed reference of ',
                  ),
                  TextSpan(
                    text:
                        '${_formatDose(rule.doseRatios.fromCurrentDoseMg)} mg → ${_formatDose(rule.doseRatios.toTargetDoseMg)} mg',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                    text:
                        '. The schedule below is the published reviewed schedule.',
                  ),
                ],
              ),
            )
          else
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: 'You entered '),
                  TextSpan(
                    text:
                        '${_formatDose(inputDoses.fromMg)} mg → ${_formatDose(inputDoses.toMg)} mg',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '. Reviewed reference is '),
                  TextSpan(
                    text:
                        '${_formatDose(rule.doseRatios.fromCurrentDoseMg)} mg → ${_formatDose(rule.doseRatios.toTargetDoseMg)} mg',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_isAdapted) ...<InlineSpan>[
                    const TextSpan(text: ' — scaled '),
                    TextSpan(
                      text:
                          '${scaleResult.applied.fromFactor.toStringAsFixed(2)}× from / '
                          '${scaleResult.applied.toFactor.toStringAsFixed(2)}× to',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ', rounded to formulation.'),
                  ] else
                    const TextSpan(
                      text:
                          '. Doses below are the unmodified reviewed reference '
                          'for verification.',
                    ),
                ],
              ),
            ),
          if (!dosesMatchReference && _isAdapted && warnings.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.sm + 2),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final w in warnings.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.xxs),
                      child: Text(
                        '• ${w.message}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (warnings.length > 4)
                    Text(
                      '+${warnings.length - 4} more',
                      style: AppTextSizes.eyebrow,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact pill button used inside [_AdaptiveScheduleBanner] to flip
/// between adapted and reviewed views. Hairline border, eyebrow-style
/// label so it sits visually with the banner's headline.
class _AdaptiveToggleButton extends StatelessWidget {
  const _AdaptiveToggleButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            unawaited(hapticsTap());
            onPressed();
          },
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.7),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm + 2,
              vertical: AppSpace.xs + 2,
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Taper-speed selector — segmented control with three options.
///
/// The dose progression in a reviewed rule (100% → 75% → 50% → 25% → 0)
/// is the clinically reviewed component — receptor occupancy and
/// discontinuation risk hinge on the dose ratios. The DAY INTERVALS
/// between those steps are context-dependent:
///
///   • **Faster** (~½ Maudsley duration) — NHS inpatient / Stahl /
///     real-world (Spanish registry avg 16 days). Stable, monitored.
///   • **Standard** (Maudsley 15th) — the reviewed reference. Default.
///   • **Slower** (~1½× Maudsley) — first-episode psychosis, high
///     relapse risk, history of discontinuation symptoms.
///
/// Renders inside a card with a small "Taper speed" eyebrow, the
/// adjusted duration headline ("14-day taper · ~½ Maudsley"), and the
/// 3-segment control. Non-default segments tint to warning amber so
/// the clinician sees they've stepped outside the reviewed schedule.
class _TaperSpeedSelector extends StatelessWidget {
  const _TaperSpeedSelector({
    required this.picked,
    required this.onPick,
    required this.durationDays,
    required this.originalDurationDays,
  });

  final TaperSpeed picked;
  final ValueChanged<TaperSpeed> onPick;
  final int durationDays;
  final int originalDurationDays;

  @override
  Widget build(BuildContext context) {
    final isNonDefault = picked != TaperSpeed.standard;
    final accentTone = isNonDefault ? AppColors.warning : AppColors.muted;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg - 2,
        AppSpace.md + 2,
        AppSpace.lg - 2,
        AppSpace.lg - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'TAPER SPEED',
                style: AppTextSizes.eyebrow,
              ),
              const Spacer(),
              Text(
                isNonDefault
                    ? '$durationDays-day taper · was $originalDurationDays'
                    : '$durationDays-day taper · Maudsley',
                style: TextStyle(
                  color: accentTone,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.sm + 2),
          // Segmented control.
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadii.md + 2),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: <Widget>[
                for (final s in taperSpeeds)
                  Expanded(
                    child: _TaperSpeedSegment(
                      speed: s,
                      isActive: s == picked,
                      onTap: () => onPick(s),
                    ),
                  ),
              ],
            ),
          ),
          if (isNonDefault) ...<Widget>[
            const Gap.v(AppSpace.sm + 2),
            Text(
              speedBasis[picked]!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaperSpeedSegment extends StatelessWidget {
  const _TaperSpeedSegment({
    required this.speed,
    required this.isActive,
    required this.onTap,
  });

  final TaperSpeed speed;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = speed != TaperSpeed.standard;
    final activeTone = accent ? AppColors.warning : AppColors.text;
    const inactiveTone = AppColors.muted;
    return Semantics(
      button: true,
      selected: isActive,
      label: '${speedLabel[speed]} taper — ${speedSublabel[speed]}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: isActive
                  ? Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                      width: 0.5,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  speedLabel[speed]!,
                  style: TextStyle(
                    color: isActive ? activeTone : inactiveTone,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
                const Gap.v(1),
                Text(
                  speedSublabel[speed]!,
                  style: TextStyle(
                    color: isActive
                        ? activeTone.withValues(alpha: 0.85)
                        : inactiveTone.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed-protocol notice — fired when the user's input doses differ
/// from the rule's reference but the scaling mode is `noScale` (LAI,
/// MAOI washouts, fluoxetine bridges where doses are dictated by the
/// product PI / PK rather than by the patient's current dose). No
/// toggle here: the schedule below is always the reviewed values.
class _FixedProtocolNotice extends StatelessWidget {
  const _FixedProtocolNotice({required this.inputDoses});

  final ({num fromMg, num toMg}) inputDoses;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      tone: AppColors.warning,
      eyebrow: 'FIXED PROTOCOL',
      title: 'Schedule not scaled to your input doses',
      body: "This rule's doses are dictated by the product PI or "
          "pharmacokinetics, not the patient's current dose. You entered "
          '${_formatDose(inputDoses.fromMg)} mg → '
          '${_formatDose(inputDoses.toMg)} mg; the schedule below uses '
          'the reviewed values.',
    );
  }
}

/// Day-by-day cross-taper schedule. Stripeless — hairline row dividers
/// only, tabular figures for the dose columns, color-coded from/to so
/// the schedule visually carries the same identity as the hero. No
/// drop-shadow, no fill — the table sits inside [_Card]'s chrome.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final List<ScheduleStep> schedule;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _ScheduleHeaderRow(),
          for (var i = 0; i < schedule.length; i++) ...<Widget>[
            Container(
              height: 0.5,
              color: AppColors.border.withValues(alpha: 0.6),
            ),
            _ScheduleRow(step: schedule[i]),
          ],
        ],
      ),
    );
  }
}

/// Tiny eyebrow row that labels the four schedule columns.
class _ScheduleHeaderRow extends StatelessWidget {
  const _ScheduleHeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = AppTextSizes.eyebrow;
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpace.xs,
        0,
        AppSpace.sm + 2,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(width: 32, child: Text('DAY', style: style)),
          SizedBox(width: 64, child: Text('FROM', style: style)),
          SizedBox(width: 64, child: Text('TO', style: style)),
          Expanded(child: Text('NOTES', style: style)),
        ],
      ),
    );
  }
}

/// Single schedule step. Day in muted-strong, dose figures in tabular
/// from/to tones for instant visual scanning, notes in body grey.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.step});

  final ScheduleStep step;

  /// Tabular figures so digits line up vertically across rows — turns
  /// the schedule into a real table rather than a column of text.
  static const _tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    const dayStyle = TextStyle(
      color: AppColors.mutedStrong,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabularFigures,
      letterSpacing: -0.1,
    );
    final doseStyleFrom = TextStyle(
      color: step.fromDoseMg == 0
          ? AppColors.muted.withValues(alpha: 0.5)
          : AppColors.from,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabularFigures,
      letterSpacing: -0.1,
    );
    final doseStyleTo = TextStyle(
      color: step.toDoseMg == 0
          ? AppColors.muted.withValues(alpha: 0.5)
          : AppColors.to,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabularFigures,
      letterSpacing: -0.1,
    );
    const notesStyle = TextStyle(
      color: AppColors.muted,
      fontSize: 12,
      height: 1.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Text(step.day.toString(), style: dayStyle),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '${_formatDose(step.fromDoseMg)} mg',
              style: doseStyleFrom,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '${_formatDose(step.toDoseMg)} mg',
              style: doseStyleTo,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(step.notes ?? '', style: notesStyle),
            ),
          ),
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
    // Hairline border + slightly larger radius. Same chrome rhythm as
    // the result hero so cards read as a calmer secondary stream.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg - 2,
        AppSpace.md + 2,
        AppSpace.lg - 2,
        AppSpace.lg - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: AppTextSizes.eyebrow,
          ),
          const Gap.v(AppSpace.sm + 2),
          child,
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
