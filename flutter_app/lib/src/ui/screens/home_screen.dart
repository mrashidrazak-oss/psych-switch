// Home screen — the app's entry surface. Rebuilt from scratch
// 2026-05-23 to drop the staged-launch alternative branches (1,300+
// lines of widgets never rendered because LaunchGate.staged is always
// true today) and tighten the visual rhythm of what actually ships.
//
// Architecture:
//   - HomeScreen    Route widget. Wraps body in the Clinical Light
//                   theme + handles the engine FutureProvider's
//                   loading / error states.
//   - _HomeBody     Receives the resolved engine + clinician name +
//                   role; lays out the sectioned page.
//
// Sections (top → bottom):
//   1. _Greeting       Avatar (tap → Settings) + greeting + subtitle.
//   2. _NamePrompt     Soft "Add your name" fade-in if name is empty.
//   3. _SearchField    Tappable search pill → /search.
//   4. _Hero           Switch-wizard CTA + drug-count ring + body
//                      that names the Maudsley 15th source inline.
//   5. _SectionLabel   "Clinical tools" + tagline.
//   6. _LaunchRail     The 5 staged clinical tools (tone-tinted).
//   7. _RecentCases    AnimatedSwitcher: empty hides, populated
//                      reveals 3-tile horizontal strip.
//   8. _PearlCard      Today's pearl, breathing 0.5% scale loop.
//   9. _Footer         Brand line + clinician disclaimer.
//
// Motion language:
//   - Sections cascade-in (60ms stagger) on first paint via
//     EntranceFade.
//   - Drug count ticks 0 → N over 900ms via TweenAnimationBuilder.
//   - Pearl card breathes via Breath primitive.
//   - Every tappable inherits the global PressScale baked into the
//     primitives (SquircleCard / PillButton / GhostPillButton / ToneTile).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/providers/preferences_provider.dart';
import 'package:psychswitch/src/providers/saved_cases_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/widgets/breath.dart';
import 'package:psychswitch/src/ui/widgets/clinical_primitives.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/switching_engine.dart'
    show SwitchInput, SwitchingEngine;

/// Maximum content-column width. Anything wider gets flanked by white-
/// space so the primary CTA never stretches across a 7.6" foldable.
const double _kMaxContentWidth = 640;

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
    final name = ref
        .watch(clinicianNameProvider)
        .maybeWhen(data: (n) => n, orElse: () => '');
    final salutation = clinicianSalutation(name);
    final initials = clinicianInitials(name);
    final role = ref
        .watch(clinicianRoleProvider)
        .maybeWhen(data: (r) => r, orElse: () => '')
        .trim();
    final subtitle = role.isEmpty ? 'Healthcare professional' : role;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
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
              // New angle: a temporal anchor above the greeting.
              // Eyebrow-styled date stamp gives clinicians orientation
              // for note-writing and scan-by-date workflows.
              const EntranceFade(child: _DateEyebrow()),
              const SizedBox(height: ClinicalSpace.sm),
              EntranceFade(
                index: 1,
                child: _Greeting(
                  greeting: greeting,
                  salutation: salutation,
                  subtitle: subtitle,
                  initials: initials,
                ),
              ),
              if (name.trim().isEmpty) ...<Widget>[
                const SizedBox(height: ClinicalSpace.sm + 2),
                const _NamePrompt(),
              ],
              const SizedBox(height: ClinicalSpace.lg + 4),
              const EntranceFade(index: 2, child: _SearchField()),
              const SizedBox(height: ClinicalSpace.lg),
              EntranceFade(
                index: 3,
                child: _Hero(drugCount: drugCount, ruleCount: ruleCount),
              ),
              const SizedBox(height: ClinicalSpace.lg),
              // Recent cases promoted ABOVE the tools rail. Returning
              // users see their continuation surface first; new users
              // (empty recents) see the rail directly since recents
              // collapses to a zero-height SizedBox.
              const EntranceFade(index: 4, child: _RecentCases()),
              const EntranceFade(
                index: 5,
                child: _SectionLabel(
                  label: 'Clinical tools',
                  tagline:
                      'Reviewed against Maudsley 15th and primary literature',
                ),
              ),
              const SizedBox(height: ClinicalSpace.md),
              const EntranceFade(index: 6, child: _LaunchRail()),
              const SizedBox(height: ClinicalSpace.lg),
              const EntranceFade(
                index: 7,
                child: Breath(child: _PearlCard()),
              ),
              const SizedBox(height: ClinicalSpace.xl),
              const EntranceFade(index: 8, child: _Footer()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date eyebrow ────────────────────────────────────────────────────

/// Small all-caps date stamp above the greeting — gives the clinician
/// temporal orientation ("today is Tuesday, 23 May") for note-writing
/// and date-anchored scanning. Muted, eyebrow-style, never competes
/// with the greeting for primary attention.
class _DateEyebrow extends StatelessWidget {
  const _DateEyebrow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = DateFormat('EEEE · d MMM').format(now).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(left: ClinicalSpace.xs),
      child: Text(label, style: ClinicalText.eyebrow),
    );
  }
}

