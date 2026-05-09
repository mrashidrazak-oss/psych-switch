// App router — go_router config.
//
// Three top-level routes for Phase 4:
//   /         → Home
//   /switch   → Switch wizard (drug pickers + dose inputs)
//   /result   → Result screen (schedule, safety flags, citations)
//
// Phase 5+ adds /history, /clozapine, /depot, /settings, /about.
//
// Routes are typed via `name` constants so screens can navigate via
// `context.goNamed(Routes.switch_)` rather than hard-coded strings.

import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/screens/home_screen.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/screens/switch_screen.dart';

/// Named route ids — kept in one place so screen code never hard-codes
/// path strings.
abstract final class Routes {
  static const home = 'home';
  static const switch_ = 'switch';
  static const result = 'result';
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
      ],
    );
