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
import 'package:psychswitch/src/ui/widgets/overlap_intensity_card.dart';
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
import 'package:psychswitch_engine/overlap_intensity.dart';
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

/// "Soften Day 1" — when on, the engine reduces the from-drug's Day 1
/// dose by ~25 % (rounded to formulation, clamped above Day 2 to keep
/// the taper monotonic). Adapted from Maudsley 15th's "halve-and-add"
/// strategy — a softer 25 % reduction (rather than a full 50 %) when
/// the standard overlap looks concerning but a full halve would risk
/// from-drug withdrawal. See `applyConservativeOverlap` in the engine.
///
/// `autoDispose` so leaving /result resets to OFF for the next case.
final _conservativeProvider =
    StateProvider.autoDispose<bool>((_) => false);

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

  /// Build the [SwitchPlanOk] payload for share/export. Three transforms,
  /// applied in clinical order:
  ///   1. Adapted view (doses): swap in the dose-scaled schedule and
  ///      flip `dosesMatchReference` so the formatter doesn't print
  ///      the "but you entered X mg" note.
  ///   2. Soften Day 1 (Conservative mode): reduce Day 1 from-dose by
  ///      ~25 % when the clinician toggled it on.
  ///   3. Taper speed (timing): compress / expand day intervals.
  SwitchPlanOk _payloadFor(
    _ScheduleView view,
    TaperSpeed speed,
    bool conservative,
  ) {
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
    if (conservative) {
      schedule = applyConservativeOverlap(schedule, fromDrug!).schedule;
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
    final conservative = ref.watch(_conservativeProvider);
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
        final payload = _payloadFor(view, effectiveSpeed, conservative);
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
          case 'handout':
            await exportPatientHandoutPdf(
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
            title: Text('Export clinician PDF'),
            subtitle: Text('Print · Save · AirDrop'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'handout',
          child: ListTile(
            leading: Icon(Icons.assignment_ind_outlined),
            title: Text('Patient handout PDF'),
            subtitle: Text('Plain language · large print · sign-off block'),
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
    final conservative = ref.watch(_conservativeProvider);
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

    // Derive the on-screen duration from the SHOWN schedule's last
    // day — the same compressed list that the table renders. Conserv-
    // ative softening doesn't change day numbers (only Day-1 dose),
    // but threading it here keeps `_shownSchedule` the single source
    // of truth for every reader.
    int? adjustedDuration;
    if (plan is SwitchPlanOk) {
      final pl = plan as SwitchPlanOk;
      final shown = _shownSchedule(
        pl,
        scaleResult,
        view,
        effectiveSpeed,
        conservative,
      );
      adjustedDuration = shown.isEmpty ? pl.rule.durationDays : shown.last.day;
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
      conservative,
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

    // Trailing footer — sits below every plan branch (OK, Maudsley
    // guidance, MAOI washout, clozapine redirect, no-rule). Gives the
    // clinician a clean send-off: a primary "Start another switch"
    // CTA + a subtle "Back to home" link. Closes the journey rather
    // than leaving the user to hunt for the back button.
    final footer = EntranceFade(
      index: 6,
      child: _ResultFooter(
        onStartAnother: () {
          unawaited(hapticsTap());
          context.goNamed(Routes.switch_);
        },
        onHome: () {
          unawaited(hapticsTap());
          context.goNamed(Routes.home);
        },
      ),
    );

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
          footer,
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
        footer,
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

  /// The schedule the UI actually shows — applies, in order:
  ///   1. Adapted vs reviewed view (dose values)
  ///   2. Conservative Day-1 softening (Day-1 from-dose × ~0.75)
  ///   3. Taper-speed compression (day intervals)
  ///
  /// Single source of truth so every reader of "the shown schedule"
  /// (table, overlap card, share/PDF, hero-eyebrow duration) sees the
  /// same final list.
  List<ScheduleStep> _shownSchedule(
    SwitchPlanOk ok,
    ScaleResult? scaleResult,
    _ScheduleView view,
    TaperSpeed speed,
    bool conservative,
  ) {
    var schedule = _displaySchedule(ok, scaleResult, view);
    if (conservative) {
      final fromDrug = engine.getDrug(input.fromDrugId);
      if (fromDrug != null) {
        schedule = applyConservativeOverlap(schedule, fromDrug).schedule;
      }
    }
    return compressSchedule(schedule, speed);
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

  /// Overlap-intensity section. Pure passthrough to the engine's
  /// `assessOverlapIntensity` — running it here (rather than inside
  /// the card widget) keeps the schedule input on the same path as
  /// the table itself: adapted/reviewed view + taper speed both
  /// applied, so the assessment reflects what's actually being
  /// prescribed, not the rule's raw schedule. Self-hides when both
  /// drugs aren't in the registry (defensive) or when there are no
  /// overlap days (the card widget handles the latter too).
  List<Widget> _overlapSection(
    SwitchPlanOk ok,
    ScaleResult? scaleResult,
    _ScheduleView view,
    TaperSpeed effectiveSpeed,
    bool conservative,
  ) {
    final fromDrug = engine.getDrug(input.fromDrugId);
    final toDrug = engine.getDrug(input.toDrugId);
    if (fromDrug == null || toDrug == null) return const <Widget>[];
    final shown = _shownSchedule(
      ok,
      scaleResult,
      view,
      effectiveSpeed,
      conservative,
    );
    final assessment = assessOverlapIntensity(
      fromDrug: fromDrug,
      toDrug: toDrug,
      schedule: shown,
    );
    if (assessment.label == 'No overlap' && assessment.score == 0) {
      return const <Widget>[];
    }
    return <Widget>[
      OverlapIntensityCard(assessment: assessment),
      const Gap.v(AppSpace.lg),
    ];
  }

  /// Soften-Day-1 (Conservative mode) section. Self-hides when:
  ///   • The from-drug isn't in the registry (defensive).
  ///   • The plan strategy doesn't include overlap (direct switch,
  ///     washout — there's no Day 1 from-dose to soften).
  ///   • The 25 % reduction would round to the same dose as Day 1
  ///     already is (low-dose schedules where formulation rounding
  ///     swallows the difference).
  ///
  /// When off but applicable: shows the offer card (toggle + reasoning).
  /// When on: shows the confirmation card (delta + reasoning).
  List<Widget> _softenDay1Section(
    SwitchPlanOk ok,
    ScaleResult? scaleResult,
    _ScheduleView view,
    bool conservative,
    WidgetRef ref,
  ) {
    final fromDrug = engine.getDrug(input.fromDrugId);
    if (fromDrug == null) return const <Widget>[];
    // Self-hide entirely if there's no overlap to soften — direct
    // switches and washouts won't even show the option.
    if (ok.schedule.length < 2 || ok.schedule.first.fromDoseMg <= 0) {
      return const <Widget>[];
    }
    // Preview what conservative WOULD do against the current (pre-
    // compression) schedule. We render the card EITHER way:
    //   • modified=true  → applicable, toggle live
    //   • modified=false → not applicable (plateau / rounding), toggle
    //                      disabled with an inline explanation so the
    //                      feature stays discoverable even when the
    //                      engine refuses to soften this particular
    //                      schedule.
    final base = _displaySchedule(ok, scaleResult, view);
    final preview = applyConservativeOverlap(base, fromDrug);
    final day1Original = base.isEmpty ? 0 : base.first.fromDoseMg;
    final day2 = base.length >= 2 ? base[1].fromDoseMg : day1Original;
    final day1Softened = preview.modified
        ? day1Original - preview.deltaMg
        : day1Original;
    // Plateau end-day: walk forward through the schedule and find the
    // last step whose from-dose still equals Day-1's. That step's
    // `.day` is when the plateau ends and the taper begins. For non-
    // plateau schedules the value equals Day 1.
    var plateauEndDay = base.isNotEmpty ? base.first.day : 1;
    for (var i = 1; i < base.length; i++) {
      if (base[i].fromDoseMg == day1Original) {
        plateauEndDay = base[i].day;
      } else {
        break;
      }
    }
    final isPlateau = plateauEndDay > (base.isNotEmpty ? base.first.day : 1);
    // Reason for refusal — only one path now reaches the not-modified
    // state with valid input: formulation rounding swallowed the 25 %
    // delta (low-dose schedules where the available tablet strengths
    // can't represent the softer dose). Plateau-only schedules are no
    // longer refused — the engine softens the whole plateau.
    final notApplicableReason = preview.modified ? null : 'rounding';
    return <Widget>[
      _SoftenDay1Card(
        on: conservative,
        applicable: preview.modified,
        notApplicableReason: notApplicableReason,
        fromDrugName: fromDrug.genericName,
        day1Original: day1Original,
        day1Softened: day1Softened,
        day2Dose: day2,
        deltaMg: preview.deltaMg,
        plateauEndDay: plateauEndDay,
        isPlateau: isPlateau,
        onToggle: (v) {
          unawaited(hapticsTap());
          ref.read(_conservativeProvider.notifier).state = v;
        },
      ),
      const Gap.v(AppSpace.lg),
    ];
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
    bool conservative,
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
                final shown = _shownSchedule(
                  ok,
                  scaleResult,
                  view,
                  effectiveSpeed,
                  conservative,
                );
                final adjustedDays = shown.isEmpty
                    ? ok.rule.durationDays
                    : shown.last.day;
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
          // Soften-Day-1 toggle (Conservative mode) — adapted from
          // Maudsley 15th's "halve-and-add" strategy. Reduces Day 1
          // from-drug dose by ~25 %, rounded to formulation, clamped
          // above Day 2 to keep the taper monotonic. Shows the
          // actual delta when on, plus clinical reasoning either way.
          ..._softenDay1Section(ok, scaleResult, view, conservative, ref),
          // Day-by-day cross-taper schedule. Reflects every modifier
          // above it: adapted/reviewed view, taper speed, and (when
          // on) Day-1 softening. The CrossoverChart that used to sit
          // above this is intentionally removed — the schedule table
          // is the primary source of truth; a parallel curve added
          // visual weight without adding signal.
          _ScheduleCard(
            schedule: _shownSchedule(
              ok,
              scaleResult,
              view,
              effectiveSpeed,
              conservative,
            ),
            day1Softened: conservative,
          ),
          const Gap.v(AppSpace.lg),
          // Overlap-intensity assessment — quantifies the clinical
          // concern about co-prescribing the two drugs during the
          // overlap window. Engine derives tier + score from Day-1
          // dose intensity, overlap duration, and mechanism stacking
          // (serotonergic, QTc, sedation, EPS, anticholinergic). The
          // card surfaces engine rationale + per-flag clinical
          // reasoning (what to monitor, when, why). Self-hides when
          // the schedule has no overlap days (direct switch path).
          ..._overlapSection(
            ok,
            scaleResult,
            view,
            effectiveSpeed,
            conservative,
          ),
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

/// Soften-Day-1 card (Conservative mode).
///
/// Adapted from Maudsley 15th's "halve-and-add" antipsychotic-switch
/// strategy. The full halve-and-add halves the from-drug dose on the
/// day the new drug is introduced; this card applies a softer ~25 %
/// reduction by default, which is appropriate when:
///   • The standard overlap intensity looks concerning but a full
///     halve would risk from-drug withdrawal.
///   • The patient is elderly, pharmacokinetically vulnerable, or
///     has a history of intolerance to the receptor profile.
///   • The clinician wants to step into the cross-taper rather than
///     start at the full from-dose.
///
/// Three states:
///   • OFF + applicable    — offer card (toggle + reasoning)
///   • ON                  — confirmation card (delta + reasoning)
///   • Not applicable      — section self-hides upstream in
///                            `_softenDay1Section` (no Day-1 from-dose,
///                            or 25 % rounds to the same dose).
class _SoftenDay1Card extends StatelessWidget {
  const _SoftenDay1Card({
    required this.on,
    required this.applicable,
    required this.notApplicableReason,
    required this.fromDrugName,
    required this.day1Original,
    required this.day1Softened,
    required this.day2Dose,
    required this.deltaMg,
    required this.plateauEndDay,
    required this.isPlateau,
    required this.onToggle,
  });

  final bool on;
  final bool applicable;

  /// Only 'rounding' today — set when formulation rounding swallows
  /// the 25 % delta at low Day-1 doses. Null when [applicable] is true.
  final String? notApplicableReason;

  final String fromDrugName;
  final num day1Original;
  final num day1Softened;
  final num day2Dose;
  final num deltaMg;

  /// Last day of the Day-1 plateau (where the from-drug is held flat).
  /// Equals Day 1 for schedules without a plateau.
  final int plateauEndDay;

  /// True when the rule holds the from-drug across more than one step
  /// (typical of antipsychotic introduce-then-taper protocols).
  final bool isPlateau;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final activeOn = on && applicable;
    final tone = !applicable
        ? AppColors.muted
        : (on ? AppColors.accent : AppColors.mutedStrong);
    final pct = day1Original > 0
        ? ((deltaMg / day1Original) * 100).round()
        : 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: applicable ? () => onToggle(!on) : null,
        borderRadius: BorderRadius.circular(AppRadii.lg + 2),
        child: Container(
          decoration: BoxDecoration(
            color: activeOn
                ? AppColors.accent.withValues(alpha: 0.06)
                : AppColors.surface,
            border: Border.all(
              color: activeOn
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.border.withValues(alpha: 0.7),
              width: activeOn ? 1 : 0.5,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Eyebrow + icon + switch / unavailable badge ─────
              Row(
                children: <Widget>[
                  Icon(
                    activeOn ? Icons.spa_rounded : Icons.spa_outlined,
                    size: 18,
                    color: tone,
                  ),
                  const Gap.h(AppSpace.sm),
                  Expanded(
                    child: Text(
                      !applicable
                          ? 'SOFTEN DAY 1 — NOT APPLICABLE'
                          : (on
                              ? 'DAY 1 SOFTENED'
                              : 'SOFTEN DAY 1 OVERLAP'),
                      style: AppTextSizes.eyebrow.copyWith(color: tone),
                    ),
                  ),
                  const Gap.h(AppSpace.sm),
                  if (applicable)
                    IgnorePointer(
                      child: Transform.scale(
                        scale: 0.85,
                        child: Switch.adaptive(
                          value: on,
                          onChanged: onToggle,
                          activeThumbColor: AppColors.accent,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        'UNAVAILABLE',
                        style: AppTextSizes.eyebrow.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap.v(AppSpace.sm + 2),
          // ── State-dependent body ────────────────────────────────
          if (!applicable)
            _NotApplicableBody(
              reason: notApplicableReason ?? 'plateau',
              fromDrugName: fromDrugName,
              day1: day1Original,
              day2: day2Dose,
            )
          else if (on)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.45,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: isPlateau
                        ? 'Plateau softened: '
                        : 'Day 1 softened: ',
                  ),
                  TextSpan(
                    text: fromDrugName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: isPlateau
                        ? ' Day 1 → Day $plateauEndDay '
                        : ' Day 1 ',
                  ),
                  TextSpan(
                    text:
                        '${_formatDose(day1Original)} mg → ${_formatDose(day1Softened)} mg',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' (−$pct %).'),
                ],
              ),
            )
          else
            Text(
              isPlateau
                  ? 'Reduce $fromDrugName across its Day 1 → Day '
                      "$plateauEndDay plateau by ~25 % — Maudsley 15th's "
                      'halve-and-add approach, adapted for a softer '
                      'reduction. Lowers the receptor load on the '
                      'highest-risk overlap days while the new drug '
                      'reaches target.'
                  : "Reduce $fromDrugName's Day 1 dose by ~25 % to lower "
                      'the simultaneous receptor occupancy during the '
                      'highest-risk day of the cross-taper.',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          const Gap.v(AppSpace.lg - 2),
          Container(
            height: 0.5,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          const Gap.v(AppSpace.md + 2),
          // ── Clinical reasoning ──────────────────────────────────
          Text(
            'CLINICAL REASONING',
            style: AppTextSizes.eyebrow.copyWith(color: tone),
          ),
          const Gap.v(AppSpace.sm + 2),
          const _SoftenReasoningRow(
            tone: AppColors.accent,
            heading: 'Maudsley 15th halve-and-add, softer',
            body:
                'Adapted from the Maudsley 15th edition halve-and-add '
                'antipsychotic-switch strategy — a softer 25 % reduction '
                '(rather than a full 50 % halve) when the standard '
                'overlap is concerning but a full halve would risk '
                'from-drug withdrawal.',
          ),
          const Gap.v(AppSpace.md + 2),
          const _SoftenReasoningRow(
            tone: AppColors.accent,
            heading: 'Lower simultaneous occupancy, lower stacking',
            body:
                'Cutting the from-drug on Day 1 directly reduces the '
                'simultaneous receptor load — fewer milligrams of either '
                'drug coexist on the highest-risk day. Lowers serotonergic, '
                'QTc-additive, sedation-additive and EPS-additive risk '
                'where the mechanisms stack.',
          ),
          const Gap.v(AppSpace.md + 2),
          const _SoftenReasoningRow(
            tone: AppColors.accent,
            heading: 'Consider when',
            body:
                'Overlap intensity is moderate-to-severe · patient is '
                'elderly or pharmacokinetically vulnerable · history of '
                'intolerance to the receptor profile · baseline cardiac '
                '(QTc), cognitive (anticholinergic) or sedation concern.',
          ),
              const Gap.v(AppSpace.md + 2),
              const _SoftenReasoningRow(
                tone: AppColors.warning,
                heading: 'Trade-off',
                body:
                    'Slightly higher chance of from-drug discontinuation '
                    'symptoms on Day 1. Reassess at Day 3 — step the '
                    'from-dose back up if withdrawal emerges.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body shown when the engine refuses to soften — explains WHY without
/// teasing a button that won't work. Two reasons today:
///   • `plateau` — Day 1 from-dose equals Day 2's, so reducing Day 1
///     would invert the taper. Common in rules that intentionally
///     hold the from-drug steady while the new drug stabilises at
///     target.
///   • `rounding` — the 25 % reduction rounds back to the same dose
///     after formulation rounding (low-dose pairs).
class _NotApplicableBody extends StatelessWidget {
  const _NotApplicableBody({
    required this.reason,
    required this.fromDrugName,
    required this.day1,
    required this.day2,
  });

  final String reason;
  final String fromDrugName;
  final num day1;
  final num day2;

  @override
  Widget build(BuildContext context) {
    final body = switch (reason) {
      'plateau' =>
        'This schedule holds $fromDrugName at ${_formatDose(day1)} mg through '
            'Day 2 to let the new drug reach target first. Reducing Day 1 '
            'below the plateau (${_formatDose(day2)} mg) would invert the '
            "taper — Day 1 lower than Day 2 — which isn't clinically "
            'meaningful. If the overlap looks too aggressive here, consider '
            'a Faster taper speed or a different from-drug starting dose.',
      'rounding' =>
        'A 25 % reduction of ${_formatDose(day1)} mg rounds back to '
            '${_formatDose(day1)} mg after formulation rounding (the '
            "available tablet strengths can't represent the softer dose). "
            'No useful softening is possible at this Day-1 dose.',
      _ => 'Softening is not applicable for this schedule.',
    };
    return Text(
      body,
      style: const TextStyle(
        color: AppColors.mutedStrong,
        fontSize: 13,
        height: 1.55,
      ),
    );
  }
}

class _SoftenReasoningRow extends StatelessWidget {
  const _SoftenReasoningRow({
    required this.tone,
    required this.heading,
    required this.body,
  });

  final Color tone;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        const Gap.h(AppSpace.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                heading,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  height: 1.3,
                ),
              ),
              const Gap.v(AppSpace.xs),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.mutedStrong,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
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

/// True for every step at or before the end of the Day-1 from-dose
/// plateau — i.e. while the from-dose is equal to (or higher than)
/// Day 1's. Used to mark every plateau step with the SOFTENED pill
/// when Conservative mode is on, mirroring the engine's plateau-aware
/// softening.
bool _isInDay1Plateau(List<ScheduleStep> schedule, int i) {
  if (schedule.isEmpty || i >= schedule.length) return false;
  final day1Dose = schedule.first.fromDoseMg;
  return schedule[i].fromDoseMg >= day1Dose;
}

/// Day-by-day cross-taper schedule.
///
/// Each step is its own little narrative — a big "DAY N" anchor, two
/// dose rows (FROM in blue, TO in green) each with a normalised
/// progress bar so the eye reads the cross-titration as a shape: the
/// from-bar shrinks step by step while the to-bar grows. The crossover
/// chart that used to sit above the table is gone; this is the chart,
/// embedded in the data rather than parallel to it.
///
/// Bars are normalised to the max dose either drug reaches across the
/// schedule (not pharmacological max) — so the highest dose is always
/// 100 % bar, and the rest land proportionally. That gives the visual
/// rhythm without needing an external scale.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    this.day1Softened = false,
  });

  final List<ScheduleStep> schedule;

  /// When true, the Day-1 block renders a small "SOFTENED" pill next
  /// to the day anchor so the user sees the Soften-Day-1 modification
  /// reflected in the schedule itself, not only in the toggle card.
  final bool day1Softened;

  @override
  Widget build(BuildContext context) {
    num fromMax = 0;
    num toMax = 0;
    for (final s in schedule) {
      if (s.fromDoseMg > fromMax) fromMax = s.fromDoseMg;
      if (s.toDoseMg > toMax) toMax = s.toDoseMg;
    }
    return _Card(
      title: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < schedule.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                color: AppColors.border.withValues(alpha: 0.5),
                margin: const EdgeInsets.symmetric(vertical: AppSpace.sm + 2),
              ),
            _ScheduleStepBlock(
              step: schedule[i],
              fromMax: fromMax,
              toMax: toMax,
              isFinal: i == schedule.length - 1,
              isSoftened: day1Softened &&
                  _isInDay1Plateau(schedule, i),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single step in the cross-taper. Day label up top, two dose rows
/// with normalised progress bars, optional clinical notes underneath.
class _ScheduleStepBlock extends StatelessWidget {
  const _ScheduleStepBlock({
    required this.step,
    required this.fromMax,
    required this.toMax,
    required this.isFinal,
    this.isSoftened = false,
  });

  final ScheduleStep step;
  final num fromMax;
  final num toMax;
  final bool isFinal;

  /// True only on the Day-1 block when Conservative mode is on —
  /// surfaces the softening as a tone-tinted pill on the day anchor.
  final bool isSoftened;

  @override
  Widget build(BuildContext context) {
    final notes = step.notes ?? '';
    final showCompleteTag = isFinal && step.fromDoseMg == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'DAY ${step.day}',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.1,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            if (isSoftened) ...<Widget>[
              const Gap.h(AppSpace.sm + 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.spa_rounded,
                      size: 11,
                      color: AppColors.accent,
                    ),
                    const Gap.h(AppSpace.xs),
                    Text(
                      'SOFTENED',
                      style: AppTextSizes.eyebrow.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (showCompleteTag)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.to.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'SWITCH COMPLETE',
                  style: AppTextSizes.eyebrow.copyWith(
                    color: AppColors.to,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
          ],
        ),
        const Gap.v(AppSpace.md),
        _ScheduleDoseRow(
          label: 'FROM',
          dose: step.fromDoseMg,
          max: fromMax,
          tone: AppColors.from,
        ),
        const Gap.v(AppSpace.sm + 2),
        _ScheduleDoseRow(
          label: 'TO',
          dose: step.toDoseMg,
          max: toMax,
          tone: AppColors.to,
        ),
        if (notes.isNotEmpty) ...<Widget>[
          const Gap.v(AppSpace.md - 2),
          Text(
            notes,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

/// One drug's dose at a step — dot + label + figure on top, progress
/// bar below. The bar's fill width = dose / max (normalised across
/// the schedule) so the visual shows where this step sits on the
/// drug's own taper curve.
class _ScheduleDoseRow extends StatelessWidget {
  const _ScheduleDoseRow({
    required this.label,
    required this.dose,
    required this.max,
    required this.tone,
  });

  final String label;
  final num dose;
  final num max;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final isZero = dose == 0;
    final fraction = max > 0
        ? (dose / max).clamp(0, 1).toDouble()
        : 0.0;
    final effectiveTone =
        isZero ? AppColors.muted.withValues(alpha: 0.5) : tone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: effectiveTone,
                shape: BoxShape.circle,
              ),
            ),
            const Gap.h(AppSpace.sm),
            Text(
              label,
              style: AppTextSizes.eyebrow.copyWith(color: effectiveTone),
            ),
            const Spacer(),
            Text(
              '${_formatDose(dose)} mg',
              style: TextStyle(
                color: isZero
                    ? AppColors.muted.withValues(alpha: 0.5)
                    : AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.1,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.xs + 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: <Widget>[
              Container(
                height: 4,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              AnimatedFractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: effectiveTone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

/// Citations list. Each citation key is a tappable row that opens a
/// bottom-sheet with a plain-English breakdown of the source: which
/// publication, which chapter / page, what it says, and how PsychSwitch
/// uses it. Builds trust by making the evidence chain inspectable
/// without leaving the result screen.
class _CitationsCard extends StatelessWidget {
  const _CitationsCard({required this.citations});

  final List<String> citations;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Citations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < citations.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            _CitationRow(key_: citations[i]),
          ],
        ],
      ),
    );
  }
}

/// Tappable citation row — surfaces a friendly source name + a small
/// chevron, opens a bottom-sheet on tap with the plain-English summary
/// from `_citationSummary(...)`.
class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.key_});

  final String key_;

  @override
  Widget build(BuildContext context) {
    final info = _citationSummary(key_);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(hapticsTap());
          _showCitationSheet(context, key_, info);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs + 2,
            vertical: AppSpace.xs + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 7, right: AppSpace.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      info.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (info.locator.isNotEmpty) ...<Widget>[
                      const Gap.v(1),
                      Text(
                        info.locator,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap.h(AppSpace.sm),
              const Icon(
                Icons.expand_more_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCitationSheet(
  BuildContext context,
  String key_,
  _CitationInfo info,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        AppSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CITATION',
            style: AppTextSizes.eyebrow.copyWith(color: AppColors.accent),
          ),
          const Gap.v(AppSpace.sm),
          Text(
            info.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          if (info.locator.isNotEmpty) ...<Widget>[
            const Gap.v(AppSpace.xs + 1),
            Text(
              info.locator,
              style: const TextStyle(
                color: AppColors.mutedStrong,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Gap.v(AppSpace.lg),
          Container(
            height: 0.5,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
          const Gap.v(AppSpace.lg),
          Text(
            'WHAT IT SAYS',
            style: AppTextSizes.eyebrow.copyWith(color: AppColors.mutedStrong),
          ),
          const Gap.v(AppSpace.sm),
          Text(
            info.summary,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const Gap.v(AppSpace.lg),
          Text(
            'HOW PSYCHSWITCH USES IT',
            style: AppTextSizes.eyebrow.copyWith(color: AppColors.mutedStrong),
          ),
          const Gap.v(AppSpace.sm),
          Text(
            info.usage,
            style: const TextStyle(
              color: AppColors.mutedStrong,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const Gap.v(AppSpace.lg),
          // Citation key footer — kept visible so the clinician can
          // grep the source bundle / changelog if they need to.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm + 2,
              vertical: AppSpace.xs + 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              key_,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Plain-English summary returned from a citation key. Used by the
/// bottom-sheet to surface what the source actually says + how
/// PsychSwitch consumes it. New keys fall through to a defensive
/// "PsychSwitch content library" entry so the sheet never breaks.
class _CitationInfo {
  const _CitationInfo({
    required this.title,
    required this.locator,
    required this.summary,
    required this.usage,
  });

  final String title;
  final String locator;
  final String summary;
  final String usage;
}

_CitationInfo _citationSummary(String key) {
  // Coarse pattern-matching — the keys carry the publisher + locator
  // by convention (e.g. `maudsley15_ch3_p369_table_3_7`), and we
  // surface a per-publication template plus the locator when present.
  final lower = key.toLowerCase();
  String locator() {
    final match = RegExp(r'p(\d+)').firstMatch(lower);
    final page = match != null ? 'page ${match.group(1)}' : '';
    final chMatch = RegExp(r'ch(\d+)').firstMatch(lower);
    final chapter = chMatch != null ? 'ch. ${chMatch.group(1)}' : '';
    return <String>[chapter, page].where((s) => s.isNotEmpty).join(' · ');
  }

  if (lower.startsWith('maudsley15')) {
    return _CitationInfo(
      title: 'Maudsley Prescribing Guidelines, 15th edition',
      locator: locator(),
      summary:
          'The Maudsley 15th (Taylor, Barnes & Young, 2021) is the '
          'current default reference for UK psychotropic prescribing — '
          'and the primary source PsychSwitch builds against. Each '
          'switching rule traces back to a specific table, box, or '
          'paragraph in the chapter cited here.',
      usage:
          'PsychSwitch lifts the dose progression, duration and any '
          'explicit safety-flag wording directly from this source. '
          'Where the Maudsley text gives a range, PsychSwitch picks '
          'the midpoint and shows the original range in the rationale.',
    );
  }
  if (lower.startsWith('maudsley14')) {
    return _CitationInfo(
      title: 'Maudsley Prescribing Guidelines, 14th edition',
      locator: locator(),
      summary:
          'The previous (2018) edition of the Maudsley guidelines. '
          'Some services and trial protocols still reference this '
          "edition's faster clozapine titration and uniform 450 mg "
          'antipsychotic target.',
      usage:
          "Used by the clozapine titration tab's 'Maudsley 14' regimen "
          'option so clinicians can compare against — or follow — the '
          'historical schedule when a site still uses it.',
    );
  }
  if (lower.startsWith('bap2020') || lower.startsWith('bap2015')) {
    return _CitationInfo(
      title: 'BAP consensus guidelines',
      locator: locator(),
      summary:
          'British Association for Psychopharmacology consensus '
          'statements. These set the UK academic standard for '
          'evidence-based prescribing in mood, anxiety, psychotic and '
          'substance-use disorders.',
      usage:
          'PsychSwitch pulls switching-strategy direction (cross-taper '
          'vs taper-then-wait vs direct) from the BAP statements where '
          'the Maudsley table is silent, and surfaces the BAP wording '
          'in the rationale paragraph.',
    );
  }
  if (lower.startsWith('nice')) {
    return _CitationInfo(
      title: 'NICE clinical guideline',
      locator: locator(),
      summary:
          'National Institute for Health and Care Excellence '
          'guidelines. Sets the NHS standard for clinical decisions '
          'and is the legal reference point for England + Wales.',
      usage:
          'PsychSwitch uses NICE for clozapine community-initiation '
          'criteria, monitoring frequency baselines, and the '
          'discontinuation-syndrome severity flags.',
    );
  }
  if (lower.startsWith('cpms')) {
    return _CitationInfo(
      title: 'Clozapine Patient Monitoring Service (CPMS)',
      locator: locator(),
      summary:
          'The UK monitoring service that holds the clozapine FBC '
          'thresholds (ANC/WBC green/amber/red), the BEN-adjusted '
          'thresholds, and the rechallenge tier rules.',
      usage:
          'Drives the FBC zone classifier on the ANC-check tab and '
          'the rechallenge tier matching on the Rechallenge tab.',
    );
  }
  if (lower.startsWith('trec')) {
    return _CitationInfo(
      title: 'TREC community clozapine protocol',
      locator: locator(),
      summary:
          'A peer-reviewed outpatient clozapine initiation pathway. '
          'Originally developed for South-London community teams; the '
          'thrice-weekly clinic-visit cadence is its defining feature.',
      usage:
          'Source for the Community regimen in the clozapine titration '
          'tab — the 28-day curve with Mon/Wed/Fri dose escalations.',
    );
  }
  if (lower.startsWith('spina') || lower.startsWith('kennedy')) {
    return _CitationInfo(
      title: 'CYP1A2 / clozapine plasma-level pharmacology',
      locator: locator(),
      summary:
          'Peer-reviewed pharmacokinetic studies on CYP1A2 induction '
          'by smoking and its impact on clozapine plasma levels — the '
          'evidence behind sex × smoker-specific maintenance targets.',
      usage:
          'Justifies the four Maudsley-15 titration variants (225 mg '
          'female non-smoker → 375 mg male smoker) and the equivalent '
          'Maudsley-14 personalisation in the same tab.',
    );
  }
  if (lower.startsWith('fda')) {
    return _CitationInfo(
      title: 'FDA labelling',
      locator: locator(),
      summary:
          'United States Food and Drug Administration product '
          'labelling. Authoritative for boxed warnings, dose ceilings, '
          'and depot LAI initiation protocols.',
      usage:
          "Drives the Depot LAI module's initiation tables (Sustenna "
          'Day 1 + Day 8 + monthly, Maintena 14-day overlap vs 1-day '
          'load) and missed-dose flows.',
    );
  }
  return const _CitationInfo(
    title: 'PsychSwitch content library',
    locator: '',
    summary:
        "A reviewed entry in PsychSwitch's clinical-content bundle. "
        "See the rule provenance card for the reviewer's name and "
        'last-reviewed date.',
    usage:
        'Surfaces under the rationale paragraph when the engine picks '
        'this rule. Tap the rule provenance card for the audit trail.',
  );
}

/// Closes the result with a clean send-off. Sits below every plan
/// branch — OK, guidance, washout, clozapine redirect, no-rule. The
/// primary CTA navigates to a fresh switch screen (go_router `.go`
/// replaces the stack so the form starts blank for the next case);
/// the subtle text link below returns to home.
///
/// Composition: hairline · "PLAN COMPLETE" eyebrow · primary CTA ·
/// home link. Tiny ceremony, lots of finality.
class _ResultFooter extends StatelessWidget {
  const _ResultFooter({
    required this.onStartAnother,
    required this.onHome,
  });

  final VoidCallback onStartAnother;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpace.xl,
        bottom: AppSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Centred hairline rule ────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 1,
              color: AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          const Gap.v(AppSpace.lg),
          Center(
            child: Text(
              'PLAN COMPLETE',
              style: AppTextSizes.eyebrow.copyWith(
                color: AppColors.mutedStrong,
                letterSpacing: 2,
              ),
            ),
          ),
          const Gap.v(AppSpace.md + 2),
          Center(
            child: Text(
              'Save it, share it, or queue the next case.',
              style: AppTextSizes.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap.v(AppSpace.xl - 2),
          // ── Primary CTA ──────────────────────────────────────────
          _StartAnotherButton(onPressed: onStartAnother),
          const Gap.v(AppSpace.md),
          // ── Subtle home link ─────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: onHome,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Back to home',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary "start another switch" button — accent-blue glow when
/// enabled, full-width, leading restart-alt icon. Mirrors the visual
/// weight of the SwitchScreen's "Generate plan" button so the journey
/// loop reads as one continuous gesture.
class _StartAnotherButton extends StatelessWidget {
  const _StartAnotherButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.restart_alt_rounded, size: 19),
            Gap.h(AppSpace.sm + 2),
            Text(
              'Start another switch',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
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
