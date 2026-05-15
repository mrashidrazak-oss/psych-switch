// Home screen — redesigned 2026-05-15 in the new "Clinical Light"
// visual language. See `lib/src/ui/theme/clinical_theme.dart` for the
// palette + spacing tokens, and `lib/src/ui/widgets/clinical_primitives.dart`
// for the reusable squircle / pill / ring widgets.
//
// Structure (top → bottom):
//
//   1. Greeting header — circular avatar (initials), good-time-of-day
//      greeting + clinician role, notification bell.
//   2. Search field — taps through to the global search screen
//      (`Routes.search`).
//   3. Hero "Start a switch" — large lavender-tone squircle with the
//      primary CTA, optional drug-count chip.
//   4. Quick actions — 4 tone-tinted tiles (Compare · Regimen check ·
//      Calculators · Adverse-effect lookup).
//   5. Category grid — 2×2 of large tone-tinted cards
//      (Antidepressants · Antipsychotics · Mood stabilisers ·
//      Clozapine), each routes to the relevant browsing surface.
//   6. Reference rail — clean list of supporting tools (Glossary,
//      Errata, Ramadan, Depot, History).
//   7. Footer — version + clinician disclaimer line, dimmed.
//
// Wrapped in a `Theme(data: buildClinicalTheme(), …)` so this screen
// renders in the new light language even though the rest of the app
// still uses the dark default. As more screens migrate we promote the
// clinical theme to the app root.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';

