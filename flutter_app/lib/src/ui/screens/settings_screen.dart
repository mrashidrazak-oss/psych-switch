// Settings screen.
//
// Two surfaces today: a citations toggle and a "delete all saved
// cases" destructive action. More toggles (reminders, locale, text
// size) follow as those features land.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:psychswitch/src/providers/auth_provider.dart';
import 'package:psychswitch/src/providers/onboarding_provider.dart';
import 'package:psychswitch/src/providers/preferences_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/services/auth_service.dart';
import 'package:psychswitch/src/services/notification_service.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/polished_toast.dart';
import 'package:url_launcher/url_launcher.dart';

final _versionProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _onRemindersToggled(WidgetRef ref, bool value) async {
    await ref.read(remindersEnabledProvider.notifier).set(value: value);
    if (value) {
      // Lazy-prompt for permission the first time the toggle is on.
      await NotificationService.instance.requestPermission();
    } else {
      // Off → cancel everything pending.
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _onSendFeedback(
    BuildContext context,
    AsyncValue<PackageInfo> asyncPkg,
  ) async {
    unawaited(hapticsTap());
    final v = asyncPkg.value;
    final version = v != null ? 'v${v.version}+${v.buildNumber}' : '';
    final subject = Uri.encodeComponent('PsychSwitch feedback · $version');
    final uri = Uri.parse('mailto:feedback@psychswitch.health?subject=$subject');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      showStatusToast(
        context,
        eyebrow: 'No mail app',
        label: 'Email feedback@psychswitch.health',
        kind: StatusToastKind.error,
      );
    }
  }

  Future<void> _onReplayTour(BuildContext context, WidgetRef ref) async {
    unawaited(hapticsTap());
    await ref.read(onboardingCompleteProvider.notifier).reset();
    if (!context.mounted) return;
    // Pop back to the gate cascade — `_OnboardingGate` re-evaluates and
    // pushes the OnboardingScreen because the flag is now false. The
    // pop chain works because /settings sits on top of the router and
    // popping clears every clinical-surface route on the stack.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCitations = ref.watch(showCitationsProvider);
    final reminders = ref.watch(remindersEnabledProvider);
    final asyncPkg = ref.watch(_versionProvider);
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
            ClinicalSpace.lg,
            ClinicalSpace.md,
            ClinicalSpace.lg,
            ClinicalSpace.xl,
          ),
          children: <Widget>[
            const _SectionHeader(text: 'PROFILE'),
            const _ClinicianNameField(),
            const Gap.v(ClinicalSpace.md),
            const _ClinicianRoleField(),

            const Gap.v(ClinicalSpace.xl),
            const _SectionHeader(text: 'ACCOUNT'),
            const _AccountSection(),

            const Gap.v(ClinicalSpace.xl),
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

            const Gap.v(ClinicalSpace.xl),
            const _SectionHeader(text: 'REMINDERS'),
            _ToggleTile(
              label: 'Monitoring reminders',
              description:
                  'Schedule a local notification on the day each '
                  'monitoring entry comes due for saved cases. '
                  'On-device only — never via remote push, never with '
                  'patient identifiers.',
              value: reminders.value ?? false,
              loading: reminders.isLoading,
              onChanged: (v) => _onRemindersToggled(ref, v),
            ),

            const Gap.v(ClinicalSpace.xl),
            const _SectionHeader(text: 'WELCOME'),
            _ActionTile(
              icon: Icons.replay_circle_filled_rounded,
              label: 'Replay onboarding tour',
              description:
                  'Replays the three-card walkthrough next time you '
                  'open PsychSwitch — or right now. Useful for showing '
                  "colleagues what's inside without a fresh install.",
              actionLabel: 'Replay tour',
              onPressed: () => _onReplayTour(context, ref),
            ),

            const Gap.v(ClinicalSpace.xl),
            const _SectionHeader(text: 'FEEDBACK'),
            _ActionTile(
              icon: Icons.email_outlined,
              label: 'Send feedback',
              description:
                  'Spotted a typo, a bug, or a clinical edge case the '
                  'engine missed? Drop a line. The version + build number '
                  'are pre-filled so we can reproduce.',
              actionLabel: 'Email feedback',
              onPressed: () => _onSendFeedback(context, asyncPkg),
            ),

            const Gap.v(ClinicalSpace.xl),
            const _SectionHeader(text: 'DATA'),
            _DangerTile(
              label: 'Delete all saved cases',
              description:
                  'Wipes the local case database. Cannot be undone. '
                  'Does not affect the clinical content registry.',
              onPressed: () => _confirmDeleteAll(context, ref),
            ),

            const Gap.v(ClinicalSpace.xxl),
            // ── Version footer ────────────────────────────────────
            Center(
              child: Text(
                asyncPkg.when(
                  data: (p) => 'PsychSwitch v${p.version} (${p.buildNumber})',
                  loading: () => 'PsychSwitch',
                  error: (_, __) => 'PsychSwitch',
                ),
                style: ClinicalText.caption.copyWith(
                  letterSpacing: 0.3,
                  color: ClinicalPalette.muted,
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.xs),
            Center(
              child: Text(
                'On-device · never transmits patient data',
                style: ClinicalText.caption.copyWith(
                  color: ClinicalPalette.muted.withValues(alpha: 0.65),
                ),
              ),
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
              backgroundColor: ClinicalPalette.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    unawaited(hapticsWarning());
    final db = ref.read(databaseProvider);
    final removed = await db.deleteAll();
    // Cancel every pending monitoring reminder — the cases that
    // queued them no longer exist.
    await NotificationService.instance.cancelAll();
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
        ClinicalSpace.xs,
        ClinicalSpace.sm,
        ClinicalSpace.xs,
        ClinicalSpace.sm,
      ),
      child: Text(text, style: ClinicalText.eyebrow),
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
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.sm,
        ClinicalSpace.md + 2,
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
                    color: ClinicalPalette.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const Gap.v(ClinicalSpace.xs),
                Text(
                  description,
                  style: ClinicalText.caption.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: loading
                ? null
                : (v) {
                    unawaited(hapticsTap());
                    onChanged(v);
                  },
          ),
        ],
      ),
    );
  }
}

