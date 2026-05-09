// Home screen — Phase 4B + 5C/D.
//
// Wordmark + tagline → engine-ready badge → today's pulse card (when
// any saved cases have due monitoring) → primary CTA + secondary
// History button. Modules grid + tools row land in Phase 6+.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/today_pulse_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      body: SafeArea(
        child: asyncEngine.when(
          loading: () => const EngineLoadingView(),
          error: (e, st) => EngineErrorView(error: e),
          data: (engine) => _HomeBody(
            drugCount: engine.listDrugs().length,
            ruleCount: engine.listRules().length,
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.drugCount, required this.ruleCount});

  final int drugCount;
  final int ruleCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Wordmark.
          const Text(
            'PsychSwitch',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reviewed cross-titration · cited at every step',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Engine ready badge — surfaces drug + rule counts so the
          // user can see the registry loaded successfully.
          _ReadyBadge(drugs: drugCount, rules: ruleCount),
          const SizedBox(height: 16),
          // Today's pulse — saved cases with monitoring due now.
          // Renders nothing when no cases or no pulses are due.
          const TodayPulseCard(),
          const SizedBox(height: 24),

          // Primary CTA.
          _StartSwitchButton(
            onPressed: () => context.goNamed(Routes.switch_),
          ),
          const SizedBox(height: 12),
          // Secondary CTA — saved cases.
          _SecondaryButton(
            label: 'History',
            icon: Icons.history,
            onPressed: () => context.goNamed(Routes.history),
          ),
          const SizedBox(height: 24),

          // Modules row — specialty tools (Clozapine, Depot in 7D).
          const _ModulesRow(),
          const SizedBox(height: 16),

          // Tools row — Glossary · Settings · About.
          const _ToolsRow(),

          const Spacer(),
          const _PhaseFooter(),
        ],
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.drugs, required this.rules});

  final int drugs;
  final int rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.to.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.to.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const _StatusDot(color: AppColors.to),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$drugs drugs · $rules reviewed switching rules',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StartSwitchButton extends StatelessWidget {
  const _StartSwitchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Start a switch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.text),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ModulesRow extends StatelessWidget {
  const _ModulesRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ModuleCard(
            title: 'Clozapine',
            subtitle: 'Titration · FBC · rechallenge',
            icon: Icons.medical_services_outlined,
            tone: AppColors.warning,
            onPressed: () => context.goNamed(Routes.clozapine),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ModuleCard(
            title: 'Depot LAI',
            subtitle: 'Sustenna · Trinza · Maintena',
            icon: Icons.colorize_outlined,
            tone: AppColors.accent,
            onPressed: () => context.goNamed(Routes.depotIndex),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: tone.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: tone),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: tone,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ToolChip(
            label: 'Glossary',
            icon: Icons.menu_book_outlined,
            onPressed: () => context.goNamed(Routes.glossary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolChip(
            label: 'Settings',
            icon: Icons.settings_outlined,
            onPressed: () => context.goNamed(Routes.settings),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolChip(
            label: 'About',
            icon: Icons.info_outline,
            onPressed: () => context.goNamed(Routes.about),
          ),
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.text),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseFooter extends StatelessWidget {
  const _PhaseFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'PHASE 4 — UI BUILD',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