/// Maximum content-column width on wide screens. Anything wider gets
/// flanked by whitespace so we never stretch a CTA across a 7.6" panel.
const double _maxContentWidth = 640;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEngine = ref.watch(engineProvider);
    return Theme(
      data: buildClinicalTheme(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: ClinicalPalette.bg,
          body: SafeArea(
            child: asyncEngine.when(
              loading: () => const EngineLoadingView(),
              error: (e, _) => EngineErrorView(error: e),
              data: (engine) => _HomeBody(
                drugCount: engine.listDrugs().length,
                ruleCount: engine.listRules().length,
              ),
            ),
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpace.lg + 4,
            ClinicalSpace.lg,
            ClinicalSpace.lg + 4,
            ClinicalSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Greeting(greeting: greeting),
              const SizedBox(height: ClinicalSpace.lg + 4),
              const _SearchField(),
              const SizedBox(height: ClinicalSpace.lg),
              _Hero(drugCount: drugCount, ruleCount: ruleCount),
              const SizedBox(height: ClinicalSpace.lg),
              const _QuickActions(),
              const SizedBox(height: ClinicalSpace.lg + 4),
              const _SectionLabel(
                label: 'Browse by class',
                tagline: 'Tap to open the matching reference',
              ),
              const SizedBox(height: ClinicalSpace.md),
              const _CategoryGrid(),
              const SizedBox(height: ClinicalSpace.lg + 4),
              const _SectionLabel(label: 'Reference', tagline: null),
              const SizedBox(height: ClinicalSpace.md),
              const _ReferenceRail(),
              const SizedBox(height: ClinicalSpace.xl),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting header ─────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting});
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const AvatarCircle(initials: 'RR'),
        const SizedBox(width: ClinicalSpace.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$greeting, Dr R',
                style: ClinicalText.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text('Consultant Psychiatrist',
                  style: ClinicalText.caption),
            ],
          ),
        ),
        _IconBubble(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.pushNamed(Routes.errata),
          showDot: true,
        ),
        const SizedBox(width: ClinicalSpace.sm),
        _IconBubble(
          icon: Icons.settings_outlined,
          onTap: () => context.pushNamed(Routes.settings),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ClinicalPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: ClinicalPalette.border,
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: 20, color: ClinicalPalette.text),
          ),
          if (showDot)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ClinicalPalette.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: ClinicalPalette.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Search ─────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(Routes.search),
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: ClinicalSpace.lg),
        decoration: BoxDecoration(
          color: ClinicalPalette.surface,
          borderRadius: BorderRadius.circular(ClinicalRadii.pill),
          border: Border.all(
            color: ClinicalPalette.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.search,
                size: 20, color: ClinicalPalette.mutedStrong),
            const SizedBox(width: ClinicalSpace.md),
            Expanded(
              child: Text(
                'Search drugs, brands, glossary…',
                style: ClinicalText.body.copyWith(
                  color: ClinicalPalette.muted,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: ClinicalPalette.cta,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 14,
                color: ClinicalPalette.ctaText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.drugCount, required this.ruleCount});

  final int drugCount;
  final int ruleCount;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: ClinicalPalette.toneLavender,
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const TonePill(
                      label: 'Switch wizard',
                      tone: Color(0xFFFFFFFF),
                      ink: ClinicalPalette.toneLavenderInk,
                    ),
                    const SizedBox(height: ClinicalSpace.md),
                    Text(
                      'Plan a safe cross-titration',
                      style: ClinicalText.heading.copyWith(
                        color: ClinicalPalette.toneLavenderInk,
                      ),
                    ),
                    const SizedBox(height: ClinicalSpace.sm),
                    Text(
                      'Day-by-day schedule, half-life maths, MAOI '
                      'washout, citations — all in one tap.',
                      style: ClinicalText.body.copyWith(
                        color: ClinicalPalette.toneLavenderInk
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              ProgressRing(
                value: 1,
                label: '$drugCount',
                size: 56,
                thickness: 5,
                tone: ClinicalPalette.toneLavenderInk,
                labelStyle: const TextStyle(
                  color: ClinicalPalette.toneLavenderInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.xl),
          Row(
            children: <Widget>[
              PillButton(
                label: 'Start a switch',
                icon: Icons.arrow_forward,
                onPressed: () => context.pushNamed(Routes.switch_),
              ),
              const SizedBox(width: ClinicalSpace.sm + 2),
              GhostPillButton(
                label: 'History',
                onPressed: () => context.pushNamed(Routes.history),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            '$drugCount drugs · $ruleCount rules · Maudsley 15th ed.',
            style: ClinicalText.caption.copyWith(
              color: ClinicalPalette.toneLavenderInk.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ───────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const items = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.compare_arrows,
        label: 'Compare',
        tone: ClinicalPalette.toneSky,
        ink: ClinicalPalette.toneSkyInk,
        route: Routes.compare,
      ),
      _QuickActionData(
        icon: Icons.medication_outlined,
        label: 'Regimen',
        tone: ClinicalPalette.tonePeach,
        ink: ClinicalPalette.tonePeachInk,
        route: Routes.polypharmacy,
      ),
      _QuickActionData(
        icon: Icons.calculate_outlined,
        label: 'Calculate',
        tone: ClinicalPalette.toneMint,
        ink: ClinicalPalette.toneMintInk,
        route: Routes.calculators,
      ),
      _QuickActionData(
        icon: Icons.health_and_safety_outlined,
        label: 'AE lookup',
        tone: ClinicalPalette.toneRose,
        ink: ClinicalPalette.toneRoseInk,
        route: Routes.adverseEffects,
      ),
    ];
    return Row(
      children: <Widget>[
        for (var i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: ClinicalSpace.sm),
          Expanded(
            child: ToneTile(
              icon: items[i].icon,
              label: items[i].label,
              tone: items[i].tone,
              ink: items[i].ink,
              onTap: () => context.pushNamed(items[i].route),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.tone,
    required this.ink,
    required this.route,
  });
  final IconData icon;
  final String label;
  final Color tone;
  final Color ink;
  final String route;
}

// ── Section label ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tagline});
  final String label;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: ClinicalSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: ClinicalText.title),
          if (tagline != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(tagline!, style: ClinicalText.caption),
          ],
        ],
      ),
    );
  }
}

// ── Category grid ───────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    const items = <_CategoryData>[
      _CategoryData(
        label: 'Antidepressants',
        sub: 'SSRI · SNRI · TCA · MAOI',
        icon: Icons.brightness_low,
        tone: ClinicalPalette.toneLavender,
        ink: ClinicalPalette.toneLavenderInk,
        route: Routes.equivalency,
      ),
      _CategoryData(
        label: 'Antipsychotics',
        sub: 'Typical · atypical · LAI',
        icon: Icons.bubble_chart_outlined,
        tone: ClinicalPalette.tonePeach,
        ink: ClinicalPalette.tonePeachInk,
        route: Routes.equivalency,
      ),
      _CategoryData(
        label: 'Mood stabilisers',
        sub: 'Lithium · valproate · lamotrigine',
        icon: Icons.balance_outlined,
        tone: ClinicalPalette.toneMint,
        ink: ClinicalPalette.toneMintInk,
        route: Routes.moodStabilizers,
      ),
      _CategoryData(
        label: 'Clozapine',
        sub: 'Titration · ANC · myocarditis',
        icon: Icons.local_hospital_outlined,
        tone: ClinicalPalette.toneRose,
        ink: ClinicalPalette.toneRoseInk,
        route: Routes.clozapine,
      ),
    ];

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _CategoryCard(data: items[0])),
            const SizedBox(width: ClinicalSpace.sm + 2),
            Expanded(child: _CategoryCard(data: items[1])),
          ],
        ),
        const SizedBox(height: ClinicalSpace.sm + 2),
        Row(
          children: <Widget>[
            Expanded(child: _CategoryCard(data: items[2])),
            const SizedBox(width: ClinicalSpace.sm + 2),
            Expanded(child: _CategoryCard(data: items[3])),
          ],
        ),
      ],
    );
  }
}

