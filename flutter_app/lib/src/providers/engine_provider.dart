// Engine providers — Riverpod scope for the loaded clinical content.
//
// `engineProvider` is the entry point: a `FutureProvider` that calls
// the runtime content loader once at app startup. Every screen that
// needs the engine listens to it via `ref.watch(engineProvider)`.
//
// The async-only API (no synchronous accessor) is deliberate: we never
// want a screen to render with a partially-loaded engine, and Riverpod's
// AsyncValue handling makes the loading + error states explicit at
// every call site.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:psychswitch/src/data/content_loader.dart';
import 'package:psychswitch/src/engine/switching_engine.dart';

/// Loads the entire clinical content bundle exactly once, asynchronously.
///
/// Watch via:
///   ```dart
///   final asyncContent = ref.watch(loadedContentProvider);
///   asyncContent.when(
///     loading: () => SplashWidget(),
///     error: (e, st) => ContentLoadErrorWidget(error: e),
///     data: (content) => HomeScreen(engine: content.engine),
///   );
///   ```
final loadedContentProvider = FutureProvider<LoadedContent>(
  (ref) => loadContent(),
);

/// Convenience: the [SwitchingEngine] subset of the loaded content,
/// with the same async loading characteristics. Most screens only need
/// the engine — providing this saves them from `.engine` chaining.
final engineProvider = FutureProvider<SwitchingEngine>((ref) async {
  final content = await ref.watch(loadedContentProvider.future);
  return content.engine;
});
