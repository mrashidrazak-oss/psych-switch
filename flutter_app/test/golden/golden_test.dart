// Golden-file engine harness — Dart side.
//
// Loads every fixture in /test/golden/fixtures/, runs the named engine
// function through the Dart port, and compares against the SAME
// snapshot the TypeScript harness writes to /test/golden/snapshots/.
//
// Identical snapshots = identical engine behavior = no drift between
// the TS reference engine and the Dart port.
//
// Modes:
//   • Default:        compare current Dart output against snapshot. Fail on diff.
//   • CAPTURE=1 env:  write Dart output as the new snapshot.
//                     ONLY use this on a clean Dart-side change that we
//                     also intend to make on the TS side. The default
//                     workflow is: change TS, regenerate snapshot from
//                     TS, then run this harness to verify Dart agrees.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/switching_engine.dart';

import '../_helpers/content_loader.dart';

const String _fixturesDir = '../test/golden/fixtures';
const String _snapshotsDir = '../test/golden/snapshots';

/// Whether to overwrite snapshots with the current Dart output instead
/// of comparing. Set the `CAPTURE` env var to `1` to enable.
bool get _capture => Platform.environment['CAPTURE'] == '1';

/// Stable-key JSON serializer. Sorts every map's keys recursively so
/// the snapshot diffs stay legible regardless of how each engine emits
/// keys. Mirrors the TS `stableStringify` byte-for-byte (2-space indent,
/// keys ascending).
///
/// Round-trips through `jsonEncode` + `jsonDecode` first to flatten any
/// freezed-generated nested objects (whose synchronous `toJson()` only
/// runs at JsonEncoder time) into primitive `Map`s/`List`s. Otherwise
/// `_sortRecursive` would skip nested instances that aren't yet Maps.
String stableStringify(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  final flattened = jsonDecode(jsonEncode(value));
  return encoder.convert(_sortRecursive(flattened));
}

dynamic _sortRecursive(Object? value) {
  if (value is Map) {
    // Skip null-valued entries — TS `JSON.stringify` omits `undefined`
    // fields, so the snapshots have no `null` keys. Dart freezed
    // toJson emits explicit `null` for unset optionals; strip them
    // here so byte equality with the TS snapshot holds.
    final keys = value.keys
        .cast<String>()
        .where((k) => value[k] != null)
        .toList()
      ..sort();
    return <String, dynamic>{
      for (final k in keys) k: _sortRecursive(value[k]),
    };
  }
  if (value is List) {
    return value.map(_sortRecursive).toList();
  }
  // Encode whole-valued doubles as ints so `100.0` round-trips as `100`,
  // matching TS `JSON.stringify` (which has only one number type).
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return value;
}

/// Dispatch table from fixture `engine` field to a Dart engine call.
/// Each entry: SwitchingEngine + raw input → JSON-serialisable output.
typedef EngineFn = Object? Function(
  SwitchingEngine engine,
  Map<String, dynamic> input,
);

final Map<String, EngineFn> _engines = <String, EngineFn>{
  'generateSwitchPlan': (engine, input) {
    final plan = engine.generateSwitchPlan(
      SwitchInput(
        fromDrugId: input['fromDrugId'] as String,
        fromDoseMg: input['fromDoseMg'] as num,
        toDrugId: input['toDrugId'] as String,
        toDoseMg: input['toDoseMg'] as num,
      ),
    );
    return plan.toJson();
  },
};

class _Fixture {
  const _Fixture({
    required this.path,
    required this.name,
    required this.engineKey,
    required this.input,
  });

  final String path;
  final String name;
  final String engineKey;
  final Map<String, dynamic> input;
}

List<_Fixture> _loadFixtures() {
  final dir = Directory(_fixturesDir);
  if (!dir.existsSync()) return const <_Fixture>[];
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) {
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return _Fixture(
      path: f.path,
      name: json['name'] as String,
      engineKey: json['engine'] as String,
      input: json['input'] as Map<String, dynamic>,
    );
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  // Build the engine once — drug + rule registry doesn't change per test.
  final engine = loadSwitchingEngine();
  final fixtures = _loadFixtures();
  final snapshotsDir = Directory(_snapshotsDir);
  if (!snapshotsDir.existsSync()) snapshotsDir.createSync(recursive: true);

  group('Golden-file engine harness — Dart side', () {
    test('at least 5 fixtures present (Phase 1C minimum)', () {
      expect(fixtures.length, greaterThanOrEqualTo(5));
    });

    for (final fixture in fixtures) {
      final fixtureName =
          fixture.path.split(Platform.pathSeparator).last.replaceAll(
                RegExp(r'\.json$'),
                '',
              );
      final snapshotPath =
          '$_snapshotsDir${Platform.pathSeparator}$fixtureName.json';

      test('fixture: ${fixture.name}', () {
        final engineFn = _engines[fixture.engineKey];
        expect(
          engineFn,
          isNotNull,
          reason: 'No Dart engine registered for "${fixture.engineKey}"',
        );

        final output = engineFn!(engine, fixture.input);
        final serialized = stableStringify(output);

        if (_capture) {
          File(snapshotPath).writeAsStringSync('$serialized\n');
          // print is the natural way to surface CAPTURE-mode progress
          // to the developer running tests; it's a one-shot status line
          // not log noise.
          // ignore: avoid_print
          print('  📸 captured $fixtureName.json');
          return;
        }

        // Verify mode: snapshot must exist and bytes must match.
        final snapshotFile = File(snapshotPath);
        expect(
          snapshotFile.existsSync(),
          isTrue,
          reason: 'Missing snapshot at $snapshotPath',
        );
        final expected = snapshotFile.readAsStringSync().trim();
        expect(
          serialized,
          equals(expected),
          reason:
              'Dart engine output differs from snapshot for "$fixtureName".\n'
              'Run the TS harness with CAPTURE=1 first if the divergence is intentional.',
        );
      });
    }
  });
}