class _CategoryData {
  const _CategoryData({
    required this.label,
    required this.sub,
    required this.icon,
    required this.tone,
    required this.ink,
    required this.route,
  });
  final String label;
  final String sub;
  final IconData icon;
  final Color tone;
  final Color ink;
  final String route;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.data});
  final _CategoryData data;

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      tone: data.tone,
      onTap: () => context.pushNamed(data.route),
      padding: const EdgeInsets.all(ClinicalSpace.lg),
      radius: ClinicalRadii.tile + 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            ),
            child: Icon(data.icon, size: 20, color: data.ink),
          ),
          const SizedBox(height: ClinicalSpace.md + 2),
          Text(
            data.label,
            style: ClinicalText.subtitle.copyWith(
              color: data.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            style: ClinicalText.caption.copyWith(
              color: data.ink.withValues(alpha: 0.75),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Reference rail ──────────────────────────────────────────────────

class _ReferenceRail extends StatelessWidget {
  const _ReferenceRail();

  @override
  Widget build(BuildContext context) {
    const rows = <_RailRow>[
      _RailRow(
        label: 'QTc stacker',
        sub: 'Aggregate QTc risk',
        icon: Icons.monitor_heart_outlined,
        route: Routes.qtcStacker,
      ),
      _RailRow(
        label: 'Depot LAI',
        sub: 'Long-acting injectable protocols',
        icon: Icons.vaccines_outlined,
        route: Routes.depotIndex,
      ),
      _RailRow(
        label: 'Halal & Ramadan',
        sub: 'Fasting-window dosing',
        icon: Icons.dark_mode_outlined,
        route: Routes.ramadan,
      ),
      _RailRow(
        label: 'Glossary',
        sub: 'Clinical-term lookup',
        icon: Icons.menu_book_outlined,
        route: Routes.glossary,
      ),
      _RailRow(
        label: 'Errata',
        sub: 'Content corrections',
        icon: Icons.fact_check_outlined,
        route: Routes.errata,
      ),
      _RailRow(
        label: 'About',
        sub: 'Version · licences',
        icon: Icons.info_outline,
        route: Routes.about,
      ),
    ];
    return SquircleCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: ClinicalSpace.lg + 4 + 30 + ClinicalSpace.md,
                color: ClinicalPalette.border,
              ),
            _RailRowView(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _RailRow {
  const _RailRow({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
  });
  final String label;
  final String sub;
  final IconData icon;
  final String route;
}

class _RailRowView extends StatelessWidget {
  const _RailRowView({required this.row});
  final _RailRow row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(row.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.lg + 4,
          vertical: ClinicalSpace.md + 2,
        ),
        child: Row(
          children: <Widget>[
            Icon(row.icon, size: 20, color: ClinicalPalette.mutedStrong),
            const SizedBox(width: ClinicalSpace.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(row.label, style: ClinicalText.subtitle),
                  Text(row.sub, style: ClinicalText.caption),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: ClinicalPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClinicalSpace.lg),
        child: Text(
          'PsychSwitch · Decision support for licensed clinicians.\n'
          'Always confirm with the most current product label.',
          textAlign: TextAlign.center,
          style: ClinicalText.caption.copyWith(
            color: ClinicalPalette.muted,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
