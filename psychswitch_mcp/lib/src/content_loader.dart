// Server-side content loader.
//
// Walks the repo's /content/ tree at startup and assembles the engine.
// Counterpart to flutter_app/lib/src/data/content_loader.dart, but
// reads from disk via dart:io rather than rootBundle (no Flutter at
// runtime).
//
// Path resolution: by default we look for `../content/` relative to
// the package root, matching the dev-time monorepo layout. Override
// via the PSYCHSWITCH_CONTENT_DIR env var if running outside the
// repo (e.g. installed globally via `dart pub global activate`).

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:psychswitch_engine/clozapine.dart';
import 'package:psychswitch_engine/maudsley15.dart';
import 'package:psychswitch_engine/mood_stabilizer_tapering.dart';
import 'package:psychswitch_engine/qtc_stacker.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';
import 'package:psychswitch_engine/types/switching_rule.dart';

/// Same skip-list as the Flutter content loader — 7 LAI rules ship
/// object-shape safetyFlags (POST_FLUTTER_DEBT.md tracks the fix).
const Set<String> _skippedRuleIds = <String>{
  'aripiprazole-lai-to-aripiprazole',
  'flupenthixol-lai-to-flupenthixol',
  'fluphenazine-lai-to-fluphenazine',
  'haloperidol-lai-to-haloperidol',
  'paliperidone-lai-to-paliperidone',
  'risperidone-lai-to-risperidone',
  'zuclopenthixol-lai-to-zuclopenthixol',
};

class ServerContent {
  const ServerContent({
    required this.engine,
    required this.qtcData,
    required this.lithiumTapering,
    required this.clozapine,
  });

  final SwitchingEngine engine;
  final QtcRiskData qtcData;
  final TaperingProtocol lithiumTapering;
  final ClozapineModule clozapine;
}

/// Resolve the on-disk `/content/` directory.
///
/// Order:
///   1. PSYCHSWITCH_CONTENT_DIR env var if set
///   2. ../content/ relative to the current working directory
///   3. ../content/ relative to the running script (handles
///      `dart pub global run` invocation)
String resolveContentDir() {
  final fromEnv = Platform.environment['PSYCHSWITCH_CONTENT_DIR'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  final cwd = Directory.current.path;
  final cwdCandidate = p.join(cwd, '..', 'content');
  if (Directory(cwdCandidate).existsSync()) return cwdCandidate;
  // Fall back to script-relative.
  final scriptDir = p.dirname(Platform.script.toFilePath());
  return p.normalize(p.join(scriptDir, '..', '..', 'content'));
}

/// Load + parse + assemble the engine from /content/.
Future<ServerContent> loadServerContent({String? contentDir}) async {
  final root = contentDir ?? resolveContentDir();
  if (!Directory(root).existsSync()) {
    throw StateError(
      'Content directory not found at "$root". '
      'Set PSYCHSWITCH_CONTENT_DIR or run from the monorepo root.',
    );
  }

  Map<String, dynamic> readJson(String relPath) {
    final file = File(p.join(root, relPath));
    if (!file.existsSync()) {
      throw StateError('Missing content file: ${file.path}');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> readJsonDir(String relDir) {
    final dir = Directory(p.join(root, relDir));
    if (!dir.existsSync()) {
      throw StateError('Missing content directory: ${dir.path}');
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files
        .map((f) => jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)
        .toList();
  }

  final drugs = readJsonDir('drugs').map(Drug.fromJson).toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  final rules = <SwitchingRule>[];
  for (final j in readJsonDir('switching-rules')) {
    final id = j['id'] as String?;
    if (id != null && _skippedRuleIds.contains(id)) continue;
    rules.add(SwitchingRule.fromJson(j));
  }
  rules.sort((a, b) => a.id.compareTo(b.id));

  final maudsley =
      Maudsley15Data.fromJson(readJson('maudsley15/strategy-matrix.json'));

  final qtc = QtcRiskData.fromJson(readJson('qtc/drug-qtc-risks.json'));

  final lithium = TaperingProtocol.fromJson(
    readJson('mood-stabilizers/lithium-tapering.json'),
  );

  final clozapineModule = ClozapineModule(
    ClozapineContent(
      femaleNonSmoker: TitrationProtocol.fromJson(
        readJson('clozapine/titration-female-non-smoker.json'),
      ),
      femaleSmoker: TitrationProtocol.fromJson(
        readJson('clozapine/titration-female-smoker.json'),
      ),
      maleNonSmoker: TitrationProtocol.fromJson(
        readJson('clozapine/titration-male-non-smoker.json'),
      ),
      maleSmoker: TitrationProtocol.fromJson(
        readJson('clozapine/titration-male-smoker.json'),
      ),
      monitoringSchedule: MonitoringScheduleData.fromJson(
        readJson('clozapine/monitoring-schedule.json'),
      ),
      safetyConsiderations: SafetyConsiderationsData.fromJson(
        readJson('clozapine/safety-considerations.json'),
      ),
      rechallengeRules: RechallengeRulesData.fromJson(
        readJson('clozapine/rechallenge-rules.json'),
      ),
      communityInitiation: CommunityInitiationData.fromJson(
        readJson('clozapine/community-initiation.json'),
      ),
    ),
  );

  return ServerContent(
    engine: SwitchingEngine(
      drugs: drugs,
      rules: rules,
      maudsley15Data: maudsley,
    ),
    qtcData: qtc,
    lithiumTapering: lithium,
    clozapine: clozapineModule,
  );
}
