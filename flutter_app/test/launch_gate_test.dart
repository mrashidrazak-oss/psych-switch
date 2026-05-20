// Staged-launch contract.
//
// Guards LaunchGate so a refactor can't silently widen the curated
// closed-beta surface, and documents which routes are deliberately
// dark-shipped. When the founder un-stages for a full release, the
// `staged` expectation below is the intended one-line checkpoint.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/launch_gate.dart';
import 'package:psychswitch/src/router.dart';

void main() {
  group('LaunchGate staged-launch surface', () {
    const curated = <String>{
      Routes.equivalency,
      Routes.adverseEffects,
      Routes.polypharmacy,
      Routes.tdm,
      Routes.scales,
    };

    test('staged mode is on for the closed beta', () {
      expect(LaunchGate.staged, isTrue);
    });

    test('exactly the five curated tools are allowed', () {
      expect(LaunchGate.allowed, curated);
    });

    test('the five curated tools are visible', () {
      for (final route in curated) {
        expect(LaunchGate.isVisible(route), isTrue, reason: route);
      }
    });

    test('dark-shipped screens are not visible while staged', () {
      // These are the in-app jumps the leak audit closed off:
      // result → clozapine, Home bell → errata, search → glossary.
      for (final route in <String>[
        Routes.clozapine,
        Routes.errata,
        Routes.glossary,
        Routes.depotIndex,
        Routes.moodStabilizers,
        Routes.ramadan,
        Routes.calculators,
        Routes.dsm,
        Routes.crisis,
      ]) {
        expect(LaunchGate.isVisible(route), isFalse, reason: route);
      }
    });
  });
}
