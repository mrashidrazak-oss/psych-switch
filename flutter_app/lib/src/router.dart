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
//
// Phase 7C+ adds /clozapine and /depot.
//
// Routes are typed via `name` constants so screens never hard-code
// path strings.

import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/screens/about_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_screen.dart';
import 'package:psychswitch/src/ui/screens/depot_screen.dart';
import 'package:psychswitch/src/ui/screens/glossary_screen.dart';
import 'package:psychswitch/src/ui/screens/history_screen.dart';
import 'package:psychswitch/src/ui/screens/home_screen.dart';
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
}

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          name: Routes.home,
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: Routes.switch_,
          path: '/switch',
          builder: (context, state) => const SwitchScreen(),
        ),
        GoRoute(
          name: Routes.result,
          path: '/result',
          builder: (context, state) {
            final args = state.extra as ResultScreenArgs?;
            return ResultScreen(args: args);
          },
        ),
        GoRoute(
          name: Routes.history,
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          name: Routes.glossary,
          path: '/glossary',
          builder: (context, state) => const GlossaryScreen(),
        ),
        GoRoute(
          name: Routes.settings,
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          name: Routes.about,
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          name: Routes.clozapine,
          path: '/clozapine',
          builder: (context, state) => const ClozapineScreen(),
        ),
        GoRoute(
          name: Routes.depotIndex,
          path: '/depot',
          builder: (context, state) => const DepotIndexScreen(),
          routes: <RouteBase>[
            GoRoute(
              name: Routes.depot,
              path: ':id',
              builder: (context, state) {
                final kind = DepotKind.parse(state.pathParameters['id']);
                if (kind == null) {
                  // Unknown id → fall back to the index.
                  return const DepotIndexScreen();
                }
                return DepotProtocolScreen(kind: kind);
              },
            ),
          ],
        ),
      ],
    );
