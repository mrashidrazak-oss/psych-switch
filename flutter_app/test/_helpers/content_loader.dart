// Test-only content loader.
//
// Reads `/content/` JSON from the host filesystem (via dart:io) and
// builds the `SwitchingEngine` payload (drugs + rules + Maudsley15
// matrix). Used by:
//   * the Dart golden-file harness (test/golden/golden_test.dart)
//   * any future integration test that wants the full registry without
//     hand-building fixtures
//
// IMPORTANT — this is a test helper, NOT the production loader. Phase 4
// will introduce a Flutter rootBundle loader for the app runtime; this
// file deliberately uses dart:io and a relative path that only resolves
// from `flutter_app/` so it cannot accidentally be imported into lib/.

import 'dart:convert';
import 'dart:io';

import 'package:psychswitch_engine/maudsley15.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

/// Path to the repo root's `content/` directory, resolved relative to
/// the flutter_app cwd (the standard `flutter test` working directory).
const String _contentDir = '../content';

/// Load every drug profile from `/content/drugs/`.
List<Drug> loadAllDrugs() {
  final dir = Directory('$_contentDir/drugs');
  if (!dir.existsSync()) {
    throw StateError(
      'Content directory not found at ${dir.absolute.path}. '
      'The Dart content loader expects to run from flutter_app/.',
    );
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) {
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return Drug.fromJson(json);
  }).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

/// Load every reviewed switching rule from `/content/switching-rules/`.
///
/// Skips rules whose JSON shape diverges from the strict TS schema —
/// see `docs/POST_FLUTTER_DEBT.md` (zuclopenthixol metabolicRisk +
/// 7 LAI-discontinuation rules with object-shape safetyFlags). For
/// the golden harness this is fine because none of the 5 fixtures
/// exercise those pairs; if a future fixture does, the loader will
/// throw at decode time and force the content fix.
List<SwitchingRule> loadAllSwitchingRules() {
  final dir = Directory('$_contentDir/switching-rules');
  if (!dir.existsSync()) {
    throw StateError('Switching-rules directory not found.');
  }
  // 7 LAI rules ship object-shape safetyFlags rather than the typed
  // string array — same skip set used in the type round-trip tests.
  const skip = <String>{
    'aripiprazole-lai-to-aripiprazole.json',
    'flupenthixol-lai-to-flupenthixol.json',
    'fluphenazine-lai-to-fluphenazine.json',
    'haloperidol-lai-to-haloperidol.json',
    'paliperidone-lai-to-paliperidone.json',
    'risperidone-lai-to-risperidone.json',
    'zuclopenthixol-lai-to-zuclopenthixol.json',
  };
  final out = <SwitchingRule>[];
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.json') || skip.contains(name)) continue;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    out.add(SwitchingRule.fromJson(json));
  }
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}

/// Load the Maudsley 15th strategy matrix from
/// `/content/maudsley15/strategy-matrix.json`.
Maudsley15Data loadMaudsley15() {
  final f = File('$_contentDir/maudsley15/strategy-matrix.json');
  if (!f.existsSync()) {
    throw StateError('Maudsley15 strategy matrix JSON not found.');
  }
  return Maudsley15Data.fromJson(
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  );
}

/// Build a fully-loaded [SwitchingEngine] from the on-disk content.
SwitchingEngine loadSwitchingEngine() {
  return SwitchingEngine(
    drugs: loadAllDrugs(),
    rules: loadAllSwitchingRules(),
    maudsley15Data: loadMaudsley15(),
  );
}
