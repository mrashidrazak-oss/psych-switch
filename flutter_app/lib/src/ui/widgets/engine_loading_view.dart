// Shared loading + error views for the async engine provider.
//
// Every screen that watches `engineProvider` (or `loadedContentProvider`)
// uses these for the loading and error branches. Centralising them
// keeps the look consistent and prevents per-screen boilerplate.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Spinner shown while `assets/content_bundle.json` is decoding into a
/// `SwitchingEngine`. Cold-start typically resolves in <100 ms on a
/// modern device, so users almost never see this.
class EngineLoadingView extends StatelessWidget {
  const EngineLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.muted,
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
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load clinical content',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