// ── Greeting ────────────────────────────────────────────────────────

/// Greeting row — avatar bubble (tap → Settings) + two-line text block.
/// No icon-bubble cluster: the single avatar tap is the discoverable
/// affordance to settings; clean header, no chrome competing with the
/// time-of-day greeting.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.salutation,
    required this.subtitle,
    required this.initials,
  });

  final String greeting;
  final String salutation;
  final String subtitle;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Edit your profile',
          child: InkResponse(
            onTap: () => context.pushNamed(Routes.settings),
            radius: 28,
            child: AvatarCircle(initials: initials),
          ),
        ),
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
              Text(
                subtitle,
                style: ClinicalText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Name prompt ─────────────────────────────────────────────────────

/// Soft "Add your name" affordance, surfaced beneath the greeting only
/// while the clinician hasn't entered a name. Fades in 2s after Home
/// arrives so it doesn't compete with the cascade entrance — suggests
/// rather than nags. Disappears the instant a name is saved.
class _NamePrompt extends StatefulWidget {
  const _NamePrompt();

  @override
  State<_NamePrompt> createState() => _NamePromptState();
}

class _NamePromptState extends State<_NamePrompt> {
  double _opacity = 0;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Aligned under the greeting text column, past the avatar gutter.
      padding: const EdgeInsets.only(left: 60),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        opacity: _opacity,
        child: InkWell(
          onTap: () => context.pushNamed(Routes.settings),
          borderRadius: BorderRadius.circular(ClinicalRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.sm,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Add your name',
                  style: ClinicalText.caption.copyWith(
                    color: ClinicalPalette.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: ClinicalPalette.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search ──────────────────────────────────────────────────────────

/// Search pill — tappable, navigates to the global search screen.
/// Looks like a text field but is a button; gives the field its
/// visual prominence without forcing the user to focus it before
/// typing (search route opens a focused input).
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
            const Icon(
              Icons.search,
              size: 20,
              color: ClinicalPalette.mutedStrong,
            ),
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

/// The primary action surface. Lavender tone, switch-wizard pill,
/// CTA copy + body, drug-count ticker on the right, and primary +
/// secondary pill buttons. The Maudsley 15th citation is now woven
/// into the body sentence instead of a separate signal line under
/// the buttons — one fewer text node, the citation reads as part of
/// what the wizard does.
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
                      'washout — reviewed against Maudsley 15th ed.',
                      style: ClinicalText.body.copyWith(
                        color: ClinicalPalette.toneLavenderInk
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClinicalSpace.md),
              // Drug-count ring — wrapped in a Semantics so VoiceOver
              // hears "165 drugs reviewed" as one fact instead of
              // separate "165" + "DRUGS" fragments. Ring + label
              // are decorative; the synthesised label is the truth.
              Semantics(
                label: '$drugCount drugs · $ruleCount rules reviewed',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: drugCount.toDouble(),
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => ProgressRing(
                        value: 1,
                        label: '${value.round()}',
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
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DRUGS',
                      style: TextStyle(
                        color: ClinicalPalette.toneLavenderInk
                            .withValues(alpha: 0.75),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }
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

// ── Launch rail ─────────────────────────────────────────────────────

/// Curated 5-tool rail. Each row: tone-tinted badge icon + label +
/// sub + chevron. Rows are tapped via the underlying InkWell; the
/// PressScale baked into the InkWell ripple gives the same tactile
/// feedback as every other surface in the app.
class _LaunchRail extends StatelessWidget {
  const _LaunchRail();

  static const _rows = <_RailRow>[
    _RailRow(
      label: 'Dose equivalency',
      sub: 'Chlorpromazine / olanzapine & antidepressant equivalents',
      icon: Icons.balance_outlined,
      route: Routes.equivalency,
      tone: ClinicalPalette.accent,
    ),
    _RailRow(
      label: 'Adverse-effect profile',
      sub: 'Predicted AE burden + management by drug',
      icon: Icons.health_and_safety_outlined,
      route: Routes.adverseEffects,
      tone: ClinicalPalette.warning,
    ),
    _RailRow(
      label: 'Interactions & burden',
      sub: 'Drug-drug interactions + sedative/anticholinergic load',
      icon: Icons.account_tree_outlined,
      route: Routes.polypharmacy,
      tone: ClinicalPalette.accent,
    ),
    _RailRow(
      label: 'Clozapine',
      sub: 'Titration · FBC schedule · ANC zone · rechallenge',
      icon: Icons.local_hospital_outlined,
      route: Routes.clozapine,
      tone: ClinicalPalette.warning,
    ),
    _RailRow(
      label: 'Rating scales',
      sub: '17 scales — PHQ · GAD · MADRS · HAM · CIWA · COWS · more',
      icon: Icons.assignment_turned_in_outlined,
      route: Routes.scales,
      tone: ClinicalPalette.toneSkyInk,
    ),
    _RailRow(
      label: 'Suicide risk assessment',
      sub: 'C-SSRS + risk/protective factors → tier + disposition',
      icon: Icons.emergency_outlined,
      route: Routes.suicideRisk,
      tone: ClinicalPalette.danger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SquircleCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < _rows.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                // Indent past the 38pt badge + its trailing gap so the
                // divider visually separates the text columns only.
                indent: ClinicalSpace.lg + 4 + 38 + ClinicalSpace.md + 2,
                color: ClinicalPalette.border,
              ),
            _RailRowView(row: _rows[i]),
          ],
        ],
      ),
    );
  }
}

/// Immutable row data — keeps `_LaunchRail._rows` a single
/// declarative constant list.
class _RailRow {
  const _RailRow({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.tone,
  });

  final String label;
  final String sub;
  final IconData icon;
  final String route;

  /// Identity tone — the rail row's badge tints to this, echoing the
  /// destination screen's ToolHero so the user sees colour continuity
  /// from tap to arrival.
  final Color tone;
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
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: row.tone.withValues(alpha: 0.12),
                border: Border.all(
                  color: row.tone.withValues(alpha: 0.34),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(ClinicalRadii.chip),
              ),
              child: Icon(row.icon, size: 19, color: row.tone),
            ),
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

// ── Recent cases ────────────────────────────────────────────────────

/// Horizontal strip of the three most-recent saved cases. Hides
/// itself silently when the list is empty (so first-launch shows no
/// dead slot); animates open the moment the first case is saved
/// thanks to the AnimatedSwitcher empty/populated keying.
class _RecentCases extends ConsumerWidget {
  const _RecentCases();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(savedCasesProvider).maybeWhen(
          data: (list) => list.take(3).toList(),
          orElse: () => const <SavedCase>[],
        );
    final engine = ref.watch(engineProvider).maybeWhen(
          data: (e) => e,
          orElse: () => null,
        );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          axisAlignment: -1,
          sizeFactor: animation,
          child: child,
        ),
      ),
      child: cases.isEmpty
          ? const SizedBox.shrink(key: ValueKey<String>('empty'))
          : _RecentCasesPopulated(
              key: const ValueKey<String>('populated'),
              cases: cases,
              engine: engine,
            ),
    );
  }
}

