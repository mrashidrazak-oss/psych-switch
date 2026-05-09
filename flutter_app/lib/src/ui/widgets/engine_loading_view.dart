// Shared loading + error views for the async engine provider.
//
// Every screen that watches `engineProvider` (or `loadedContentProvider`)
// uses these for the loading and error branches. Centralising them
// keeps the look consistent and prevents per-screen boilerplate.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Splash shown while `assets/content_bundle.json` is decoding into a
/// `SwitchingEngine`. Cold-start typically resolves in <100 ms, but
/// when it does flash we want users to see a deliberate brand surface
/// rather than a bare spinner.
class EngineLoadingView extends StatelessWidget {
  const EngineLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Brand mark — faint, monogram-style. Animated entrance so it
          // never appears jarring on quick loads.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 8),
                child: const _BrandMark(),
              ),
            ),
          ),
          const Gap.v(AppSpace.lg),
          const Text('PsychSwitch', style: AppTextSizes.subtitle),
          const Gap.v(AppSpace.xs),
          const Text(
            'Loading clinical registry…',
            style: AppTextSizes.caption,
          ),
          const Gap.v(AppSpace.xl),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.from, AppColors.to],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

/// Displayed when the bundle fails to decode. This is a hard failure
/// — the app cannot function clinically without the registry — so we
/// show the error verbatim rather than swallowing it.
class EngineErrorView extends StatelessWidget {
  const EngineErrorView({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 28,
              ),
            ),
            const Gap.v(AppSpace.lg),
            const Text(
              'Could not load clinical content',
              style: AppTextSizes.subtitle,
              textAlign: TextAlign.center,
            ),
            const Gap.v(AppSpace.sm),
            Text(
              '$error',
              style: AppTextSizes.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
