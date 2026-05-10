// History screen — Phase 5C.
//
// Lists every saved case (savedCasesProvider stream), sorted
// newest-first by updatedISO. Tap a row to re-open it on /result.
// Long-press to delete.
//
// Empty state explains the workflow and points back to Home's
// Start-a-switch CTA.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.muted,
                size: 28,
              ),
            ),
            const Gap.v(AppSpace.lg),
            const Text(
              'No saved cases yet',
              style: AppTextSizes.subtitle,
            ),
            const Gap.v(AppSpace.sm),
            Text(
              'Save a case from the Result screen to see it here.\n'
              "It's the easiest way to keep monitoring on track.",
              style: AppTextSizes.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Gap.v(AppSpace.lg),
            FilledButton.icon(
              onPressed: () => context.pushNamed(Routes.switch_),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Start a switch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseList extends ConsumerWidget {
  const _CaseList({required this.cases, required this.engine});

  final List<SavedCase> cases;
  final SwitchingEngine engine;

  String _drugName(String id) =>
      engine.getDrug(id)?.genericName ?? id;

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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = cases[i];
        final fromName = _drugName(c.fromDrugId);
        final toName = _drugName(c.toDrugId);
        // Only stagger the first 6 — past that, ListView clips and
        // scrolling new items in shouldn't be animated.
        return EntranceFade(
          index: i.clamp(0, 5),
          child: _CaseTile(
            caseRow: c,
            fromName: fromName,
            toName: toName,
            onTap: () => context.pushNamed(
              Routes.result,
              extra: ResultScreenArgs(
                input: SwitchInput(
                  fromDrugId: c.fromDrugId,
                  fromDoseMg: c.fromDoseMg,
                  toDrugId: c.toDrugId,
                  toDoseMg: c.toDoseMg,
                ),
              ),
            ),
            onDelete: () => _onDeletePressed(context, ref, c),
          ),
        );
      },
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({
    required this.caseRow,
    required this.fromName,
    required this.toName,
    required this.onTap,
    required this.onDelete,
  });

  final SavedCase caseRow;
  final String fromName;
  final String toName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            caseRow.label.isEmpty
                                ? '$fromName → $toName'
                                : caseRow.label,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(caseRow.updatedISO),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$fromName ${_formatDose(caseRow.fromDoseMg)} mg → '
                      '$toName ${_formatDose(caseRow.toDoseMg)} mg',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.muted,
                  size: 20,
                ),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
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
  return DateFormat.yMMMd().format(parsed.toLocal());
}
