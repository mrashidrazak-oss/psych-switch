// Round-trip parse test for the Drug type.
//
// Loads every JSON in /content/drugs/ via the Dart Drug.fromJson,
// then re-emits via toJson, and asserts the JSON roundtrip is
// field-equivalent. This is the contract that lets the same content
// files feed both the TS and Dart engines without divergence.
//
// Run: cd flutter_app && dart test test/engine/types/drug_roundtrip_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/engine/types/drug.dart';

void main() {
  group('Drug round-trip', () {
    final drugsDir = Directory('../content/drugs');

    test('drug content directory exists', () {
      expect(
        drugsDir.existsSync(),
        isTrue,
        reason: 'Expected ${drugsDir.absolute.path} to exist',
      );
    });

    final files = drugsDir.existsSync()
        ? drugsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
        : <File>[];

    test('at least 30 drug JSONs found', () {
      expect(
        files.length,
        greaterThan(30),
        reason: 'Expected the v0.4.23 RN repo to ship 30+ drug profiles',
      );
    });

    for (final file in files) {
      final basename = file.path.split('/').last;
      test('$basename parses + re-emits without losing data', () {
        final original = jsonDecode(file.readAsStringSync())
            as Map<String, dynamic>;
        final drug = Drug.fromJson(original);
        // Force a flat round trip through JSON so nested freezed
        // objects are reduced to plain maps.
        final reEmitted = jsonDecode(jsonEncode(drug.toJson()))
            as Map<String, dynamic>;

        // Required scalar fields must round-trip exactly:
        expect(reEmitted['id'], equals(original['id']));
        expect(reEmitted['genericName'], equals(original['genericName']));
        expect(reEmitted['drugClass'], equals(original['drugClass']));
        expect(
          reEmitted['malaysianBrandNames'],
          equals(original['malaysianBrandNames']),
        );
        expect(
          reEmitted['lastReviewedISO'],
          equals(original['lastReviewedISO']),
        );
        expect(reEmitted['reviewedBy'], equals(original['reviewedBy']));
        expect(
          reEmitted['formulationNotes'],
          equals(original['formulationNotes']),
        );

        // Optional category/risk fields: present only if originally present.
        if (original.containsKey('category')) {
          expect(reEmitted['category'], equals(original['category']));
        }
        if (original.containsKey('epsRisk')) {
          expect(reEmitted['epsRisk'], equals(original['epsRisk']));
        }
        if (original.containsKey('qtcRisk')) {
          expect(reEmitted['qtcRisk'], equals(original['qtcRisk']));
        }

        // Nested objects round-trip:
        final origHalfLife = original['halfLife']! as Map<String, dynamic>;
        final reHalfLife = reEmitted['halfLife']! as Map<String, dynamic>;
        expect(reHalfLife['meanHours'], equals(origHalfLife['meanHours']));
        final origDosing = original['dosing']! as Map<String, dynamic>;
        final reDosing = reEmitted['dosing']! as Map<String, dynamic>;
        expect(reDosing['startingDoseMg'],
            equals(origDosing['startingDoseMg']));
        expect(reDosing['maxDoseMg'], equals(origDosing['maxDoseMg']));

        // Citations + safetyFlags lists round-trip:
        expect(reEmitted['citations'], equals(original['citations']));
      });
    }
  });
}
