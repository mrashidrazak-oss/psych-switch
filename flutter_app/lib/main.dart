// PsychSwitch — Flutter migration entry point.
//
// Starts Sentry (no-op when SENTRY_DSN is unset), creates the Riverpod
// scope that hosts the engine providers, and launches the go_router
// app shell. The Home screen does the engine load via
// `engineProvider.watch`, which keeps cold-start work off this entry
// point and gives every screen explicit loading/error states.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/observability/sentry_init.dart';
import 'package:psychswitch/src/router.dart';
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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
