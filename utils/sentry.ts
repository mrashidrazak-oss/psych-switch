// Sentry wiring — currently a NO-OP STUB.
//
// History: v0.3.0 wired @sentry/react-native, but the package's peer-dep
// graph clashes with pnpm's hoisted layout in Expo SDK 54 (it expects a
// nested @sentry/react it doesn't actually ship in its dist). Rather
// than fight the bundler, we ship the stub: same exported surface, no
// native module, and we'll re-introduce a real reporter only when we
// switch from Expo Go to a custom development build (where we can pin
// versions and run the Sentry config-plugin properly).
//
// What still works:
//   • ErrorBoundary catches render errors and shows the fallback UI.
//   • setCrashReporter(...) hook is still there — call it with any
//     reporter you want (Bugsnag, custom HTTP endpoint, etc.).
//
// To re-introduce Sentry later (custom dev build):
//   1. pnpm add @sentry/react-native@~8.x
//   2. Add the Expo plugin to app.json: "@sentry/react-native/expo".
//   3. Restore initSentry() with the previous code (see git log).
//   4. Run `eas build` (NOT Expo Go).

import { setCrashReporter } from '../components/ErrorBoundary';

let _initialised = false;

/**
 * No-op in this build. Kept as a stable entry point so callers don't
 * need to be conditionally guarded.
 */
export function initSentry(): void {
  if (_initialised) return;
  _initialised = true;

  // Wire a console reporter in dev so opt-ins still see *something*
  // useful when they trigger an error during local testing.
  if (__DEV__) {
    setCrashReporter((err, info) => {
      // eslint-disable-next-line no-console
      console.warn('[crash-reporter:dev]', err?.message ?? err, info?.componentStack);
    });
  }
}

/**
 * No-op stub. Real builds with Sentry restored will re-route this to
 * Sentry.captureException.
 */
export function reportNonFatal(_err: unknown, _tag?: string): void {
  /* no-op */
}
