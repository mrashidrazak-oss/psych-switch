// Shared loading + error views for the async engine provider.
//
// Every screen that watches `engineProvider` (or `loadedContentProvider`)
// uses these for the loading and error branches. Centralising them
// keeps the look consistent and prevents per-screen boilerplate.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
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
          const Gap.v(ClinicalSpace.lg),
          const Text('PsychSwitch', style: ClinicalText.subtitle),
          const Gap.v(ClinicalSpace.xs),
          const Text(
            'Loading clinical registry…',
            style: ClinicalText.caption,
          ),
          const Gap.v(ClinicalSpace.xl),
          const RepaintBoundary(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real brand mark — matches the dual-tone glow treatment used by the
/// Disclaimer's `_BrandHero`. Three cold-start surfaces (loading,
/// disclaimer, about) now share one mark instead of three.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ClinicalPalette.toneLavenderInk.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(-5, 6),
          ),
          BoxShadow(
            color: ClinicalPalette.toneMintInk.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(5, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        child: Image.asset(
          'assets/icon.png',
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
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
      padding: const EdgeInsets.all(ClinicalSpace.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ClinicalPalette.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: ClinicalPalette.danger,
                size: 28,
              ),
            ),
            const Gap.v(ClinicalSpace.lg),
            const Text(
              'Could not load clinical content',
              style: ClinicalText.subtitle,
              textAlign: TextAlign.center,
            ),
            const Gap.v(ClinicalSpace.sm),
            Text(
              '$error',
              style: ClinicalText.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
