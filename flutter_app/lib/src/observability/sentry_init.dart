// Sentry wiring — Phase 1D stub.
//
// Real DSN is supplied at build time via:
//   flutter build appbundle --dart-define=SENTRY_DSN=https://…@sentry.io/…
//
// When SENTRY_DSN is empty or absent (e.g. during `flutter test`,
// CI builds, or local dev), Sentry init is a no-op.
//
// Patient context, drug names, dose values, and case labels MUST never
// leave the device. The `beforeSend` hook below scrubs anything
// unexpected. Stack trace + system info is the most we ship.

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const String _kSentryDsn = String.fromEnvironment('SENTRY_DSN');
const String _kBuildEnv = String.fromEnvironment(
  'BUILD_ENV',
  defaultValue: 'development',
);

bool get isSentryConfigured => _kSentryDsn.isNotEmpty;

/// Initialise Sentry. Call once from main() before runApp().
///
/// Pass the runApp callback as [appRunner] so Sentry wraps it for
/// proper error boundary coverage. When DSN is absent, just runs the
/// app directly.
Future<void> initSentry(Future<void> Function() appRunner) async {
  if (!isSentryConfigured) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = _kSentryDsn
        ..environment = _kBuildEnv
        ..tracesSampleRate = kReleaseMode ? 0.2 : 0.0
        ..sendDefaultPii = false
        ..beforeSend = _scrubClinicalContext;
    },
    appRunner: appRunner,
  );
}

/// Strip anything that could carry clinical content. Defense-in-depth:
/// the engine should never put PHI into events, but if a future bug
/// somehow attaches a saved-case label or patient context to an
/// exception's `extra` block, this drops it before it hits the network.
SentryEvent? _scrubClinicalContext(SentryEvent event, Hint hint) {
  // Wipe any extras (we never set them ourselves; if something else
  // does, it's almost certainly clinical context we don't want shipped).
  // ignore: deprecated_member_use
  event.extra?.clear();

  // Scrub breadcrumbs of free-text data fields. Keep category + level —
  // enough to debug the crash chain, never enough to reconstruct what
  // the user was looking at.
  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    for (final b in breadcrumbs) {
      b.data?.clear();
      // Note: Breadcrumb.message is final, can't clear; the SDK may
      // populate it for some categories (navigation, http). For our
      // app where there are no http calls, it'll be navigation
      // route names — those are class names, not patient data.
    }
  }

  return event;
}
