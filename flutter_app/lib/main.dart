// PsychSwitch — Flutter migration entry point.
//
// Boot order:
//   1. Initialise Flutter binding + system overlay style.
//   2. Initialise Sentry (no-op when SENTRY_DSN is unset).
//   3. Mount the Riverpod scope.
//   4. Wrap the router in a [_DisclaimerGate]: until the user
//      acknowledges the decision-support disclaimer, no clinical
//      surface is reachable.
//
// Cold-start work is kept light: rootBundle decoding happens later
// inside `engineProvider`, off the main isolate via compute().

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/observability/sentry_init.dart';
import 'package:psychswitch/src/providers/disclaimer_provider.dart';
import 'package:psychswitch/src/providers/onboarding_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/screens/disclaimer_screen.dart';
import 'package:psychswitch/src/ui/screens/onboarding_screen.dart';
import 'package:psychswitch/src/ui/theme/app_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Translucent system bars so our scaffold colour shows through.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await initSentry(() async {
    runApp(
      const ProviderScope(
        child: PsychSwitchApp(),
      ),
    );
  });
}

class PsychSwitchApp extends StatefulWidget {
  const PsychSwitchApp({super.key});

  @override
  State<PsychSwitchApp> createState() => _PsychSwitchAppState();
}

class _PsychSwitchAppState extends State<PsychSwitchApp> {
  // Build the router once and re-use across rebuilds — recreating it
  // on every rebuild would lose navigation state.
  late final _router = buildRouter();
  // Build the theme once — it's a hot allocation and never changes.
  late final _theme = buildAppTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PsychSwitch',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      routerConfig: _router,
      // Cap text scaling so safety-critical layouts can't be broken by
      // extreme accessibility text sizes — but still respect the user's
      // preference up to 130%.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scaler = mq.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: scaler),
          child: _DisclaimerGate(
            child: _OnboardingGate(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the router only after the user has acknowledged the
/// decision-support disclaimer. Until then, only the [DisclaimerScreen]
/// is visible — there is no other path into the clinical surfaces.
///
/// The gate listens to [disclaimerAcknowledgedProvider] which is
/// backed by SharedPreferences; the provider's first build resolves
/// in <50ms typically, during which we show the dark surface so the
/// flicker from native splash → app is invisible.
class _DisclaimerGate extends ConsumerWidget {
  const _DisclaimerGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAck = ref.watch(disclaimerAcknowledgedProvider);
    return asyncAck.when(
      // Bridge the brief async-prefs read with a dark surface — never
      // a white frame.
      loading: () => const ColoredBox(color: AppColors.bg),
      // If prefs is genuinely broken we still render the gate; safer
      // to over-prompt than to slip past the disclaimer.
      error: (_, __) => const DisclaimerScreen(),
      data: (acknowledged) =>
          acknowledged ? child : const DisclaimerScreen(),
    );
  }
}

/// After the disclaimer, show the onboarding tour once. Returning
/// users (`markComplete()` flipped on a prior launch) skip straight
/// through to the router. Failure-mode bias: if SharedPreferences
/// errors, we treat the user as already-onboarded — better to skip
/// the tour for a returning user than to make them sit through it
/// every cold start.
class _OnboardingGate extends ConsumerWidget {
  const _OnboardingGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDone = ref.watch(onboardingCompleteProvider);
    return asyncDone.when(
      loading: () => const ColoredBox(color: AppColors.bg),
      error: (_, __) => child,
      data: (done) => done ? child : const OnboardingScreen(),
    );
  }
}