/// Action tile — like ToggleTile but with a tap-to-fire button instead
/// of a switch. Used for one-shot affordances like "Replay tour".
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: ClinicalPalette.accent),
              const Gap.h(ClinicalSpace.sm + 2),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ClinicalPalette.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 1),
          Text(
            description,
            style: ClinicalText.caption.copyWith(height: 1.55),
          ),
          const Gap.v(ClinicalSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ClinicalPalette.accent,
                side: BorderSide(
                  color: ClinicalPalette.accent.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClinicalSpace.lg - 2,
                  vertical: ClinicalSpace.xs + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
        color: ClinicalPalette.danger.withValues(alpha: 0.05),
        border: Border.all(
          color: ClinicalPalette.danger.withValues(alpha: 0.35),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: ClinicalPalette.danger,
                size: 16,
              ),
              const Gap.h(ClinicalSpace.sm),
              Text(
                label,
                style: const TextStyle(
                  color: ClinicalPalette.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs),
          Text(
            description,
            style: ClinicalText.caption.copyWith(height: 1.5),
          ),
          const Gap.v(ClinicalSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ClinicalPalette.danger,
                side: BorderSide(
                  color: ClinicalPalette.danger.withValues(alpha: 0.5),
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

/// Clinician-name editor — surfaces on the Home greeting and (future)
/// PDF exports. Stored locally via [clinicianNameProvider]; never
/// transmitted.
class _ClinicianNameField extends ConsumerStatefulWidget {
  const _ClinicianNameField();

  @override
  ConsumerState<_ClinicianNameField> createState() =>
      _ClinicianNameFieldState();
}

class _ClinicianNameFieldState extends ConsumerState<_ClinicianNameField> {
  late final TextEditingController _ctrl;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seed the field once when prefs resolve so we don't fight the
    // user's edits on every rebuild.
    ref.watch(clinicianNameProvider).whenData((current) {
      if (!_seeded) {
        _ctrl.text = current;
        _seeded = true;
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.person_outline, size: 18, color: ClinicalPalette.accent),
              Gap.h(ClinicalSpace.sm + 2),
              Expanded(
                child: Text(
                  'Your name',
                  style: TextStyle(
                    color: ClinicalPalette.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 1),
          Text(
            'Personalises the Home greeting and (later) exported '
            'switch-plan PDFs. Stays on this device.',
            style: ClinicalText.caption.copyWith(height: 1.55),
          ),
          const Gap.v(ClinicalSpace.md),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: 'Full name',
              counterText: '',
              isDense: true,
            ),
            onSubmitted: (v) =>
                ref.read(clinicianNameProvider.notifier).set(v),
            onChanged: (v) =>
                ref.read(clinicianNameProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

/// Clinician role / title editor — surfaces under the Home greeting.
/// Optional. Empty falls back to the generic "Healthcare professional"
/// subtitle. Stored locally via [clinicianRoleProvider]; never
/// transmitted.
class _ClinicianRoleField extends ConsumerStatefulWidget {
  const _ClinicianRoleField();

  @override
  ConsumerState<_ClinicianRoleField> createState() =>
      _ClinicianRoleFieldState();
}

class _ClinicianRoleFieldState extends ConsumerState<_ClinicianRoleField> {
  late final TextEditingController _ctrl;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(clinicianRoleProvider).whenData((current) {
      if (!_seeded) {
        _ctrl.text = current;
        _seeded = true;
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.badge_outlined, size: 18, color: ClinicalPalette.accent),
              Gap.h(ClinicalSpace.sm + 2),
              Expanded(
                child: Text(
                  'Your role',
                  style: TextStyle(
                    color: ClinicalPalette.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 1),
          Text(
            'Shown under your name on the Home greeting. Optional — '
            'leave blank for a generic salutation.',
            style: ClinicalText.caption.copyWith(height: 1.55),
          ),
          const Gap.v(ClinicalSpace.md),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 32,
            decoration: const InputDecoration(
              hintText: 'Consultant Psychiatrist',
              counterText: '',
              isDense: true,
            ),
            onSubmitted: (v) =>
                ref.read(clinicianRoleProvider.notifier).set(v),
            onChanged: (v) =>
                ref.read(clinicianRoleProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

/// Optional Google sign-in surface.
///
/// The app is offline-first and account-free; signing in is a strictly
/// opt-in convenience and never required. Renders one of three states:
/// unavailable (no Firebase project wired in — see
/// store/FIREBASE_SETUP.md), signed out, or signed in.
class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection();

  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> {
  bool _busy = false;

  Future<void> _signIn() async {
    unawaited(hapticsTap());
    setState(() => _busy = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      unawaited(hapticsConfirm());
      showStatusToast(
        context,
        eyebrow: 'Signed in',
        label: user.label,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showStatusToast(
        context,
        eyebrow: 'Sign-in failed',
        label: e.message,
        kind: StatusToastKind.error,
      );
    } on Object catch (_) {
      if (!mounted) return;
      showStatusToast(
        context,
        eyebrow: 'Sign-in failed',
        label: "Couldn't sign in. Try again.",
        kind: StatusToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    unawaited(hapticsTap());
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      showStatusToast(
        context,
        eyebrow: 'Signed out',
        label: 'See you next time.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(authAvailableProvider);
    final user = ref.watch(authStateProvider).asData?.value;

    // Pick which branch + a stable key so AnimatedSwitcher recognises
    // sign-in / sign-out as distinct subtrees worth cross-fading.
    final Widget card;
    final String key;
    if (!available) {
      key = 'unconfigured';
      card = const _AccountCard(
        icon: Icons.lock_outline,
        title: 'Sign in with Google',
        description:
            'Optional account sign-in. Becomes available in an '
            'upcoming update once the cloud project is connected — '
            'PsychSwitch stays fully usable offline either way.',
      );
    } else if (user == null) {
      key = 'signed-out';
      card = _AccountCard(
        icon: Icons.account_circle_outlined,
        title: 'Sign in with Google',
        description:
            'Optional. Signing in stores only your Google name, '
            'email and photo, to label this device. Patient data '
            'never leaves the device — signed in or not. You can '
            'sign out anytime.',
        action: OutlinedButton.icon(
          onPressed: _busy ? null : _signIn,
          style: _accountButtonStyle(),
          icon: _busy
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login, size: 18),
          label: Text(
            _busy ? 'Signing in…' : 'Continue with Google',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      );
    } else {
      key = 'signed-in';
      card = _AccountCard(
        photoUrl: user.photoUrl,
        initials: clinicianInitials(user.label),
        title: user.label,
        description: user.email ?? 'Signed in with Google',
        action: OutlinedButton(
          onPressed: _busy ? null : _signOut,
          style: _accountButtonStyle(),
          child: Text(
            _busy ? 'Signing out…' : 'Sign out',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      );
    }

    // Fade + slight rise on state transition. Matches the rest of the
    // app's motion language — same easeOutCubic, same ~280ms beat as
    // the engine-loading fragment cycle and AnimatedSwitcher patterns.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<String>(key), child: card),
    );
  }
}

/// Shared outlined-button style for the account card — matches the
/// accent-tinted affordance used by [_ActionTile].
ButtonStyle _accountButtonStyle() => OutlinedButton.styleFrom(
      foregroundColor: ClinicalPalette.accent,
      side: BorderSide(
        color: ClinicalPalette.accent.withValues(alpha: 0.5),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg - 2,
        vertical: ClinicalSpace.xs + 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      ),
    );

/// Presentational card for the account section. Shows either a leading
/// [icon] or a [photoUrl]/[initials] avatar, a [title], a [description]
/// and an optional [action] button.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.title,
    required this.description,
    this.icon,
    this.photoUrl,
    this.initials,
    this.action,
  });

  final String title;
  final String description;
  final IconData? icon;
  final String? photoUrl;
  final String? initials;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
        ClinicalSpace.lg - 2,
        ClinicalSpace.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _leading(),
              const Gap.h(ClinicalSpace.sm + 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ClinicalPalette.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const Gap.v(ClinicalSpace.xs + 1),
          Text(
            description,
            style: ClinicalText.caption.copyWith(height: 1.55),
          ),
          if (action != null) ...<Widget>[
            const Gap.v(ClinicalSpace.md),
            Align(alignment: Alignment.centerLeft, child: action),
          ],
        ],
      ),
    );
  }

  Widget _leading() {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: ClinicalPalette.accent.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(url),
      );
    }
    if (initials != null) {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ClinicalPalette.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Text(
          initials!,
          style: const TextStyle(
            color: ClinicalPalette.accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Icon(icon, size: 18, color: ClinicalPalette.accent);
  }
}
