// PsychSwitch — Flutter migration entry point.
//
// Starts Sentry (no-op when SENTRY_DSN is unset), creates the Riverpod
// scope that hosts the engine providers, and launches the go_router
// app shell. The Home screen does the engine load via
// `engineProvider.watch`, which keeps cold-start work off this entry
// point and gives every screen explicit loading/error states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/observability/sentry_init.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PsychSwitch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.accent,
          secondary: AppColors.from,
          tertiary: AppColors.to,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}
