// Home screen — hero brand block, ready badge, today's pulse,
// primary actions, modules row, tools row, footer.
//
// Layout principle: every element on this screen earns its place.
// The hero gives the app personality, the ready badge confirms the
// engine loaded, the pulse card surfaces actionable monitoring, and
// the actions/modules/tools rows are the everyday entry points.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/status_pill.dart';
import 'package:psychswitch/src/ui/widgets/today_pulse_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Ambient backdrop — radial glow from the top-left, gives the
          // dark surface depth without being noisy.
          const Positioned.fill(child: _AmbientBackdrop()),
          SafeArea(
            child: asyncEngine.when(
              loading: () => const EngineLoadingView(),
              error: (e, st) => EngineErrorView(error: e),
              data: (engine) => _HomeBody(
                drugCount: engine.listDrugs().length,
                ruleCount: engine.listRules().length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.85),
            radius: 1.1,
            colors: <Color>[
              AppColors.from.withValues(alpha: 0.08),
              AppColors.to.withValues(alpha: 0.04),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.45, 1],
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const EntranceFade(child: _Hero()),
          const Gap.v(AppSpace.xl),

          EntranceFade(
            index: 1,
            child: _ReadyBadge(drugs: drugCount, rules: ruleCount),
          ),
          const Gap.v(AppSpace.lg),

          // Today's pulse — saved cases with monitoring due now.
          // Renders nothing when no cases or no pulses are due.
          const EntranceFade(index: 2, child: TodayPulseCard()),
          const Gap.v(AppSpace.xl),

          // Primary CTA.
          EntranceFade(
            index: 3,
            child: _StartSwitchButton(
              onPressed: () => context.pushNamed(Routes.switch_),
            ),
          ),
          const Gap.v(AppSpace.md),
          // Secondary CTA — saved cases.
          EntranceFade(
            index: 4,
            child: _SecondaryButton(
              label: 'History',
              icon: Icons.history,
              onPressed: () => context.pushNamed(Routes.history),
            ),
          ),
          const Gap.v(AppSpace.xl),

          // Modules row — specialty surfaces.
          const EntranceFade(
            index: 5,
            child: _SectionLabel(text: 'CLINICAL MODULES'),
          ),
          const Gap.v(AppSpace.sm),
          const EntranceFade(index: 5, child: _ModulesRow()),
          const Gap.v(AppSpace.lg),

          // Tools row — Glossary · Settings · About.
          const EntranceFade(
            index: 6,
            child: _SectionLabel(text: 'TOOLS'),
          ),
          const Gap.v(AppSpace.sm),
          const EntranceFade(index: 6, child: _ToolsRow()),
          const Gap.v(AppSpace.xxl),

          const EntranceFade(index: 7, child: _Footer()),
        ],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'PsychSwitch. Reviewed cross-titration, cited at every step.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _BrandMonogram(),
                const Gap.h(AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'PsychSwitch',
                        style: AppTextSizes.display.copyWith(
                          letterSpacing: -1,
                          fontSize: 30,
                        ),
                      ),
                      const Gap.v(AppSpace.xxs),
                      Text(
                        'Reviewed cross-titration · cited at every step',
                        style: AppTextSizes.caption.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMonogram extends StatelessWidget {
  const _BrandMonogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.from, AppColors.to],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: -3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ── Ready badge ───────────────────────────────────────────────────────

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.drugs, required this.rules});

  final int drugs;
  final int rules;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Engine ready. $drugs drugs and '
          '$rules reviewed switching rules loaded.',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.to.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.to.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Row(
            children: <Widget>[
              const _PulsingDot(color: AppColors.to),
              const Gap.h(AppSpace.md),
              Expanded(
                child: Text(
                  '$drugs drugs · $rules reviewed switching rules',
                  style: AppTextSizes.caption.copyWith(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const StatusPill(
                label: 'READY',
                tone: AppColors.to,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_ctl.value);
          return SizedBox(
            width: 12,
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15 + 0.15 * t),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── CTAs ──────────────────────────────────────────────────────────────

class _StartSwitchButton extends StatelessWidget {
  const _StartSwitchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Start a switch'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Modules + tools rows ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextSizes.eyebrow);
  }
}

class _ModulesRow extends StatelessWidget {
  const _ModulesRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _ModuleCard(
                title: 'Clozapine',
                subtitle: 'Titration · FBC · rechallenge',
                icon: Icons.medical_services_outlined,
                tone: AppColors.warning,
                onPressed: () => context.pushNamed(Routes.clozapine),
              ),
            ),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: _ModuleCard(
                title: 'Depot LAI',
                subtitle: 'Sustenna · Trinza · Maintena',
                icon: Icons.colorize_outlined,
                tone: AppColors.accent,
                onPressed: () => context.pushNamed(Routes.depotIndex),
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _ModuleCard(
                title: 'Mood stabilisers',
                subtitle: 'Lithium · VPA · LTG · CBZ',
                icon: Icons.balance_rounded,
                tone: AppColors.to,
                onPressed: () =>
                    context.pushNamed(Routes.moodStabilizers),
              ),
            ),
            const Gap.h(AppSpace.sm),
            const Expanded(child: SizedBox.shrink()),
          ],
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
      color: tone.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: tone.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.md,
            AppSpace.md,
            AppSpace.md + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 16, color: tone),
              ),
              const Gap.v(AppSpace.sm),
              Text(
                title,
                style: TextStyle(
                  color: tone,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap.v(2),
              Text(
                subtitle,
                style: AppTextSizes.micro.copyWith(height: 1.4),
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
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _ToolChip(
                label: 'QTc stacker',
                icon: Icons.monitor_heart_outlined,
                onPressed: () => context.pushNamed(Routes.qtcStacker),
              ),
            ),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: _ToolChip(
                label: 'Glossary',
                icon: Icons.menu_book_outlined,
                onPressed: () => context.pushNamed(Routes.glossary),
              ),
            ),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: _ToolChip(
                label: 'Errata',
                icon: Icons.fact_check_outlined,
                onPressed: () => context.pushNamed(Routes.errata),
              ),
            ),
          ],
        ),
        const Gap.v(AppSpace.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _ToolChip(
                label: 'Settings',
                icon: Icons.settings_outlined,
                onPressed: () => context.pushNamed(Routes.settings),
              ),
            ),
            const Gap.h(AppSpace.sm),
            Expanded(
              child: _ToolChip(
                label: 'About',
                icon: Icons.info_outline,
                onPressed: () => context.pushNamed(Routes.about),
              ),
            ),
            const Gap.h(AppSpace.sm),
            const Expanded(child: SizedBox.shrink()),
          ],
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
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.text),
              const Gap.v(AppSpace.xs + 2),
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

// ── Footer ────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.from.withValues(alpha: 0.7),
                  AppColors.to.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const Gap.v(AppSpace.md),
          Text(
            'For licensed clinicians',
            style: AppTextSizes.micro.copyWith(
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const Gap.v(2),
          Text(
            'Decision support — not a substitute for clinical judgement',
            style: AppTextSizes.micro.copyWith(
              fontSize: 10,
              color: AppColors.muted.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
