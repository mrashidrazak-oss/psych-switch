// History screen.
//
// Lists every saved case (savedCasesProvider stream), newest-first by
// updatedISO. Cards now carry status pills ("Day 5 of 14" /
// "Complete · 3 days ago") computed by re-running the engine on each
// row. Tap a row to re-open it on /result. Tap the delete glyph for
// a confirm dialog.
//
// Empty state is a friendly invite, not a cul-de-sac.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/services/notification_service.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/breakpoints.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/switching_engine.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    final asyncCases = ref.watch(savedCasesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) => asyncCases.when(
            loading: () => const EngineLoadingView(),
            error: (e, st) => EngineErrorView(error: e),
            data: (cases) => cases.isEmpty
                ? const _EmptyState()
                : _CaseList(cases: cases, engine: engine),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ── Illustrative mark — bookmark glyph cradled in the
            //     brand's two-tone gradient ring, dual-tone glow.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.from.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: -10,
                    offset: const Offset(-6, 8),
                  ),
                  BoxShadow(
                    color: AppColors.to.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: -10,
                    offset: const Offset(6, 8),
                  ),
                ],
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.from,
                      AppColors.to,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const Gap.v(AppSpace.xl),
            const Text(
              'No saved cases yet',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const Gap.v(AppSpace.sm + 2),
            Text(
              "Save a case from the result screen — it'll appear here "
              'with a day counter so you can pick the patient back up '
              'at the next visit.',
              style: AppTextSizes.caption.copyWith(height: 1.55),
              textAlign: TextAlign.center,
            ),
            const Gap.v(AppSpace.xl),
            FilledButton.icon(
              onPressed: () {
                unawaited(hapticsTap());
                context.pushNamed(Routes.switch_);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Start a switch'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.md + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────

class _CaseList extends ConsumerWidget {
  const _CaseList({required this.cases, required this.engine});

  final List<SavedCase> cases;
  final SwitchingEngine engine;

  String _drugName(String id) => engine.getDrug(id)?.genericName ?? id;

  /// Compute day-by-day status for a saved case by re-running the
  /// engine and comparing the schedule's total days to time elapsed
  /// since `startedISO`. Returns null when the plan isn't a clean
  /// `SwitchPlanOk` (washout / no-rule etc. — those carry no schedule).
  ({String label, Color tone})? _statusFor(SavedCase c) {
    final plan = engine.generateSwitchPlan(
      SwitchInput(
        fromDrugId: c.fromDrugId,
        fromDoseMg: c.fromDoseMg,
        toDrugId: c.toDrugId,
        toDoseMg: c.toDoseMg,
      ),
    );
    if (plan is! SwitchPlanOk) return null;
    final start = DateTime.tryParse(c.startedISO);
    if (start == null) return null;
    final now = DateTime.now();
    final elapsed = now.difference(start.toLocal()).inDays + 1;
    final total = plan.rule.durationDays;
    if (elapsed <= 0) return (label: 'Starts today', tone: AppColors.accent);
    if (elapsed < total) {
      return (label: 'Day $elapsed of $total', tone: AppColors.accent);
    }
    if (elapsed == total) {
      return (label: 'Day $total · final', tone: AppColors.to);
    }
    final overshoot = elapsed - total;
    return (
      label: overshoot == 1
          ? 'Complete · yesterday'
          : 'Complete · $overshoot days ago',
      tone: AppColors.mutedStrong,
    );
  }

  Future<void> _onDeletePressed(
    BuildContext context,
    WidgetRef ref,
    SavedCase c,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete case?',
          style: TextStyle(color: AppColors.text),
        ),
        content: Text(
          'Removes "${c.label}". This cannot be undone.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(savedCaseRepositoryProvider).delete(c.id);
    // Cancel any pending monitoring reminders for the deleted case.
    await NotificationService.instance.cancelForCase(c.id);
  }

  Widget _buildTile(BuildContext context, WidgetRef ref, int i) {
    final c = cases[i];
    return EntranceFade(
      index: i.clamp(0, 5),
      child: _CaseCard(
        caseRow: c,
        fromName: _drugName(c.fromDrugId),
        toName: _drugName(c.toDrugId),
        status: _statusFor(c),
        onTap: () {
          unawaited(hapticsTap());
          context.pushNamed(
            Routes.result,
            extra: ResultScreenArgs(
              input: SwitchInput(
                fromDrugId: c.fromDrugId,
                fromDoseMg: c.fromDoseMg,
                toDrugId: c.toDrugId,
                toDoseMg: c.toDoseMg,
              ),
            ),
          );
        },
        onDelete: () => _onDeletePressed(context, ref, c),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md - 2,
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'SAVED CASES',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const Spacer(),
          Text(
            '${cases.length} ${cases.length == 1 ? 'case' : 'cases'}',
            style: const TextStyle(
              color: AppColors.mutedStrong,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (context.isWide) {
      return CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: header),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.xl,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 460,
                crossAxisSpacing: AppSpace.md,
                mainAxisSpacing: AppSpace.md,
                childAspectRatio: 3.4,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildTile(context, ref, i),
                childCount: cases.length,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.xl,
      ),
      itemCount: cases.length + 1,
      separatorBuilder: (_, __) => const Gap.v(AppSpace.sm + 2),
      itemBuilder: (_, i) {
        if (i == 0) return header;
        return _buildTile(context, ref, i - 1);
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────

/// A single saved-case card. Two-row layout:
///   • Row 1: from-blue dot + from drug + arrow + to-green dot + to drug
///     (with doses inline); status pill on the right.
///   • Row 2: label (or fallback descriptor) + relative-date stamp
///     + delete affordance.
///
/// Tap anywhere on the card to re-open the result.
class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.caseRow,
    required this.fromName,
    required this.toName,
    required this.status,
    required this.onTap,
    required this.onDelete,
  });

  final SavedCase caseRow;
  final String fromName;
  final String toName;
  final ({String label, Color tone})? status;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg + 2),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg - 2,
            AppSpace.md + 2,
            AppSpace.sm,
            AppSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Row 1: drug pair + status pill ──────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          height: 1.3,
                        ),
                        children: <InlineSpan>[
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _Dot(color: AppColors.from),
                          ),
                          const WidgetSpan(child: SizedBox(width: 5)),
                          TextSpan(text: fromName),
                          TextSpan(
                            text: '  ${_formatDose(caseRow.fromDoseMg)} mg',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(
                            text: '   →   ',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _Dot(color: AppColors.to),
                          ),
                          const WidgetSpan(child: SizedBox(width: 5)),
                          TextSpan(text: toName),
                          TextSpan(
                            text: '  ${_formatDose(caseRow.toDoseMg)} mg',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (status != null) ...<Widget>[
                    const Gap.h(AppSpace.sm),
                    _StatusPill(
                      label: status!.label,
                      tone: status!.tone,
                    ),
                  ],
                ],
              ),
              const Gap.v(AppSpace.sm + 2),
              // ── Row 2: label + date + delete ────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      caseRow.label.isEmpty
                          ? 'Saved case'
                          : caseRow.label,
                      style: const TextStyle(
                        color: AppColors.mutedStrong,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap.h(AppSpace.sm),
                  Text(
                    _formatDate(caseRow.updatedISO),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap.h(AppSpace.xs),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete case',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tone-tinted status pill (Day X of Y / Complete / Final).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 1,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: tone.withValues(alpha: 0.32),
          width: 0.5,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _formatDose(num n) {
  if (n is int || n == n.toInt()) return n.toInt().toString();
  return n.toString();
}

String _formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final local = parsed.toLocal();
  final now = DateTime.now();
  final daysAgo = now.difference(local).inDays;
  if (daysAgo == 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return '${daysAgo}d ago';
  return DateFormat.MMMd().format(local);
}

// `unawaited` shim — `dart:async` import isn't otherwise needed.
void unawaited(Future<void> _) {}
