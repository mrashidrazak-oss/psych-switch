// Tests for the Dart errata port. Mirrors engine/__tests__/errata.test.ts.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/errata.dart';

void main() {
  group('errata feed', () {
    test('listErrata returns at least one entry', () {
      expect(listErrata(), isNotEmpty);
    });

    test('entries are sorted newest first', () {
      final all = listErrata();
      for (var i = 1; i < all.length; i++) {
        expect(
          all[i].dateISO.compareTo(all[i - 1].dateISO),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('every entry has required fields', () {
      final isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');
      final semver = RegExp(r'^\d+\.\d+');
      for (final e in listErrata()) {
        expect(e.id, isNotEmpty);
        expect(isoDate.hasMatch(e.dateISO), isTrue);
        expect(e.scope, isNotEmpty);
        expect(e.scopeLabel, isNotEmpty);
        expect(e.summary, isNotEmpty);
        expect(e.detail, isNotEmpty);
        expect(e.rationale, isNotEmpty);
        expect(e.reviewer, isNotEmpty);
        expect(semver.hasMatch(e.appVersion), isTrue);
      }
    });

    test('errataCount matches listErrata length', () {
      expect(errataCount(), equals(listErrata().length));
    });

    test('errataForScope filters by scope', () {
      final paroxetine = errataForScope('paroxetine');
      expect(paroxetine, isNotEmpty);
      expect(paroxetine.every((e) => e.scope == 'paroxetine'), isTrue);
    });

    test('errataForRule alias works the same as errataForScope', () {
      expect(
        errataForRule('paroxetine').length,
        equals(errataForScope('paroxetine').length),
      );
    });

    test(
        'errataSinceVersion ignores entries from before the given version',
        () {
      final since = errataSinceVersion('0.3.0');
      // Every entry should be ≥ 0.3 by major.minor.
      for (final e in since) {
        final parts = e.appVersion.split('.');
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        expect(major > 0 || (major == 0 && minor >= 3), isTrue,
            reason: 'unexpected version ${e.appVersion}');
      }
    });

    test('errataSinceVersion("0.0.0") returns everything', () {
      expect(errataSinceVersion('0.0.0').length, equals(listErrata().length));
    });

    test('errataSinceVersion("99.0.0") returns nothing', () {
      expect(errataSinceVersion('99.0.0'), isEmpty);
    });

    test('label helpers return user-facing strings', () {
      expect(severityLabel(ErrataSeverity.critical), equals('Critical'));
      expect(changeKindLabel(ErrataChangeKind.dose), equals('Dose'));
      expect(changeKindLabel(ErrataChangeKind.safetyFlag),
          equals('Safety flag'));
      expect(changeKindLabel(ErrataChangeKind.newRule), equals('New rule'));
    });

    test('severityColorTokens returns non-empty tokens for each severity',
        () {
      for (final s in ErrataSeverity.values) {
        final c = severityColorTokens(s);
        expect(c.bg, isNotEmpty);
        expect(c.text, isNotEmpty);
        expect(c.border, isNotEmpty);
      }
    });
  });

  group('jsonValue round-trips', () {
    test('every ErrataChangeKind serialises and parses identically', () {
      for (final k in ErrataChangeKind.values) {
        expect(ErrataChangeKind.fromJson(k.jsonValue), equals(k));
      }
    });

    test('every ErrataSeverity serialises and parses identically', () {
      for (final s in ErrataSeverity.values) {
        expect(ErrataSeverity.fromJson(s.jsonValue), equals(s));
      }
    });
  });

  group('ErrataEntry.toJson', () {
    test('omits before/after when null', () {
      final entry = listErrata()
          .firstWhere((e) => e.id == '2026-05-08-paroxetine-pregnancy-trimester');
      final j = entry.toJson();
      expect(j.containsKey('before'), isFalse);
      expect(j.containsKey('after'), isFalse);
    });

    test('includes before/after when present', () {
      final entry = listErrata()
          .firstWhere((e) => e.id == '2026-05-08-pp3m-bridge-dose');
      final j = entry.toJson();
      expect(j['before'], isNotNull);
      expect(j['after'], isNotNull);
    });

    test('serialises changeKind and severity as JSON literals', () {
      final j = listErrata().first.toJson();
      expect(j['changeKind'], isA<String>());
      expect(j['severity'], isA<String>());
    });
  });
}