class _RecentCasesPopulated extends StatelessWidget {
  const _RecentCasesPopulated({
    required this.cases,
    required this.engine,
    super.key,
  });

  final List<SavedCase> cases;
  final SwitchingEngine? engine;

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: BorderRadius.circular(ClinicalRadii.pill),
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
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: ClinicalPalette.text,
                        ),
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
                    fromName:
                        engine?.getDrug(cases[i].fromDrugId)?.genericName ??
                            cases[i].fromDrugId,
                    toName:
                        engine?.getDrug(cases[i].toDrugId)?.genericName ??
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

  /// Per-position tone rotation so the strip reads as three distinct
  /// cards (lavender / mint / peach), not three copies.
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

  int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _tones[_hash(savedCase.id) % _tones.length];
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
              Icon(
                Icons.swap_horiz_rounded,
                size: 14,
                color: palette.ink.withValues(alpha: 0.7),
              ),
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

/// A single bite of Maudsley-derived clinical wisdom, rotated daily.
/// Deterministic by day-of-year so two devices on the same day see
/// the same pearl — a clinician can mention "today's pearl" to a
/// colleague and have them recognise it.
class _PearlCard extends StatelessWidget {
  const _PearlCard();

  static const _pearls = <_Pearl>[
    _Pearl(
      title: 'Fluoxetine washout',
      body: 'Allow at least 5 weeks off fluoxetine before starting an '
          'MAOI — its long-acting metabolite norfluoxetine has a '
          'half-life of 7-15 days.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Clozapine missed doses',
      body: 'After ≥48 h off clozapine, restart from 12.5 mg and '
          're-titrate. Tolerance is rapidly lost; the original dose '
          'can precipitate severe orthostasis or sedation.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Lithium + ACE inhibitors',
      body: 'Adding an ACE inhibitor can raise lithium levels by '
          '30-40%. Recheck a level within 5-7 days and dose-reduce '
          'lithium pre-emptively in the elderly.',
      source: 'Stahl, 7e',
    ),
    _Pearl(
      title: 'Paroxetine discontinuation',
      body: 'Of the SSRIs, paroxetine has the highest '
          'discontinuation-syndrome risk owing to its short half-life '
          'and potent muscarinic rebound. Taper over ≥ 4 weeks; '
          'consider a fluoxetine bridge.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Valproate in women of childbearing age',
      body: 'Valproate is teratogenic and neurodevelopmentally toxic '
          '— avoid unless there is no effective alternative AND a '
          'pregnancy-prevention plan is documented.',
      source: 'MHRA Toolkit',
    ),
    _Pearl(
      title: 'Olanzapine + smoking cessation',
      body: 'Stopping smoking raises olanzapine and clozapine levels '
          'by ~50% via CYP1A2 de-induction. Recheck levels within 1-2 '
          'weeks of cessation and consider a 25-50% dose reduction.',
      source: 'Stahl, 7e',
    ),
    _Pearl(
      title: 'Aripiprazole partial agonism',
      body: 'Cross-titrating onto aripiprazole from a full D2 '
          'antagonist can unmask dopaminergic rebound (akathisia, '
          'agitation). Slow the taper of the outgoing drug to '
          'mitigate.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Mirtazapine + sedation paradox',
      body: 'At 15 mg mirtazapine is more sedating than at 45 mg — '
          'higher doses recruit noradrenergic activity that offsets '
          'the H1 antihistamine effect. Up-titrate to fix daytime '
          'drowsiness.',
      source: 'Stahl, 7e',
    ),
    _Pearl(
      title: 'Quetiapine QTc',
      body: 'Quetiapine has a dose-dependent QTc effect that becomes '
          'meaningful above 600 mg/day; combine with citalopram and '
          'the additive risk crosses clinically significant '
          'thresholds.',
      source: 'CredibleMeds',
    ),
    _Pearl(
      title: 'SSRI bleeding risk',
      body: 'Co-prescribed SSRI + NSAID raises GI bleed risk 4-5×. '
          'Consider a PPI, especially in patients > 65 or on '
          'anticoagulants.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Lamotrigine titration',
      body: 'Slow up-titration (25 mg/day for weeks 1-2, then '
          '50 mg/day for weeks 3-4) is non-negotiable — fast '
          'titration drives the Stevens-Johnson rate from 1:10,000 '
          'to 1:300.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'NaSSA + SSRI combo',
      body: 'Mirtazapine + SSRI ("California rocket fuel") can be '
          'more effective than monotherapy, but watch for sedation, '
          'weight gain, and rare serotonin-syndrome reports at high '
          'SSRI doses.',
      source: 'Stahl, 7e',
    ),
    _Pearl(
      title: 'Metformin for AP weight gain',
      body: 'Metformin can blunt antipsychotic-induced weight gain by '
          '3-5 kg over 12 weeks, especially in olanzapine/clozapine '
          'users. Start at 500 mg BD with food.',
      source: 'BMJ Open 2022',
    ),
    _Pearl(
      title: 'Carbamazepine auto-induction',
      body: 'CBZ induces its own CYP3A4 metabolism over the first '
          '2-4 weeks — expect serum levels to fall after the first '
          'dose-target hit, then re-uptitrate.',
      source: 'Maudsley 15th ed.',
    ),
    _Pearl(
      title: 'Hyponatraemia with SSRIs',
      body: 'SSRI-induced SIADH typically appears in the first 2-4 '
          'weeks. Check sodium at baseline and at week 2 in patients '
          '≥ 65 or on diuretics.',
      source: 'Maudsley 15th ed.',
    ),
  ];

  /// Deterministic pick by day-of-year so the same pearl shows for
  /// every device on a given calendar day.
  static _Pearl _pearlOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _pearls[dayOfYear % _pearls.length];
  }

  @override
  Widget build(BuildContext context) {
    final p = _pearlOfTheDay();
    // Synthesise the full pearl as one Semantics label so VoiceOver
    // reads it as a digestible unit, not four disconnected fragments.
    return Semantics(
      label: "Today's pearl. ${p.title}. ${p.body} Source: ${p.source}.",
      excludeSemantics: true,
      child: SquircleCard(
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
      ),
    );
  }
}

/// Immutable pearl record — keeps the pearls list a single
/// declarative constant.
class _Pearl {
  const _Pearl({
    required this.title,
    required this.body,
    required this.source,
  });

  final String title;
  final String body;
  final String source;
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
          'PsychSwitch · Decision support for healthcare professionals.\n'
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
