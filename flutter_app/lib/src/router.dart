// App router — go_router config.
//
// Top-level routes:
//   /         → Home
//   /switch   → Switch wizard (drug pickers + dose inputs)
//   /result   → Result screen (schedule, safety flags, citations)
//   /history  → Saved cases list
//   /glossary → Clinical-term lookup
//   /settings → Toggles + destructive actions
//   /about    → Version, stats, licenses
//   /clozapine→ Clozapine module (5 tabs)
//   /depot    → Depot LAI index, with /:id detail children
//
// Routes are typed via `name` constants so screens never hard-code
// path strings.
//
// Every route uses [_fadeThroughPage] so navigation feels smooth and
// brand-cohesive instead of the platform-default slide. The transition
// auto-disables when MediaQuery.disableAnimations is true (system
// reduced-motion preference) — accessibility-correct without ceremony.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/screens/about_screen.dart';
import 'package:psychswitch/src/ui/screens/adverse_effects_screen.dart';
import 'package:psychswitch/src/ui/screens/calculators_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_screen.dart';
import 'package:psychswitch/src/ui/screens/depot_screen.dart';
import 'package:psychswitch/src/ui/screens/drug_profile_screen.dart';
import 'package:psychswitch/src/ui/screens/equivalency_screen.dart';
import 'package:psychswitch/src/ui/screens/errata_screen.dart';
import 'package:psychswitch/src/ui/screens/glossary_screen.dart';
import 'package:psychswitch/src/ui/screens/history_screen.dart';
import 'package:psychswitch/src/ui/screens/home_screen.dart';
import 'package:psychswitch/src/ui/screens/lithium_tapering_screen.dart';
import 'package:psychswitch/src/ui/screens/mood_stabilizer_detail_screen.dart';
import 'package:psychswitch/src/ui/screens/mood_stabilizer_home_screen.dart';
import 'package:psychswitch/src/ui/screens/qtc_stacker_screen.dart';
import 'package:psychswitch/src/ui/screens/ramadan_screen.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/screens/settings_screen.dart';
import 'package:psychswitch/src/ui/screens/switch_screen.dart';

/// Named route ids — kept in one place so screen code never hard-codes
/// path strings.
abstract final class Routes {
  static const home = 'home';
  static const switch_ = 'switch';
  static const result = 'result';
  static const history = 'history';
  static const glossary = 'glossary';
  static const settings = 'settings';
  static const about = 'about';
  static const clozapine = 'clozapine';
  static const depotIndex = 'depot_index';
  static const depot = 'depot';
  static const moodStabilizers = 'mood_stabilizers';
  static const moodStabilizerDetail = 'mood_stabilizer_detail';
  static const lithiumTapering = 'lithium_tapering';
  static const qtcStacker = 'qtc_stacker';
  static const errata = 'errata';
  static const adverseEffects = 'adverse_effects';
  static const equivalency = 'equivalency';
  static const drugProfile = 'drug_profile';
  static const ramadan = 'ramadan';
  static const calculators = 'calculators';
}

/// Custom fade-through page builder. Mirrors Material's fade-through
/// motion spec — incoming page fades in from 92% scale, outgoing page
/// fades out — but kept short (200ms) so it never feels in the way.
CustomTransitionPage<T> _fadeThroughPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Honour system reduced-motion preference.
      if (MediaQuery.disableAnimationsOf(context)) return child;

      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      );
      final scaleIn = Tween<double>(begin: 0.985, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      );
      return FadeTransition(
        opacity: ReverseAnimation(fadeOut),
        child: FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(scale: scaleIn, child: child),
        ),
      );
    },
  );
}

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          name: Routes.home,
          path: '/',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const HomeScreen()),
        ),
        GoRoute(
          name: Routes.switch_,
          path: '/switch',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const SwitchScreen()),
        ),
        GoRoute(
          name: Routes.result,
          path: '/result',
          pageBuilder: (context, state) {
            final args = state.extra as ResultScreenArgs?;
            return _fadeThroughPage(
              state: state,
              child: ResultScreen(args: args),
            );
          },
        ),
        GoRoute(
          name: Routes.history,
          path: '/history',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const HistoryScreen()),
        ),
        GoRoute(
          name: Routes.glossary,
          path: '/glossary',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const GlossaryScreen()),
        ),
        GoRoute(
          name: Routes.settings,
          path: '/settings',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const SettingsScreen()),
        ),
        GoRoute(
          name: Routes.about,
          path: '/about',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const AboutScreen()),
        ),
        GoRoute(
          name: Routes.clozapine,
          path: '/clozapine',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const ClozapineScreen()),
        ),
        GoRoute(
          name: Routes.moodStabilizers,
          path: '/mood-stabilizers',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MoodStabilizerHomeScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: Routes.moodStabilizerDetail,
              path: ':id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return _fadeThroughPage(
                  state: state,
                  child: MoodStabilizerDetailScreen(drugId: id),
                );
              },
            ),
          ],
        ),
        GoRoute(
          name: Routes.lithiumTapering,
          path: '/lithium-tapering',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const LithiumTaperingScreen(),
          ),
        ),
        GoRoute(
          name: Routes.qtcStacker,
          path: '/qtc-stacker',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const QtcStackerScreen(),
          ),
        ),
        GoRoute(
          name: Routes.errata,
          path: '/errata',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ErrataScreen(),
          ),
        ),
        GoRoute(
          name: Routes.adverseEffects,
          path: '/adverse-effects',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AdverseEffectsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.equivalency,
          path: '/equivalency',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const EquivalencyScreen(),
          ),
        ),
        GoRoute(
          name: Routes.drugProfile,
          path: '/drug/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _fadeThroughPage(
              state: state,
              child: DrugProfileScreen(drugId: id),
            );
          },
        ),
        GoRoute(
          name: Routes.ramadan,
          path: '/ramadan',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const RamadanScreen(),
          ),
        ),
        GoRoute(
          name: Routes.calculators,
          path: '/calculators',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CalculatorsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.depotIndex,
          path: '/depot',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const DepotIndexScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: Routes.depot,
              path: ':id',
              pageBuilder: (context, state) {
                final kind = DepotKind.parse(state.pathParameters['id']);
                final child = kind == null
                    // Unknown id → fall back to the index.
                    ? const DepotIndexScreen()
                    : DepotProtocolScreen(kind: kind);
                return _fadeThroughPage(state: state, child: child);
              },
            ),
          ],
        ),
      ],
    );
