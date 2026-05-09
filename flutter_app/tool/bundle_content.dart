// Build-time content bundler.
//
// Walks the repo's `/content/` tree and emits a single
// `flutter_app/assets/content_bundle.json` file that the production
// app loads at startup via `rootBundle.loadString`.
//
// Why one bundle vs N assets:
//   • Flutter assets must live within (or be referenced from) the
//     package; /content/ stays at repo root for dual TS+Dart access.
//     A single bundled JSON is simpler than orchestrating asset
//     declarations or symlinks.
//   • One disk read at startup is faster than 170+ small reads.
//   • The whole engine fits comfortably in memory (the TS Webpack
//     bundle inlines the same data already).
//
// Usage:
//   dart run tool/bundle_content.dart
//
// Run from `flutter_app/`. Reads from `../content/`. Writes to
// `assets/content_bundle.json` (overwrites if present).
//
// CI runs this before `flutter test` / `flutter build` so the
// committed bundle is always re-derivable from source.

import 'dart:convert';
import 'dart:io';

const String _contentDir = '../content';
const String _outPath = 'assets/content_bundle.json';

void main() {
  final out = <String, dynamic>{
    'drugs': _readJsonDir('$_contentDir/drugs'),
    'switching-rules': _readJsonDir('$_contentDir/switching-rules'),
    'maudsley15': _readJsonFile(
      '$_contentDir/maudsley15/strategy-matrix.json',
    ),
    'qtc': _readJsonFile('$_contentDir/qtc/drug-qtc-risks.json'),
    'mood-stabilizers': <String, dynamic>{
      'lithium-tapering': _readJsonFile(
        '$_contentDir/mood-stabilizers/lithium-tapering.json',
      ),
    },
    'clozapine': <String, dynamic>{
      'titration-female-non-smoker': _readJsonFile(
        '$_contentDir/clozapine/titration-female-non-smoker.json',
      ),
      'titration-female-smoker': _readJsonFile(
        '$_contentDir/clozapine/titration-female-smoker.json',
      ),
      'titration-male-non-smoker': _readJsonFile(
        '$_contentDir/clozapine/titration-male-non-smoker.json',
      ),
      'titration-male-smoker': _readJsonFile(
        '$_contentDir/clozapine/titration-male-smoker.json',
      ),
      'monitoring-schedule': _readJsonFile(
        '$_contentDir/clozapine/monitoring-schedule.json',
      ),
      'safety-considerations': _readJsonFile(
        '$_contentDir/clozapine/safety-considerations.json',
      ),
      'rechallenge-rules': _readJsonFile(
        '$_contentDir/clozapine/rechallenge-rules.json',
      ),
      'community-initiation': _readJsonFile(
        '$_contentDir/clozapine/community-initiation.json',
      ),
    },
  };

  final outFile = File(_outPath);
  outFile.parent.createSync(recursive: true);
  // Compact JSON — readable enough via prettier on diff inspection,
  // saves ~40% on bundle size vs indented.
  outFile.writeAsStringSync(jsonEncode(out));

  // print is the natural way for a build-time CLI tool to surface
  // status; this is a one-shot script invoked manually or in CI, not
  // long-running app code.
  // ignore: avoid_print
  print(
    '📦 wrote $_outPath '
    '(${(outFile.lengthSync() / 1024).toStringAsFixed(1)} KB · '
    '${(out['drugs'] as Map).length} drugs · '
    '${(out['switching-rules'] as Map).length} rules)',
  );
}

/// Read every `*.json` file in [dirPath] and return a `Map` keyed by
/// file basename (without extension).
Map<String, dynamic> _readJsonDir(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    throw StateError('Bundler: directory not found at $dirPath');
  }
  final out = <String, dynamic>{};
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.json')) continue;
    final id = name.substring(0, name.length - '.json'.length);
    out[id] = jsonDecode(f.readAsStringSync());
  }
  return out;
}

dynamic _readJsonFile(String path) {
  final f = File(path);
  if (!f.existsSync()) {
    throw StateError('Bundler: file not found at $path');
  }
  return jsonDecode(f.readAsStringSync());
}
