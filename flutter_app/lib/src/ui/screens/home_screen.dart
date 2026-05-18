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
import 'package:psychswitch/src/providers/preferences_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/switching_engine.dart' show SwitchInput;

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

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.drugCount, required this.ruleCount});

  final int drugCount;
  final int ruleCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final nameAsync = ref.watch(clinicianNameProvider);
    final name = nameAsync.maybeWhen(data: (n) => n, orElse: () => '');
    final salutation = clinicianSalutation(name);
    final initials = clinicianInitials(name);

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
              _Greeting(
                greeting: greeting,
                salutation: salutation,
                initials: initials,
              ),
              const SizedBox(height: ClinicalSpace.lg + 4),
              const _SearchField(),
              const SizedBox(height: ClinicalSpace.lg),
              _Hero(drugCount: drugCount, ruleCount: ruleCount),
              const SizedBox(height: ClinicalSpace.lg),
              const _RecentCasesStrip(),
              const _PearlCard(),
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
  const _Greeting({
    required this.greeting,
    required this.salutation,
    required this.initials,
  });
  final String greeting;
  final String salutation;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AvatarCircle(initials: initials),
        const SizedBox(width: ClinicalSpace.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$greeting, $salutation',
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

// ── Recent cases strip ──────────────────────────────────────────────

/// Horizontal mini-strip of the three most-recent saved cases. Hides
/// itself silently when there are no cases (so first-launch and clean
/// installs don't show an empty row).
class _RecentCasesStrip extends ConsumerWidget {
  const _RecentCasesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedCasesProvider);
    final cases = async.maybeWhen(
      data: (list) => list.take(3).toList(),
      orElse: () => const <SavedCase>[],
    );
    if (cases.isEmpty) return const SizedBox.shrink();

    final engineAsync = ref.watch(engineProvider);
    final engine = engineAsync.maybeWhen(
      data: (e) => e,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: ClinicalSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: ClinicalSpace.xs,
              bottom: ClinicalSpace.md,
            ),
            child: Row(
              children: <Widget>[
                const Text('Recent cases', style: ClinicalText.title),
                const Spacer(),
                InkWell(
                  onTap: () => context.pushNamed(Routes.history),
                  borderRadius:
                      BorderRadius.circular(ClinicalRadii.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClinicalSpace.sm,
                      vertical: 4,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'All',
                          style: ClinicalText.caption.copyWith(
                            color: ClinicalPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right,
                            size: 14, color: ClinicalPalette.text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              for (var i = 0; i < cases.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: ClinicalSpace.sm + 2),
                Expanded(
                  child: _RecentCaseTile(
                    savedCase: cases[i],
                    fromName: engine?.getDrug(cases[i].fromDrugId)?.genericName ??
                        cases[i].fromDrugId,
                    toName: engine?.getDrug(cases[i].toDrugId)?.genericName ??
                        cases[i].toDrugId,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentCaseTile extends StatelessWidget {
  const _RecentCaseTile({
    required this.savedCase,
    required this.fromName,
    required this.toName,
  });

  final SavedCase savedCase;
  final String fromName;
  final String toName;

  /// Pick a tone family per case position so the strip reads as three
  /// distinct cards (lavender / mint / peach in rotation).
  static const _tones = <({Color tone, Color ink})>[
    (tone: ClinicalPalette.toneLavender, ink: ClinicalPalette.toneLavenderInk),
    (tone: ClinicalPalette.toneMint, ink: ClinicalPalette.toneMintInk),
    (tone: ClinicalPalette.tonePeach, ink: ClinicalPalette.tonePeachInk),
  ];

  String _ago(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    if (diff < 30) return '${(diff / 7).floor()}w ago';
    return '${(diff / 30).floor()}mo ago';
  }

  String _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _tones[int.parse(_hash(savedCase.id)) % _tones.length];
    return SquircleCard(
      tone: palette.tone,
      radius: ClinicalRadii.tile,
      padding: const EdgeInsets.all(ClinicalSpace.md),
      onTap: () => context.pushNamed(
        Routes.result,
        extra: ResultScreenArgs(
          input: SwitchInput(
            fromDrugId: savedCase.fromDrugId,
            fromDoseMg: savedCase.fromDoseMg,
            toDrugId: savedCase.toDrugId,
            toDoseMg: savedCase.toDoseMg,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.swap_horiz_rounded,
                  size: 14, color: palette.ink.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _ago(savedCase.updatedISO),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: palette.ink.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.sm),
          Text(
            fromName,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.ink,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '→ $toName',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.ink,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Today's pearl ───────────────────────────────────────────────────

/// One bite of Maudsley-derived clinical wisdom, rotated daily.
///
/// Deterministic by date so two devices on the same day see the same
/// pearl — the clinician can mention it to a colleague and they'll
/// recognise it.
class _PearlCard extends StatelessWidget {
  const _PearlCard();

  static const List<({String title, String body, String source})> _pearls =
      <({String title, String body, String source})>[
    (
      title: 'Fluoxetine washout',
      body:
          'Allow at least 5 weeks off fluoxetine before starting an '
              'MAOI — its long-acting metabolite norfluoxetine has a '
              'half-life of 7–15 days.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Clozapine missed doses',
      body:
          'After ≥48 h off clozapine, restart from 12.5 mg and re-titrate. '
              'Tolerance is rapidly lost; the original dose can precipitate '
              'severe orthostasis or sedation.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Lithium + ACE inhibitors',
      body:
          'Adding an ACE inhibitor can raise lithium levels by 30–40%. '
              'Recheck a level within 5–7 days and dose-reduce lithium '
              'pre-emptively in the elderly.',
      source: 'Stahl, 7e',
    ),
    (
      title: 'Paroxetine discontinuation',
      body:
          'Of the SSRIs, paroxetine has the highest discontinuation-syndrome '
              'risk owing to its short half-life and potent muscarinic '
              'rebound. Taper over ≥ 4 weeks; consider fluoxetine bridge.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Valproate in women of childbearing age',
      body:
          'Valproate is teratogenic and neurodevelopmentally toxic — avoid '
              'unless there is no effective alternative AND a '
              'pregnancy-prevention plan is documented.',
      source: 'MHRA Toolkit',
    ),
    (
      title: 'Olanzapine + smoking cessation',
      body:
          'Stopping smoking raises olanzapine and clozapine levels by '
              '~50% via CYP1A2 de-induction. Recheck levels within 1–2 '
              'weeks of cessation and consider a 25–50% dose reduction.',
      source: 'Stahl, 7e',
    ),
    (
      title: 'Aripiprazole partial agonism',
      body:
          'Cross-titrating onto aripiprazole from a full D2 antagonist '
              'can unmask dopaminergic rebound (akathisia, agitation). '
              'Slow the taper of the outgoing drug to mitigate.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Mirtazapine + sedation paradox',
      body:
          'At 15 mg mirtazapine is more sedating than at 45 mg — higher '
              'doses recruit noradrenergic activity that offsets the H1 '
              'antihistamine effect. Up-titrate to fix daytime drowsiness.',
      source: 'Stahl, 7e',
    ),
    (
      title: 'Quetiapine QTc',
      body:
          'Quetiapine has a dose-dependent QTc effect that becomes '
              'meaningful above 600 mg/day; combine with citalopram and '
              'the additive risk crosses clinically significant thresholds.',
      source: 'CredibleMeds',
    ),
    (
      title: 'SSRI bleeding risk',
      body:
          'Co-prescribed SSRI + NSAID raises GI bleed risk 4–5×. '
              'Consider a PPI, especially in patients > 65 or on '
              'anticoagulants.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Lamotrigine titration',
      body:
          'Slow up-titration (25 mg/day for weeks 1-2, then 50 mg/day for '
              'weeks 3-4) is non-negotiable — fast titration drives the '
              'Stevens-Johnson rate from 1:10,000 to 1:300.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'NaSSA + SSRI combo',
      body:
          'Mirtazapine + SSRI ("California rocket fuel") can be more '
              'effective than monotherapy, but watch for sedation, weight '
              'gain, and rare serotonin-syndrome reports at high SSRI '
              'doses.',
      source: 'Stahl, 7e',
    ),
    (
      title: 'Metformin for AP weight gain',
      body:
          'Metformin can blunt antipsychotic-induced weight gain by '
              '3–5 kg over 12 weeks, especially in olanzapine/clozapine '
              'users. Start at 500 mg BD with food.',
      source: 'BMJ Open 2022',
    ),
    (
      title: 'Carbamazepine auto-induction',
      body:
          'CBZ induces its own CYP3A4 metabolism over the first 2–4 '
              'weeks — expect serum levels to fall after the first '
              'dose-target hit, then re-uptitrate.',
      source: 'Maudsley 15th ed.',
    ),
    (
      title: 'Hyponatraemia with SSRIs',
      body:
          'SSRI-induced SIADH typically appears in the first 2–4 weeks. '
              'Check sodium at baseline and at week 2 in patients ≥ 65 '
              'or on diuretics.',
      source: 'Maudsley 15th ed.',
    ),
  ];

  static ({String title, String body, String source}) _pearlOfTheDay() {
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year)).inDays;
    return _pearls[dayOfYear % _pearls.length];
  }

  @override
  Widget build(BuildContext context) {
    final p = _pearlOfTheDay();
    return SquircleCard(
      tone: ClinicalPalette.toneSand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              TonePill(
                label: "Today's pearl",
                tone: Color(0xFFFFFFFF),
                ink: ClinicalPalette.toneSandInk,
              ),
              Spacer(),
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: ClinicalPalette.toneSandInk,
              ),
            ],
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            p.title,
            style: ClinicalText.subtitle.copyWith(
              color: ClinicalPalette.toneSandInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: ClinicalSpace.xs + 2),
          Text(
            p.body,
            style: ClinicalText.body.copyWith(
              color: ClinicalPalette.toneSandInk.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
          const SizedBox(height: ClinicalSpace.md),
          Text(
            p.source,
            style: ClinicalText.caption.copyWith(
              color: ClinicalPalette.toneSandInk.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
        label: 'Rating scales',
        sub: '17 scales — PHQ-2/9 · GAD-2/7 · MADRS · HAM · CIWA · COWS · CAGE-AID · Mini-Cog · more',
        icon: Icons.assignment_turned_in_outlined,
        route: Routes.scales,
      ),
      _RailRow(
        label: 'Lab interpreter',
        sub: 'TSH · prolactin · ANC · sodium · CK · HbA1c · more',
        icon: Icons.biotech_outlined,
        route: Routes.lab,
      ),
      _RailRow(
        label: 'Movement disorder',
        sub: 'EPS differentiator — parkinsonism · dystonia · akathisia · TD',
        icon: Icons.accessibility_new,
        route: Routes.movement,
      ),
      _RailRow(
        label: 'Agitation management',
        sub: 'De-escalation · oral PRN · IM rapid tranquillisation',
        icon: Icons.flash_on_outlined,
        route: Routes.agitation,
      ),
      _RailRow(
        label: 'C-SSRS suicide screen',
        sub: 'Columbia severity + risk tier',
        icon: Icons.emergency_outlined,
        route: Routes.cssrs,
      ),
      _RailRow(
        label: 'NMS screener',
        sub: 'Levenson criteria — neuroleptic malignant syndrome',
        icon: Icons.local_fire_department_outlined,
        route: Routes.nms,
      ),
      _RailRow(
        label: 'Serotonin syndrome',
        sub: 'Hunter toxicity criteria',
        icon: Icons.bolt_outlined,
        route: Routes.serotonin,
      ),
      _RailRow(
        label: 'TDM interpreter',
        sub: 'Lithium · clozapine · valproate · lamotrigine',
        icon: Icons.science_outlined,
        route: Routes.tdm,
      ),
      _RailRow(
        label: 'AD deprescribing',
        sub: 'Hyperbolic taper planner (Maudsley method)',
        icon: Icons.trending_down,
        route: Routes.deprescribing,
      ),
      _RailRow(
        label: 'Benzo taper',
        sub: 'Diazepam-equivalent + Ashton schedule',
        icon: Icons.trending_down,
        route: Routes.benzoTaper,
      ),
      _RailRow(
        label: '4AT delirium',
        sub: 'Rapid delirium assessment (Bellelli 2014)',
        icon: Icons.psychology_alt_outlined,
        route: Routes.delirium4at,
      ),
      _RailRow(
        label: 'Catatonia screen',
        sub: 'Bush-Francis + lorazepam challenge',
        icon: Icons.accessibility_new,
        route: Routes.catatonia,
      ),
      _RailRow(
        label: 'Hyperthermic Dx',
        sub: 'NMS vs serotonin vs catatonia vs anticholinergic',
        icon: Icons.local_fire_department_outlined,
        route: Routes.hyperthermicDx,
      ),
      _RailRow(
        label: 'Lithium toxicity',
        sub: 'Graded management + dialysis criteria',
        icon: Icons.science_outlined,
        route: Routes.lithiumToxicity,
      ),
      _RailRow(
        label: 'Alcohol withdrawal',
        sub: 'CIWA-driven regimen + thiamine plan',
        icon: Icons.local_bar_outlined,
        route: Routes.alcoholWithdrawal,
      ),
      _RailRow(
        label: 'OST induction',
        sub: 'Buprenorphine / methadone day-1 protocol',
        icon: Icons.medication_liquid_outlined,
        route: Routes.ostInduction,
      ),
      _RailRow(
        label: 'Wernicke / thiamine',
        sub: 'Prophylaxis vs treatment dosing',
        icon: Icons.vaccines_outlined,
        route: Routes.thiamine,
      ),
      _RailRow(
        label: 'Hyponatraemia / SIADH',
        sub: 'Sodium + symptom-graded plan, correction cap',
        icon: Icons.water_drop_outlined,
        route: Routes.hyponatraemia,
      ),
      _RailRow(
        label: 'Hyperprolactinaemia',
        sub: 'Prolactin band + prolactinoma threshold',
        icon: Icons.science_outlined,
        route: Routes.hyperprolactinaemia,
      ),
      _RailRow(
        label: 'Clozapine myocarditis',
        sub: 'First-weeks troponin/CRP surveillance + triage',
        icon: Icons.monitor_heart_outlined,
        route: Routes.clozapineMyocarditis,
      ),
      _RailRow(
        label: 'Valproate PPP',
        sub: 'Pregnancy Prevention Programme prescribing gate',
        icon: Icons.pregnant_woman_outlined,
        route: Routes.valproatePpp,
      ),
      _RailRow(
        label: 'Olanzapine LAI — PDSS',
        sub: 'Post-injection observation + delirium triage',
        icon: Icons.timer_outlined,
        route: Routes.postInjectionSyndrome,
      ),
      _RailRow(
        label: 'Opioid overdose',
        sub: 'Naloxone + airway + re-narcotisation net',
        icon: Icons.emergency_outlined,
        route: Routes.opioidOverdose,
      ),
      _RailRow(
        label: 'Pre-stimulant cardiac',
        sub: 'ADHD cardiovascular screening gate',
        icon: Icons.favorite_border,
        route: Routes.stimulantCardiac,
      ),
      _RailRow(
        label: 'ECT work-up',
        sub: 'Pre-ECT checklist + drug-interaction review',
        icon: Icons.electric_bolt_outlined,
        route: Routes.ectWorkup,
      ),
      _RailRow(
        label: 'MAOI diet',
        sub: 'Tyramine food tiers + crisis script',
        icon: Icons.restaurant_outlined,
        route: Routes.maoiDiet,
      ),
      _RailRow(
        label: 'Refeeding risk',
        sub: 'NICE criteria + feeding / monitoring plan',
        icon: Icons.monitor_weight_outlined,
        route: Routes.refeeding,
      ),
      _RailRow(
        label: 'Renal & hepatic dosing',
        sub: 'eGFR / Child-Pugh adjustment reference',
        icon: Icons.water_drop_outlined,
        route: Routes.renalHepatic,
      ),
      _RailRow(
        label: 'Pharmacogenomics',
        sub: 'CYP2D6 / CYP2C19 dosing implications',
        icon: Icons.biotech_outlined,
        route: Routes.pharmacogenomics,
      ),
      _RailRow(
        label: 'Metabolic monitoring',
        sub: 'Antipsychotic monitoring calendar',
        icon: Icons.event_available_outlined,
        route: Routes.metabolicMonitoring,
      ),
      _RailRow(
        label: 'Smoking & CYP1A2',
        sub: 'Clozapine / olanzapine dose adjustment',
        icon: Icons.smoke_free,
        route: Routes.smokingAdjustment,
      ),
      _RailRow(
        label: 'Capacity assessment',
        sub: 'Four-limb ACE evaluation',
        icon: Icons.balance,
        route: Routes.capacity,
      ),
      _RailRow(
        label: 'Clinician self-care',
        sub: 'Weekly burnout check · for you',
        icon: Icons.favorite_border,
        route: Routes.selfCare,
      ),
      _RailRow(
        label: 'MSE generator',
        sub: 'Tap anchors · paste-ready paragraph',
        icon: Icons.edit_note_rounded,
        route: Routes.mse,
      ),
      _RailRow(
        label: 'Crisis + safety plan',
        sub: 'Talian Kasih · Befrienders · Stanley-Brown',
        icon: Icons.phone_in_talk,
        route: Routes.crisis,
      ),
      _RailRow(
        label: 'MHA 2001 (MY)',
        sub: 'Sections · durations · forms',
        icon: Icons.gavel_outlined,
        route: Routes.mha,
      ),
      _RailRow(
        label: 'DSM-5-TR criteria',
        sub: 'Tick-box criterion sets · live tally',
        icon: Icons.checklist_rounded,
        route: Routes.dsm,
      ),
      _RailRow(
        label: 'Pregnancy & lactation',
        sub: 'Per-drug perinatal safety atlas',
        icon: Icons.pregnant_woman,
        route: Routes.perinatal,
      ),
      _RailRow(
        label: 'STOPP / START',
        sub: 'Geriatric deprescribing prompts',
        icon: Icons.elderly,
        route: Routes.stoppStart,
      ),
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
