// PsychSwitch — Flutter migration entry point.
//
// Phase 1 placeholder. The real app structure (theme, routing,
// Riverpod scope, error boundary) lands in subsequent phases. For
// now this is just enough to:
//   • verify the build works
//   • initialise Sentry when SENTRY_DSN is provided at build time
//   • render a placeholder screen using the locked design tokens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/observability/sentry_init.dart';
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

class PsychSwitchApp extends StatelessWidget {
  const PsychSwitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const _ComingSoonScreen(),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PsychSwitch',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Flutter migration · v0.5.0-alpha.0',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PHASE 1 — FOUNDATION',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (isSentryConfigured) ...[
                const SizedBox(height: 12),
                const Text(
                  'Sentry: configured',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
