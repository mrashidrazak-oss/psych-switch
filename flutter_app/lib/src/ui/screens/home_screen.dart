// Home screen.
//
// Design principle: this app exists to plan a cross-titration. The
// home screen exists to start one. Everything else is in service of
// that single act, and earns its visual weight accordingly.
//
//   1. Hero — display headline + the giant Start-a-switch CTA.
//      Restrained brand mark (24-pt), wordmark only as a quiet
//      eyebrow line. The button is the focal point of the screen.
//   2. Today's pulse — only renders when there's actionable
//      monitoring on a saved case. Hidden silently when empty.
//   3. Modules — a calm vertical list of clinical entry points
//      (Clozapine, Depot, Mood stabilisers). Each row is a wide
//      tap target with subtle chrome, not a tile in a grid.
//   4. Tools — inline interpunct-separated text links. They're
//      utilities; they don't deserve grid real estate.
//   5. Sign-off footer — for licensed clinicians, decision support
//      only, version. One line, dimmed.
//
// Wide screens (foldable inner / tablet / desktop) keep the same
// vertical flow but cap the content column at ~640 px so we never
// stretch a single button or row across an entire 7.6" panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch/src/ui/widgets/today_pulse_card.dart';

/// Maximum content-column width on wide screens. Anything wider gets
/// flanked by whitespace — never stretch a single CTA across a
/// 7.6-inch foldable.
const double _maxContentWidth = 640;

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xxl,
              AppSpace.xl,
              AppSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const EntranceFade(child: _Mark()),
                const Gap.v(AppSpace.xxl + AppSpace.md),
                const EntranceFade(index: 1, child: _Headline()),
                const Gap.v(AppSpace.lg),
                EntranceFade(
                  index: 2,
                  child: _Stats(
                    drugCount: drugCount,
                    ruleCount: ruleCount,
                  ),
                ),
                const Gap.v(AppSpace.xxl + AppSpace.md),
                EntranceFade(
                  index: 3,
                  child: _StartButton(
                    onPressed: () =>
                        context.pushNamed(Routes.switch_),
                  ),
                ),
                const Gap.v(AppSpace.lg),
                EntranceFade(
                  index: 4,
                  child: _HistoryLink(
                    onPressed: () =>
                        context.pushNamed(Routes.history),
                  ),
                ),
                const Gap.v(AppSpace.xxl),

                // Today's pulse — only renders when there are
                // actionable saved-case reminders, otherwise the
                // widget collapses to SizedBox.shrink and this
                // section disappears completely.
                const EntranceFade(index: 5, child: TodayPulseCard()),
                const Gap.v(AppSpace.xl),

                const EntranceFade(index: 6, child: _ModulesSection()),
                const Gap.v(AppSpace.xxl),

                const EntranceFade(index: 7, child: _ToolsSection()),
                const Gap.v(AppSpace.xxl + AppSpace.md),

                const EntranceFade(index: 8, child: _SignOff()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────

/// Brand mark.
///
/// The product's own logo (the cross-titration X-mark in from-blue +
/// to-green) sits at 54-pt with a soft dual-tone glow behind it — the
/// blue glow leaning left, the green leaning right, mirroring the
/// strokes in the icon. Pairs with a confident 24-pt w800 wordmark
/// and a small caps tagline.
///
/// Materially honest: no gimmick, no decorative chrome. Just the
/// product mark given the room it deserves, the way Apple gives a
/// 60-pt icon room on App Store landing pages.
class _Mark extends StatelessWidget {
  const _Mark();

  static const double _markSize = 54;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PsychSwitch · Reviewed cross-titration',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            // ── Brand mark with dual-tone glow ──────────────────────
            // The two shadows offset opposite directions so the glow
            // mirrors the logo's X-strokes — from-blue trailing one
            // way, to-green the other. Subtle, only visible when the
            // surrounding bg is dark (which on this screen it always
            // is).
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg + 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.from.withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(-5, 6),
                  ),
                  BoxShadow(
                    color: AppColors.to.withValues(alpha: 0.28),
                    blurRadius: 30,
                    spreadRadius: -8,
                    offset: const Offset(5, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg + 2),
                child: Image.asset(
                  'assets/icon.png',
                  width: _markSize,
                  height: _markSize,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const Gap.h(AppSpace.md + 2),
            // ── Wordmark + tagline ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'PsychSwitch',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const Gap.v(AppSpace.xs + 1),
                  Row(
                    children: <Widget>[
                      // Two tiny tone dots echoing the logo's palette
                      // so the brand identity reads as a system, not
                      // as an isolated icon.
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.from,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap.h(3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.to,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap.h(AppSpace.sm),
                      const Text(
                        'Reviewed cross-titration',
                        style: TextStyle(
                          color: AppColors.mutedStrong,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Plan a cross-\ntitration.',
      style: TextStyle(
        color: AppColors.text,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.4,
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.drugCount, required this.ruleCount});

  final int drugCount;
  final int ruleCount;

  @override
  Widget build(BuildContext context) {
    // Wording deliberately preserved: existing widget tests + RN
    // parity assert "<drugs> drugs · <rules> reviewed switching rules".
    return Text(
      '$drugCount drugs · $ruleCount reviewed switching rules',
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// The screen's single focal point. Big rounded rectangle, accent
/// fill, generous internal padding. The button itself is the design.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Start a switch',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              Gap.h(AppSpace.sm + 2),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// History as a quiet text link, not a button. Tertiary action.
class _HistoryLink extends StatelessWidget {
  const _HistoryLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mutedStrong,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.history, size: 14),
            Gap.h(AppSpace.xs + 2),
            Text('History'),
          ],
        ),
      ),
    );
  }
}

// ── Modules ──────────────────────────────────────────────────────────

class _ModulesSection extends StatelessWidget {
  const _ModulesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: AppSpace.xs),
          child: Text('CLINICAL MODULES', style: AppTextSizes.eyebrow),
        ),
        const Gap.v(AppSpace.md),
        _ModuleRow(
          title: 'Clozapine',
          subtitle: 'Titration · FBC monitoring · ANC checker · '
              'rechallenge · community criteria',
          icon: Icons.medical_services_outlined,
          tone: AppColors.warning,
          onPressed: () => context.pushNamed(Routes.clozapine),
        ),
        const Gap.v(AppSpace.sm + 2),
        _ModuleRow(
          title: 'Depot LAI',
          subtitle: 'Sustenna · Trinza · Maintena initiation, '
              'missed-dose flows, needle guides',
          icon: Icons.colorize_outlined,
          tone: AppColors.accent,
          onPressed: () => context.pushNamed(Routes.depotIndex),
        ),
        // Mood-stabiliser module hidden pre-release pending clinical
        // sign-off of lithium / valproate / lamotrigine / carbamazepine
        // content. Route + screens kept in the codebase; restore the
        // _ModuleRow here once content is reviewed.
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
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
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md + 2,
            AppSpace.md + 2,
            AppSpace.md + 2,
            AppSpace.md + 2,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.sm + 2),
                ),
                child: Icon(icon, size: 18, color: tone),
              ),
              const Gap.h(AppSpace.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const Gap.v(2),
                    Text(
                      subtitle,
                      style: AppTextSizes.micro.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
              const Gap.h(AppSpace.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tools ────────────────────────────────────────────────────────────
//
// Two grouped cells, Apple-Settings style. The clinical reference
// utilities cluster as one group (QTc, Equivalency, AE lookup,
// Glossary, Errata); app-shell utilities (Settings, About) cluster as
// a second. Each row is a quiet tap-target with a monochrome icon, a
// label, and a chevron — no accent blue, no tinted tiles. The chrome
// is borderless surface with hairline dividers between rows so the
// cluster reads as one considered unit, not a list of links.

class _ToolsSection extends StatelessWidget {
  const _ToolsSection();

  static const _reference = <_ToolItem>[
    _ToolItem(
      label: 'QTc stacker',
      icon: Icons.monitor_heart_outlined,
      route: Routes.qtcStacker,
    ),
    _ToolItem(
      label: 'Dose equivalency',
      icon: Icons.swap_horiz_rounded,
      route: Routes.equivalency,
    ),
    _ToolItem(
      label: 'Adverse-effect lookup',
      icon: Icons.health_and_safety_outlined,
      route: Routes.adverseEffects,
    ),
    _ToolItem(
      label: 'Glossary',
      icon: Icons.menu_book_outlined,
      route: Routes.glossary,
    ),
    _ToolItem(
      label: 'Errata',
      icon: Icons.fact_check_outlined,
      route: Routes.errata,
    ),
  ];

  static const _app = <_ToolItem>[
    _ToolItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: Routes.settings,
    ),
    _ToolItem(
      label: 'About',
      icon: Icons.info_outline,
      route: Routes.about,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppSpace.xs),
          child: Text('REFERENCE', style: AppTextSizes.eyebrow),
        ),
        Gap.v(AppSpace.sm + 2),
        _ToolGroup(items: _reference),
        Gap.v(AppSpace.lg),
        Padding(
          padding: EdgeInsets.only(left: AppSpace.xs),
          child: Text('APP', style: AppTextSizes.eyebrow),
        ),
        Gap.v(AppSpace.sm + 2),
        _ToolGroup(items: _app),
      ],
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}

class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.items});

  final List<_ToolItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < items.length; i++) ...<Widget>[
            _ToolRow(item: items[i]),
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: Divider(height: 1, thickness: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.item});

  final _ToolItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(item.route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md + 2,
            AppSpace.md - 2,
            AppSpace.md + 2,
            AppSpace.md - 2,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 28,
                child: Icon(
                  item.icon,
                  size: 18,
                  color: AppColors.mutedStrong,
                ),
              ),
              const Gap.h(AppSpace.md - 2),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign-off footer ──────────────────────────────────────────────────

class _SignOff extends StatelessWidget {
  const _SignOff();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 24,
            height: 1,
            color: AppColors.border,
          ),
          const Gap.v(AppSpace.md),
          Text(
            'For licensed clinicians.',
            style: AppTextSizes.micro.copyWith(
              color: AppColors.mutedStrong,
              letterSpacing: 0.3,
            ),
          ),
          const Gap.v(2),
          Text(
            'Decision support — not medical advice.',
            style: AppTextSizes.micro.copyWith(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
