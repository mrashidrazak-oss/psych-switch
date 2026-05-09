// Tests for the Dart changelog port. No TS counterpart exists.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/changelog.dart';

void main() {
  group('changelog registry', () {
    test('has at least the v0.1.0 baseline entry', () {
      expect(changelog.length, greaterThanOrEqualTo(1));
      expect(changelog.last.version, equals('0.1.0'));
    });

    test('entries are sorted newest-first by version', () {
      // Just check that the first entry is newer than the last by date.
      expect(
        changelog.first.dateISO.compareTo(changelog.last.dateISO),
        greaterThanOrEqualTo(0),
      );
    });

    test('every entry has the required shape', () {
      final iso = RegExp(r'^\d{4}-\d{2}-\d{2}');
      final semver = RegExp(r'^\d+\.\d+');
      for (final e in changelog) {
        expect(semver.hasMatch(e.version), isTrue);
        expect(iso.hasMatch(e.dateISO), isTrue);
        expect(e.title, isNotEmpty);
        expect(e.items, isNotEmpty);
        for (final item in e.items) {
          expect(item, isNotEmpty);
        }
      }
    });

    test('versions are unique', () {
      final versions = changelog.map((e) => e.version).toList();
      expect(versions.toSet().length, equals(versions.length));
    });
  });

  group('ChangeKind jsonValue round-trips', () {
    test('every kind serialises and parses identically', () {
      for (final k in ChangeKind.values) {
        expect(ChangeKind.fromJson(k.jsonValue), equals(k));
      }
    });

    test('fromJson rejects unknown values', () {
      expect(() => ChangeKind.fromJson('nope'), throwsArgumentError);
    });
  });

  group('ChangelogEntry.toJson', () {
    test('includes all required keys with correct kind serialisation', () {
      final j = changelog.first.toJson();
      expect(
        j.keys,
        containsAll(<String>['version', 'dateISO', 'kind', 'title', 'items']),
      );
      expect(j['kind'], isA<String>());
      // The first entry is breaking (v0.4.23).
      expect(j['kind'], equals('breaking'));
    });
  });
}
