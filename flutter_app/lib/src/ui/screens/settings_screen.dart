// Settings screen.
//
// Two surfaces today: a citations toggle and a "delete all saved
// cases" destructive action. More toggles (reminders, locale, text
// size) follow as those features land.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/preferences_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCitations = ref.watch(showCitationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xl,
          ),
          children: <Widget>[
            const _SectionHeader(text: 'DISPLAY'),
            _ToggleTile(
              label: 'Show citation chips',
              description:
                  'Inline citation chips on the Result schedule rows. '
                  'Turn off to declutter when teaching or screen-sharing.',
              value: showCitations.value ?? true,
              loading: showCitations.isLoading,
              onChanged: (v) =>
                  ref.read(showCitationsProvider.notifier).set(value: v),
            ),

            const Gap.v(AppSpace.xl),
            const _SectionHeader(text: 'DATA'),
            _DangerTile(
              label: 'Delete all saved cases',
              description:
                  'Wipes the local case database. Cannot be undone. '
                  'Does not affect the clinical content registry.',
              onPressed: () => _confirmDeleteAll(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all saved cases?'),
        content: const Text(
          'Every saved case is removed from this device. The clinical '
          'content registry (drugs, rules, citations) is not affected.',
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
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    final removed = await db.deleteAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed == 0
              ? 'Nothing to delete.'
              : 'Deleted $removed saved case${removed == 1 ? '' : 's'}.',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.sm,
        AppSpace.xs,
        AppSpace.sm,
      ),
      child: Text(text, style: AppTextSizes.eyebrow),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.description,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap.v(AppSpace.xxs),
                Text(
                  description,
                  style: AppTextSizes.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          // Switch styling now comes from the global SwitchTheme.
          Switch(
            value: value,
            onChanged: loading ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.label,
    required this.description,
    required this.onPressed,
  });

  final String label;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md + 2,
        AppSpace.md,
        AppSpace.md + 2,
        AppSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 16,
              ),
              const Gap.h(AppSpace.sm),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap.v(AppSpace.xs),
          Text(
            description,
            style: AppTextSizes.caption.copyWith(height: 1.5),
          ),
          const Gap.v(AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.5),
                ),
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
